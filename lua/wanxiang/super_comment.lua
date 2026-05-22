---Enhances candidate display by dynamically generating and appending corrected
---Pinyin tones and other annotations to candidate comments.
---@author amzxyz
---@author Fidel Yin <fidel.yin@hotmail.com>

---@class SuperCommentConfig
---@field auto_delimiter string
---@field min_candidate_length integer

---@class SuperCommentCorrectorConfig
---@field enabled boolean
---@field format string

---@diagnostic disable-next-line: duplicate-type
---@class Env
---@field super_comment_config SuperCommentConfig?
---@field super_comment_corrector_config SuperCommentCorrectorConfig?

local wanxiang = require("wanxiang.wanxiang")

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
    ["ň"] = "n",
    ["ū"] = "u",
    ["ú"] = "u",
    ["ǔ"] = "u",
    ["ù"] = "u",
    ["ǹ"] = "n",
    ["ǖ"] = "ü",
    ["ǘ"] = "ü",
    ["ǚ"] = "ü",
    ["ǜ"] = "ü",
    ["ń"] = "n",
}

---Strip tone marks from a pinyin string.
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

---@param format string
---@return boolean
local function is_format_valid(format)
    return (pcall(string.format, format, "test"))
end

-- Mispronunciation/typo hint module

local corrector = {
    ---@type table<string, {text: string, comment: string}>?
    corrections_cache = nil,
}

---@param cand Candidate
---@param config SuperCommentCorrectorConfig
---@return string?
function corrector.get_comment(cand, config)
    if not corrector.corrections_cache then
        return nil
    end

    local correction = corrector.corrections_cache[cand.comment]
    if not correction or cand.text ~= correction.text then
        return nil
    end

    return config.format:format(correction.comment)
end

---@param env Env
function corrector.init(env)
    assert(env.super_comment_config)

    local rime_config = env.engine.schema.config

    local enabled = rime_config:get_bool("super_comment/correction_enabled")
    if enabled == nil then
        enabled = true
    end

    local format = rime_config:get_string("super_comment/correction_format") or "〔%s〕"
    if not is_format_valid(format) then
        log.warning(("Invalid config value super_comment/correction_format: %s"):format(format))
        format = "〔%s〕"
    end

    env.super_comment_corrector_config = {
        enabled = enabled,
        format = format,
    }

    -- Lazy-load the corrections dictionary; cached across schema reloads.
    if not corrector.corrections_cache then
        local file = wanxiang.load_file_with_fallback("dicts/cuoyin.dict.yaml")
        if file then
            corrector.corrections_cache = {}

            local auto_delimiter = env.super_comment_config.auto_delimiter
            for line in file:lines() do
                if not line:match("^#") then
                    local text, code, _, comment = line:match("^(.-)\t(.-)\t(.-)\t(.-)$")
                    if text and code then
                        text = text:match("^%s*(.-)%s*$")
                        code = code:match("^%s*(.-)%s*$")
                        comment = comment and comment:match("^%s*(.-)%s*$") or ""

                        comment = comment:gsub("%s+", auto_delimiter)
                        code = code:gsub("%s+", auto_delimiter)

                        corrector.corrections_cache[code] = { text = text, comment = comment }
                    end
                end
            end

            file:close()
        end
    end
end

---@param env Env
function corrector.fini(env)
    env.super_comment_corrector_config = nil
end

-- Charset annotation for component-composed characters

---Return a short Unicode block label (in Chinese) for the first character of `text`,
---or nil when the character does not belong to any tracked block.
---@param text string
---@return string?
local function get_charset_label(text)
    if text == "" then
        return nil
    end

    local code = utf8.codepoint(text)

    -- Ordered roughly by frequency.
    if code >= 0x4E00 and code <= 0x9FFF then
        return "基本"
    end
    if code >= 0x3400 and code <= 0x4DBF then
        return "扩A"
    end
    if code >= 0x20000 and code <= 0x2A6DF then
        return "扩B"
    end
    if code >= 0x2A700 and code <= 0x2B73F then
        return "扩C"
    end
    if code >= 0x2B740 and code <= 0x2B81F then
        return "扩D"
    end
    if code >= 0x2B820 and code <= 0x2CEAF then
        return "扩E"
    end
    if code >= 0x2CEB0 and code <= 0x2EBEF then
        return "扩F"
    end
    if code >= 0x2EBF0 and code <= 0x2EE5F then
        return "扩I"
    end
    if code >= 0x30000 and code <= 0x3134F then
        return "扩G"
    end
    if code >= 0x31350 and code <= 0x323AF then
        return "扩H"
    end

    -- Compatibility blocks.
    if code >= 0xF900 and code <= 0xFAFF then
        return "兼容"
    end
    if code >= 0x2F800 and code <= 0x2FA1F then
        return "兼容"
    end

    return nil
end

