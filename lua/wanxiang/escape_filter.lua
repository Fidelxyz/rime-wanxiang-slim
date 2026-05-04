---Converts escape sequences in candidate text (\n, \t, \r, \\, \s) to their
---corresponding literal characters.
---@author amzxyz
---@author Fidel Yin <fidel.yin@hotmail.com>

---Lookup table for escape sequence replacement.
---Each key is a two-character escape sequence; the value is the literal character.
---@type table<string, string>
local escape_map = {
    ["\\n"] = "\n", -- newline
    ["\\t"] = "\t", -- tab
    ["\\r"] = "\r", -- carriage return
    ["\\s"] = " ", -- space
    ["\\\\"] = "\\", -- backslash
}

---Replace recognised escape sequences in text using the escape_map table.
---Returns the (possibly converted) text and whether any replacement occurred.
---Short-circuits when the text contains no backslash at all.
---@param text string
---@return string result
---@return boolean changed
local function apply_escape_fast(text)
    if not text:find("\\", 1, true) then
        return text, false
    end

    local escaped = text:gsub("\\[\\ntrs]", escape_map)
    return escaped, escaped ~= text
end

local M = {}

---For each candidate, apply escape sequence conversion. When the text contains
---escape sequences, a new Candidate is created with the converted text.
---@param translation Translation
function M.func(translation, _)
    for cand in translation:iter() do
        local text = cand.text
        if text == "" then
            yield(cand)
            goto continue
        end

        local converted, changed = apply_escape_fast(text)
        if not changed then
            yield(cand)
            goto continue
        end

        local new_cand = Candidate(cand.type, cand.start, cand._end, converted, cand.comment)
        new_cand.preedit = cand.preedit
        yield(new_cand)

        ::continue::
    end
end

return M
