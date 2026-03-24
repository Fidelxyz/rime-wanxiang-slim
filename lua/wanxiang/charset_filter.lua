-- charset_filter.lua
-- 功能：独立的字符集过滤与兜底组件
-- 逻辑：
-- 1. 支持配置多个选项，开启多个选项时 Base 和 Addlist 取并集（任意一个允许即放行），Blacklist 一票否决。
-- 2. 单字如果不符合字符集，直接丢弃（删除），不进行兜底。
-- 3. 词组如果包含生僻字，尝试从历史记录寻找同长度拼音的词组进行兜底。

---@class Filter
---@field options string[]
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
---@param text string
---@param config CharsetFilterConfig
---@param state CharsetFilterState
---@param ctx Context
---@return boolean
local function codepoint_in_charset(codepoint, text, config, state, ctx)
    local active_options_count = 0
    local is_allowed = false
    local is_blacklisted = false

    for _, rule in ipairs(config.filters) do
        -- 检查当前规则开关是否开启
        local is_rule_active = false
        for _, opt_name in ipairs(rule.options) do
            if opt_name == "true" or ctx:get_option(opt_name) then
                is_rule_active = true
                break
            end
        end

        if is_rule_active then
            active_options_count = active_options_count + 1

            -- 1. 黑名单一票否决
            if rule.ban[codepoint] then
                is_blacklisted = true
                break
            end

            -- 2. Base 和 白名单取并集
            if not is_allowed then
                if rule.add[codepoint] then
                    is_allowed = true
                else
                    local attr = state.db_memo[text]
                    if attr == nil then
                        attr = state.charset_db:lookup(text) or ""
                        state.db_memo[text] = attr
                    end

                    if check_intersection(attr, rule.base_set) then
                        is_allowed = true
                    end
                end
            end
        end
    end

    -- 如果没有任何规则开启，默认全放行
    if active_options_count == 0 then
        return true
    end

    -- 命中黑名单，直接丢弃
    if is_blacklisted then
        return false
    end

    return is_allowed
end

---检查单字/全词是否符合字符集（供单字快速判定用）
---@param text string
---@param config CharsetFilterConfig
---@param state CharsetFilterState
---@param ctx Context
---@return boolean
local function in_charset(text, config, state, ctx)
    local codepoint_count = 0
    local target_codepoint = nil
    for _, cp in utf8.codes(text) do
        codepoint_count = codepoint_count + 1
        if codepoint_count > 1 then
            return true
        end -- 大于一个字交由词组专用逻辑处理
        target_codepoint = cp
    end

    if codepoint_count == 0 or not target_codepoint then
        return true
    end

    local char = utf8.char(target_codepoint)
    if not wanxiang.is_chinese_char(char) then
        return true
    end

    return codepoint_in_charset(target_codepoint, char, config, state, ctx)
end

-- 精准探测：检查词组中是否包含生僻字
---@param text string
---@param config CharsetFilterConfig
---@param state CharsetFilterState
---@param ctx Context
---@return boolean
local function has_rare_char(text, config, state, ctx)
    for _, codepoint in utf8.codes(text) do
        local char = utf8.char(codepoint)
        if wanxiang.is_chinese_char(char) and not codepoint_in_charset(codepoint, char, config, state, ctx) then
            return true
        end
    end
    return false
end

local M = {}

---@param env Env
function M.init(env)
    local rime_config = env.engine.schema.config

    local charsetFile = rime_api.get_distribution_code_name():lower() ~= "weasel"
            and wanxiang.get_filename_with_fallback("lua/data/charset.reverse.bin")
        or "lua/data/charset.reverse.bin"

    local config_root = "charset"
    local config_list = rime_config:get_list(config_root)

    ---@type Filter[]
    local filters = {}
    if config_list then
        for i = 0, config_list.size - 1 do
            local entry_path = config_root .. "/@" .. i
            ---@type string[]
            local triggers = {}
            local opts_keys = { "option", "options" }

            for _, key in ipairs(opts_keys) do
                local key_path = entry_path .. "/" .. key
                local sub_list = rime_config:get_list(key_path)
                if sub_list then
                    for k = 0, sub_list.size - 1 do
                        local val = rime_config:get_string(key_path .. "/@" .. k)
                        if val and val ~= "" then
                            table.insert(triggers, val)
                        end
                    end
                else
                    if rime_config:get_bool(key_path) == true then
                        table.insert(triggers, "true")
                    else
                        local val = rime_config:get_string(key_path)
                        if val and val ~= "" and val ~= "true" then
                            table.insert(triggers, val)
                        end
                    end
                end
            end

            if #triggers > 0 then
                ---@type table<string, boolean>
                local rule_base_set = {}
                ---@type table<integer, boolean>
                local rule_add = {}
                ---@type table<integer, boolean>
                local rule_ban = {}

                local base_str = rime_config:get_string(entry_path .. "/base")
                if base_str and #base_str > 0 then
                    for j = 1, #base_str do
                        rule_base_set[base_str:sub(j, j)] = true
                    end
                end

                ---@param list_name string
                ---@param map table<integer, boolean>
                local function load_list_to_map(list_name, map)
                    local lp = entry_path .. "/" .. list_name
                    local sl = rime_config:get_list(lp)
                    if sl then
                        for k = 0, sl.size - 1 do
                            local val = rime_config:get_string(lp .. "/@" .. k)
                            if val and val ~= "" then
                                for _, cp in utf8.codes(val) do
                                    map[cp] = true
                                end
                            end
                        end
                    end
                end

                load_list_to_map("addlist", rule_add)
                load_list_to_map("blacklist", rule_ban)

                table.insert(filters, {
                    options = triggers,
                    base_set = rule_base_set,
                    add = rule_add,
                    ban = rule_ban,
                })
            end
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
    local is_functional = false
    if wanxiang.s2t_conversion then
        is_functional = wanxiang.s2t_conversion(context)
    end

    local charset_active = #config.filters > 0 and not is_functional

    if #code == 5 and code:sub(-1):find("[^%w]") then
        charset_active = false
    end

    -- 3. 遍历候选词
    local has_recorded_history = false -- 【修复点】：只有第一个有效产出的词才记入历史

    -- 内部帮助函数：记录历史并推入管道
    local function yield_and_record(cand, text)
        if not has_recorded_history and text and text ~= "" and (utf8.len(text) or 0) >= 1 then
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

            if in_charset(text, config, state, context) then
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
        if in_charset(new_cand.text, config, state, context) then
            yield_and_record(new_cand, new_cand.text)
        end

        ::continue::
    end
end

return M
