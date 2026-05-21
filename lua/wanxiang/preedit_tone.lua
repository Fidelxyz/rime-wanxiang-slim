---Maps tone digits (7890) in candidate preedit to superscript characters (¹²³⁴).
---@author amzxyz
---@author Fidel Yin <fidel.yin@hotmail.com>

---@type table<string, string>
local TONE_SUPERSCRIPT = {
    ["7"] = "¹",
    ["8"] = "²",
    ["9"] = "³",
    ["0"] = "⁴",
}

--- Replace tone digits with superscript in a preedit string.
--- Only replaces digits that follow alphabetic characters (pinyin syllables).
---@param preedit string
---@return string
local function map_tone_digits(preedit)
    return (
        preedit:gsub("([^%d%s]+)(%d+)", function(body, digits)
            local mapped = digits:gsub("%d", function(d)
                return TONE_SUPERSCRIPT[d] or d
            end)
            return body .. mapped
        end)
    )
end

local M = {}

---@param input Translation
---@param env Env
function M.func(input, env)
    local context = env.engine.context
    local input_str = context.input or ""

    -- Skip if input contains consecutive digits
    if input_str:match("%d%d") then
        for cand in input:iter() do
            yield(cand)
        end
        return
    end

    for cand in input:iter() do
        local genuine_cand = cand:get_genuine()

        -- Skip if candidate is pure English
        if genuine_cand.text:match("^[%a%p%s]+$") then
            yield(genuine_cand)
            goto continue
        end

        local preedit = genuine_cand.preedit
        if preedit ~= "" then
            genuine_cand.preedit = map_tone_digits(preedit)
        end

        yield(genuine_cand)
        ::continue::
    end
end

return M