---Build a reverse-lookup-mode comment showing pinyin, aux code, and charset block.
---@param cand Candidate
---@param initial_comment string
---@return string
local function get_reverse_lookup_comment(cand, initial_comment)
    ---@type string[]
    local inner_parts = {}

    -- Decompose phonetic/aux annotations.
    if initial_comment ~= "" then
        ---@type string[]
        local segments = {}
        for segment in initial_comment:gmatch("[^%s]+") do
            segments[#segments + 1] = segment
        end

        if #segments > 0 then
            local semicolon_count = select(2, segments[1]:gsub(";", ""))
            ---@type string[]
            local pinyins = {}
            ---@type string?
            local aux = nil

            for _, segment in ipairs(segments) do
                local pinyin = segment:match("^[^;~]+")
                if pinyin then
                    pinyins[#pinyins + 1] = pinyin
                end

                if not aux then
                    local curr_aux = semicolon_count == 1 and segment:match(";(.+)$") or nil
                    if curr_aux and curr_aux ~= "" then
                        aux = curr_aux
                    end
                end
            end

            if #pinyins > 0 then
                inner_parts[#inner_parts + 1] = ("音%s"):format(table.concat(pinyins, ","))
                if aux then
                    inner_parts[#inner_parts + 1] = ("辅%s"):format(aux)
                end
            end
        end
    end

    local label = get_charset_label(cand.text)
    if label then
        inner_parts[#inner_parts + 1] = label
    end

    if #inner_parts == 0 then
        return "〔无〕"
    end
    return "〔" .. table.concat(inner_parts, "・") .. "〕"
end

-- Aux-code or toned full-pinyin annotation

---@param cand Candidate
---@param initial_comment string
---@param config SuperCommentConfig
---@param ctx Context
---@return string
local function get_aux_comment(cand, initial_comment, config, ctx)
    local length = utf8.len(cand.text)
    if length > config.min_candidate_length then
        return ""
    end

    local auto_delimiter = config.auto_delimiter or " "

    ---@type string[]
    local segments = {}
    for segment in initial_comment:gmatch("[^" .. auto_delimiter .. "]+") do
        segments[#segments + 1] = segment
    end

    -- Tone option overrides aux-code presentation.
    local use_tone = ctx:get_option("tone_hint") or ctx:get_option("toneless_hint")
    local aux_type = use_tone and "tone" or "fuzhu"

    local first_segment = segments[1] or ""
    local semicolon_count = select(2, first_segment:gsub(";", ""))

    -- No semicolon: fall back to the original comment with delimiters normalised.
    if semicolon_count == 0 then
        return (initial_comment:gsub(auto_delimiter, " "))
    end

    -- With semicolon: extract per type.
    ---@type string[]
    local aux_comments = {}
    for _, segment in ipairs(segments) do
        if aux_type == "tone" then
            -- Take the part before the first semicolon.
            local before = segment:match("^(.-);")
            if before and before ~= "" then
                aux_comments[#aux_comments + 1] = before
            end
        else
            -- Take the part after the first semicolon (to end of segment).
            local after = segment:match(";(.+)$")
            if after and after ~= "" then
                aux_comments[#aux_comments + 1] = after
            end
        end
    end

    if #aux_comments == 0 then
        return ""
    end
    -- Tone uses space, fuzhu uses slash.
    return table.concat(aux_comments, aux_type == "tone" and " " or "/")
end

-- Main filter: dispatch to the right annotation generator per option set.

local M = {}

---@param env Env
function M.init(env)
    local rime_config = env.engine.schema.config

    local delimiter = rime_config:get_string("speller/delimiter") or " '"
    local auto_delimiter = delimiter:sub(1, 1)
    local min_candidate_length = rime_config:get_int("super_comment/min_candidate_length") or 1

    env.super_comment_config = {
        auto_delimiter = auto_delimiter,
        min_candidate_length = min_candidate_length,
    }

    corrector.init(env)
end

---@param env Env
function M.fini(env)
    corrector.fini(env)
    env.super_comment_config = nil
end

---@param input Translation
---@param env Env
function M.func(input, env)
    local config = env.super_comment_config
    assert(config)
    local corrector_config = env.super_comment_corrector_config
    assert(corrector_config)

    local context = env.engine.context
    local input_str = context.input
    local is_reverse_lookup = wanxiang.is_reverse_lookup_mode(env)
    local skip_annotations = wanxiang.is_function_mode_active(context) or input_str == ""
    local tone_hint = context:get_option("tone_hint")
    local toneless_hint = context:get_option("toneless_hint")
    local fuzhu_hint = context:get_option("fuzhu_hint")

    for cand in input:iter() do
        local genuine_cand = cand:get_genuine()
        local initial_comment = genuine_cand.comment
        local final_comment = initial_comment

        if skip_annotations then
            yield(genuine_cand)
            goto continue
        end

        -- Aux-code or tone annotation.
        if fuzhu_hint or tone_hint then
            final_comment = get_aux_comment(cand, initial_comment, config, context)
        elseif toneless_hint then
            final_comment = remove_pinyin_tone(get_aux_comment(cand, initial_comment, config, context))
        else
            final_comment = ""
        end

        -- Mispronunciation / typo hint takes priority over the aux annotation.
        if corrector_config.enabled then
            local correction_comment = corrector.get_comment(cand, corrector_config)
            if correction_comment and correction_comment ~= "" then
                final_comment = correction_comment
            end
        end

        -- Reverse-lookup mode replaces everything else.
        if is_reverse_lookup then
            local reverse_lookup_comment = get_reverse_lookup_comment(cand, initial_comment)
            if reverse_lookup_comment ~= "" then
                final_comment = reverse_lookup_comment
            end
        end

        if final_comment ~= initial_comment then
            genuine_cand.comment = final_comment
        end

        yield(genuine_cand)
        ::continue::
    end
end

return M
