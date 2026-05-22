---Converts escape sequences in candidate text (\n, \t, \r, \\, \s) to their
---corresponding literal characters.
---@author amzxyz
---@author Fidel Yin <fidel.yin@hotmail.com>

---Lookup table for escape sequence replacement.
---Each key is a two-character escape sequence; the value is the literal character.
---@type table<string, string>
local ESCAPE_MAP = {
    ["\\n"] = "\n", -- newline
    ["\\t"] = "\t", -- tab
    ["\\r"] = "\r", -- carriage return
    ["\\s"] = " ", -- space
    ["\\\\"] = "\\", -- backslash
}

---Replace recognised escape sequences in `text` using ESCAPE_MAP.
---Short-circuits when the text contains no backslash at all.
---@param text string
---@return string converted
---@return boolean changed
local function convert_escapes(text)
    if not text:find("\\", 1, true) then
        return text, false
    end

    local converted = text:gsub("\\[\\ntrs]", ESCAPE_MAP)
    return converted, converted ~= text
end

local M = {}

---For each candidate, apply escape sequence conversion. When the text contains
---escape sequences, a new Candidate is created with the converted text.
---@param translation Translation
function M.func(translation, _)
    for cand in translation:iter() do
        local converted, changed = convert_escapes(cand.text)
        if not changed then
            yield(cand)
        else
            local new_cand = Candidate(cand.type, cand.start, cand._end, converted, cand.comment)
            new_cand.preedit = cand.preedit
            yield(new_cand)
        end
    end
end

return M
