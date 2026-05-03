---Generates Unicode character candidates by parsing a hexadecimal code entered after a specific trigger prefix.
---@author amzxyz
---@author Fidel Yin <fidel.yin@hotmail.com>

---@param input string
---@param segment Segment
function translator(input, segment, _)
    if not segment:has_tag("unicode") then
        return
    end

    local ucodestr = input:sub(2)
    if #ucodestr <= 1 then
        return
    end

    local code = tonumber(ucodestr, 16)
    if not code then
        return
    end

    -- Out of Unicode range
    if code > 0x10FFFF then
        return
    end

    -- Skip surrogate code points (U+D800 to U+DFFF)
    if code >= 0xD800 and code <= 0xDFFF then
        return
    end

    local text = utf8.char(code)
    yield(Candidate("unicode", segment.start, segment._end, text, ("U%x"):format(code):upper()))

    if code < 0x10000 then
        for i = 0, 15 do
            local new_code = code * 16 + i

            -- Skip surrogate code points (U+D800 to U+DFFF)
            if new_code >= 0xD800 and new_code <= 0xDFFF then
                goto continue
            end

            text = utf8.char(new_code)
            yield(Candidate("unicode", segment.start, segment._end, text, ("U%x~%x"):format(code, i):upper()))

            ::continue::
        end
    end
end

return translator
