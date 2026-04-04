---Reorders candidates to prioritize table/user-dictionary entries, formats escape sequences within candidate text, and filters out unwanted sentence derivations to improve mixed Chinese-English input experience.
---@module "wanxiang.super_filter"
---@author amzxyz
---@author Fidel Yin <fidel.yin@hotmail.com>

-- 功能 A：候选文本中的转义序列格式化（始终开启）
--         \n \t \r \\ \s(空格) \d(-)
-- 功能 B：候选重排（仅编码长度 2..6 时）
--         - 第一候选不动
--         - 其余按组输出：①不含字母(table/user_table) → ②其他
--         - 若第二候选为 table/user_table，则不排序，直接透传
-- 功能 C 三码空候选轻量兜底（2码记录首选单字，3码无候选时直接兜底）
-- 功能 D 由于在混输场景中输入comment commit等等之类的英文时候，由于直接辅助码的派生能力，会将三个好不想干的单字组合在一起，这会造成不好的体验
--      因此在首选已经是英文的时候，且type=completion且大于等于4个字符，这个时候后面如果有type=sentence的派生词则直接干掉，这个还要依赖，表翻译器
--      权重设置与主翻译器不可相差太大

---@class SuperFilterConfig
---@field enable_taichi_filter boolean
---@field cand_type_symbols table<string, string>

---@class SuperFilterState
---@field last_2code_char string?

---@class Env
---@field super_filter_config SuperFilterConfig?
---@field super_filter_state SuperFilterState?

---@class Wrapper
---@field cand Candidate
---@field text string
---@field is_table boolean
---@field has_eng boolean

---@class EmitContext
---@field suppress_set table<string, boolean>?
---@field unify_tail_span fun(c: Candidate): Candidate
---@field enable_taichi_filter boolean
---@field drop_sentence_after_completion boolean

---@param cand Candidate
---@return boolean
local function is_table_type(cand)
    local t = cand.type
    return t == "table" or t == "user_table" or t == "fixed"
end

---@param s string
---@return boolean
local function has_english_token_fast(s)
    local len = #s
    for i = 1, len do
        local b = s:byte(i)
        if b < 0x80 then
            -- A-Z (0x41-0x5A) or a-z (0x61-0x7A)
            if (b >= 0x41 and b <= 0x5A) or (b >= 0x61 and b <= 0x7A) then
                return true
            end
        end
    end
    return false
end

local escape_map = {
    ["\\n"] = "\n", -- 换行
    ["\\r"] = "\r", -- 回车
    ["\\t"] = "\t", -- 制表符
    ["\\s"] = " ", -- 空格
    ["\\z"] = "\226\128\139", -- 零宽空格
}

