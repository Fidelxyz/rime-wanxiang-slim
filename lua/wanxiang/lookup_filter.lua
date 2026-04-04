---Filters candidates by matching secondary auxiliary codes (entered after a trigger character) against reverse lookup dictionaries or candidate comments, supporting fuzzy matching and multiple data sources.
---@module "wanxiang.lookup_filter"
---@author amzxyz
---@author Fidel Yin <fidel.yin@hotmail.com>

---@class LookupFilterConfig
---@field data_sources (string|"aux"|"db")[]
---@field has_db boolean
---@field has_comment boolean
---@field db_table ReverseLookup[]
---@field main_projection Projection?
---@field xlit_projection Projection?
---@field comment_split_pattern string?
---@field trigger_str string
---@field bypass_prefix string?
---@field tags string[]

---@class LookupFilterState
---@field db_cache table<string, {main: string[], xlit: string[]}>
---@field comment_cache table<string, string[][]|false>
---@field cache_size integer
---
---@field select_notifier Connection

---@class Env
---@field lookup_filter_config LookupFilterConfig?
---@field lookup_filter_state LookupFilterState?

---转义正则特殊字符
---@param s string
---@return string
local function alt_lua_punc(s)
    return (s:gsub("([%.%+%-%*%?%[%]%^%$%(%)%%])", "%%%1"))
end

---@param schema_id string
---@return string[]? main_rules
---@return string[]? xlit_rules
local function parse_rules(schema_id)
    if schema_id == "" then
        return nil, nil
    end
    local schema = Schema(schema_id)
    local config = schema.config

    local algebra_list = config:get_list("speller/algebra")
    if not algebra_list or algebra_list.size == 0 then
        return nil, nil
    end

    local main_rules, xlit_rules = {}, {}
    for i = 0, algebra_list.size - 1 do
        local rule = algebra_list:get_value_at(i).value
        if rule and #rule > 0 then
            if rule:match("^xlit/HSPZN/") then
                table.insert(xlit_rules, rule)
            else
                table.insert(main_rules, rule)
            end
        end
    end
    if #main_rules == 0 and #xlit_rules == 0 then
        return nil, nil
    end
    return main_rules, xlit_rules
end

---@param env Env
---@return string[] main_rules
---@return string[] xlit_rules
local function get_schema_rules(env)
    local config = env.engine.schema.config
    local db_list = config:get_list("lookup_filter/dicts")
    if not db_list or db_list.size == 0 then
        return {}, {}
    end

    local schema_id_val = db_list:get_value_at(0)
    local schema_id = schema_id_val and schema_id_val.value
    if not schema_id or schema_id == "" then
        return {}, {}
    end

    local main_rules, xlit_rules = parse_rules(schema_id)
    if not main_rules and not xlit_rules then
        return {}, {}
    end

    return main_rules or {}, xlit_rules or {}
end

---@param main_projection Projection?
---@param xlit_projection Projection?
---@param part string
---@return string[] main_variants
---@return string[] xlit_variants
local function expand_code_variant(main_projection, xlit_projection, part)
    ---@type string[]
    local out = {}
    ---@type table<string, boolean>
    local seen = {}
    ---@type string[]
    local out_xlit = {}
    ---@type table<string, boolean>
    local seen_xlit = {}

    ---@param s string
    local function add(s)
        if #s > 0 and not seen[s] then
            seen[s] = true
            table.insert(out, s)
        end
    end

    ---@param s string
    local function add_xlit(s)
        if #s > 0 and not seen_xlit[s] then
            seen_xlit[s] = true
            table.insert(out_xlit, s)
        end
    end

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

    local _, quote_count = part:gsub("'", "")
    if quote_count == 1 then
        local s1, s2 = part:match("^([^']*)'([^']*)$")
        if s1 and s2 and #s1 > 0 and #s2 > 0 then
            add(s1:sub(1, 1) .. s2:sub(1, 1))
        end
    end
    if part:match("^%l+$") then
        add(part)
    end
    local raw_extracted = extract_odd_positions(part)
    if raw_extracted then
        add(raw_extracted)
    end

    if main_projection and not part:match("^%u+$") then
        local p = main_projection:apply(part, true)
        if p and #p > 0 then
            add(p)
            local v_variant = get_v_variant(p)
            if v_variant then
                add(v_variant)
            end
            local proj_extracted = extract_odd_positions(p)
            if proj_extracted then
                add(proj_extracted)
            end
        end
    end
    if part:match("^%u+$") and xlit_projection then
        local xlit_result = xlit_projection:apply(part, true)
        if xlit_result and #xlit_result > 0 then
            add_xlit(xlit_result)
        end
    end
    return out, out_xlit
end

