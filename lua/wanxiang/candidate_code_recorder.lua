---Utility for recording codes from comments of candidates to be retrieved later.
---The filter must be placed before comments are cleared.
---Must be enabled at initialization to take effect.
---@author Fidel Yin <fidel.yin@hotmail.com>

---@type boolean
local enabled = false
---@type table<string, string> Codes of candidate texts, keyed by candidate text.
local codes = {}

local M = {}

---Enable the recorder.
function M.enable()
    enabled = true
end

---Query the recorded code for a candidate text.
---@param text string
---@return string?
function M.get(text)
    return codes[text]
end

---@class CandidateCodeRecorderState
---@field commit_notifier Connection
---@field delete_notifier Connection

---@diagnostic disable-next-line: duplicate-type
---@class Env
---@field candidate_code_recorder_state CandidateCodeRecorderState?

local F = {}

---@param env Env
function F.init(env)
    local commit_notifier = env.engine.context.commit_notifier:connect(function(_)
        -- Clear codes on each input change before codes for the new candidates are recorded.
        codes = {}
    end)
    local delete_notifier = env.engine.context.delete_notifier:connect(function(_)
        -- Clear codes when input is deleted, which may cause stale codes to be shown for new candidates.
        codes = {}
    end)

    env.candidate_code_recorder_state = {
        commit_notifier = commit_notifier,
        delete_notifier = delete_notifier,
    }
end

---@param env Env
function F.fini(env)
    if env.candidate_code_recorder_state then
        env.candidate_code_recorder_state.commit_notifier:disconnect()
        env.candidate_code_recorder_state.delete_notifier:disconnect()
    end
    env.candidate_code_recorder_state = nil
end

---@param input Translation
function F.func(input, _)
    for cand in input:iter() do
        local genuine_cand = cand:get_genuine()

        local text = cand.text
        local comment = genuine_cand.comment

        if text ~= "" and comment ~= "" then
            codes[text] = comment
        end

        yield(cand)
    end
end

---@return boolean
function F.tags_match(_, _)
    return enabled
end

M.F = F

return M
