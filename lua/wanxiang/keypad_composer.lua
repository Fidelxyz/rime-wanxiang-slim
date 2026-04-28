---Intercept keypad keys and compose them directly in composing mode, or always if configured to do so.
---@author amzxyz
---@author Fidel Yin <fidel.yin@hotmail.com>

---@class KeypadComposerConfig
---@field mode "auto"|"compose"|"select"

---@class KeypadComposerState
---@field is_composing boolean
---
---@field update_notifier Connection

---@diagnostic disable-next-line: duplicate-type
---@class Env
---@field keypad_composer_config KeypadComposerConfig?
---@field keypad_composer_state KeypadComposerState?

local wanxiang = require("wanxiang.wanxiang")

local P = {}

---@param env Env
function P.init(env)
    local rime_config = env.engine.schema.config

    local mode = rime_config:get_string("keypad_composer/keypad_mode")
    if mode ~= "auto" and mode ~= "compose" and mode ~= "select" then
        mode = "select"
    end
    ---@cast mode "auto"|"compose"|"select"

    local update_notifier = env.engine.context.update_notifier:connect(function(ctx)
        local state = env.keypad_composer_state
        assert(state)

        state.is_composing = ctx:is_composing()
    end)

    env.keypad_composer_config = {
        mode = mode,
    }

    env.keypad_composer_state = {
        is_composing = false,
        update_notifier = update_notifier,
    }
end

---@param env Env
function P.fini(env)
    assert(env.keypad_composer_state)
    env.keypad_composer_state.update_notifier:disconnect()
    env.keypad_composer_config = nil
    env.keypad_composer_state = nil
end

---@param key KeyEvent
---@param env Env
---@return integer
function P.func(key, env)
    local config = env.keypad_composer_config
    assert(config)

    -- Keep the default behavior in select mode
    if config.mode == "select" then
        return wanxiang.RIME_PROCESS_RESULTS.kNoop
    end

    -- Only process keypad keys without modifiers
    local keycode = key.keycode
    if (keycode < 0xFFB0 or 0xFFB9 < keycode) or key:ctrl() or key:alt() or key:super() or key:release() then
        return wanxiang.RIME_PROCESS_RESULTS.kNoop
    end

    local state = env.keypad_composer_state
    assert(state)

    -- keycode 0xFFB0-0xFFB9 -> keypad 0-9
    local ch = tostring(keycode - 0xFFB0)

    if config.mode == "compose" or (config.mode == "auto" and state.is_composing) then
        -- Compose mode or auto mode with active composition: always process
        env.engine.context:push_input(ch)
    else
        -- Auto mode with inactive composition: commit directly
        env.engine:commit_text(ch)
    end
    return wanxiang.RIME_PROCESS_RESULTS.kAccepted
end

return P
