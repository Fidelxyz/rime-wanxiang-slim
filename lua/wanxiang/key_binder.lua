---Provides context-aware key bindings by evaluating regular expressions against the current input string to determine if a key sequence should be redirected.
---@module "wanxiang.key_binder"
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

---@class Env
---@field key_binder_config KeyBinderConfig?
---@field key_binder_state KeyBinderState?

---解析配置文件中的按键绑定配置
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

    return { match = match, accept = KeyEvent(accept), send_sequence = KeySequence(send_sequence) }
end

local M = {}

---@param env Env
function M.init(env)
    ---@type Binding[]
    local bindings = {}

    local cfg_bindings = env.engine.schema.config:get_list("key_binder/bindings")
    if not cfg_bindings then
        return
    end

    for i = 1, cfg_bindings.size do
        local item = cfg_bindings:get_at(i - 1)
        if not item then
            goto continue
        end

        local value = item:get_map()
        if not value then
            goto continue
        end

        local binding = parse_binding(value)
        if not binding then
            goto continue
        end

        bindings[#bindings + 1] = binding
        ::continue::
    end

    env.key_binder_config = {
        bindings = bindings,
    }

    env.key_binder_state = {
        redirecting = false,
    }
end

---@param key_event KeyEvent
---@param env Env
---@return ProcessResult
function M.func(key_event, env)
    local config = env.key_binder_config
    assert(config)
    local state = env.key_binder_state
    assert(state)

    local input = env.engine.context.input

    if state.redirecting then
        return wanxiang.RIME_PROCESS_RESULTS.kNoop
    end

    if not env.engine.context.composition:back():has_tag("abc") then
        return wanxiang.RIME_PROCESS_RESULTS.kNoop
    end

    for _, binding in ipairs(config.bindings) do
        -- 只有当按键和当前输入的模式都匹配的时候，才起作用
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
