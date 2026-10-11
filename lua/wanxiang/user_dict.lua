---Retrieve user-created phrases and format candidates in word-creation mode.
---
---@author Fidel Yin <fidel.yin@hotmail.com>

---@class UserDictTranslatorState
---@field translator ScriptTranslator

---@class UserDictAppenderConfig
---@field tips string?

---@diagnostic disable-next-line: duplicate-type
---@class Env
---@field user_dict_translator_state UserDictTranslatorState?
---@field user_dict_appender_config UserDictAppenderConfig?

local T = {}

---@param env Env
function T.init(env)
    env.user_dict_translator_state = {
        translator = assert(
            Component.ScriptTranslator(env.engine, env.engine.schema, "user_dict", "script_translator")
        ),
    }
end

---@param env Env
function T.fini(env)
    local state = env.user_dict_translator_state
    assert(state)
    state.translator:disconnect()
    env.user_dict_translator_state = nil
end

---@param input string
---@param segment Segment
---@param env Env
function T.func(input, segment, env)
    local state = env.user_dict_translator_state
    assert(state)

    local translator = state.translator

    local user_dict = translator.user_dict
    if not user_dict or not user_dict.loaded then
        return
    end

    -- Skip if the user dictionary contains no entries.
    -- Flush pending learning before probing, as native Query does before matching.
    translator:finish_session()
    if user_dict:lookup_words("", true, 1).exhausted then
        return
    end

    local translation = translator:query(input, segment)
    if not translation then
        return
    end

    for cand in translation:iter() do
        if cand.type == "user_phrase" then
            yield(cand)
        end
    end
end

local F = {}

---@param env Env
function F.init(env)
    local rime_config = env.engine.schema.config
    assert(rime_config)

    local tips = rime_config:get_string("user_dict_appender/tips")
    if tips == "" then
        tips = nil
    end

    env.user_dict_appender_config = {
        tips = tips,
    }
end

---@param env Env
function F.fini(env)
    env.user_dict_appender_config = nil
end

---@param translation Translation
---@param env Env
function F.func(translation, env)
    local config = env.user_dict_appender_config
    assert(config)

    local context = env.engine.context
    if config.tips then
        local segment = context.composition:back()
        if segment then
            segment.prompt = config.tips
        end
    end

    for cand in translation:iter() do
        if cand.type ~= "sentence" then
            yield(cand)
        end
    end
end

---@param segment Segment
---@return boolean
function F.tags_match(segment, _)
    return segment:has_tag("user_dict_appender")
end

return { T = T, F = F }
