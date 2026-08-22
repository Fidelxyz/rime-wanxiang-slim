---Appends candidate type markers to candidate comments. Symbols are defined
---per candidate type and are appended once to the genuine candidate's comment.
---@author amzxyz
---@author Fidel Yin <fidel.yin@hotmail.com>

---@class CandidateTypeMarkerConfig
---@field types table<string, string>

---@diagnostic disable-next-line: duplicate-type
---@class Env
---@field candidate_type_marker_config CandidateTypeMarkerConfig?

---Append the configured type symbol for `cand` to its genuine comment.
---No-op when no symbol is configured for the candidate's type.
---@param cand Candidate
---@param config CandidateTypeMarkerConfig
local function append_type_symbol(cand, config)
    local symbol = config.types[cand.type]
    if not symbol then
        return
    end

    local genuine = cand:get_genuine()
    genuine.comment = genuine.comment .. symbol
end

local M = {}

---@param env Env
function M.init(env)
    local rime_config = env.engine.schema.config

    ---@type table<string, string>
    local types = {}
    local map = rime_config:get_map("candidate_type_marker/types")
    if map then
        for _, key in ipairs(map:keys()) do
            local val = map:get_value(key)
            local val_str = val and val:get_string()
            if val_str and val_str ~= "" then
                types[key] = val_str
            end
        end
    end

    env.candidate_type_marker_config = {
        types = types,
    }
end

---@param env Env
function M.fini(env)
    env.candidate_type_marker_config = nil
end

---@param translation Translation
---@param env Env
function M.func(translation, env)
    local config = env.candidate_type_marker_config
    assert(config)

    for cand in translation:iter() do
        append_type_symbol(cand, config)
        yield(cand)
    end
end

return M
