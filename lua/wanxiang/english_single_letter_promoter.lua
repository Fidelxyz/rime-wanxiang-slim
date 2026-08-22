---Ensures single-letter candidates are available and promoted ahead of regular ASCII candidates.
---
---For single-letter input, generates both lowercase and uppercase candidates and inserts them
---before the first regular ASCII candidate produced by the translator.
---
---@author amzxyz
---@author Fidel Yin <fidel.yin@hotmail.com>

local utils = require("utils.utils")

local F = {}

function F.init(_) end

function F.fini(_) end

---@param input Translation
---@param env Env
function F.func(input, env)
    local code = env.engine.context.input
    local code_lower = code:lower()

    local single_char_yielded = false

    local function yield_single_chars()
        local b = code:byte()
        local is_upper = (b >= 65 and b <= 90)
        yield(Candidate("completion", 0, 1, code, ""))
        yield(Candidate("completion", 0, 1, is_upper and code:lower() or code:upper(), ""))
    end

    for cand in input:iter() do
        -- Drop raw candidates.
        if cand.type == "raw" then
            goto continue
        end

        -- Drop candidates that are identical to the input code.
        if cand.text:lower() == code_lower then
            goto continue
        end

        -- User table and phrase candidates should be yielded before single-letter candidates.
        if cand.type == "user_table" or cand.type == "phrase" or not utils.is_english_phrase(cand.text) then
            yield(cand)
            goto continue
        end

        if not single_char_yielded then
            yield_single_chars()
            single_char_yielded = true
        end

        yield(cand)
        ::continue::
    end

    if not single_char_yielded then
        yield_single_chars()
    end
end

---@param env Env
---@return boolean
function F.tags_match(_, env)
    local code = env.engine.context.input
    return #code == 1 and utils.has_ascii_letter(code)
end

return F
