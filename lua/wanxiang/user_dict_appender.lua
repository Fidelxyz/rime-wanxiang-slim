---Display tips and drop sentence candidates in word-creation mode.
---
---@author Fidel Yin <fidel.yin@hotmail.com>

---@class UserDictAppenderConfig
---@field tips string?

---@diagnostic disable-next-line: duplicate-type
---@class Env
---@field user_dict_appender_config UserDictAppenderConfig?

local F = {}

---@param env Env
function F.init(env)
    local rime_config = env.engine.schema.config

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

    -- Attach the word-creation tip.
    local context = env.engine.context
    if config.tips then
        local segment = context.composition:back()
        if segment then
            segment.prompt = config.tips
        end
    end

    for cand in translation:iter() do
        -- Drop sentence candidates.
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

return F
