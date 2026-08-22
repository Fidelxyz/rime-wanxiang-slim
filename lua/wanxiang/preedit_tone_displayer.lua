---Maps tone digits (7890) in candidate preedit to superscript characters (¹²³⁴).
---@author Fidel Yin <fidel.yin@hotmail.com>

---@type table<string, string>
local TONE_DISPLAY = {
    ["7"] = "¹",
    ["8"] = "²",
    ["9"] = "³",
    ["0"] = "⁴",
}

---Replace tone digits with superscript in a preedit string.
---Only digits that follow non-digit, non-space characters are replaced.
---@param preedit string
---@return string
local function map_tone_digits(preedit)
    local mapped = preedit:gsub("([^%d%s]+)(%d+)", function(body, digits)
        return body .. (digits:gsub("%d", TONE_DISPLAY))
    end)
    return mapped
end

local F = {}

---@param input Translation
---@param env Env
function F.func(input, env)
    local input_str = env.engine.context.input

    -- Skip if the raw input contains consecutive digits (likely codes, not tone marks).
    if input_str:match("%d%d") then
        for cand in input:iter() do
            yield(cand)
        end
        return
    end

    for cand in input:iter() do
        local genuine_cand = cand:get_genuine()

        -- Skip pure-English candidates.
        if genuine_cand.text:match("^[%a%p%s]+$") then
            yield(genuine_cand)
        else
            genuine_cand.preedit = map_tone_digits(genuine_cand.preedit)
            yield(genuine_cand)
        end
    end
end

return F
