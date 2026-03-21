-- Ctrl+1..9,0：上屏首选前 N 字；按 preedit/script_text 的前 N 音节对齐 raw input

---@class PartialCommitConfig
---@field auto_delimiter string
---@field manual_delimiter string

---@class PartialCommitState
---@field pending_rest string?
---
---@field update_conn Connection
---@field key_handler function

---@class Env
---@field partial_commit_config PartialCommitConfig?
---@field partial_commit_state PartialCommitState?

local wanxiang = require("wanxiang.wanxiang")

---Digit keys mapping
---@type table<integer, integer>
local DIGIT = {
    [0x31] = 1,
    [0x32] = 2,
    [0x33] = 3,
    [0x34] = 4,
    [0x35] = 5,
    [0x36] = 6,
    [0x37] = 7,
    [0x38] = 8,
    [0x39] = 9,
    [0x30] = 10,
}

---Keypad keys mapping
---@type table<integer, integer>
local KP = {
    [0xFFB1] = 1,
    [0xFFB2] = 2,
    [0xFFB3] = 3,
    [0xFFB4] = 4,
    [0xFFB5] = 5,
    [0xFFB6] = 6,
    [0xFFB7] = 7,
    [0xFFB8] = 8,
    [0xFFB9] = 9,
    [0xFFB0] = 10,
}

-- 工具：安全获取 UTF-8 字符
---@param str string
---@param index integer
---@return string?
local function get_utf8_char(str, index)
    if not str or str == "" then
        return nil
    end
    local start_byte = utf8.offset(str, index)
    if not start_byte then
        return nil
    end
    local end_byte = utf8.offset(str, index + 1)
    return str:sub(start_byte, (end_byte and end_byte - 1) or nil)
end

-- 放进字符类 [...] 使用的转义（只转义 % ^ ] -）
---@param c string
---@return string
local function esc_class(c)
    if not c or c == "" then
        return ""
    end
    return (c:gsub("([%%%^%]%-])", "%%%1"))
end

-- 普通模式串位置的单字符转义
---@param s string
---@return string
local function esc_pat(s)
    if not s or s == "" then
        return ""
    end
    return (s:gsub("[%^%$%(%)%%%.%[%]%*%+%-%?]", "%%%1"))
end

-- 清洗整串 raw：去掉手动分隔符
---@param raw string
---@param config PartialCommitConfig
---@return string
local function clean_raw(raw, config)
    if raw == "" then
        return ""
    end

    local manual_delimiter = config.manual_delimiter
    if manual_delimiter and manual_delimiter ~= "" then
        raw = raw:gsub(esc_pat(manual_delimiter), "")
    end
    return raw
end

-- 取候选前 n 个字符
---@param s string
---@param n integer
---@return string
local function utf8_head(s, n)
    if not s or s == "" or n <= 0 then
        return ""
    end
    local offset = utf8.offset(s, n + 1)
    return offset and s:sub(1, offset - 1) or s
end

-- 生成 target：按分隔符切 preedit/script_text，取前 n 个并去分隔符拼接
---@param n integer
---@param config PartialCommitConfig
---@param ctx Context
---@return string
local function script_prefix(n, config, ctx)
    local raw_in = ctx.input or ""
    local prop_key = ctx:get_property("sequence_preedit_key") or ""
    local prop_val = ctx:get_property("sequence_preedit_val") or ""
    local script_txt = ctx:get_script_text() or ""

    local s = (prop_key == raw_in and prop_val ~= "") and prop_val or script_txt
    if s == "" then
        return ""
    end

    local pat = "[^" .. esc_class(config.auto_delimiter) .. esc_class(config.manual_delimiter) .. "%s]+"

    ---@type string[]
    local parts = {}
    for w in s:gmatch(pat) do
        parts[#parts + 1] = w
    end
    if #parts == 0 then
        return ""
    end

    local upto = math.min(n, #parts)
    local target = table.concat({ table.unpack(parts, 1, upto) }, "")
    return target
end

-- 对齐“去分隔符后的 raw_clean”与 target；返回消耗长度（基于 raw_clean）
---@param target string
---@param config PartialCommitConfig
---@param ctx Context
---@return integer
local function eat_len_by_target(target, config, ctx)
    if target == "" then
        return 0
    end

    local raw = ctx.input
    if raw == "" then
        return 0
    end

    local clean = clean_raw(raw, config)
    local i = 1
    local j = 1
    while i <= #clean and j <= #target do
        if clean:sub(i, i) ~= target:sub(j, j) then
            return 0
        end
        i, j = i + 1, j + 1
    end
    if j <= #target then
        return 0
    end
    return i - 1
end

local M = {}

---@param env Env
function M.init(env)
    local rime_config = env.engine.schema.config

    local delimiter = rime_config:get_string("speller/delimiter") or " '"
    local auto_delimiter = get_utf8_char(delimiter, 1) or " "
    local manual_delimiter = get_utf8_char(delimiter, 2) or "'"

    local context = env.engine.context
    local update_conn = context.update_notifier:connect(function(ctx)
        local state = env.partial_commit_state
        assert(state)

        if not state.pending_rest then
            return
        end

        -- Take pending rest
        local rest = state.pending_rest or ""
        state.pending_rest = nil

        ctx.input = rest
        if ctx.clear_non_confirmed_composition then
            ctx:clear_non_confirmed_composition()
        end
        if ctx.caret_pos ~= nil then
            ctx.caret_pos = #rest
        end
    end)

    local key_handler = function(key)
        local config = env.partial_commit_config
        assert(config)
        local state = env.partial_commit_state
        assert(state)

        if not key:ctrl() or key:release() then
            return wanxiang.RIME_PROCESS_RESULTS.kNoop
        end

        local n = DIGIT[key.keycode] or KP[key.keycode]
        if not n then
            return wanxiang.RIME_PROCESS_RESULTS.kNoop
        end

        local context = env.engine.context
        if not context:is_composing() then
            return wanxiang.RIME_PROCESS_RESULTS.kNoop
        end

        local cand = context:get_selected_candidate()
        if #cand.text == 0 then
            return wanxiang.RIME_PROCESS_RESULTS.kNoop
        end

        local head = utf8_head(cand.text, n)
        if head == "" then
            return wanxiang.RIME_PROCESS_RESULTS.kNoop
        end

        local target = script_prefix(n, config, context)
        if target == "" then
            return wanxiang.RIME_PROCESS_RESULTS.kNoop
        end

        local consumed = eat_len_by_target(target, config, context)
        if consumed == 0 then
            return wanxiang.RIME_PROCESS_RESULTS.kNoop
        end

        local raw_clean = clean_raw(context.input, config)
        local rest = raw_clean:sub(consumed + 1)

        env.engine:commit_text(head)
        -- Set pending rest
        state.pending_rest = rest or ""
        context:refresh_non_confirmed_composition()

        return wanxiang.RIME_PROCESS_RESULTS.kAccepted
    end

    env.partial_commit_config = {
        auto_delimiter = auto_delimiter,
        manual_delimiter = manual_delimiter,
    }

    env.partial_commit_state = {
        pending_rest = nil,
        update_conn = update_conn,
        key_handler = key_handler,
    }
end

---@param env Env
function M.fini(env)
    env.partial_commit_state.update_conn:disconnect()
    env.partial_commit_state = nil
end

---@param key KeyEvent
---@param env Env
---@return ProcessResult
function M.func(key, env)
    local state = env.partial_commit_state
    assert(state)

    if not state.key_handler then
        return wanxiang.RIME_PROCESS_RESULTS.kNoop
    end
    return state.key_handler(key)
end

return M
