---Appends candidate type markers to candidate comments. Symbols are defined per candidate type and are appended once
---to the genuine candidate's comment.
---@author amzxyz
---@author Fidel Yin <fidel.yin@hotmail.com>

---@class CandidateTypeMarkerConfig
---@field types table<string, string>

---@diagnostic disable-next-line: duplicate-type
---@class Env
---@field candidate_type_marker_config CandidateTypeMarkerConfig?

---Append the type symbol for a single candidate's type to its genuine comment.
---Skips when the symbol is empty, the comment is "~", or the symbol is already
---present at the end of the comment.
---@param cand Candidate
---@param config CandidateTypeMarkerConfig
---@return Candidate
local function append_type_symbol(cand, config)
    local symbol = config.types[cand.type]
    if not symbol or symbol == "" then
        return cand
    end

    local genuine = cand:get_genuine()
    genuine.comment = genuine.comment .. symbol

    return cand
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

---For each candidate, append the configured type symbol to its comment, then
---yield the result.
---@param translation Translation
---@param env Env
function M.func(translation, env)
    local config = env.candidate_type_marker_config
    assert(config)

    for cand in translation:iter() do
        yield(append_type_symbol(cand, config))
    end
end

return M
