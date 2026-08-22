---Converts escape sequences in candidate text (\n, \t, \r, \\, \s) to their corresponding literal characters.
---@author amzxyz
---@author Fidel Yin <fidel.yin@hotmail.com>

---Lookup table for escape sequence replacement.
---@type table<string, string>
local ESCAPE_MAP = {
    ["\\n"] = "\n", -- newline
    ["\\t"] = "\t", -- tab
    ["\\r"] = "\r", -- carriage return
    ["\\s"] = " ", -- space
    ["\\\\"] = "\\", -- backslash
}

---Pattern to match any of the defined escape sequences in ESCAPE_MAP.
local ESCAPE_PATTERN = "\\[\\ntrs]"

---Replace recognised escape sequences in `text`.
---@param text string
---@return string? converted Converted text. `nil` if no changes were made.
local function convert_escapes(text)
    if not text:find("\\", 1, true) then
        return nil
    end

    local converted = text:gsub(ESCAPE_PATTERN, ESCAPE_MAP)
    if converted == text then
        return nil
    end

    return converted
end

local F = {}

---@param translation Translation
function F.func(translation, _)
    for cand in translation:iter() do
        local converted = convert_escapes(cand.text)
        if not converted then
            yield(cand)
        else
            local genuine_cand = cand
            genuine_cand.text = converted
            yield(genuine_cand)
        end
    end
end

return F
