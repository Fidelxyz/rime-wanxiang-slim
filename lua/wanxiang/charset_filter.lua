-- 功能：独立的字符集过滤与兜底组件
-- 逻辑：
-- 1. 支持配置多个选项，开启多个选项时 Base 和 Addlist 取并集（任意一个允许即放行），Blacklist 一票否决。
-- 2. 单字如果不符合字符集，直接丢弃（删除），不进行兜底。
-- 3. 词组如果包含生僻字，尝试从历史记录寻找同长度拼音的词组进行兜底。

---@class Filter
---@field options string[]|true
---@field base_set table<string, boolean>
---@field add table<integer, boolean>
---@field ban table<integer, boolean>

---@class CharsetFilterConfig
---@field filters Filter[]

---@class CharsetFilterState
---@field charset_db ReverseDb
---@field db_memo table<string, string>
---@field phrase_history_dict table<integer, string>

---@class Env
---@field charset_filter_config CharsetFilterConfig?
---@field charset_Filter_state CharsetFilterState?

local wanxiang = require("wanxiang.wanxiang")

-- 检查交集
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

-- 核心判定逻辑：检查单个 codepoint 是否在允许的字符集中（支持多开关并集）
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
        -- 检查当前规则开关是否开启
        if rule.options ~= true then
            local is_rule_active = false
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

        -- 1. 黑名单一票否决
        if rule.ban[codepoint] then
            return false
        end

        -- 2. Base 和 白名单取并集
        if not is_allowed then
            if rule.add[codepoint] then
                is_allowed = true
            else
                local attr = state.db_memo[char]
                if attr == nil then
                    attr = state.charset_db:lookup(char) or ""
                    state.db_memo[char] = attr
                end

                if check_intersection(attr, rule.base_set) then
                    is_allowed = true
                end
            end
        end

        ::continue::
    end

    -- 如果没有任何规则开启，默认全放行
    if active_options_count == 0 then
        return true
    end

    return is_allowed
end

---检查单字/全词是否符合字符集（供单字快速判定用）
---@param text string
---@param config CharsetFilterConfig
---@param state CharsetFilterState
---@param ctx Context
---@return boolean
local function is_text_in_charset(text, config, state, ctx)
    local codepoint_count = 0
    ---@type integer?
    local codepoint = nil
    for _, cp in utf8.codes(text) do
        codepoint_count = codepoint_count + 1
        if codepoint_count > 1 then
            return true
        end -- 大于一个字交由词组专用逻辑处理
        codepoint = cp
    end

    if not codepoint or not wanxiang.is_chinese_codepoint(codepoint) then
        return true
    end

    return is_codepoint_in_charset(codepoint, config, state, ctx)
end

-- 精准探测：检查词组中是否包含生僻字
---@param text string
---@param config CharsetFilterConfig
---@param state CharsetFilterState
---@param ctx Context
---@return boolean
local function has_rare_char(text, config, state, ctx)
    for _, codepoint in utf8.codes(text) do
        if wanxiang.is_chinese_codepoint(codepoint) and not is_codepoint_in_charset(codepoint, config, state, ctx) then
            return true
        end
    end
    return false
end

---@param context Context
---@return boolean
local function should_skip_filter(context)
    if context.composition:empty() then
        return false
    end

    local seg = context.composition:back()
    if not seg then
        return false
    end

    return seg:has_tag("unicode") -- unicode.lua 输出 Unicode 字符 U+小写字母或数字
        or seg:has_tag("punct") -- 标点符号 全角半角提示
        or seg:has_tag("wanxiang_reverse")
end

local M = {}

