---When consecutive tone digits (7890) are pressed, compress them to keep only the last one.
---This allows users to correct tone selection by simply pressing a different tone digit.
---@author amzxyz
---@author Fidel Yin <fidel.yin@hotmail.com>

---@class ToneFallbackConfig
---@field lookup_trigger string

---@class ToneFallbackState
---@field working_state "idle"|"compress"|"skip"
---
---@field conn_update Connection

---@diagnostic disable-next-line: duplicate-type
---@class Env
---@field tone_fallback_config ToneFallbackConfig?
---@field tone_fallback_state ToneFallbackState?

local wanxiang = require("wanxiang.wanxiang")

local TONE_DIGITS = { ["7"] = true, ["8"] = true, ["9"] = true, ["0"] = true }

--- Compress consecutive tone digits, keeping only the last one.
--- e.g. "ni78" -> "ni8", "hao790" -> "hao0"
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
    local config = env.engine.schema.config
    local context = env.engine.context

    local lookup_trigger = config:get_string("lookup_filter/trigger") or "`"

    -- Connect to update_notifier to perform compression after input changes
    local conn_update = context.update_notifier:connect(function(ctx)
        local state = env.tone_fallback_state
        assert(state)

        local working_state = state.working_state
        state.working_state = "idle"

        if working_state ~= "compress" then
            return
        end

        local input = ctx.input or ""
        if input == "" then
            return
        end

        local caret = ctx.caret_pos or #input
        if caret < 0 then
            caret = 0
        end
        if caret > #input then
            caret = #input
        end

        local left = (caret > 0) and input:sub(1, caret) or ""
        local left_new, changed = compress_tone_runs(left)

        if changed then
            if caret > 0 then
                ctx:pop_input(caret)
            end
            if #left_new > 0 then
                ctx:push_input(left_new)
            end
        end
    end)

    env.tone_fallback_config = {
        lookup_trigger = lookup_trigger,
    }

    env.tone_fallback_state = {
        working_state = "idle",
        conn_update = conn_update,
    }
end

---@param env Env
function fini(env)
    assert(env.tone_fallback_state)
    env.tone_fallback_state.conn_update:disconnect()
    env.tone_fallback_config = nil
    env.tone_fallback_state = nil
end

---@param key KeyEvent
---@param env Env
---@return ProcessResult
function P.func(key, env)
    local ctx = env.engine.context
    local input = ctx.input or ""

    -- Only act when composing
    if input == "" then
        return 2
    end

    -- Ignore modified keys
    if key:ctrl() or key:alt() or key:super() then
        return 2
    end

    local config = env.tone_fallback_config
    assert(config)
    local state = env.tone_fallback_state
    assert(state)

    local repr = key:repr() or ""

    -- Check if this is a tone digit
    if TONE_DIGITS[repr] then
        -- Skip tone compression in lookup mode or function mode
        if input:find(config.lookup_trigger, 1, true) then
            state.working_state = "idle"
            return 2
        end

        if wanxiang.is_function_mode_active(ctx) then
            state.working_state = "idle"
            return 2
        end

        -- Skip if first candidate contains English (likely English input)
        local cand = ctx:get_selected_candidate()
        if cand and cand.text:match("[a-zA-Z]") then
            state.working_state = "idle"
            return 2
        end

        -- Set state to compress; the update_notifier will handle the actual compression
        state.working_state = "compress"

        -- Pre-check: if compression would happen, let the digit through
        -- (the notifier will compress after the digit is appended)
        local caret = ctx.caret_pos or #input
        if caret > #input then
            caret = #input
        end
        local left = (caret > 0) and input:sub(1, caret) or ""
        local _, would_change = compress_tone_runs(left)
        if would_change then
            -- There are already consecutive tones; the new digit will be appended
            -- and then the notifier will compress. Return noop to let speller handle it.
            return 2
        end

        return 2
    end

    -- Non-tone key: reset state
    state.working_state = "idle"
    return 2
end

return P