-- 主入口：全局保护 [[]] 并执行所有转义逻辑
---@param text string
---@return string result, boolean changed
local function apply_escape_fast(text)
    -- 性能护航：不含反斜杠直接返回
    if not text or not text:find("\\", 1, true) then
        return text, false
    end

    -- 第一步：保护 [[...]]
    ---@type string[]
    local blocks = {}
    local s = text:gsub("%[%[(.-)%]%]", function(txt)
        blocks[#blocks + 1] = txt
        return "\0BLK" .. #blocks .. "\0"
    end)

    -- 第二步：处理基础转义 (\n, \t, \s, \z 等)
    s = s:gsub("\\[ntrsz]", escape_map)

    -- 第五步：还原 [[...]]
    s = s:gsub("\0BLK(%d+)\0", function(i)
        return blocks[tonumber(i)] or ""
    end)

    return s, s ~= text
end

---@param cand Candidate
---@param config SuperFilterConfig
---@return Candidate
local function format_and_autocap(cand, config)
    local text = cand.text
    if text == "" then
        return cand
    end

    -- 1. 处理转义字符
    local t2, text_changed = apply_escape_fast(text)

    -- 2. 处理尾巴符号追加
    local genuine = cand:get_genuine()
    local current_comment = genuine.comment
    local symbol = config.cand_type_symbols[cand.type]
    local comment_changed = false

    if symbol and symbol ~= "" and current_comment ~= "~" then
        -- 防重判断，避免因为各种原因重复追加
        local escaped_symbol = symbol:gsub("[%-%^%$%(%)%%%.%[%]%*%+%?]", "%%%1")
        if not current_comment:match(escaped_symbol .. "$") then
            current_comment = current_comment .. symbol
            comment_changed = true
        end
    end

    if text_changed then
        local new_cand = Candidate(cand.type, cand.start, cand._end, t2, current_comment)
        new_cand.preedit = cand.preedit
        return new_cand
    else
        if comment_changed then
            genuine.comment = current_comment
        end
        return cand
    end
end

-- 上屏管道：负责去重、格式化、修饰
---@param wrapper Wrapper
---@param ctxs EmitContext
---@param config SuperFilterConfig
---@return boolean
local function emit_with_pipeline(wrapper, ctxs, config)
    local cand = wrapper.cand
    local text = wrapper.text

    -- 2. 太极/句子过滤 (使用缓存的属性)
    if ctxs.enable_taichi_filter and wrapper.has_eng then
        if cand.comment and cand.comment:find("\226\152\175") then
            return false
        end
    end

    -- 3. 英文长句过滤 (Function E)
    if ctxs.drop_sentence_after_completion then
        if cand.type == "sentence" then
            return false
        end
    end

    -- 4. 最终去重
    if ctxs.suppress_set and ctxs.suppress_set[text] then
        return false
    end

    -- 5. 格式化与修饰
    cand = format_and_autocap(cand, config)
    cand = ctxs.unify_tail_span(cand)

    yield(cand)
    return true
end

local M = {}

---@param env Env
function M.init(env)
    local rime_config = env.engine.schema.config

    -- PageSize & TablePosition
    env.page_size = rime_config and rime_config:get_int("menu/page_size")

    local schema_id = env.engine.schema.schema_id
    local enable_taichi_filter = schema_id == "wanxiang" or schema_id == "wanxiang_pro"

    -- 读取全局类型符号配置
    ---@type table<string, string>
    local cand_type_symbols = {}
    local map = rime_config:get_map("super_comment/cand_type")
    if map then
        for _, key in ipairs(map:keys()) do
            local val = map:get_value(key):get_string()
            if val and val ~= "" then
                cand_type_symbols[key] = val
            end
        end
    end

    env.super_filter_config = {
        enable_taichi_filter = enable_taichi_filter,
        cand_type_symbols = cand_type_symbols,
    }

    env.super_filter_state = {
        last_2code_char = nil,
    }
end

---@param env Env
function M.fini(env)
    env.super_filter_config = nil
    env.super_filter_state = nil
end

---@param input Translation
---@param env Env
function M.func(input, env)
    local context = env.engine.context

    local config = env.super_filter_config
    assert(config)
    local state = env.super_filter_state
    assert(state)

    local code = context.input
    local comp = context.composition

    -- 1. 空环境清理
    if not code or code == "" or comp:empty() then
        state.last_2code_char = nil
        for cand in input:iter() do
            yield(cand)
        end
        return
    end

    -- 计算当前拼音片段长度，用于精确判定2码和3码
    local last_seg = comp:back()
    local code_len = #code
    local seg_len = last_seg and (last_seg._end - last_seg.start) or code_len

    -- 及时清理兜底数据
    if seg_len < 2 or seg_len > 3 then
        state.last_2code_char = nil
    end

    -- 3. 成对符号包裹功能已移除
    local fully_consumed = false

    local do_group = code_len >= 2 and code_len <= 6

    -- 闭包上下文 (Context)
    ---@param c Candidate
    ---@return Candidate
    local function unify_tail_span(c)
        if fully_consumed and last_seg and c and c._end ~= last_seg._end then
            local new_cand = Candidate(c.type, c.start, last_seg._end, c.text, c.comment)
            new_cand.preedit = c.preedit
            return new_cand
        end
        return c
    end

    ---@type EmitContext
    local emit_ctx = {
        suppress_set = nil,
        unify_tail_span = unify_tail_span,
        enable_taichi_filter = config.enable_taichi_filter,
        drop_sentence_after_completion = false, -- 初始化为 false
    }

    local page_size = env.page_size
    local sort_window = 30
    local visual_idx = 0

    -- 通用候选处理 (Wrap -> Emit)
    ---@param wrapper Wrapper
    ---@return boolean
    local function try_process_wrapper(wrapper)
        if emit_with_pipeline(wrapper, emit_ctx, config) then
            visual_idx = visual_idx + 1
            return true
        end
        return false
    end

    -- 三码空候选轻量兜底执行函数
    local function check_and_yield_fallback()
        if visual_idx == 0 and seg_len == 3 then
            local fallback_text = state.last_2code_char
            if fallback_text then
                local start_pos = last_seg and last_seg.start or (#code - 3)
                if start_pos < 0 then
                    start_pos = 0
                end
                local end_pos = last_seg and last_seg._end or #code
                local new_cand = Candidate("fallback", start_pos, end_pos, fallback_text, "")
                -- 分割预编辑区，例如输入 "abc" -> 显示 "ab c"
                local seg_str = code:sub(start_pos + 1, end_pos)
                if #seg_str >= 3 then
                    new_cand.preedit = seg_str:sub(1, 2) .. " " .. seg_str:sub(3)
                else
                    new_cand.preedit = seg_str
                end
                yield(new_cand)
            end
        end
    end

    -- 模式 1: 非分组 (Direct Pass)
    if not do_group then
        local idx = 0
        for cand in input:iter() do
            idx = idx + 1
            -- 封装 Wrapper，后续逻辑复用属性
            local txt = cand.text
            local w = {
                cand = cand,
                text = txt,
                is_table = is_table_type(cand),
                has_eng = has_english_token_fast(txt),
            }

            if idx == 1 then
                -- 为3码兜底做准备
                if seg_len == 2 and (utf8.len(txt) or 0) == 1 and not w.has_eng then
                    state.last_2code_char = txt
                end

                -- 英文长句过滤触发器
                if w.is_table and #txt >= 4 and w.has_eng then
                    emit_ctx.drop_sentence_after_completion = true
                end
            end

            try_process_wrapper(w)
        end
        -- 单字无候选时兜底
        check_and_yield_fallback()
        return
    end

    -- 模式 2: 分组模式 (Grouping)
    local idx2 = 0
    local mode = "unknown" -- unknown | passthrough | grouping

    local normal_buf = {} -- 存 Normal
    local special_buf = {} -- 存 Table/UserTable

    ---@param force_all boolean
    local function try_flush_page_sort(force_all)
        while true do
            local next_pos = visual_idx + 1
            local current_idx_in_page = ((next_pos - 1) % page_size) + 1
            local is_second_page = (visual_idx >= page_size)

            local allow_special = is_second_page or (current_idx_in_page >= page_size)

            local w_to_emit = nil
            if force_all then
                if allow_special then
                    if #special_buf > 0 then
                        w_to_emit = table.remove(special_buf, 1)
                    elseif #normal_buf > 0 then
                        w_to_emit = table.remove(normal_buf, 1)
                    end
                else
                    if #normal_buf > 0 then
                        w_to_emit = table.remove(normal_buf, 1)
                    elseif #special_buf > 0 then
                        w_to_emit = table.remove(special_buf, 1)
                    end
                end
                if not w_to_emit then
                    break
                end
            else
                if allow_special then
                    if #special_buf > 0 then
                        w_to_emit = table.remove(special_buf, 1)
                    else
                        if #normal_buf > sort_window then
                            w_to_emit = table.remove(normal_buf, 1)
                        else
                            break
                        end
                    end
                else
                    if #normal_buf > 0 then
                        w_to_emit = table.remove(normal_buf, 1)
                    else
                        break
                    end
                end
            end

            if w_to_emit then
                try_process_wrapper(w_to_emit)
            end
        end
    end

    local grouped_cnt = 0
    local window_closed = false

    for cand in input:iter() do
        idx2 = idx2 + 1
        local txt = cand.text
        ---@type Wrapper
        local w = {
            cand = cand,
            text = txt,
            is_table = is_table_type(cand),
            has_eng = has_english_token_fast(txt),
        }

        if idx2 == 1 then
            -- 为3码兜底做准备
            if seg_len == 2 and (utf8.len(txt) or 0) == 1 and not w.has_eng then
                state.last_2code_char = txt
            end

            if w.is_table and #txt >= 4 and w.has_eng then
                emit_ctx.drop_sentence_after_completion = true
            end

            try_process_wrapper(w)
        elseif idx2 == 2 and mode == "unknown" then
            if w.is_table then
                mode = "passthrough"
                try_process_wrapper(w)
            else
                mode = "grouping"
                table.insert(normal_buf, w)
                try_flush_page_sort(false)
            end
        else
            if mode == "passthrough" then
                try_process_wrapper(w)
            else
                if (not window_closed) and (grouped_cnt < sort_window) then
                    grouped_cnt = grouped_cnt + 1
                    if w.is_table and not w.has_eng then
                        table.insert(special_buf, w)
                    else
                        table.insert(normal_buf, w)
                    end

                    if grouped_cnt >= sort_window then
                        window_closed = true
                    end
                    try_flush_page_sort(false)
                else
                    if w.is_table and not w.has_eng then
                        table.insert(special_buf, w)
                    else
                        table.insert(normal_buf, w)
                    end
                    try_flush_page_sort(false)
                end
            end
        end
    end

    if mode == "grouping" then
        try_flush_page_sort(true)
    end
    -- 单字无候选时兜底
    check_and_yield_fallback()
end

return M
