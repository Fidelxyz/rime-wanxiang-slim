---Filters candidates by matching secondary auxiliary codes (entered after a trigger character) against reverse lookup
---dictionaries or candidate comments, supporting fuzzy matching and multiple data sources.
---@author amzxyz
---@author Fidel Yin <fidel.yin@hotmail.com>

---@alias LookupSource "aux_code"|"dictionary"

---@class LookupFilterConfig
---@field tags string[]
---@field trigger string?
---@field sources LookupSource[]
---@field reverse_lookup ReverseLookup?
---@field component_projection Projection?
---@field stroke_projection Projection?
---@field comment_split_pattern string?
---@field bypass_prefix string?

---@class LookupFilterState
---@field db_cache SegmentedCache<{component_match_codes: string[], stroke_match_codes: string[]}>
---@field comment_cache SegmentedCache<string[][]|false>
---
---@field select_notifier Connection?

---@diagnostic disable-next-line: duplicate-type
---@class Env
---@field lookup_filter_config LookupFilterConfig?
---@field lookup_filter_state LookupFilterState?

local utils = require("utils.utils")
local SegmentedCache = require("utils.segmented_cache")

-- Maximum number of live entries per cache generation. A cache holds between
-- `MAX_CACHE_SIZE` and `2 * MAX_CACHE_SIZE` entries before its coldest
-- generation is dropped.
local MAX_CACHE_SIZE = 1024

---Return whether any string in `list` starts with the literal `prefix`.
---@param list string[]
---@param prefix string
---@return boolean
local function any_starts_with(list, prefix)
    for i = 1, #list do
        if list[i]:find(prefix, 1, true) == 1 then
            return true
        end
    end
    return false
end

---Find the start of the rightmost literal occurrence of `needle` at or after `init`.
---@param haystack string
---@param needle string
---@param init integer
---@return integer? match_start
local function find_last(haystack, needle, init)
    ---@type integer?
    local match_start = nil
    local scan_from = init
    while true do
        local hit_start = haystack:find(needle, scan_from, true)
        if not hit_start then
            break
        end
        match_start = hit_start
        scan_from = hit_start + 1
    end
    return match_start
end

---Load component and stroke projection rules from a schema.
---@param schema_id string
---@return string[] component_rules
---@return string[] stroke_rules
local function parse_schema_rules(schema_id)
    if schema_id == "" then
        return {}, {}
    end
    local schema = Schema(schema_id)

    local rime_config = schema.config
    assert(rime_config)

    local algebra_list = rime_config:get_list("speller/algebra")
    if not algebra_list or algebra_list.size == 0 then
        return {}, {}
    end

    ---@type string[]
    local component_rules = {}
    local component_rules_len = 0
    ---@type string[]
    local stroke_rules = {}
    local stroke_rules_len = 0
    for i = 0, algebra_list.size - 1 do
        local rule_val = algebra_list:get_value_at(i)
        local rule = rule_val and rule_val:get_string()
        if rule and #rule > 0 then
            if rule:match("^xlit/HSPZN/") then
                stroke_rules_len = stroke_rules_len + 1
                stroke_rules[stroke_rules_len] = rule
            else
                component_rules_len = component_rules_len + 1
                component_rules[component_rules_len] = rule
            end
        end
    end
    return component_rules, stroke_rules
end

