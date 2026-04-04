---Generates Unicode character candidates by parsing a hexadecimal code entered after a specific trigger prefix.
---@module "wanxiang.unicode"
---@author amzxyz
---@author Fidel Yin <fidel.yin@hotmail.com>

--- @param input string
--- @param seg Segment
--- @param env Env
local function unicode(input, seg, env)
    -- Extract the second character of the configured trigger as the trigger key.
    env.unicode_trigger = env.unicode_trigger
        or env.engine.schema.config:get_string("recognizer/patterns/unicode"):sub(2, 2)

    if (not seg:has_tag("unicode")) or env.unicode_trigger == "" or input:sub(1, 1) ~= env.unicode_trigger then
        return
    end

    local ucodestr = input:match(env.unicode_trigger .. "(%x+)")
    if not ucodestr or #ucodestr <= 1 then
        return
    end

    local segment = env.engine.context.composition:back()
    if segment then
        segment.tags = segment.tags + Set({ "unicode" })
    end

    local code = tonumber(ucodestr, 16)

    -- Out of Unicode range
    if code > 0x10FFFF then
        return
    end

    -- Skip surrogate code points (U+D800 to U+DFFF)
    if code >= 0xD800 and code <= 0xDFFF then
        return
    end

    local text = utf8.char(code)
    yield(Candidate("unicode", seg.start, seg._end, text, ("U%x"):format(code)))

    if code < 0x10000 then
        for i = 0, 15 do
            local new_code = code * 16 + i

            -- Skip surrogate code points (U+D800 to U+DFFF)
            if new_code >= 0xD800 and new_code <= 0xDFFF then
                goto continue
            end

            text = utf8.char(new_code)
            yield(Candidate("unicode", seg.start, seg._end, text, ("U%x~%x"):format(code, i)))
        end
        ::continue::
    end
end

return unicode
