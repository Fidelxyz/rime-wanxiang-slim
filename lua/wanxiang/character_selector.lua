---Selects and commits only the first or last character of the current candidate phrase based on configured shortcut
---keys.
---@author amzxyz
---@author Fidel Yin <fidel.yin@hotmail.com>

---@class CharacterSelectorConfig
---@field select_first_key string?
---@field select_last_key string?

---@diagnostic disable-next-line: duplicate-type
---@class Env
---@field character_selector_config CharacterSelectorConfig?

local wanxiang = require("wanxiang.wanxiang")

---@param key KeyEvent
---@param config CharacterSelectorConfig
---@param env Env
---@param ctx Context
---@return boolean
local function apply_character_selector(key, config, env, ctx)
    if not config.select_first_key and not config.select_last_key then
        return false
    end

    if not ctx:is_composing() and not ctx:has_menu() then
        return false
    end

    local repr = key:repr()
    local ch = (key.keycode >= 0x20 and key.keycode <= 0x7E) and string.char(key.keycode) or nil

    local select_first = config.select_first_key and (repr == config.select_first_key or ch == config.select_first_key)
    local select_last = config.select_last_key and (repr == config.select_last_key or ch == config.select_last_key)
    if not select_first and not select_last then
        return false
    end

    local text = ctx.input
    local cand = ctx:get_selected_candidate()
    if cand then
        text = cand.text
    end

    if text == "" then
        return false
    end

    -- 执行上屏
    if select_first then
        -- 上屏第一个字 (sub: 1 到 第二个字偏移量-1)
        env.engine:commit_text(text:sub(1, utf8.offset(text, 2) - 1))
        ctx:clear()
        return true
    elseif select_last then
        -- 上屏最后一个字 (sub: 最后一个字偏移量)
        env.engine:commit_text(text:sub(utf8.offset(text, -1)))
        ctx:clear()
        return true
    end
    return false
end

local P = {}

---@param env Env
function P.init(env)
    local rime_config = env.engine.schema.config

    local select_first_key = rime_config:get_string("character_selector/select_first_key")
    if select_first_key == "" then
        select_first_key = nil
    end

    local select_last_key = rime_config:get_string("character_selector/select_last_key")
    if select_last_key == "" then
        select_last_key = nil
    end

    env.character_selector_config = {
        select_first_key = select_first_key,
        select_last_key = select_last_key,
    }
end

---@param env Env
function P.fini(env)
    env.character_selector_config = nil
end

---@param key KeyEvent
---@param env Env
---@return integer
function P.func(key, env)
    local context = env.engine.context

    local config = env.character_selector_config
    assert(config)

    if apply_character_selector(key, config, env, context) then
        return wanxiang.RIME_PROCESS_RESULTS.kAccepted
    end

    return wanxiang.RIME_PROCESS_RESULTS.kNoop
end

return P
