---Provides context-aware key bindings by evaluating regular expressions
---against the current input string to determine if a key sequence should be
---redirected.
---@author amzxyz
---@author Fidel Yin <fidel.yin@hotmail.com>

local wanxiang = require("wanxiang.wanxiang")

---@class Binding
---@field match string
---@field accept KeyEvent
---@field send_sequence KeySequence

---@class KeyBinderConfig
---@field bindings Binding[]

---@class KeyBinderState
---@field redirecting boolean

---@diagnostic disable-next-line: duplicate-type
---@class Env
---@field key_binder_config KeyBinderConfig?
---@field key_binder_state KeyBinderState?

---Parse a single key-binding entry from the schema config.
---@param value ConfigMap
---@return Binding?
local function parse_binding(value)
    local match_val = value:get_value("match")
    local match = match_val and match_val:get_string()
    if not match then
        return nil
    end

    local accept_val = value:get_value("accept")
    local accept = accept_val and accept_val:get_string()
    if not accept then
        return nil
    end

    local send_sequence_val = value:get_value("send_sequence")
    if not send_sequence_val then
        return nil
    end
    local send_sequence = send_sequence_val:get_string()

    return {
        match = match,
        accept = KeyEvent(accept),
        send_sequence = KeySequence(send_sequence),
    }
end

local M = {}

---@param env Env
function M.init(env)
    ---@type Binding[]
    local bindings = {}
    local bindings_len = 0

    local cfg_bindings = env.engine.schema.config:get_list("key_binder/bindings")
    if cfg_bindings then
        for i = 0, cfg_bindings.size - 1 do
            local item = cfg_bindings:get_at(i)
            local value = item and item:get_map()
            if value then
                local binding = parse_binding(value)
                if binding then
                    bindings_len = bindings_len + 1
                    bindings[bindings_len] = binding
                end
            end
        end
    end

    env.key_binder_config = {
        bindings = bindings,
    }

    env.key_binder_state = {
        redirecting = false,
    }
end

---@param env Env
function M.fini(env)
    env.key_binder_config = nil
    env.key_binder_state = nil
end

---@param key_event KeyEvent
---@param env Env
---@return ProcessResult
function M.func(key_event, env)
    local config = env.key_binder_config
    assert(config)
    local state = env.key_binder_state
    assert(state)

    -- Avoid infinite recursion when we are mid-replay.
    if state.redirecting then
        return wanxiang.RIME_PROCESS_RESULTS.kNoop
    end

    local context = env.engine.context
    local segment = context.composition:back()
    if not segment or not segment:has_tag("abc") then
        return wanxiang.RIME_PROCESS_RESULTS.kNoop
    end

    local input = context.input
    for _, binding in ipairs(config.bindings) do
        -- A binding fires only when both the key and the input pattern match.
        if key_event:eq(binding.accept) and rime_api.regex_match(input, binding.match) then
            state.redirecting = true
            for _, event in ipairs(binding.send_sequence:toKeyEvent()) do
                env.engine:process_key(event)
            end
            state.redirecting = false
            return wanxiang.RIME_PROCESS_RESULTS.kAccepted
        end
    end
    return wanxiang.RIME_PROCESS_RESULTS.kNoop
end

return M
