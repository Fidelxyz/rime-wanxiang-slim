---Converts raw input codes in the preedit area to full pinyin (with or without tones).
---
---Switches:
---  tone_pinyin_code: Show full pinyin with tones (e.g. "nh" → "nǐ hǎo")
---  toneless_pinyin_code: Show full pinyin without tones (e.g. "nh" → "ni hao")
---
---When neither switch is active, preedit is passed through unchanged.
---@author amzxyz
---@author Fidel Yin <fidel.yin@hotmail.com>

---@class PreeditPinyinExpanderConfig
---@field auto_delimiter string
---@field manual_delimiter string
---@field split_code_pattern string

---@diagnostic disable-next-line: duplicate-type
---@class Env
---@field preedit_pinyin_expander_config PreeditPinyinExpanderConfig?

local utils = require("utils.utils")

--- Split preedit into segments by delimiters, preserving delimiters as separate entries.
---@param preedit string
---@param config PreeditPinyinExpanderConfig
---@return string[]
local function split_preedit(preedit, config)
    ---@type string[]
    local parts = {}
    local parts_len = 0
    local current = ""
    for char in preedit:gmatch("[%z\1-\127\194-\244][\128-\191]*") do
        if char == config.auto_delimiter or char == config.manual_delimiter then
            if #current > 0 then
                parts_len = parts_len + 1
                parts[parts_len] = current
                current = ""
            end
            parts_len = parts_len + 1
            parts[parts_len] = char
        else
            current = current .. char
        end
    end
    if #current > 0 then
        parts_len = parts_len + 1
        parts[parts_len] = current
    end
    return parts
end

--- Extract pinyin segments from comment string (before any semicolons).
---@param comment string
---@param config PreeditPinyinExpanderConfig
---@return string[]
local function extract_pinyin_from_comment(comment, config)
    ---@type string[]
    local pinyins = {}
    local pinyins_len = 0
    for segment in comment:gmatch(config.split_code_pattern) do
        local pinyin = segment:match("^[^;]+")
        if pinyin then
            pinyin = pinyin:gsub("[%[%]]", "") -- Strip brackets from English entries
            pinyins_len = pinyins_len + 1
            pinyins[pinyins_len] = pinyin
        end
    end
    return pinyins
end

--- Convert preedit to full pinyin using comment data.
--- Replaces each input segment with the corresponding pinyin from the comment.
--- The last incomplete segment is kept as-is (partial input).
---@param preedit string
---@param comment string
---@param config PreeditPinyinExpanderConfig
---@return string
local function convert_preedit_to_pinyin(preedit, comment, config)
    local parts = split_preedit(preedit, config)
    local pinyins = extract_pinyin_from_comment(comment, config)

    local pinyin_idx = 1
    for i, part in ipairs(parts) do
        if part == config.auto_delimiter or part == config.manual_delimiter then
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

local F = {}

---@param env Env
function F.init(env)
    local config = env.engine.schema.config

    local delimiter = config:get_string("speller/delimiter") or " '"
    local auto_delimiter = delimiter:sub(1, 1)
    local manual_delimiter = delimiter:sub(2, 2)
    local split_code_pattern = "[^" .. utils.escape_for_pattern(delimiter) .. "]+"

    env.preedit_pinyin_expander_config = {
        auto_delimiter = auto_delimiter,
        manual_delimiter = manual_delimiter,
        split_code_pattern = split_code_pattern,
    }
end

---@param env Env
function F.fini(env)
    env.preedit_pinyin_expander_config = nil
end

---@param input Translation
---@param env Env
function F.func(input, env)
    local config = env.preedit_pinyin_expander_config
    assert(config)

    local context = env.engine.context
    local is_tone_pinyin = context:get_option("tone_pinyin_code")
    local is_toneless_pinyin = context:get_option("toneless_pinyin_code")

    if not is_tone_pinyin and not is_toneless_pinyin then
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
        local comment = genuine_cand.comment
        if preedit ~= "" and comment ~= "" then
            preedit = convert_preedit_to_pinyin(preedit, comment, config)
            if is_toneless_pinyin then
                preedit = utils.remove_pinyin_tone(preedit)
            end
            genuine_cand.preedit = preedit
        end

        yield(genuine_cand)
        ::continue::
    end
end

return F
