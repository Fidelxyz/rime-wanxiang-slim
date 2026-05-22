---When consecutive tone digits (7890) are pressed, compress them to keep only the last one.
---This allows users to correct tone selection by simply pressing a different tone digit.
---@author amzxyz
---@author Fidel Yin <fidel.yin@hotmail.com>

---@class ToneFallbackConfig
---@field lookup_trigger string

---@class ToneFallbackState
---Set in `func` to request the notifier to compress on the next input update.
---@field pending_compress boolean
---
---@field update_notifier Connection

---@diagnostic disable-next-line: duplicate-type
---@class Env
---@field tone_fallback_config ToneFallbackConfig?
---@field tone_fallback_state ToneFallbackState?

local wanxiang = require("wanxiang.wanxiang")

---@type table<string, true>
local TONE_DIGITS = { ["7"] = true, ["8"] = true, ["9"] = true, ["0"] = true }

---Compress consecutive tone digits, keeping only the last one.
---e.g. "ni78" -> "ni8", "hao790" -> "hao0".
---@param text string
---@return string compressed
---@return boolean changed
local function compress_tone_runs(text)
    local changed = false
    local out = text:gsub("([7890])([7890]+)", function(_, tail)
        changed = true
        return tail:sub(-1)
    end)
    return out, changed
end

local P = {}

---@param env Env
function P.init(env)
    local rime_config = env.engine.schema.config
    local context = env.engine.context

    local lookup_trigger = rime_config:get_string("lookup_filter/trigger") or "`"

    -- Compress the prefix up to caret_pos when the previous keystroke set the flag.
    local update_notifier = context.update_notifier:connect(function(ctx)
        local state = env.tone_fallback_state
        assert(state)

        if not state.pending_compress then
            return
        end
        state.pending_compress = false

        local caret = ctx.caret_pos
        local left = ctx.input:sub(1, caret)
        local compressed, changed = compress_tone_runs(left)
        if not changed then
            return
        end

        ctx:pop_input(caret)
        ctx:push_input(compressed)
    end)

    env.tone_fallback_config = {
        lookup_trigger = lookup_trigger,
    }

    env.tone_fallback_state = {
        pending_compress = false,
        update_notifier = update_notifier,
    }
end

---@param env Env
function P.fini(env)
    assert(env.tone_fallback_state)
    env.tone_fallback_state.update_notifier:disconnect()
    env.tone_fallback_config = nil
    env.tone_fallback_state = nil
end

---@param key KeyEvent
---@param env Env
---@return ProcessResult
function P.func(key, env)
    local context = env.engine.context
    local input = context.input

    local config = env.tone_fallback_config
    assert(config)
    local state = env.tone_fallback_state
    assert(state)

    -- Reset the flag for any key that doesn't qualify below.
    state.pending_compress = false

    -- Only act when composing.
    if input == "" then
        return wanxiang.RIME_PROCESS_RESULTS.kNoop
    end

    -- Ignore modified keys.
    if key:ctrl() or key:alt() or key:super() then
        return wanxiang.RIME_PROCESS_RESULTS.kNoop
    end

    if not TONE_DIGITS[key:repr()] then
        return wanxiang.RIME_PROCESS_RESULTS.kNoop
    end

    -- Skip in reverse-lookup mode and function mode.
    if input:find(config.lookup_trigger, 1, true) then
        return wanxiang.RIME_PROCESS_RESULTS.kNoop
    end
    if wanxiang.is_function_mode_active(context) then
        return wanxiang.RIME_PROCESS_RESULTS.kNoop
    end

    -- Skip if the selected candidate contains Latin letters (likely English input).
    local cand = context:get_selected_candidate()
    if cand and cand.text:match("[a-zA-Z]") then
        return wanxiang.RIME_PROCESS_RESULTS.kNoop
    end

    -- Let the speller append the tone digit; the notifier will compress afterwards.
    state.pending_compress = true
    return wanxiang.RIME_PROCESS_RESULTS.kNoop
end

return P
