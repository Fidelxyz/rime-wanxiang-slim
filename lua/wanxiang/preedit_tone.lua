---Preedit tone display: maps tone digits to superscript and optionally converts
---raw input codes to full pinyin (with or without tones) in the preedit area.
---
---Switches:
---  tone_pinyin_code: Show full pinyin with tones in preedit (e.g. "nh" → "nǐ hǎo")
---  toneless_pinyin_code: Show full pinyin without tones in preedit (e.g. "nh" → "ni hao")
---
---When neither switch is active, only tone digit superscript mapping is applied.
---@author amzxyz
---@author Fidel Yin <fidel.yin@hotmail.com>

---@type table<string, string>
local TONE_SUPERSCRIPT = {
    ["7"] = "¹",
    ["8"] = "²",
    ["9"] = "³",
    ["0"] = "⁴",
}

---@type table<string, string>
local TONE_STRIP_MAP = {
    ["ā"] = "a",
    ["á"] = "a",
    ["ǎ"] = "a",
    ["à"] = "a",
    ["ē"] = "e",
    ["é"] = "e",
    ["ě"] = "e",
    ["è"] = "e",
    ["ī"] = "i",
    ["í"] = "i",
    ["ǐ"] = "i",
    ["ì"] = "i",
    ["ō"] = "o",
    ["ó"] = "o",
    ["ǒ"] = "o",
    ["ò"] = "o",
    ["ū"] = "u",
    ["ú"] = "u",
    ["ǔ"] = "u",
    ["ù"] = "u",
    ["ǖ"] = "ü",
    ["ǘ"] = "ü",
    ["ǚ"] = "ü",
    ["ǜ"] = "ü",
    ["ń"] = "n",
    ["ň"] = "n",
    ["ǹ"] = "n",
}

--- Replace tone digits with superscript in a preedit string.
--- Only replaces digits that follow non-digit non-space characters.
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

--- Remove pinyin tone marks from a string.
---@param s string
---@return string
local function remove_pinyin_tone(s)
    ---@type string[]
    local result = {}
    for uchar in s:gmatch("[%z\1-\127\194-\244][\128-\191]*") do
        result[#result + 1] = TONE_STRIP_MAP[uchar] or uchar
    end
    return table.concat(result)
end

--- Split preedit into segments by delimiters, preserving delimiters as separate entries.
---@param preedit string
---@param auto_delim string
---@param manual_delim string
---@return string[]
local function split_preedit(preedit, auto_delim, manual_delim)
    ---@type string[]
    local parts = {}
    local current = ""
    for char in preedit:gmatch("[%z\1-\127\194-\244][\128-\191]*") do
        if char == auto_delim or char == manual_delim then
            if #current > 0 then
                parts[#parts + 1] = current
                current = ""
            end
            parts[#parts + 1] = char
        else
            current = current .. char
        end
    end
    if #current > 0 then
        parts[#parts + 1] = current
    end
    return parts
end

--- Extract pinyin segments from comment string (before any semicolons).
---@param comment string
---@param auto_delim string
---@param manual_delim string
---@return string[]
local function extract_pinyin_from_comment(comment, auto_delim, manual_delim)
    ---@type string[]
    local pinyins = {}
    local pattern = "[^" .. auto_delim:gsub("(%W)", "%%%1") .. manual_delim:gsub("(%W)", "%%%1") .. "]+"
    for segment in comment:gmatch(pattern) do
        local pinyin = segment:match("^[^;]+")
        if pinyin then
            pinyin = pinyin:gsub("[%[%]]", "") -- Strip brackets from English entries
            pinyins[#pinyins + 1] = pinyin
        end
    end
    return pinyins
end

--- Convert preedit to full pinyin using comment data.
--- Replaces each input segment with the corresponding pinyin from the comment.
--- The last incomplete segment is kept as-is (partial input).
---@param preedit string
---@param comment string
---@param auto_delim string
---@param manual_delim string
---@return string
local function convert_preedit_to_pinyin(preedit, comment, auto_delim, manual_delim)
    local parts = split_preedit(preedit, auto_delim, manual_delim)
    local pinyins = extract_pinyin_from_comment(comment, auto_delim, manual_delim)

    local pinyin_idx = 1
    for i, part in ipairs(parts) do
        if part == auto_delim or part == manual_delim then
            -- Keep delimiters as-is
        else
            local py = pinyins[pinyin_idx]
            if py then
                -- Last segment with single char: keep raw (partial input)
                if i == #parts and #part == 1 then
                    local prefix = py:sub(1, 2)
                    local ch = part:sub(1, 1):lower()
                    if ch == "s" or ch == "c" or ch == "z" then
                        -- Could be sh/ch/zh, keep as-is
                    elseif prefix == "zh" or prefix == "ch" or prefix == "sh" then
                        parts[i] = prefix
                    end
                else
                    -- Preserve trailing tone digits from the input
                    local tone = part:match("[^%a]*$")
                    parts[i] = py .. (tone or "")
                    pinyin_idx = pinyin_idx + 1
                end
            end
        end
    end

    return table.concat(parts)
end

---@class PreeditToneConfig
---@field auto_delim string
---@field manual_delim string

---@diagnostic disable-next-line: duplicate-type
---@class Env
---@field preedit_tone_config PreeditToneConfig?

local M = {}

---@param env Env
function M.init(env)
    local config = env.engine.schema.config
    local delimiter = config:get_string("speller/delimiter") or " '"
    local auto_delim = delimiter:sub(1, 1)
    local manual_delim = delimiter:sub(2, 2)

    env.preedit_tone_config = {
        auto_delim = auto_delim,
        manual_delim = manual_delim,
    }
end

---@param env Env
function M.fini(env)
    env.preedit_tone_config = nil
end

---@param input Translation
---@param env Env
function M.func(input, env)
    local config = env.preedit_tone_config
    assert(config)

    local context = env.engine.context
    local input_str = context.input or ""

    -- Skip if input contains consecutive digits
    if input_str:match("%d%d") then
        for cand in input:iter() do
            yield(cand)
        end
        return
    end

    local is_tone_display = context:get_option("tone_pinyin_code")
    local is_full_pinyin = context:get_option("toneless_pinyin_code")
    local do_pinyin_conversion = is_tone_display or is_full_pinyin

    for cand in input:iter() do
        local genuine_cand = cand:get_genuine()

        -- Skip if candidate is pure English
        if genuine_cand.text:match("^[%a%p%s]+$") then
            yield(genuine_cand)
            goto continue
        end

        local preedit = genuine_cand.preedit
        if preedit ~= "" then
            if do_pinyin_conversion then
                local comment = genuine_cand.comment
                if comment ~= "" then
                    preedit = convert_preedit_to_pinyin(preedit, comment, config.auto_delim, config.manual_delim)
                    if is_full_pinyin then
                        preedit = remove_pinyin_tone(preedit)
                    end
                end
            end

            -- Always apply tone digit superscript mapping
            genuine_cand.preedit = map_tone_digits(preedit)
        end

        yield(genuine_cand)
        ::continue::
    end
end

return M
