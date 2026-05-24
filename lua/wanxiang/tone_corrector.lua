---Allows users to correct tone selection by simply pressing a different tone digit.
---@author amzxyz
---@author Fidel Yin <fidel.yin@hotmail.com>

---@class ToneCorrectorConfig
---@field lookup_trigger string?

---@class ToneCorrectorState
---Set in `func` to request the notifier to compress on the next input update.
---@field pending_correction boolean
---
---@field update_notifier Connection

---@diagnostic disable-next-line: duplicate-type
---@class Env
---@field tone_corrector_config ToneCorrectorConfig?
---@field tone_corrector_state ToneCorrectorState?

local wanxiang = require("wanxiang.wanxiang")

---@type table<string, true>
local TONE_DIGITS = { ["7"] = true, ["8"] = true, ["9"] = true, ["0"] = true }

---Replace each run of tone digits with only its last digit.
---@param text string
---@return string replaced
---@return boolean changed
local function correct_tone(text)
    local changed = false
    local out = text:gsub("[7890]+", function(run)
        if #run == 1 then
            return run
        end
        changed = true
        return run:sub(-1)
    end)
    return out, changed
end

local P = {}

---@param env Env
function P.init(env)
    local rime_config = env.engine.schema.config
    local context = env.engine.context

    local lookup_trigger = rime_config:get_string("lookup_filter/trigger")
    if lookup_trigger == "" then
        lookup_trigger = nil
    end

    -- Compress the prefix up to caret_pos when the previous keystroke set the flag.
    local update_notifier = context.update_notifier:connect(function(ctx)
        local state = env.tone_corrector_state
        assert(state)

        if not state.pending_correction then
            return
        end
        state.pending_correction = false

        local caret = ctx.caret_pos
        local left = ctx.input:sub(1, caret)
        local compressed, changed = correct_tone(left)
        if not changed then
            return
        end

        ctx:pop_input(caret)
        ctx:push_input(compressed)
    end)

    env.tone_corrector_config = {
        lookup_trigger = lookup_trigger,
    }

    env.tone_corrector_state = {
        pending_correction = false,
        update_notifier = update_notifier,
    }
end

---@param env Env
function P.fini(env)
    assert(env.tone_corrector_state)
    env.tone_corrector_state.update_notifier:disconnect()
    env.tone_corrector_config = nil
    env.tone_corrector_state = nil
end

---@param key KeyEvent
---@param env Env
---@return ProcessResult
function P.func(key, env)
    local context = env.engine.context

    local state = env.tone_corrector_state
    assert(state)

    -- Reset the flag for any key that doesn't qualify below.
    state.pending_correction = false

    -- Only act when composing.
    local input = context.input
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

    local config = env.tone_corrector_config
    assert(config)

    -- Skip in reverse-lookup mode and function mode.
    if config.lookup_trigger and input:find(config.lookup_trigger, 1, true) then
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
    state.pending_correction = true
    return wanxiang.RIME_PROCESS_RESULTS.kNoop
end

return P
