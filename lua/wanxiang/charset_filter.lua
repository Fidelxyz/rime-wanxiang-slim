---Filters candidates based on configurable character sets, removing single characters outside the allowed sets and
---attempting to replace phrases containing unallowed characters with valid historical input of the same length.
---@author amzxyz
---@author Fidel Yin <fidel.yin@hotmail.com>

---@class CharsetFilter
---@field options string[]|true
---@field charset table<string, boolean>
---@field whitelist table<integer, boolean>
---@field blacklist table<integer, boolean>

---@class CharsetFilterConfig
---@field filters CharsetFilter[]

---@class CharsetFilterState
---@field charset_db ReverseDb
---@field db_memo table<string, string>
---@field phrase_history_dict table<integer, string>

---@diagnostic disable-next-line: duplicate-type
---@class Env
---@field charset_filter_config CharsetFilterConfig?
---@field charset_filter_state CharsetFilterState?

local wanxiang = require("wanxiang.wanxiang")

---Whether any character of `db_attr` is a key in `config_base_set`.
---@param db_attr string
---@param config_base_set table<string, boolean>
---@return boolean
local function check_intersection(db_attr, config_base_set)
    for i = 1, #db_attr do
        local c = db_attr:sub(i, i)
        if config_base_set[c] then
            return true
        end
    end
    return false
end

---Core decision: whether `codepoint` is in any allowed charset, taking the
---union over all currently active rules (multi-switch support).
---@param codepoint integer
---@param config CharsetFilterConfig
---@param state CharsetFilterState
---@param ctx Context
---@return boolean
local function is_codepoint_in_charset(codepoint, config, state, ctx)
    local char = utf8.char(codepoint)

    local active_options_count = 0
    local is_allowed = false

    for _, rule in ipairs(config.filters) do
        -- Check whether this rule's switch is on.
        if rule.options ~= true then
            local is_rule_active = false
            ---@diagnostic disable-next-line: param-type-mismatch
            for _, opt in ipairs(rule.options) do
                if ctx:get_option(opt) then
                    is_rule_active = true
                    break
                end
            end
            if not is_rule_active then
                goto continue
            end
        end

        active_options_count = active_options_count + 1

        if rule.blacklist[codepoint] then
            return false
        end

        -- Take the union of base set and whitelist.
        if not is_allowed then
            if rule.whitelist[codepoint] then
                is_allowed = true
            else
                local attr = state.db_memo[char]
                if attr == nil then
                    attr = state.charset_db:lookup(char)
                    state.db_memo[char] = attr
                end

                if check_intersection(attr, rule.charset) then
                    is_allowed = true
                end
            end
        end

        ::continue::
    end

    -- No rule active: pass through by default.
    if active_options_count == 0 then
        return true
    end

    return is_allowed
end

---Strict check: whether the entire text (single character or phrase) fully matches the active charset.
---@param text string
---@param config CharsetFilterConfig
---@param state CharsetFilterState
---@param ctx Context
---@return boolean
local function is_text_in_charset(text, config, state, ctx)
    if text == "" then
        return true
    end
    for _, codepoint in utf8.codes(text) do
        if wanxiang.is_chinese_codepoint(codepoint) then
            -- Reject as soon as we hit any uncommon/blacklisted character.
            if not is_codepoint_in_charset(codepoint, config, state, ctx) then
                return false
            end
        end
    end
    return true
end

---Whether the current segment should bypass charset filtering.
---@param context Context
---@return boolean
local function should_skip_filter(context)
    local seg = context.composition:back()
    if not seg then
        return false
    end

    -- Skip Unicode-output, punctuation, and reverse-lookup segments.
    return seg:has_tag("unicode") or seg:has_tag("punct") or seg:has_tag("wanxiang_reverse")
end

local M = {}

