---Allows Ctrl + number keys to commit the first N characters of the current candidate and keep the rest in the input
---box for further editing.
---@author amzxyz
---@author Fidel Yin <fidel.yin@hotmail.com>

---@class PartialCommitterState
---@field pending_rest string?
---
---@field update_notifier Connection

---@diagnostic disable-next-line: duplicate-type
---@class Env
---@field partial_committer_state PartialCommitterState?

local wanxiang = require("wanxiang.wanxiang")

---Mapping from digit key codes to the number of characters to commit.
---Key `0` is treated as 10.
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
    [0xFFB0] = 10,
    [0xFFB1] = 1,
    [0xFFB2] = 2,
    [0xFFB3] = 3,
    [0xFFB4] = 4,
    [0xFFB5] = 5,
    [0xFFB6] = 6,
    [0xFFB7] = 7,
    [0xFFB8] = 8,
    [0xFFB9] = 9,
}

---Take the first n UTF-8 characters of a string.
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

local P = {}

---@param env Env
function P.init(env)
    local context = env.engine.context

    -- After commit_text fires, restore the remaining raw input back into the input box.
    local update_notifier = context.update_notifier:connect(function(ctx)
        local state = env.partial_committer_state
        assert(state)

        if not state.pending_rest then
            return
        end

        local rest = state.pending_rest
        state.pending_rest = nil

        ctx.input = rest
        ctx:clear_non_confirmed_composition()
        ctx.caret_pos = #rest
    end)

    env.partial_committer_state = {
        pending_rest = nil,
        update_notifier = update_notifier,
    }
end

---@param env Env
function P.fini(env)
    assert(env.partial_committer_state)
    env.partial_committer_state.update_notifier:disconnect()
    env.partial_committer_state = nil
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

    -- Spans expose the physical syllable boundaries of the input.
    local spans = context.composition:spans()
    if spans.count == 0 or #spans.vertices < 2 then
        return wanxiang.RIME_PROCESS_RESULTS.kNoop
    end

    -- Clamp n to the smallest of: requested length, available syllables, candidate length.
    local available_syllables = #spans.vertices - 1
    local cand_len = utf8.len(cand.text) or 0
    n = math.min(n, available_syllables, cand_len)
    if n <= 0 then
        return wanxiang.RIME_PROCESS_RESULTS.kNoop
    end

    -- The candidate prefix to commit.
    local head = utf8_head(cand.text, n)
    -- vertices[n + 1] is the byte offset where the n-th syllable ends in the raw input.
    -- Always present because n was clamped to #spans.vertices - 1 above.
    local cut_byte = spans.vertices[n + 1]
    assert(cut_byte)
    local rest = context.input:sub(cut_byte + 1)
    -- Drop a leading delimiter (manual `'` or auto ` `) so the remaining input stays clean.
    if rest:sub(1, 1) == "'" or rest:sub(1, 1) == " " then
        rest = rest:sub(2)
    end

    local state = env.partial_committer_state
    assert(state)

    -- Commit the prefix and stash the rest; update_notifier will restore it shortly after.
    env.engine:commit_text(head)
    state.pending_rest = rest
    context:refresh_non_confirmed_composition()

    return wanxiang.RIME_PROCESS_RESULTS.kAccepted
end

return P
