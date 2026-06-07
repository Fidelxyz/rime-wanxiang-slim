---Show reverse lookup hints, code hints and correction hints in candidate comments.
---@author amzxyz
---@author Fidel Yin <fidel.yin@hotmail.com>

---@class CodeHintConfig
---@field auto_delimiter string
---@field max_candidate_length integer

---@class CorrectionHintConfig
---@field enabled boolean

---@diagnostic disable-next-line: duplicate-type
---@class Env
---@field code_hint_config CodeHintConfig?
---@field correction_hint_config CorrectionHintConfig?

local wanxiang = require("wanxiang.wanxiang")

---Reverse-lookup hint module, showing pinyin and aux-code for candidates from reverse lookup segments.
local reverse_lookup_hint = {}

---@param context Context
---@return boolean
function reverse_lookup_hint.is_active(context)
    local segment = context.composition:back()
    if not segment then
        return false
    end

    return segment:has_tag("wanxiang_reverse")
end

---@param raw_comment string
---@return string?
function reverse_lookup_hint.get_comment(raw_comment)
    -- Parse multiple segments (for multi-pronunciation candidates).
    ---@type string[]
    local segments = {}
    local segments_len = 0
    -- Delimiters for reverse lookup comments are always whitespace, regardless of the auto_delimiter config.
    for segment in raw_comment:gmatch("[^%s]+") do
        segments_len = segments_len + 1
        segments[segments_len] = segment
    end
    if segments_len == 0 then
        return nil
    end

    ---@type string[]
    local pinyins = {}
    local pinyins_len = 0
    ---@type string?
    local auxcode = nil

    for _, segment in ipairs(segments) do
        -- Extract the pinyin part before the semicolon, if any. Semicolon is not required.
        -- Tilde for unknown pinyin is also excluded.
        local pinyin = segment:match("^[^;~]+")
        if pinyin then
            pinyins_len = pinyins_len + 1
            pinyins[pinyins_len] = pinyin
        end

        -- Extract the aux-code part after the semicolon, if any.
        if not auxcode then
            local curr_aux = segment:match(";(.+)$")
            if curr_aux then
                auxcode = curr_aux
            end
        end
    end

    -- Collect comment parts.
    ---@type string[]
    local comment_parts = {}
    local comment_parts_len = 0
    if #pinyins > 0 then
        comment_parts_len = comment_parts_len + 1
        comment_parts[comment_parts_len] = table.concat(pinyins, ",")
    end
    if auxcode then
        comment_parts_len = comment_parts_len + 1
        comment_parts[comment_parts_len] = auxcode
    end
    if comment_parts_len == 0 then
        return nil
    end

    return "〔" .. table.concat(comment_parts, "｜") .. "〕"
end

---Code hint module for aux-code or tone annotation.
local code_hint = {}

---@param env Env
function code_hint.init(env)
    local rime_config = env.engine.schema.config

    local delimiter = rime_config:get_string("speller/delimiter") or " '"
    local auto_delimiter = delimiter:sub(1, 1)

    local max_candidate_length = rime_config:get_int("code_hint/max_candidate_length") or 0

    env.code_hint_config = {
        auto_delimiter = auto_delimiter,
        max_candidate_length = max_candidate_length,
    }
end

function code_hint.fini(env)
    env.code_hint_config = nil
end

---@param context Context
---@return boolean
function code_hint.is_active(context)
    return context:get_option("tone_hint") or context:get_option("toneless_hint") or context:get_option("fuzhu_hint")
end

---@param cand Candidate
---@param raw_comment string
---@param env Env
---@return string?
function code_hint.get_comment(cand, raw_comment, env)
    local config = env.code_hint_config
    assert(config)

    local cand_length = utf8.len(cand.text)
    if cand_length > config.max_candidate_length then
        return nil
    end

    local context = env.engine.context
    local show_auxcode = context:get_option("fuzhu_hint")

    ---@type string[]
    local segments = {}
    local segments_len = 0
    for segment in raw_comment:gmatch("[^" .. config.auto_delimiter .. "]+") do
        segments_len = segments_len + 1
        segments[segments_len] = segment
    end

    ---@type string[]
    local comments = {}
    local comments_len = 0
    for _, segment in ipairs(segments) do
        ---@type string?
        local comment
        if show_auxcode then
            -- Extract the aux-code part after the semicolon.
            comment = segment:match(";(.+)$")
        else
            -- Extract the pinyin part before the semicolon. Semicolon is not required.
            comment = segment:match("^[^;]+")
        end

        if comment and comment ~= "" then
            comments_len = comments_len + 1
            comments[comments_len] = comment
        end
    end
    if comments_len == 0 then
        return nil
    end

    local comment = table.concat(comments, " ")
    if context:get_option("toneless_hint") then
        comment = wanxiang.remove_pinyin_tone(comment)
    end
    return comment
