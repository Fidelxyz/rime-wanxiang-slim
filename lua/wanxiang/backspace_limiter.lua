---Enhances input processing by enforcing backspace limits.
---@author amzxyz
---@author Fidel Yin <fidel.yin@hotmail.com>

---@class BackspaceLimiterConfig
---@field enabled boolean

---@class BackspaceLimiterState
---@field bs_deleting_preedit boolean

---@diagnostic disable-next-line: duplicate-type
---@class Env
---@field backspace_limiter_config BackspaceLimiterConfig?
---@field backspace_limiter_state BackspaceLimiterState?

local wanxiang = require("wanxiang.wanxiang")

---@param key KeyEvent
---@param config BackspaceLimiterConfig
---@param state BackspaceLimiterState
---@param ctx Context
---@return boolean
local function handle_backspace(key, config, state, ctx)
    if wanxiang.is_mobile_device() or not config.enabled then
        return false
    end

    -- If the backspace key is released, reset the state.
    if key.keycode ~= 0xFF08 or key:release() then
        state.bs_deleting_preedit = false
        return false
    end

    -- If the backspace key is presesed when the input is not empty,
    -- it means the user is deleting preedit.
    if ctx.input ~= "" then
        state.bs_deleting_preedit = true
        return false
    end

    -- Now, the input is empty, i.e. the last character of the input has been deleted.
    -- Intercept the backspace key to prevent deleting committed text, if the
    -- backspace key is pressed when deleting preedit.
    return state.bs_deleting_preedit
end

local P = {}

---@param env Env
function P.init(env)
    local rime_config = env.engine.schema.config

    local enabled = rime_config:get_bool("backspace_limiter/enabled")
    if enabled == nil then
        enabled = false
    end

    env.backspace_limiter_config = {
        enabled = enabled,
    }

    env.backspace_limiter_state = {
        bs_deleting_preedit = false,
    }
end

---@param env Env
function P.fini(env)
    env.backspace_limiter_config = nil
    env.backspace_limiter_state = nil
end

---@param key_event KeyEvent
---@param env Env
---@return ProcessResult
function P.func(key_event, env)
    local context = env.engine.context

    local config = env.backspace_limiter_config
    assert(config)
    local state = env.backspace_limiter_state
    assert(state)

    if handle_backspace(key_event, config, state, context) then
        return wanxiang.RIME_PROCESS_RESULTS.kAccepted
    end

    return wanxiang.RIME_PROCESS_RESULTS.kNoop
end

return P
