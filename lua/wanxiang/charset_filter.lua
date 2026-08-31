---Filters candidates based on configurable character sets, removing characters and phrases outside the allowed sets.
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
---@field charset_db_cache table<string, string>
---@field option_update_notifier Connection

---@diagnostic disable-next-line: duplicate-type
---@class Env
---@field charset_filter_config CharsetFilterConfig?
---@field charset_filter_state CharsetFilterState?

local utils = require("utils.utils")

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

---Return whether `codepoint` is in any allowed charset, taking the union over all active rules.
---Callers must pass the pre-collected active rules so option switches are checked once per input rather than once per
---candidate character.
---@param codepoint integer
---@param active_rules CharsetFilter[]
---@param state CharsetFilterState
---@return boolean
local function is_codepoint_allowed(codepoint, active_rules, state)
    local char = utf8.char(codepoint)

    local is_allowed = false

    for _, rule in ipairs(active_rules) do
        if rule.blacklist[codepoint] then
            return false
        end

        -- Take the union of base set and whitelist.
        if not is_allowed then
            if rule.whitelist[codepoint] then
                is_allowed = true
            else
                local attr = state.charset_db_cache[char]
                if not attr then
                    attr = state.charset_db:lookup(char)
                    state.charset_db_cache[char] = attr
                end

                if check_intersection(attr, rule.charset) then
                    is_allowed = true
                end
            end
        end
    end

    return is_allowed
end

---Return whether the entire text (single character or phrase) fully matches the active charset.
---@param text string
---@param active_rules CharsetFilter[]
---@param state CharsetFilterState
---@return boolean
local function is_text_allowed(text, active_rules, state)
    for _, codepoint in utf8.codes(text) do
        if utils.is_chinese_codepoint(codepoint) then
            -- Reject as soon as we hit any unallowed character.
            if not is_codepoint_allowed(codepoint, active_rules, state) then
                return false
            end
        end
    end
    return true
end

---Return whether the current segment should be subject to charset filtering, based on its tags.
---@param segment Segment
---@return boolean
local function should_filter(segment)
    -- Skip Unicode-output, punctuation, and reverse-lookup segments.
    return not segment:has_tag("unicode") and not segment:has_tag("punct") and not segment:has_tag("wanxiang_reverse")
end

local M = {}

---@param env Env
function M.init(env)
    local rime_config = env.engine.schema.config
    assert(rime_config)

    local charset_db = rime_api.get_distribution_code_name():lower() ~= "weasel"
            and utils.get_filename_with_fallback("lua/data/charset.reverse.bin")
        or "lua/data/charset.reverse.bin"

    ---@type CharsetFilter[]
    local filters = {}
    local filters_len = 0
    local filters_cfg = rime_config:get_list("charset_filter/filters")
    if filters_cfg then
        for i = 0, filters_cfg.size - 1 do
            local filter_cfg = filters_cfg:get_at(i)
            local filter_map = filter_cfg and filter_cfg:get_map()
            if not filter_map then
                goto continue
            end

            ---@type string[]
            local options = {}
            local options_len = 0
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
                            options_len = options_len + 1
                            options[options_len] = option
                        end
                    end
                elseif options_value and options_value:get_bool() == true then
                    always_on = true
                else
                    local option = options_value and options_value:get_string()
                    if option and option ~= "" then
                        options_len = options_len + 1
                        options[options_len] = option
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

                ---@param str string
                ---@param map table<integer, boolean>
                local function load_string_to_map(str, map)
                    for _, cp in utf8.codes(str) do
                        map[cp] = true
                    end
                end

                ---@type table<integer, boolean>
                local rule_whitelist = {}
                local whitelist_val = filter_map:get_value("whitelist")
                local whitelist = whitelist_val and whitelist_val:get_string()
                if whitelist then
                    load_string_to_map(whitelist, rule_whitelist)
                end

                ---@type table<integer, boolean>
                local rule_blacklist = {}
                local blacklist_val = filter_map:get_value("blacklist")
                local blacklist = blacklist_val and blacklist_val:get_string()
                if blacklist then
                    load_string_to_map(blacklist, rule_blacklist)
                end

                filters_len = filters_len + 1
                filters[filters_len] = {
                    options = always_on or options,
                    charset = rule_charset,
                    whitelist = rule_whitelist,
                    blacklist = rule_blacklist,
                }
            end
            ::continue::
        end
    end

    -- Re-filter non-confirmed candidates immediately when a charset switch is toggled.
    local option_update_notifier = env.engine.context.option_update_notifier:connect(function(ctx, name)
        for _, filter in ipairs(filters) do
            if filter.options ~= true then
                ---@diagnostic disable-next-line: param-type-mismatch
                for _, option in ipairs(filter.options) do
                    if name == option then
                        ctx:refresh_non_confirmed_composition()
                        return
                    end
                end
            end
        end
    end)

    env.charset_filter_config = {
        filters = filters,
    }

    env.charset_filter_state = {
        charset_db = ReverseDb(charset_db),
        charset_db_cache = {},
        option_update_notifier = option_update_notifier,
    }
end

---@param env Env
function M.fini(env)
    assert(env.charset_filter_state)
    env.charset_filter_state.option_update_notifier:disconnect()

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
    local seg = context.composition:back()

    -- Collect the rules whose switches are currently on.
    ---@type CharsetFilter[]
    local active_rules = {}
    if #config.filters > 0 and seg and should_filter(seg) then
        local active_rules_len = 0
        for _, rule in ipairs(config.filters) do
            local is_rule_active = rule.options == true
            ---@cast rule.options string[]

            if not is_rule_active then
                ---@diagnostic disable-next-line: param-type-mismatch
                for _, option in ipairs(rule.options) do
                    if context:get_option(option) then
                        is_rule_active = true
                        break
                    end
                end
            end

            if is_rule_active then
                active_rules_len = active_rules_len + 1
                active_rules[active_rules_len] = rule
            end
        end
    end

    -- No active rule: pass everything through.
    local charset_active = #active_rules > 0

    for cand in input:iter() do
        local text = cand.text

        -- Filtering disabled: pass through.
        if not charset_active or text == "" then
            yield(cand)
            goto continue
        end

        -- Skip user-committed candidates (from user phrase/table dictionaries).
        if cand.type == "user_phrase" or cand.type == "user_table" then
            yield(cand)
            goto continue
        end

        -- Drop any candidate (single character or phrase) that contains an uncommon character.
        if is_text_allowed(text, active_rules, state) then
            yield(cand)
        end

        ::continue::
    end
end

return M