---@param env Env
function M.init(env)
    local rime_config = env.engine.schema.config

    local charsetFile = rime_api.get_distribution_code_name():lower() ~= "weasel"
            and wanxiang.get_filename_with_fallback("lua/data/charset.reverse.bin")
        or "lua/data/charset.reverse.bin"

    local filters_cfg = rime_config:get_list("charset")

    ---@type Filter[]
    local filters = {}
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
                        local val = options_list:get_value_at(k)
                        if val and val ~= "" then
                            table.insert(options, val)
                        end
                    end
                elseif options_value and options_value:get_bool() == true then
                    always_on = true
                else
                    local options_str = options_value and options_value:get_string()
                    if options_str and options_str ~= "" then
                        table.insert(options, options_str)
                    end
                end
            end

            if always_on or #options > 0 then
                ---@type table<string, boolean>
                local rule_base_set = {}
                local base_value = filter_map:get_value("base")
                local base_str = base_value and base_value:get_string()
                if base_str then
                    for j = 1, #base_str do
                        rule_base_set[base_str:sub(j, j)] = true
                    end
                end

                ---@param list ConfigList
                ---@param map table<integer, boolean>
                local function load_list_to_map(list, map)
                    for k = 0, list.size - 1 do
                        local val = list:get_value_at(k)
                        local val_str = val and val:get_string()
                        if val_str and val_str ~= "" then
                            for _, cp in utf8.codes(val_str) do
                                map[cp] = true
                            end
                        end
                    end
                end

                ---@type table<integer, boolean>
                local rule_add = {}
                local addlist_cfg = filter_map:get("addlist")
                local addlist_list = addlist_cfg and addlist_cfg:get_list()
                if addlist_list then
                    load_list_to_map(addlist_list, rule_add)
                end

                ---@type table<integer, boolean>
                local rule_ban = {}
                local blacklist_cfg = filter_map:get("blacklist")
                local blacklist_list = blacklist_cfg and blacklist_cfg:get_list()
                if blacklist_list then
                    load_list_to_map(blacklist_list, rule_ban)
                end

                table.insert(filters, {
                    options = always_on or options,
                    base_set = rule_base_set,
                    add = rule_add,
                    ban = rule_ban,
                })
            end
            ::continue::
        end
    end

    env.charset_filter_config = {
        filters = filters,
    }

    env.charset_Filter_state = {
        charset_db = ReverseDb(charsetFile),
        db_memo = {},
        phrase_history_dict = {},
    }
end

---@param env Env
function M.fini(env)
    env.charset_filter_config = nil
    env.charset_Filter_state = nil
end

-- ==========================================
-- 核心过滤流水线
-- ==========================================

---@param input Translation
---@param env Env
function M.func(input, env)
    local config = env.charset_filter_config
    assert(config)
    local state = env.charset_Filter_state
    assert(state)

    local context = env.engine.context
    local code = context.input
    local comp = context.composition

    -- 1. 维护历史输入字典
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

    -- 2. 判断当前是否需要开启字符集过滤
    local charset_active = #config.filters > 0 and not should_skip_filter(context)

    -- Skip filter if the last character is non-alphanumeric, to avoid interfering with punctuation hints and similar features.
    if #code == 5 and code:sub(-1):find("[^%w]") then
        charset_active = false
    end

    -- 3. 遍历候选词
    local has_recorded_history = false -- 只有第一个有效产出的词才记入历史

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

        -- 如果未开启过滤，直接放行并记录历史
        if not charset_active or text == "" then
            yield_and_record(cand, text)
            goto continue
        end

        local text_length = utf8.len(text)
        if text_length < 2 then
            -- 单字过滤：如果不符合就直接丢弃，不执行兜底，也不执行记录
            if is_text_in_charset(text, config, state, context) then
                yield_and_record(cand, text)
            end
            goto continue
        end

        -- 词组过滤
        if not has_rare_char(text, config, state, context) then
            -- 不含生僻字，直接放行
            yield_and_record(cand, text)
            goto continue
        end

        -- 含有生僻字，开始词组兜底
        local fallback_text = nil
        local current_code_length = #code
        for history_length = current_code_length - 1, 1, -1 do
            local history_text = state.phrase_history_dict[history_length]
            if history_text and utf8.len(history_text) == text_length then
                fallback_text = history_text
                break
            end
        end
        if not fallback_text then
            goto continue
        end

        -- 构造兜底候选
        local preedit_text = cand.preedit or code
        if #preedit_text > 1 and preedit_text:sub(-1):match("[%w%p]") then
            preedit_text = preedit_text:sub(1, -2) .. " " .. preedit_text:sub(-1)
        end

        local new_cand = Candidate(cand.type, cand.start, cand._end, fallback_text, cand.comment or "")
        new_cand.preedit = preedit_text

        -- 验证兜底词自身不是生僻词
        if is_text_in_charset(new_cand.text, config, state, context) then
            yield_and_record(new_cand, new_cand.text)
        end

        ::continue::
    end
end

return M
