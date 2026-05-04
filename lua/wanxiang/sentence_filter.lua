---Drops sentence-type derivation candidates when the first candidate is a
---long English word from the table/user_table/fixed source. This keeps the
---candidate list clean during mixed Chinese-English input.
---@author amzxyz
---@author Fidel Yin <fidel.yin@hotmail.com>

---Check whether a candidate originates from the table, user_table, or fixed
---translators.
---@param cand Candidate
---@return boolean
local function is_table_type(cand)
    local t = cand.type
    return t == "table" or t == "user_table" or t == "fixed"
end

---Byte-level scan for ASCII letters (A-Z, a-z).
---Returns true as soon as any letter byte is found.
---@param s string
---@return boolean
local function has_english_token_fast(s)
    local len = #s
    for i = 1, len do
        local b = s:byte(i)
        if b < 0x80 then
            -- A-Z (0x41-0x5A) or a-z (0x61-0x7A)
            if (b >= 0x41 and b <= 0x5A) or (b >= 0x61 and b <= 0x7A) then
                return true
            end
        end
    end
    return false
end

local M = {}

---When the first candidate is a table-type entry with 4+ characters containing
---English letters, drop all subsequent sentence-type candidates. This prevents
---irrelevant sentence derivations from cluttering the candidate list when the
---user is clearly typing an English word.
---@param translation Translation
function M.func(translation, _)
    local drop_sentence = false

    for cand in translation:iter() do
        if not drop_sentence then
            -- First candidate: decide whether to activate sentence dropping.
            local text = cand.text
            if is_table_type(cand) and #text >= 4 and has_english_token_fast(text) then
                drop_sentence = true
            end
            yield(cand)
        else
            -- Subsequent candidates: skip sentence-type when flag is set.
            if cand.type == "sentence" then
                -- Drop: sentence derivation suppressed by English first candidate
            else
                yield(cand)
            end
        end
    end
end

return M
