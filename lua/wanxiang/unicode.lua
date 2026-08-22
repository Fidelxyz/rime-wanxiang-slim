---Generates Unicode character candidates by parsing a hexadecimal code entered after a specific trigger prefix.
---@author Fidel Yin <fidel.yin@hotmail.com>

---@param code integer
---@return boolean
local function is_valid_codepoint(code)
    return code <= 0x10FFFF and (code < 0xD800 or code > 0xDFFF)
end

---@param input string
---@param segment Segment
local function translator(input, segment, _)
    if not segment:has_tag("unicode") then
        return
    end

    -- Strip the leading "U" trigger.
    local hex = input:sub(2)
    if #hex <= 1 then
        return
    end

    local code = tonumber(hex, 16)
    if not code or not is_valid_codepoint(code) then
        return
    end

    yield(Candidate("unicode", segment.start, segment._end, utf8.char(code), ("U%X"):format(code)))

    -- For BMP code points, also yield "extended" candidates by appending one more hex nibble.
    if code <= 0xFFFF then
        for i = 0, 15 do
            local extended_code = code * 16 + i
            if is_valid_codepoint(extended_code) then
                yield(
                    Candidate(
                        "unicode",
                        segment.start,
                        segment._end,
                        utf8.char(extended_code),
                        ("U%X~%X"):format(code, i)
                    )
                )
            end
        end
    end
end

return translator
