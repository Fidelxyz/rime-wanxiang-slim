---Provides English dictionary candidates when English input is enabled.
---
---@author Fidel Yin <fidel.yin@hotmail.com>

---@class EnglishTranslatorState
---@field translator TableTranslator

---@diagnostic disable-next-line: duplicate-type
---@class Env
---@field english_translator_state EnglishTranslatorState?

local T = {}

---@param env Env
function T.init(env)
    env.english_translator_state = {
        translator = assert(
            Component.TableTranslator(env.engine, env.engine.schema, "wanxiang_english", "table_translator")
        ),
    }
end

---@param env Env
function T.fini(env)
    local state = env.english_translator_state
    assert(state)
    state.translator:disconnect()
    env.english_translator_state = nil
end

---@param input string
---@param segment Segment
---@param env Env
function T.func(input, segment, env)
    if env.engine.context:get_option("disable_english") then
        return
    end

    local state = env.english_translator_state
    assert(state)

    local translation = state.translator:query(input, segment)
    if not translation then
        return
    end

    for cand in translation:iter() do
        yield(cand)
    end
end

return T