end

---Mispronunciation/typo hint module.
local correction_hint = {}

correction_hint.DICT_PATH = "dicts/cuoyin.dict.yaml"

---@type table<string, {text: string, comment: string}>?
correction_hint.dict = nil

---@param env Env
function correction_hint.init(env)
    local rime_config = env.engine.schema.config

    local delimiter = rime_config:get_string("speller/delimiter") or " '"
    local auto_delimiter = delimiter:sub(1, 1)

    -- Initialize corrector with Memory-based lookup
    local enabled = rime_config:get_bool("correction_hint/enabled")
    if enabled == nil then
        enabled = true
    end

    env.correction_hint_config = {
        enabled = enabled,
    }

    -- Parse the correction hint dictionary from text since comment column is not supported by Rime yet.
    -- See https://github.com/rime/librime/issues/538.
    if not correction_hint.dict then
        local file = wanxiang.load_file_with_fallback(correction_hint.DICT_PATH)
        if file then
            correction_hint.dict = {}

            for line in file:lines() do
                -- Skip comment lines.
                if line:match("^#") then
                    goto continue
                end

                local text, code, _, comment = line:match("^(.-)\t(.-)\t(.-)\t(.-)$")
                if not text or not code then
                    goto continue
                end

                -- Strip whitespace.
                text = text:match("^%s*(.-)%s*$")
                code = code:match("^%s*(.-)%s*$")
                comment = comment and comment:match("^%s*(.-)%s*$")

                -- Normalize whitespace to auto_delimiter.
                comment = comment and comment:gsub("%s+", auto_delimiter)
                code = code and code:gsub("%s+", auto_delimiter)

                if comment then
                    correction_hint.dict[code] = { text = text, comment = comment }
                end

                ::continue::
            end

            file:close()
        end
    end
end

---@param env Env
function correction_hint.fini(env)
    env.correction_hint_config = nil
end

---@param cand Candidate
---@param env Env
---@return string?
function correction_hint.get_comment(cand, env)
    local config = env.correction_hint_config
    assert(config)

    if not config.enabled then
        return nil
    end

    if not correction_hint.dict then
        return nil
    end

    local correction = correction_hint.dict[cand.comment]
    if not correction or cand.text ~= correction.text then
        return nil
    end

    return correction.comment
end

local F = {}

---@param env Env
function F.init(env)
    code_hint.init(env)
    correction_hint.init(env)
end

---@param env Env
function F.fini(env)
    code_hint.fini(env)
    correction_hint.fini(env)
end

---@param translation Translation
---@param env Env
function F.func(translation, env)
    local context = env.engine.context
    local reverse_lookup_hint_active = reverse_lookup_hint.is_active(context)
    local code_hint_active = code_hint.is_active(context)

    for cand in translation:iter() do
        local genuine_cand = cand:get_genuine()
        local raw_comment = genuine_cand.comment
        local final_comment = raw_comment

        if reverse_lookup_hint_active then
            local comment = reverse_lookup_hint.get_comment(raw_comment)
            if comment then
                final_comment = comment
                goto yield
            end
        end

        do
            local comment = correction_hint.get_comment(genuine_cand, env)
            if comment then
                final_comment = comment
                goto yield
            end
        end

        if code_hint_active then
            local comment = code_hint.get_comment(genuine_cand, raw_comment, env)
            if comment then
                final_comment = comment
                goto yield
            end
        end

        -- Clear comment if no hints are applicable.
        final_comment = ""

        ::yield::
        genuine_cand.comment = final_comment
        yield(genuine_cand)
    end
end

---@param segment Segment
---@return boolean
function F.tags_match(segment, _)
    return not wanxiang.is_function_mode_active_segment(segment)
end

return F
