---Applies casing formatting to English candidates based on input code pattern.
---
---Casing rules driven by the first two input letters:
--- 1. ALL CAPS when both are uppercase.
--- 2. Title Case when only the first is uppercase.
--- 3. Lowercase otherwise.
---
---@author amzxyz
---@author Fidel Yin <fidel.yin@hotmail.com>

local utils = require("utils.utils")

---@param text string
---@param input_code string
---@return string
local function apply_casing(text, input_code)
    if input_code:find("^%u%u") then
        return text:upper()
    elseif input_code:find("^%u") then
        return (text:gsub("^%a", string.upper))
    end
    return text
end

local F = {}

function F.init(_) end

function F.fini(_) end

---@param input Translation
---@param env Env
function F.func(input, env)
    local code = env.engine.context.input

    for cand in input:iter() do
        local text = cand.text

        if not utils.is_english_phrase(text) then
            yield(cand)
            goto continue
        end

        local new_text = apply_casing(text, code)
        if new_text ~= text then
            local new_cand = Candidate(cand.type, cand.start, cand._end, new_text, cand.comment)
            new_cand.preedit = cand.preedit
            yield(new_cand)
        else
            yield(cand)
        end

        ::continue::
    end
end

return F