---@param main_projection Projection?
---@param xlit_projection Projection?
---@param db_table ReverseLookup[]
---@param text string
---@return string[] main
---@return string[] xlit
local function build_reverse_group(main_projection, xlit_projection, db_table, text)
    ---@type string[]
    local group_main = {}
    ---@type boolean[]
    local seen_main = {}
    ---@type string[]
    local group_xlit = {}
    ---@type boolean[]
    local seen_xlit = {}

    for _, db in ipairs(db_table) do
        local code = db:lookup(text)
        if code ~= "" then
            for part in code:gmatch("%S+") do
                -- 接收分离的两种数据
                local main_variants, xlit_variants = expand_code_variant(main_projection, xlit_projection, part)

                -- 装填主数据
                for _, v in ipairs(main_variants) do
                    if not seen_main[v] then
                        seen_main[v] = true
                        group_main[#group_main + 1] = v
                    end
                end
                -- 装填 xlit 数据
                for _, v in ipairs(xlit_variants) do
                    if not seen_xlit[v] then
                        seen_xlit[v] = true
                        group_xlit[#group_xlit + 1] = v
                    end
                end
            end
        end
    end
    return group_main, group_xlit
end

---@param list string[]
---@param prefix string
---@return boolean
local function any_starts_with(list, prefix)
    if not list then
        return false
    end

    for i = 1, #list do
        if string.find(list[i], prefix, 1, true) == 1 then
            return true
        end
    end

    return false
end

---@param codes_sequence string[][]
---@param idx integer
---@param input_str string
---@param input_idx integer
---@param memo table<integer, boolean>
---@param is_phrase_mode boolean
---@return boolean
local function match_fuzzy_recursive(codes_sequence, idx, input_str, input_idx, memo, is_phrase_mode)
    if input_idx > #input_str then
        return true
    end
    if idx > #codes_sequence then
        return false
    end

    local state_key = idx * 1000 + input_idx
    if memo[state_key] ~= nil then
        return memo[state_key]
    end

    local codes = codes_sequence[idx]
    local result = false

    if codes then
        for _, code in ipairs(codes) do
            local skip = false
            if is_phrase_mode and #code > 3 then
                skip = true
            end

            if code:match("^%d+$") then
                skip = true
            end
            if not skip then
                local i_curr = input_idx
                local c_curr = 1
                local i_limit = #input_str
                local c_limit = #code
                while i_curr <= i_limit and c_curr <= c_limit do
                    if input_str:byte(i_curr) == code:byte(c_curr) then
                        i_curr = i_curr + 1
                    end
                    c_curr = c_curr + 1
                end
                if match_fuzzy_recursive(codes_sequence, idx + 1, input_str, i_curr, memo, is_phrase_mode) then
                    result = true
                    break
                end
            end
        end
    else
        if match_fuzzy_recursive(codes_sequence, idx + 1, input_str, input_idx, memo, is_phrase_mode) then
            result = true
        end
    end
    memo[state_key] = result
    return result
end

-- 解析输入中的反查分隔点。
-- 兼容动态获取的造词前缀：如果输入以 bypass_prefix 开头，则跳过它，只把后续反查引导符当作筛选分隔点。
---@param input string
---@param key string
---@param bypass_prefix string?
---@return string? code
---@return string? aux_code
---@return integer? key_start
---@return integer? key_end
local function split_lookup_input(input, key, bypass_prefix)
    if input == "" or key == "" then
        return nil
    end

    local scan_from = 1
    -- 如果有配置造词前缀，且当前输入是以它开头，就把扫描起点后移
    if bypass_prefix and bypass_prefix ~= "" and input:sub(1, #bypass_prefix) == bypass_prefix then
        scan_from = #bypass_prefix + 1
    end

    local s_start, s_end = nil, nil
    local from = scan_from
    while true do
        local s, e = input:find(key, from, true)
        if not s then
            break
        end
        s_start, s_end = s, e
        from = s + 1
    end

    if not s_start then
        return nil
    end

    local code = input:sub(1, s_start - 1)
    local aux_code = input:sub(s_end + 1)
    return code, aux_code, s_start, s_end
end

---@param comment string
---@param pattern string
---@param target_len integer
---@return string[][]?
local function parse_comment_codes(comment, pattern, target_len)
    if not comment or comment == "" then
        return nil
    end

    ---@type string[]
    local parts = {}

    if target_len == 1 then
        parts = { comment }
    else
        for seg in comment:gmatch(pattern) do
            table.insert(parts, seg)
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
        -- 提取辅码
        if #codes_part > 0 then
            for c in codes_part:gmatch("[^,]+") do
                local trimmed = c:gsub("^%s+", ""):gsub("%s+$", "")
                if #trimmed > 0 then
                    table.insert(codes_list, trimmed)
                end
            end
        end
        result[i] = codes_list
    end
    return result
end

---@param seg Segment
---@param config LookupFilterConfig
---@return boolean
local function matches_tags(seg, config)
    for _, v in ipairs(config.tags) do
        if seg.tags[v] then
            return true
        end
    end
    return false
end

local F = {}

---@param env Env
function F.init(env)
    local rime_config = env.engine.schema.config

    -- 1. 读取数据源
    local sources_list = rime_config:get_list("lookup_filter/data_source")

    ---@type string[]
    local data_sources = {}
    local has_db = false
    local config_has_aux_source = false
    if sources_list and sources_list.size > 0 then
        for i = 0, sources_list.size - 1 do
            local s = sources_list:get_value_at(i).value
            table.insert(data_sources, s)
            if s == "aux" then
                config_has_aux_source = true
            end
            if s == "db" then
                has_db = true
            end
        end
    else
        data_sources = { "aux", "db" }
        config_has_aux_source = true
        has_db = true
    end
    -- 核心逻辑：只要配置了 aux 源，就必须解析注释
    local has_comment = config_has_aux_source

    ---@type ReverseLookup[]
    local db_table = nil
    ---@type Projection?
    local main_projection = nil
    ---@type Projection?
    local xlit_projection = nil
    if has_db then
        local db_list = rime_config:get_list("lookup_filter/dicts")
        if db_list and db_list.size > 0 then
            db_table = {}
            for i = 0, db_list.size - 1 do
                table.insert(db_table, ReverseLookup(db_list:get_value_at(i).value))
            end
            local main_rules, xlit_rules = get_schema_rules(env)
            main_projection = #main_rules > 0 and Projection() or nil
            if main_projection then
                main_projection:load(main_rules)
            end
            xlit_projection = #xlit_rules > 0 and Projection() or nil
            if xlit_projection then
                xlit_projection:load(xlit_rules)
            end
        else
            has_db = false
        end
    end

    ---@type string?
    local comment_split_pattern = nil
    if has_comment then
        local delimiter = rime_config:get_string("speller/delimiter") or " '"
        if delimiter == "" then
            delimiter = " "
        end
        comment_split_pattern = "[^" .. alt_lua_punc(delimiter) .. "]+"
    end

    local trigger_str = rime_config:get_string("lookup_filter/trigger") or "`"
    local bypass_prefix = rime_config:get_string("add_user_dict/prefix")

    ---@type string[]
    local tags = {}
    local tags_list = rime_config:get_list("lookup_filter/tags")
    if tags_list and tags_list.size > 0 then
        tags = {}
        for i = 0, tags_list.size - 1 do
            table.insert(tags, tags_list:get_value_at(i).value)
        end
    else
        tags = { "abc" }
    end

    local select_notifier = env.engine.context.select_notifier:connect(function(ctx)
        local state = env.lookup_filter_state
        assert(state)

        local input = ctx.input
        local code, _ = split_lookup_input(input, trigger_str, bypass_prefix)
        if not code or code == "" then
            return
        end

        local preedit = ctx:get_preedit()
        local no_search_string = code
        local preedit_text = (preedit and preedit.text) or ""
        local edit = select(1, split_lookup_input(preedit_text, trigger_str, bypass_prefix))
        if edit and edit:match("[%w/]") then
            ctx.input = no_search_string .. trigger_str
        else
            ctx.input = no_search_string
            ctx:commit()
        end
    end)

    env.lookup_filter_config = {
        data_sources = data_sources,
        has_db = has_db,
        has_comment = has_comment,
        db_table = db_table,
        main_projection = main_projection,
        xlit_projection = xlit_projection,
        comment_split_pattern = comment_split_pattern,
        trigger_str = trigger_str,
        bypass_prefix = bypass_prefix,
        tags = tags,
    }

    env.lookup_filter_state = {
        db_cache = {},
        comment_cache = {},
        cache_size = 0,
        select_notifier = select_notifier,
    }
end

---@param input Translation
---@param env Env
function F.func(input, env)
    local context = env.engine.context

    local config = env.lookup_filter_config
    assert(config)
    local state = env.lookup_filter_state
    assert(state)

    local seg = context.composition:back()
    if not seg or not matches_tags(seg, config) then
        for cand in input:iter() do
            yield(cand)
        end
        return
    end

    if #config.data_sources == 0 then
        for cand in input:iter() do
            yield(cand)
        end
        return
    end

    local ctx_input = env.engine.context.input
    -- 传入 env.bypass_prefix
    local _, aux_code, s_start, _ = split_lookup_input(ctx_input, config.trigger_str, config.bypass_prefix)
    if not s_start then
        for cand in input:iter() do
            yield(cand)
        end
        return
    end
    if not aux_code or aux_code == "" then
        for cand in input:iter() do
            yield(cand)
        end
        return
    end

    local if_single_char_first = env.engine.context:get_option("char_priority")

    ---@type table<integer, table<integer, Candidate[]>>
    local buckets = {}
    for i = 1, #config.data_sources do
        buckets[i] = {}
    end

    ---@type Candidate[]
    local long_word_cands = {}
    local max_len = 0

    if state.cache_size > 2000 then
        state.db_cache = {}
        state.comment_cache = {}
        state.cache_size = 0
    end
    local db_cache = state.db_cache
    local comment_cache = state.comment_cache

    for cand in input:iter() do
        if cand.type == "sentence" then
            goto skip
        end
        local cand_text = cand.text
        local cand_len = utf8.len(cand_text)
        if not cand_len or cand_len == 0 then
            goto skip
        end
        local b = cand_text:byte(1)
        if b and b < 128 then
            goto skip
        end

        ---@type table<"aux"|"db", string[][]>
        local raw_data = {}

        -- 数据加载 A: Aux Data (From Comment)
        if config.has_comment then
            local genuine = cand:get_genuine()
            local comment_text = genuine and genuine.comment or ""
            if comment_text ~= "" then
                local cache_key = cand_text .. "_" .. comment_text
                if not comment_cache[cache_key] then
                    comment_cache[cache_key] = parse_comment_codes(comment_text, config.comment_split_pattern, cand_len)
                        or false
                    state.cache_size = state.cache_size + 1
                end
                if comment_cache[cache_key] then
                    raw_data.aux = comment_cache[cache_key]
                end
            end
        end

        -- 数据加载 B: DB Data
        if config.has_db then
            raw_data.db = {}
            local i = 0
            for _, code_point in utf8.codes(cand_text) do
                i = i + 1
                local char_str = utf8.char(code_point)

                -- 1. 查缓存，如果没有就调用底层函数，拿到分离后的两种数据
                if not db_cache[char_str] then
                    local main_codes, xlit_codes =
                        build_reverse_group(config.main_projection, config.xlit_projection, config.db_table, char_str)
                    db_cache[char_str] = {
                        main = main_codes or {},
                        xlit = xlit_codes or {},
                    }
                    state.cache_size = state.cache_size + 1
                end

                -- 2. 核心分配逻辑：控制词组取什么数据
                if cand_len == 1 then
                    local combined = {}
                    for _, v in ipairs(db_cache[char_str].main) do
                        table.insert(combined, v)
                    end
                    for _, v in ipairs(db_cache[char_str].xlit) do
                        table.insert(combined, v)
                    end
                    raw_data.db[i] = (#combined > 0) and combined or nil
                else
                    local main_data = db_cache[char_str].main
                    raw_data.db[i] = (main_data and #main_data > 0) and main_data or nil
                end
            end
        end

        local matched_idx = nil

        for i, source_type in ipairs(config.data_sources) do
            local codes_seq = raw_data[source_type]
            if codes_seq then
                local is_match = false
                if source_type == "aux" then
                    if cand_len == 1 then
                        if any_starts_with(codes_seq[1], aux_code) then
                            is_match = true
                        end
                    else
                        local memo = {}
                        if match_fuzzy_recursive(codes_seq, 1, aux_code, 1, memo, false) then
                            is_match = true
                        end
                    end
                elseif source_type == "db" then
                    if cand_len == 1 then
                        if any_starts_with(codes_seq[1], aux_code) then
                            is_match = true
                        end
                    else
                        local memo = {}
                        if match_fuzzy_recursive(codes_seq, 1, aux_code, 1, memo, true) then
                            is_match = true
                        end
                    end
                end

                if is_match then
                    matched_idx = i
                    break
                end
            end
        end

        if matched_idx then
            if if_single_char_first and cand_len > 1 then
                table.insert(long_word_cands, cand)
            else
                if not buckets[matched_idx][cand_len] then
                    buckets[matched_idx][cand_len] = {}
                end
                table.insert(buckets[matched_idx][cand_len], cand)
                if cand_len > max_len then
                    max_len = cand_len
                end
            end
        end
        ::skip::
    end

    if if_single_char_first then
        for i = 1, #config.data_sources do
            if buckets[i][1] then
                for _, c in ipairs(buckets[i][1]) do
                    yield(c)
                end
            end
        end
        for l = max_len, 2, -1 do
            for i = 1, #config.data_sources do
                if buckets[i][l] then
                    for _, c in ipairs(buckets[i][l]) do
                        yield(c)
                    end
                end
            end
        end
    else
        for l = max_len, 1, -1 do
            for i = 1, #config.data_sources do
                if buckets[i][l] then
                    for _, c in ipairs(buckets[i][l]) do
                        yield(c)
                    end
                end
            end
        end
    end

    for _, c in ipairs(long_word_cands) do
        yield(c)
    end
end

---@param env Env
function F.fini(env)
    env.lookup_filter_state.select_notifier:disconnect()
    env.lookup_filter_config = nil
    env.lookup_filter_state = nil
end

return F
