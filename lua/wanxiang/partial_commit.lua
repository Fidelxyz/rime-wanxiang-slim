-- Ctrl+1..9,0：上屏首选前 N 字；按 preedit/script_text 的前 N 音节对齐 raw input

---@class PartialCommitConfig
---@field auto_delimiter string
---@field manual_delimiter string

---@class PartialCommitState
---@field pending_rest string?
---
---@field update_notifier Connection

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
    if str == "" then
        return nil
    end
    local start_byte = utf8.offset(str, index)
    if not start_byte then
        return nil
    end
    local end_byte = utf8.offset(str, index + 1)
    return str:sub(start_byte, end_byte and end_byte - 1)
end

-- 取候选前 n 个字符
---@param s string
---@param n integer
---@return string
local function utf8_head(s, n)
    if s == "" or n <= 0 then
        return ""
    end
    local offset = utf8.offset(s, n + 1)
    return offset and s:sub(1, offset - 1) or s
end

---@param rest string
---@param state PartialCommitState
local function set_pending(rest, state)
    state.pending_rest = rest
end

local P = {}

---@param env Env
function P.init(env)
    local rime_config = env.engine.schema.config

    local delimiter = rime_config:get_string("speller/delimiter") or " '"
    local auto_delimiter = get_utf8_char(delimiter, 1) or " "
    local manual_delimiter = get_utf8_char(delimiter, 2) or "'"

    local context = env.engine.context

    -- 监听器：在上屏动作完成后，立刻将截断后的剩余拼音恢复到输入框
    local update_notifier = context.update_notifier:connect(function(ctx)
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

    env.partial_commit_config = {
        auto_delimiter = auto_delimiter,
        manual_delimiter = manual_delimiter,
    }

    env.partial_commit_state = {
        pending_rest = nil,
        update_notifier = update_notifier,
    }
end

---@param env Env
function P.fini(env)
    env.partial_commit_state.update_notifier:disconnect()
    env.partial_commit_state = nil
end

---@param key KeyEvent
---@param env Env
---@return ProcessResult
function P.func(key, env)
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

    local ctx = env.engine.context
    if not ctx:is_composing() then
        return wanxiang.RIME_PROCESS_RESULTS.kNoop
    end

    local cand = ctx:get_selected_candidate()
    if not cand or cand.text == "" then
        return wanxiang.RIME_PROCESS_RESULTS.kNoop
    end

    -- 直接调用底层 spans 获取物理切分坐标
    local spans = ctx.composition:spans()
    if spans.count == 0 or #spans.vertices < 2 then
        return wanxiang.RIME_PROCESS_RESULTS.kNoop
    end

    -- 防呆保护：取 期望长度(N)、实际拼音音节数、候选词字符数 三者中的最小值
    local available_syllables = #spans.vertices - 1
    local cand_len = utf8.len(cand.text) or 0
    n = math.min(n, available_syllables, cand_len)
    if n <= 0 then
        return wanxiang.RIME_PROCESS_RESULTS.kNoop
    end

    -- 获取需要上屏的中文候选字串
    local head = utf8_head(cand.text, n)
    -- 利用 vertices 拿到第 n 个音节的精确字节偏移量
    local cut_byte = spans.vertices[n + 1]
    -- 截取剩余的 raw_input
    local rest = ctx.input:sub(cut_byte + 1)
    -- 如果剩余输入首字符是手动输入的分隔符（比如 ' ），顺手切掉保证清爽
    if rest:sub(1, 1) == "'" or rest:sub(1, 1) == " " then
        rest = rest:sub(2)
    end

    -- 提交前 n 个字
    env.engine:commit_text(head)
    -- 挂起剩余拼音，触发 update_notifier 恢复
    set_pending(rest, state)
    ctx:refresh_non_confirmed_composition()

    return wanxiang.RIME_PROCESS_RESULTS.kAccepted
end

return P
