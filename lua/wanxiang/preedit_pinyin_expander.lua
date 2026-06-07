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
---@field auto_delim string
---@field manual_delim string

---@diagnostic disable-next-line: duplicate-type
---@class Env
---@field preedit_pinyin_expander_config PreeditPinyinExpanderConfig?

local wanxiang = require("wanxiang.wanxiang")

--- Split preedit into segments by delimiters, preserving delimiters as separate entries.
---@param preedit string
---@param auto_delim string
---@param manual_delim string
---@return string[]
local function split_preedit(preedit, auto_delim, manual_delim)
    ---@type string[]
    local parts = {}
    local parts_len = 0
    local current = ""
    for char in preedit:gmatch("[%z\1-\127\194-\244][\128-\191]*") do
        if char == auto_delim or char == manual_delim then
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
---@param auto_delim string
---@param manual_delim string
---@return string[]
local function extract_pinyin_from_comment(comment, auto_delim, manual_delim)
    ---@type string[]
    local pinyins = {}
    local pinyins_len = 0
    local pattern = "[^" .. auto_delim:gsub("(%W)", "%%%1") .. manual_delim:gsub("(%W)", "%%%1") .. "]+"
    for segment in comment:gmatch(pattern) do
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

local F = {}

---@param env Env
function F.init(env)
    local config = env.engine.schema.config
    local delimiter = config:get_string("speller/delimiter") or " '"
    local auto_delim = delimiter:sub(1, 1)
    local manual_delim = delimiter:sub(2, 2)

    env.preedit_pinyin_expander_config = {
        auto_delim = auto_delim,
        manual_delim = manual_delim,
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
            preedit = convert_preedit_to_pinyin(preedit, comment, config.auto_delim, config.manual_delim)
            if is_toneless_pinyin then
                preedit = wanxiang.remove_pinyin_tone(preedit)
            end
            genuine_cand.preedit = preedit
        end

        yield(genuine_cand)
        ::continue::
    end
end

return F
