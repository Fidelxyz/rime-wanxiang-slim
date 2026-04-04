---Intercept keypad keys and compose them directly in composing mode, or always
---if configured to do so.
---@module "wanxiang.keypad_composer"
---@author amzxyz
---@author Fidel Yin <fidel.yin@hotmail.com>

---@class KeypadComposerConfig
---@field mode "auto"|"compose"

---@class KeypadComposerState
---@field is_composing boolean
---
---@field update_notifier Connection

---@class Env
---@field keypad_composer_config KeypadComposerConfig?
---@field keypad_composer_state KeypadComposerState?

local wanxiang = require("wanxiang.wanxiang")

---@type table<integer, integer>
local KP_MAP = {
    [0xFFB0] = 0,
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

local P = {}

---@param env Env
function P.init(env)
    local rime_config = env.engine.schema.config

    local mode = rime_config:get_string("keypad_composer/keypad_mode")
    if mode ~= "auto" and mode ~= "compose" then
        mode = "auto"
    end
    ---@cast mode "auto"|"compose"

    local update_notifier = env.engine.context.update_notifier:connect(function(ctx)
        local state = env.keypad_composer_state

        -- 缓存状态
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
    env.keypad_composer_state.update_notifier:disconnect()
    env.keypad_composer_config = nil
    env.keypad_composer_state = nil
end

---@param key KeyEvent
---@param env Env
---@return integer
function P.func(key, env)
    if key:ctrl() or key:alt() or key:super() then
        return wanxiang.RIME_PROCESS_RESULTS.kNoop
    end

    local kp_num = KP_MAP[key.keycode]
    -- Skip keypad intercept for mobile devices
    if not kp_num or wanxiang.is_mobile_device() then
        return wanxiang.RIME_PROCESS_RESULTS.kNoop
    end

    local config = env.keypad_composer_config
    assert(config)
    local state = env.keypad_composer_state
    assert(state)

    local ch = tostring(kp_num)

    -- 模式处理
    if config.mode == "compose" or (config.mode == "auto" and state.is_composing) then
        -- Compose mode or auto mode with active composition: always process
        env.engine.context:push_input(ch)
        return wanxiang.RIME_PROCESS_RESULTS.kAccepted
    else
        return wanxiang.RIME_PROCESS_RESULTS.kNoop
    end
end

return P
