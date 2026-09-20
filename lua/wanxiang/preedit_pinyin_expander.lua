---Converts raw input codes in the preedit area to full pinyin (with or without tones).
---
---Switches:
---  tone_pinyin_code: Show full pinyin with tones
---  toneless_pinyin_code: Show full pinyin without tones
---
---@author amzxyz
---@author Fidel Yin <fidel.yin@hotmail.com>

---@class PreeditPinyinExpanderConfig
---@field split_code_pattern string
---@field delimiter_pattern string

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
    local pos = 1
    local len = #preedit
    while pos <= len do
        local delim_start, delim_end = preedit:find(config.delimiter_pattern, pos)
        -- Add the last segment if no more delimiters are found
        if not delim_start or not delim_end then
            parts_len = parts_len + 1
            parts[parts_len] = preedit:sub(pos)
            break
        end

        -- Add the segment before the delimiter
        if delim_start > pos then
            parts_len = parts_len + 1
            parts[parts_len] = preedit:sub(pos, delim_start - 1)
        end

        -- Add the delimiter itself
        parts_len = parts_len + 1
        parts[parts_len] = preedit:sub(delim_start, delim_end)
        pos = delim_end + 1
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
    local preedits = split_preedit(preedit, config)
    local pinyins = extract_pinyin_from_comment(comment, config)

    local pinyin_idx = 1
    for i, code in ipairs(preedits) do
        if code:match(config.delimiter_pattern) then
            -- Keep delimiters as-is
            goto continue
        end

        local pinyin = pinyins[pinyin_idx]
        if not pinyin then
            goto continue
        end

        -- Last segment with single char: keep raw (partial input)
        if i == #preedits and #code == 1 then
            local ch = code:lower()
            if ch == "z" or ch == "c" or ch == "s" then
                -- Could be zh/ch/sh, keep as-is
                break
            end

            local initial = pinyin:sub(1, 2)
            if initial == "zh" or initial == "ch" or initial == "sh" then
                preedits[i] = initial
            end
            break
        end

        -- Preserve trailing tone digits from the input
        local tone = code:match("[^%a]*$")
        if tone then
            preedits[i] = pinyin .. tone
        else
            preedits[i] = pinyin
        end
        pinyin_idx = pinyin_idx + 1

        ::continue::
    end

    return table.concat(preedits)
end

local F = {}

---@param env Env
function F.init(env)
    local rime_config = env.engine.schema.config
    assert(rime_config)

    local delimiter = rime_config:get_string("speller/delimiter") or " '"
    local auto_delimiter = delimiter:sub(1, 1)
    local split_code_pattern = "[^" .. utils.escape_for_pattern(auto_delimiter) .. "]+"
    local delimiter_pattern = "[" .. utils.escape_for_pattern(delimiter) .. "]"

    env.preedit_pinyin_expander_config = {
        split_code_pattern = split_code_pattern,
        delimiter_pattern = delimiter_pattern,
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