---Derive match codes from one raw code returned by a reverse-lookup database.
---@param raw_code string A reverse-lookup entry containing component spellings or an uppercase stroke sequence.
---@param component_projection Projection?
---@param stroke_projection Projection?
---@return string[] component_match_codes
---@return string[] stroke_match_codes
local function derive_match_codes(raw_code, component_projection, stroke_projection)
    -- Collect both code categories without duplicates.
    ---@type string[]
    local component_match_codes = {}
    local component_match_codes_len = 0
    ---@type table<string, boolean>
    local seen_component_match_codes = {}

    ---@type string[]
    local stroke_match_codes = {}
    local stroke_match_codes_len = 0
    ---@type table<string, boolean>
    local seen_stroke_match_codes = {}

    ---Collect a component match code.
    ---@param s string
    local function add_component_match_code(s)
        if #s > 0 and not seen_component_match_codes[s] then
            seen_component_match_codes[s] = true
            component_match_codes_len = component_match_codes_len + 1
            component_match_codes[component_match_codes_len] = s
        end
    end

    ---Collect a stroke match code.
    ---@param s string
    local function add_stroke_match_code(s)
        if #s > 0 and not seen_stroke_match_codes[s] then
            seen_stroke_match_codes[s] = true
            stroke_match_codes_len = stroke_match_codes_len + 1
            stroke_match_codes[stroke_match_codes_len] = s
        end
    end

    ---Extract each character's first auxiliary-code letter from a sequence of two-letter codes.
    ---@param s string
    ---@return string?
    local function extract_odd_positions(s)
        if not s:match("^%l+$") or #s % 2 ~= 0 then
            return nil
        end
        local res = ""
        for i = 1, #s, 2 do
            res = res .. s:sub(i, i)
        end
        return res
    end

    ---Derive the conventional `u` spelling for `j/q/x/y + v` component pairs.
    ---@param s string
    ---@return string?
    local function get_v_variant(s)
        if not s:match("^%l+$") or #s % 2 ~= 0 then
            return nil
        end
        local res = ""
        local has_change = false
        for i = 1, #s, 2 do
            local char_odd = s:sub(i, i)
            local char_even = s:sub(i + 1, i + 1)
            if (char_odd == "j" or char_odd == "q" or char_odd == "x" or char_odd == "y") and char_even == "v" then
                res = res .. char_odd .. "u"
                has_change = true
            else
                res = res .. char_odd .. char_even
            end
        end
        return has_change and res or nil
    end

    -- Add an unsplit lowercase raw code unchanged.
    if raw_code:match("^%l+$") then
        add_component_match_code(raw_code)
    end

    -- Reverse dictionaries separate component spellings with apostrophes.
    -- For a two-component raw code, add the initial of each component spelling.
    local _, quote_count = raw_code:gsub("'", "")
    if quote_count == 1 then
        local s1, s2 = raw_code:match("^([^']*)'([^']*)$")
        if s1 and s2 and #s1 > 0 and #s2 > 0 then
            add_component_match_code(s1:sub(1, 1) .. s2:sub(1, 1))
        end
    end

    -- Add each character's first auxiliary-code letter from an unsplit two-letter code sequence.
    local component_initials = extract_odd_positions(raw_code)
    if component_initials then
        add_component_match_code(component_initials)
    end

    -- Apply the component spelling projection to a non-stroke raw code.
    if component_projection and not raw_code:match("^%u+$") then
        local projected_code = component_projection:apply(raw_code, true)
        if projected_code and projected_code ~= "" then
            -- Add the projected component code unchanged.
            add_component_match_code(projected_code)

            -- Add the `u` spelling when the projected code contains `j/q/x/y + v` pairs.
            local v_variant = get_v_variant(projected_code)
            if v_variant then
                add_component_match_code(v_variant)
            end

            -- Add each character's first auxiliary-code letter from the projected two-letter codes.
            local projected_component_initials = extract_odd_positions(projected_code)
            if projected_component_initials then
                add_component_match_code(projected_component_initials)
            end
        end
    end

    -- Uppercase HSPZN raw codes encode strokes and must be transliterated to the active layout.
    if raw_code:match("^%u+$") and stroke_projection then
        local stroke_match_code = stroke_projection:apply(raw_code, true)
        if stroke_match_code and #stroke_match_code > 0 then
            add_stroke_match_code(stroke_match_code)
        end
    end
    return component_match_codes, stroke_match_codes
end

