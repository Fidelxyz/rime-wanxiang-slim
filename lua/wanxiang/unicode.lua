---Generates Unicode character candidates by parsing a hexadecimal code entered after a specific trigger prefix.
---@author amzxyz
---@author Fidel Yin <fidel.yin@hotmail.com>

---@class UnicodeConfig
---@field trigger string

---@diagnostic disable-next-line: duplicate-type
---@class Env
---@field unicode_config UnicodeConfig?

local T = {}

---@param env Env
function T.init(env)
    -- Extract the second character of the configured trigger as the trigger key.
    local pattern = env.engine.schema.config:get_string("recognizer/patterns/unicode")
    local trigger = pattern and pattern:sub(2, 2) or ""

    env.unicode_config = {
        trigger = trigger,
    }
end

---@param env Env
function T.fini(env)
    env.unicode_config = nil
end

---@param input string
---@param seg Segment
---@param env Env
function T.func(input, seg, env)
    local config = env.unicode_config
    assert(config)

    if not seg:has_tag("unicode") or config.trigger == "" then
        return
    end
    if input:sub(1, 1) ~= config.trigger then
        return
    end

    local ucodestr = input:match(config.trigger .. "(%x+)")
    if not ucodestr or #ucodestr <= 1 then
        return
    end

    local segment = env.engine.context.composition:back()
    if segment then
        ---@diagnostic disable-next-line: assign-type-mismatch
        segment.tags = segment.tags + Set({ "unicode" })
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

            ::continue::
        end
    end
end

return T
