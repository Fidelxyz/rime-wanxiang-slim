---Ctrl + number keys to commit the first n characters of the current candidate,
---and keep the rest in the input box for further editing.
---@author amzxyz
---@author Fidel Yin <fidel.yin@hotmail.com>

---@class PartialCommitState
---@field pending_rest string?
---
---@field update_notifier Connection

---@diagnostic disable-next-line: duplicate-type
---@class Env
---@field partial_commit_state PartialCommitState?

local wanxiang = require("wanxiang.wanxiang")

---Digit keys mapping
---@type table<integer, integer>
local NUMKEY_MAP = {
    -- Number keys (top row)
    [0x30] = 10,
    [0x31] = 1,
    [0x32] = 2,
    [0x33] = 3,
    [0x34] = 4,
    [0x35] = 5,
    [0x36] = 6,
    [0x37] = 7,
    [0x38] = 8,
    [0x39] = 9,
    -- Numpad keys
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
    local context = env.engine.context

    -- 监听器：在上屏动作完成后，立刻将截断后的剩余拼音恢复到输入框
    local update_notifier = context.update_notifier:connect(function(ctx)
        local state = env.partial_commit_state
        assert(state)

        if not state.pending_rest then
            return
        end

        -- Take pending rest
        local rest = state.pending_rest
        state.pending_rest = nil

        ctx.input = rest
        ctx:clear_non_confirmed_composition()
        if ctx.caret_pos ~= nil then
            ctx.caret_pos = #rest
        end
    end)

    env.partial_commit_state = {
        pending_rest = nil,
        update_notifier = update_notifier,
    }
end

---@param env Env
function P.fini(env)
    assert(env.partial_commit_state)
    env.partial_commit_state.update_notifier:disconnect()
    env.partial_commit_state = nil
end

---@param key KeyEvent
---@param env Env
---@return ProcessResult
function P.func(key, env)
    if not key:ctrl() or key:release() then
        return wanxiang.RIME_PROCESS_RESULTS.kNoop
    end

    local n = NUMKEY_MAP[key.keycode]
    if not n then
        return wanxiang.RIME_PROCESS_RESULTS.kNoop
    end

    local context = env.engine.context
    if not context:is_composing() then
        return wanxiang.RIME_PROCESS_RESULTS.kNoop
    end

    local cand = context:get_selected_candidate()
    if not cand or cand.text == "" then
        return wanxiang.RIME_PROCESS_RESULTS.kNoop
    end

    -- 直接调用底层 spans 获取物理切分坐标
    local spans = context.composition:spans()
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
    local rest = cut_byte and context.input:sub(cut_byte + 1) or ""
    -- 如果剩余输入首字符是手动输入的分隔符（比如 ' ），顺手切掉保证清爽
    if rest:sub(1, 1) == "'" or rest:sub(1, 1) == " " then
        rest = rest:sub(2)
    end

    local state = env.partial_commit_state
    assert(state)

    -- 提交前 n 个字
    env.engine:commit_text(head)
    -- 挂起剩余拼音，触发 update_notifier 恢复
    set_pending(rest, state)
    context:refresh_non_confirmed_composition()

    return wanxiang.RIME_PROCESS_RESULTS.kAccepted
end

return P