---Collect component and stroke match codes for `text` from a reverse-lookup database.
---@param component_projection Projection?
---@param stroke_projection Projection?
---@param reverse_lookup ReverseLookup
---@param text string
---@return string[] component_match_codes
---@return string[] stroke_match_codes
local function build_reverse_group(component_projection, stroke_projection, reverse_lookup, text)
    ---@type string[]
    local component_match_codes = {}
    local component_match_codes_len = 0
    ---@type table<string, boolean>
    local seen_component_match_codes = {}
    ---@type string[]
    local stroke_match_codes = {}
    local stroke_match_codes_len = 0
    ---@type table<string, boolean>
    local seen_stroke_match_codes = {}

    local code = reverse_lookup:lookup(text)
    if code ~= "" then
        for raw_code in code:gmatch("%S+") do
            local derived_component_match_codes, derived_stroke_match_codes =
                derive_match_codes(raw_code, component_projection, stroke_projection)

            for _, match_code in ipairs(derived_component_match_codes) do
                if not seen_component_match_codes[match_code] then
                    seen_component_match_codes[match_code] = true
                    component_match_codes_len = component_match_codes_len + 1
                    component_match_codes[component_match_codes_len] = match_code
                end
            end
            for _, match_code in ipairs(derived_stroke_match_codes) do
                if not seen_stroke_match_codes[match_code] then
                    seen_stroke_match_codes[match_code] = true
                    stroke_match_codes_len = stroke_match_codes_len + 1
                    stroke_match_codes[stroke_match_codes_len] = match_code
                end
            end
        end
    end
    return component_match_codes, stroke_match_codes
end

---Get cached reverse-lookup codes for `text`, deriving them on a cache miss.
---@param text string
---@param config LookupFilterConfig
---@param state LookupFilterState
---@return {component_match_codes: string[], stroke_match_codes: string[]}
local function get_reverse_entry(text, config, state)
    local entry = state.db_cache:get(text)
    if entry then
        return entry
    end

    assert(config.reverse_lookup)
    local component_match_codes, stroke_match_codes =
        build_reverse_group(config.component_projection, config.stroke_projection, config.reverse_lookup, text)
    entry = {
        component_match_codes = component_match_codes,
        stroke_match_codes = stroke_match_codes,
    }
    state.db_cache:insert(text, entry)
    return entry
end

