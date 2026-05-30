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

---Return whether `codepoint` is in any allowed charset, taking the union over all currently active rules
---(multi-switch support).
---@param codepoint integer
---@param config CharsetFilterConfig
---@param state CharsetFilterState
---@param ctx Context
---@return boolean
local function is_codepoint_allowed(codepoint, config, state, ctx)
    local char = utf8.char(codepoint)

    local has_active_rule = false
    local is_allowed = false

    for _, rule in ipairs(config.filters) do
        -- Check whether this rule's switch is on.
        if rule.options ~= true then
            local is_rule_active = false
            for _, option in ipairs(rule.options) do
                if ctx:get_option(option) then
                    is_rule_active = true
                    break
                end
            end
            if not is_rule_active then
                goto continue
            end
        end

        has_active_rule = true

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

        ::continue::
    end

    -- No rule active: pass through by default.
    if not has_active_rule then
        return true
    end

    return is_allowed
end

---Return whether the entire text (single character or phrase) fully matches the active charset.
---@param text string
---@param config CharsetFilterConfig
---@param state CharsetFilterState
---@param ctx Context
---@return boolean
local function is_text_allowed(text, config, state, ctx)
    for _, codepoint in utf8.codes(text) do
        if wanxiang.is_chinese_codepoint(codepoint) then
            -- Reject as soon as we hit any unallowed character.
            if not is_codepoint_allowed(codepoint, config, state, ctx) then
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

    local charset_db = rime_api.get_distribution_code_name():lower() ~= "weasel"
            and wanxiang.get_filename_with_fallback("lua/data/charset.reverse.bin")
        or "lua/data/charset.reverse.bin"

    ---@type CharsetFilter[]
    local filters = {}
    local filters_len = 0
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

    env.charset_filter_config = {
        filters = filters,
    }

    env.charset_filter_state = {
        charset_db = ReverseDb(charset_db),
        charset_db_cache = {},
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
    local seg = context.composition:back()

    -- Decide whether charset filtering applies to the current input.
    local charset_active = #config.filters > 0 and seg and should_filter(seg)

    for cand in input:iter() do
        local text = cand.text

        -- Filtering disabled: pass through.
        if not charset_active or text == "" then
            yield(cand)
            goto continue
        end

        -- Drop any candidate (single character or phrase) that contains an uncommon character.
        if is_text_allowed(text, config, state, context) then
            yield(cand)
        end

        ::continue::
    end
end

return M