---@param env Env
function M.init(env)
    local rime_config = env.engine.schema.config

    local charset_db = rime_api.get_distribution_code_name():lower() ~= "weasel"
            and wanxiang.get_filename_with_fallback("lua/data/charset.reverse.bin")
        or "lua/data/charset.reverse.bin"

    ---@type CharsetFilter[]
    local filters = {}
    local filters_cfg = rime_config:get_list("charset_filter")
    if filters_cfg then
        for i = 0, filters_cfg.size - 1 do
            local filter_cfg = filters_cfg:get_at(i)
            local filter_map = filter_cfg and filter_cfg:get_map()
            if not filter_map then
                goto continue
            end

            ---@type string[]
            local options = {}
            ---@type boolean
            local always_on = false

            local options_cfg = filter_map:get("option")
            if options_cfg then
                local options_list = options_cfg:get_list()
                local options_value = options_cfg:get_value()
                if options_list then
                    for k = 0, options_list.size - 1 do
                        local option_val = options_list:get_value_at(k)
                        local option = option_val and option_val:get_string()
                        if option and option ~= "" then
                            options[#options + 1] = option
                        end
                    end
                elseif options_value and options_value:get_bool() == true then
                    always_on = true
                else
                    local option = options_value and options_value:get_string()
                    if option and option ~= "" then
                        options[#options + 1] = option
                    end
                end
            end

            if always_on or #options > 0 then
                ---@type table<string, boolean>
                local rule_charset = {}
                local charset_val = filter_map:get_value("charset")
                local charset = charset_val and charset_val:get_string()
                if charset then
                    for j = 1, #charset do
                        rule_charset[charset:sub(j, j)] = true
                    end
                end

                ---@param list ConfigList
                ---@param map table<integer, boolean>
                local function load_list_to_map(list, map)
                    for k = 0, list.size - 1 do
                        local val = list:get_value_at(k)
                        local str = val and val:get_string()
                        if str and str ~= "" then
                            for _, cp in utf8.codes(str) do
                                map[cp] = true
                            end
                        end
                    end
                end

                ---@type table<integer, boolean>
                local rule_whitelist = {}
                local whitelist_cfg = filter_map:get("whitelist")
                local whitelist_list = whitelist_cfg and whitelist_cfg:get_list()
                if whitelist_list then
                    load_list_to_map(whitelist_list, rule_whitelist)
                end

                ---@type table<integer, boolean>
                local rule_blacklist = {}
                local blacklist_cfg = filter_map:get("blacklist")
                local blacklist_list = blacklist_cfg and blacklist_cfg:get_list()
                if blacklist_list then
                    load_list_to_map(blacklist_list, rule_blacklist)
                end

                filters[#filters + 1] = {
                    options = always_on or options,
                    charset = rule_charset,
                    whitelist = rule_whitelist,
                    blacklist = rule_blacklist,
                }
            end
            ::continue::
        end
    end

    env.charset_filter_config = {
        filters = filters,
    }

    env.charset_filter_state = {
        charset_db = ReverseDb(charset_db),
        db_memo = {},
        phrase_history_dict = {},
    }
end

---@param env Env
function M.fini(env)
    env.charset_filter_config = nil
    env.charset_filter_state = nil
end

---@param input Translation
---@param env Env
function M.func(input, env)
    local config = env.charset_filter_config
    assert(config)
    local state = env.charset_filter_state
    assert(state)

    local context = env.engine.context
    local code = context.input
    local comp = context.composition

    -- Maintain the input-history dictionary.
    if code == "" or comp:empty() then
        state.phrase_history_dict = {}
    else
        local current_code_length = #code
        for key_length in pairs(state.phrase_history_dict) do
            if key_length > current_code_length then
                state.phrase_history_dict[key_length] = nil
            end
        end
    end

    -- Decide whether charset filtering applies to the current input.
    local charset_active = #config.filters > 0 and not should_skip_filter(context)

    -- Walk the candidate list.
    -- Only the first valid candidate is recorded in history.
    local has_recorded_history = false

    ---Record the first valid candidate and yield it.
    ---@param cand Candidate
    ---@param text string
    local function yield_and_record(cand, text)
        if not has_recorded_history and text ~= "" then
            state.phrase_history_dict[#code] = text
            has_recorded_history = true
        end
        yield(cand)
    end

    for cand in input:iter() do
        local text = cand.text

        -- Filtering disabled: pass through and record.
        if not charset_active or text == "" then
            yield_and_record(cand, text)
            goto continue
        end

        local text_length = utf8.len(text)
        -- Validate the entire text (single character or phrase).
        local is_text_valid = is_text_in_charset(text, config, state, context)
        if text_length < 2 then
            -- Single character: drop on mismatch, no fallback.
            if is_text_valid then
                yield_and_record(cand, text)
            end
            goto continue
        end

        -- Phrase logic.
        if is_text_valid then
            -- No uncommon characters: pass through.
            yield_and_record(cand, text)
            goto continue
        end

        -- Phrase contains an uncommon character: try to substitute from history.
        local fallback_text = nil
        local current_code_length = #code

        -- Search starting at current_code_length so the just-typed candidate is also considered.
        for history_length = current_code_length, 1, -1 do
            local history_text = state.phrase_history_dict[history_length]
            if history_text and utf8.len(history_text) == text_length then
                fallback_text = history_text
                break
            end
        end
        if not fallback_text then
            goto continue
        end

        -- Construct the fallback candidate.
        local preedit_text = cand.preedit
        if #preedit_text > 1 and preedit_text:sub(-1):match("[%w%p]") then
            preedit_text = preedit_text:sub(1, -2) .. " " .. preedit_text:sub(-1)
        end

        local new_cand = Candidate(cand.type, cand.start, cand._end, fallback_text, cand.comment)
        new_cand.preedit = preedit_text

        -- Verify the fallback itself contains no uncommon characters.
        if is_text_in_charset(new_cand.text, config, state, context) then
            yield_and_record(new_cand, new_cand.text)
        end

        ::continue::
    end
end

return M