---Fuzzy-match `input_str` against per-character code alternatives.
---@param codes_sequence (string[]|false)[]
---@param idx integer
---@param input_str string
---@param input_idx integer
---@param match_state_cache table<integer, boolean>
---@param is_phrase_mode boolean
---@return boolean
local function match_fuzzy_recursive(codes_sequence, idx, input_str, input_idx, match_state_cache, is_phrase_mode)
    if input_idx > #input_str then
        return true
    end
    if idx > #codes_sequence then
        return false
    end

    local match_state_key = idx * (#input_str + 1) + input_idx

    local cached_result = match_state_cache[match_state_key]
    if cached_result ~= nil then
        return cached_result
    end

    local codes = codes_sequence[idx]
    local result = false

    if codes then
        for _, code in ipairs(codes) do
            if is_phrase_mode and #code > 3 then
                goto continue
            end

            if code:match("^%d+$") then
                goto continue
            end

            local i_curr = input_idx
            local c_curr = 1
            local i_limit = #input_str
            local c_limit = #code
            -- Greedily consume as much of the input as this code covers.
            -- Maximizing consumption here is optimal for subsequence
            -- matching: advancing the input pointer further never makes the
            -- remaining sequence harder to satisfy, so no backtracking on
            -- consumption count is needed.
            while i_curr <= i_limit and c_curr <= c_limit do
                if input_str:byte(i_curr) == code:byte(c_curr) then
                    i_curr = i_curr + 1
                end
                c_curr = c_curr + 1
            end

            if match_fuzzy_recursive(codes_sequence, idx + 1, input_str, i_curr, match_state_cache, is_phrase_mode) then
                result = true
                break
            end

            ::continue::
        end
    else
        result = match_fuzzy_recursive(codes_sequence, idx + 1, input_str, input_idx, match_state_cache, is_phrase_mode)
    end

    match_state_cache[match_state_key] = result
    return result
end

---Split input into base and auxiliary codes at the lookup trigger.
---@param input string
---@param trigger string
---@param bypass_prefix string?
---@return string? base_code
---@return string? aux_code
local function split_lookup_input(input, trigger, bypass_prefix)
    if input == "" then
        return nil
    end

    local scan_from = 1
    -- If a word-creation prefix is configured and matches at the start, advance the scan origin past it.
    if bypass_prefix and bypass_prefix ~= "" and input:sub(1, #bypass_prefix) == bypass_prefix then
        scan_from = #bypass_prefix + 1
    end

    local input_body = input:sub(scan_from)
    -- Reject a body starting with a symbol trigger (no base code precedes it); alphanumeric triggers are exempt.
    if input_body:sub(1, #trigger) == trigger and not trigger:match("^%w+$") then
        return nil
    end

    local trigger_start = find_last(input, trigger, scan_from)
    if not trigger_start then
        return nil
    end

    local base_code = input:sub(1, trigger_start - 1)
    local aux_code = input:sub(trigger_start + #trigger)
    return base_code, aux_code
end

---Parse per-character auxiliary codes from a candidate comment.
---@param comment string
---@param pattern string
---@param target_len integer
---@return string[][]?
local function parse_comment_codes(comment, pattern, target_len)
    if comment == "" then
        return nil
    end

    ---@type string[]
    local parts = {}
    local parts_len = 0

    if target_len == 1 then
        parts = { comment }
    else
        for seg in comment:gmatch(pattern) do
            parts_len = parts_len + 1
            parts[parts_len] = seg
        end
        if #parts ~= target_len then
            return nil
        end
    end

    ---@type string[][]
    local result = {}
    for i, part in ipairs(parts) do
        local p1, p2 = part:find(";")

        local codes_part = p1 and part:sub(p2 + 1) or ""

        ---@type string[]
        local codes_list = {}
        local codes_list_len = 0
        -- Extract auxiliary codes.
        if #codes_part > 0 then
            for c in codes_part:gmatch("[^,]+") do
                local trimmed = c:gsub("^%s+", ""):gsub("%s+$", "")
                if #trimmed > 0 then
                    codes_list_len = codes_list_len + 1
                    codes_list[codes_list_len] = trimmed
                end
            end
        end
        result[i] = codes_list
    end
    return result
end

local F = {}

---@param env Env
function F.init(env)
    local rime_config = env.engine.schema.config
    assert(rime_config)
    local cfg_root = rime_config:get_map("lookup_filter")

    ---@type string[]
    local tags = {}
    local tags_len = 0
    local tags_item = cfg_root and cfg_root:get("tags")
    local tags_cfg = tags_item and tags_item:get_list()
    if tags_cfg and tags_cfg.size > 0 then
        for i = 0, tags_cfg.size - 1 do
            local tag_val = tags_cfg:get_value_at(i)
            local tag = tag_val and tag_val:get_string()
            if tag and tag ~= "" then
                tags_len = tags_len + 1
                tags[tags_len] = tag
            end
        end
    end

    local trigger_val = cfg_root and cfg_root:get_value("trigger")
    local trigger = trigger_val and trigger_val:get_string()
    if trigger == "" then
        trigger = nil
    end

    ---@type LookupSource[]
    local sources = {}
    local sources_len = 0
    ---@type table<LookupSource, boolean>
    local seen_sources = {}
    local has_dictionary_source = false
    local has_aux_code_source = false
    local sources_list_item = cfg_root and cfg_root:get("sources")
    local sources_list = sources_list_item and sources_list_item:get_list()
    if sources_list then
        for i = 0, sources_list.size - 1 do
            local source_val = sources_list:get_value_at(i)
            local source = source_val and source_val:get_string()
            if source ~= "aux_code" and source ~= "dictionary" then
                goto continue
            end
            ---@cast source LookupSource
            if seen_sources[source] then
                goto continue
            end

            seen_sources[source] = true
            sources_len = sources_len + 1
            sources[sources_len] = source

            if source == "aux_code" then
                has_aux_code_source = true
            else
                has_dictionary_source = true
            end

            ::continue::
        end
    end

    ---@type ReverseLookup?
    local reverse_lookup = nil
    ---@type Projection?
    local component_projection = nil
    ---@type Projection?
    local stroke_projection = nil
    if has_dictionary_source then
        local dict_val = cfg_root and cfg_root:get_value("dictionary")
        local dict_name = dict_val and dict_val:get_string()
        if dict_name and dict_name ~= "" then
            reverse_lookup = ReverseLookup(dict_name)
            local component_rules, stroke_rules = parse_schema_rules(dict_name)
            if #component_rules > 0 then
                component_projection = Projection()
                component_projection:load(component_rules)
            end
            if #stroke_rules > 0 then
                stroke_projection = Projection()
                stroke_projection:load(stroke_rules)
            end
        end
    end

    ---@type string?
    local comment_split_pattern = nil
    if has_aux_code_source then
        local delimiter = rime_config:get_string("speller/delimiter") or " '"
        if delimiter == "" then
            delimiter = " "
        end
        comment_split_pattern = "[^" .. utils.escape_for_pattern(delimiter) .. "]+"
    end

    local bypass_prefix = rime_config:get_string("user_dict_appender/prefix")

    -- Keep the trigger after selecting a partial composition; remove it and commit when conversion is complete.
    ---@type Connection?
    local select_notifier = nil
    if trigger then
        select_notifier = env.engine.context.select_notifier:connect(function(ctx)
            local input = ctx.input
            local base_code = split_lookup_input(input, trigger, bypass_prefix)
            if not base_code or base_code == "" then
                return
            end

            local edit = split_lookup_input(ctx:get_preedit().text, trigger, bypass_prefix)
            if edit and edit:match("[%w/]") then
                ctx.input = base_code .. trigger
            else
                ctx.input = base_code
                ctx:commit()
            end
        end)
    end

    env.lookup_filter_config = {
        tags = tags,
        trigger = trigger,
        sources = sources,
        reverse_lookup = reverse_lookup,
        component_projection = component_projection,
        stroke_projection = stroke_projection,
        comment_split_pattern = comment_split_pattern,
        bypass_prefix = bypass_prefix,
    }

    env.lookup_filter_state = {
        db_cache = SegmentedCache.new(MAX_CACHE_SIZE),
        comment_cache = SegmentedCache.new(MAX_CACHE_SIZE),
        select_notifier = select_notifier,
    }
end

---@param env Env
function F.fini(env)
    assert(env.lookup_filter_state)
    if env.lookup_filter_state.select_notifier then
        env.lookup_filter_state.select_notifier:disconnect()
    end
    env.lookup_filter_config = nil
    env.lookup_filter_state = nil
end

---@param translation Translation
---@param env Env
function F.func(translation, env)
    local context = env.engine.context

    local config = env.lookup_filter_config
    assert(config)

    -- `trigger` is ensured to be non-nil in `F.init()`.
    assert(config.trigger)

    local input = context.input
    local _, aux_code = split_lookup_input(input, config.trigger, config.bypass_prefix)
    if not aux_code or aux_code == "" then
        for cand in translation:iter() do
            yield(cand)
        end
        return
    end

    local state = env.lookup_filter_state
    assert(state)

    local if_single_char_first = context:get_option("char_priority")

    ---@type table<integer, Candidate[]>
    local cands_by_length = {}

    ---@type Candidate[]
    local long_word_cands = {}
    local long_word_cands_len = 0
    local max_cand_len = 0

    for cand in translation:iter() do
        if cand.type == "sentence" then
            goto continue
        end

        local cand_text = cand.text
        local cand_len = utf8.len(cand_text)
        if not cand_len or cand_len == 0 then
            goto continue
        end

        if utils.is_english_or_mixed_phrase(cand_text) then
            goto continue
        end

        ---@type boolean
        local matched = false
        for _, source in ipairs(config.sources) do
            if source == "aux_code" then
                if not config.comment_split_pattern then
                    goto continue
                end

                local genuine = cand:get_genuine()
                local comment_text = genuine.comment
                if comment_text == "" then
                    goto continue
                end

                local cache_key = cand_text .. ":" .. comment_text
                local codes_sequence = state.comment_cache:get(cache_key)
                ---@cast codes_sequence string[][]|false
                if codes_sequence == nil then
                    codes_sequence = parse_comment_codes(comment_text, config.comment_split_pattern, cand_len) or false
                    state.comment_cache:insert(cache_key, codes_sequence)
                end
                if not codes_sequence then
                    goto continue
                end

                if cand_len == 1 then
                    assert(#codes_sequence == 1)
                    matched = any_starts_with(codes_sequence[1], aux_code)
                else
                    matched = match_fuzzy_recursive(codes_sequence, 1, aux_code, 1, {}, false)
                end
            else -- if source == "dictionary" then
                if not config.reverse_lookup then
                    goto continue
                end

                if cand_len == 1 then
                    local entry = get_reverse_entry(cand_text, config, state)
                    matched = any_starts_with(entry.component_match_codes, aux_code)
                        or any_starts_with(entry.stroke_match_codes, aux_code)
                else
                    ---@type (string[]|false)[]
                    local codes_sequence = {}
                    local codes_sequence_len = 0
                    for _, codepoint in utf8.codes(cand_text) do
                        local entry = get_reverse_entry(utf8.char(codepoint), config, state)
                        local codes = entry.component_match_codes
                        codes_sequence_len = codes_sequence_len + 1
                        -- Preserve the sequence length for characters without component codes.
                        codes_sequence[codes_sequence_len] = next(codes) ~= nil and codes or false
                    end
                    matched = match_fuzzy_recursive(codes_sequence, 1, aux_code, 1, {}, true)
                end
            end

            if matched then
                break
            end

            ::continue::
        end

        if not matched then
            goto continue
        end

        -- Collect each matched candidate into the structures that determine its output order.
        if if_single_char_first and cand_len > 1 then
            long_word_cands_len = long_word_cands_len + 1
            long_word_cands[long_word_cands_len] = cand
        else
            if not cands_by_length[cand_len] then
                cands_by_length[cand_len] = {}
            end
            table.insert(cands_by_length[cand_len], cand)

            if cand_len > max_cand_len then
                max_cand_len = cand_len
            end
        end

        ::continue::
    end

    if if_single_char_first then
        -- Under char_priority, every multi-char candidate was diverted to long_word_cands above,
        -- so cands_by_length only ever holds single chars.
        -- Effective order: single chars -> long words (in original order).
        if cands_by_length[1] then
            for _, c in ipairs(cands_by_length[1]) do
                yield(c)
            end
        end
    else
        for l = max_cand_len, 1, -1 do
            if cands_by_length[l] then
                for _, c in ipairs(cands_by_length[l]) do
                    yield(c)
                end
            end
        end
    end

    for _, c in ipairs(long_word_cands) do
        yield(c)
    end
end

---@param segment Segment
---@param env Env
---@return boolean
function F.tags_match(segment, env)
    local config = env.lookup_filter_config
    assert(config)

    if not config.trigger or next(config.sources) == nil then
        return false
    end

    for _, tag in ipairs(config.tags) do
        if segment.tags[tag] then
            return true
        end
    end
    return false
end

return F
