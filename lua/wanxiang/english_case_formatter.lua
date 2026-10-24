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

---@param text string The text to format.
---@param input_code string The input code, starting with an uppercase letter.
---@return string
local function apply_casing(text, input_code)
    -- If the input code starts with two uppercase letters, convert the text to ALL CAPS.
    if input_code:find("^%u%u") then
        return text:upper()
    end
    -- If the input code starts with an uppercase letter followed by a lowercase letter, convert the text to Title Case.
    return (text:gsub("^%a", string.upper))
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

        -- The code is expected to start with an uppercase letter, gauranteed by F.tags_match().
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

---@param env Env
---@return boolean
function F.tags_match(_, env)
    -- Only apply to English phrases that start with an uppercase letter.
    return env.engine.context.input:find("^%u") ~= nil
end

return F
