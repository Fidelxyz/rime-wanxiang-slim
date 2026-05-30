---Enhances English input by applying smart casing and spacing, and ensuring single-letter candidates are available.
---
---Core features:
--- 1. Casing formatting driven by the first two input letters: ALL CAPS when both are uppercase, Title Case when only
---    the first is uppercase, otherwise lowercase.
--- 2. Smart sentence spacing: adds spaces around committed English words (Smart Spacing) and losslessly restores word
---    splits from the preedit guide.
--- 3. Single-letter cut-in ordering: ensures single-letter candidates are available and promoted ahead of regular
---    ASCII candidates.
---
---@author amzxyz
---@author Fidel Yin <fidel.yin@hotmail.com>

---@class EnglishConfig
---@field english_spacing_mode string|"off"|"smart"|"before"|"after"
---@field spacing_timeout number
---@field user_dict_trigger string
---@field split_pattern string
---@field delim_check_pattern string

---@class EnglishState
---@field is_prev_commit_english boolean
---@field last_commit_time number
---@field comp_start_time number?
---
---@field update_notifier Connection
---@field commit_notifier Connection

---@diagnostic disable-next-line: duplicate-type
---@class Env
---@field english_config EnglishConfig?
---@field english_state EnglishState?

---@class CodeContext
---@field raw_input string
---@field spacing_mode string|"off"|"smart"|"before"|"after"
---@field is_prev_commit_english boolean

local wanxiang = require("wanxiang.wanxiang")

---@param s string
---@return string
local function normalize_word(s)
    return s:gsub("[^a-zA-Z]", ""):lower()
end

---@type table<integer, boolean>
local allowed_ascii_symbols = {
    [32] = true, -- space
    [33] = true, -- !
    [39] = true, -- '
    [44] = true, -- ,
    [45] = true, -- -
    [43] = true, -- +
    [46] = true, -- .

    [48] = true,
    [49] = true,
    [50] = true,
    [51] = true,
    [52] = true,
    [53] = true,
    [54] = true,
    [55] = true,
    [56] = true,
    [57] = true,
}

-- Must contain at least one English letter; pure digits/symbols return false.
---@param s string
---@return boolean
local function is_english_phrase(s)
    local has_alpha = false
    for i = 1, #s do
        local b = s:byte(i)
        if (b >= 65 and b <= 90) or (b >= 97 and b <= 122) then
            has_alpha = true
        elseif not allowed_ascii_symbols[b] then
            return false
        end
    end
    return has_alpha
end

---@param s string
---@return boolean
local function has_letters(s)
    return s:find("[a-zA-Z]") ~= nil
end

---@param text string
---@param start_pos integer
---@param target string
---@return integer?
---@return integer?
local function find_subsequence(text, start_pos, target)
    if target == "" then
        return nil, nil
    end

    local match_start = nil
    local target_idx = 1
    local scan_pos = start_pos

    while scan_pos <= #text and target_idx <= #target do
        local text_byte = text:byte(scan_pos)
        local target_byte = target:byte(target_idx)

        -- ASCII lowercase normalization (only for A-Z)
        if target_byte >= 65 and target_byte <= 90 then
            target_byte = target_byte + 32
        end

        if text_byte == target_byte then
            if target_idx == 1 then
                match_start = scan_pos -- Record where the match begins
            end
            target_idx = target_idx + 1
        end

        scan_pos = scan_pos + 1
    end

    if target_idx > #target then -- Matched all
        return match_start, scan_pos - 1
    end

    return nil, nil
end

---comment
---@param cand Candidate
---@param split_pattern string
---@param check_pattern string
---@return Candidate
local function restore_sentence_spacing(cand, split_pattern, check_pattern)
    local guide = cand.preedit
    if not guide:find(check_pattern) then
        return cand
    end

    local text = cand.text

    ---@type string[]
    local targets = {}
    local targets_len = 0
    for seg in guide:gmatch(split_pattern) do
        local t = normalize_word(seg)
        if t ~= "" then
            targets_len = targets_len + 1
            targets[targets_len] = t
        end
    end
    if next(targets) == nil then
        return cand
    end

    ---@type integer[]
    local starts = {}
    local starts_len = 0
    local p = 1
    for _, target in ipairs(targets) do
        local s, e = find_subsequence(text, p, target)
        if not s or not e then
            return cand
        end
        starts_len = starts_len + 1
        starts[starts_len] = s
        p = e + 1
    end

    ---@type string[]
    local parts = {}
    local parts_len = 0
    if starts[1] and starts[1] > 1 then
        parts_len = parts_len + 1
        parts[parts_len] = text:sub(1, starts[1] - 1)
    end
    for i = 1, #starts do
        local current_s = starts[i]
        local next_s = starts[i + 1]
        local chunk_end = next_s and (next_s - 1) or #text
        parts_len = parts_len + 1
        parts[parts_len] = text:sub(current_s, chunk_end)
    end

    local new_text = ""
    for i, part in ipairs(parts) do
        if i == 1 then
            new_text = part
        else
            local last_char = new_text:sub(-1)
            if last_char == "'" or last_char == "-" then
                new_text = new_text .. part
            else
                new_text = new_text .. " " .. part
            end
        end
    end
    new_text = new_text:gsub("%s%s+", " ")
    if new_text == "" then
        return cand
    end

    local new_cand = Candidate(cand.type, cand.start, cand._end, new_text, cand.comment)
    new_cand.preedit = guide
    return new_cand
end

---@param text string
---@param input_code string
---@return string
local function apply_casing(text, input_code)
    if input_code:find("^%u%u") then
        return text:upper()
    elseif input_code:find("^%u") then
        return (text:gsub("^%a", string.upper))
    end

    return text
end

---@param cand Candidate
---@param code_ctx CodeContext
---@return Candidate
local function apply_formatting(cand, code_ctx)
    local text = cand.text
    if text == "" then
        return cand
    end

    local changed = false

    local norm = text:gsub(string.char(0xC2, 0xA0), " ")
    if norm ~= text then
        text = norm
        changed = true
    end

    if is_english_phrase(text) then
        local new_text = apply_casing(text, code_ctx.raw_input)
        if new_text ~= text then
            text = new_text
            changed = true
        end
        if code_ctx.spacing_mode and code_ctx.spacing_mode ~= "off" then
            local mode = code_ctx.spacing_mode
            if mode == "smart" then
                if code_ctx.is_prev_commit_english then
                    if not text:find("^%s") then
                        text = " " .. text
                        changed = true
                    end
                end
            elseif mode == "before" then
                if not text:find("^%s") then
                    text = " " .. text
                    changed = true
                end
            elseif mode == "after" then
                if not text:find("%s$") then
                    text = text .. " "
                    changed = true
                end
            end
        end
    end

    if not changed then
        return cand
    end

    local new_cand = Candidate(cand.type, cand.start, cand._end, text, cand.comment)
    new_cand.preedit = cand.preedit
    return new_cand
end

local P = {}

---@param key_event KeyEvent
---@param env Env
---@return ProcessResult
function P.func(key_event, env)
    -- Ignore key release events. Otherwise, when Space/Enter selects an English candidate,
    -- the press event sees a non-empty composition (skipped), the speller commits and clears
    -- the composition, and the release event would then incorrectly mark the standalone
    -- Space/Enter as a chain-breaker, suppressing the next smart spacing.
    if key_event:release() then
        return wanxiang.RIME_PROCESS_RESULTS.kNoop
    end

    local context = env.engine.context
    local keycode = key_event.keycode

    if context.composition:empty() then
        if keycode == 0xff0d or keycode == 0xff8d or keycode == 0x20 then
            context:set_property("english_spacing", "true")
        end
    end

    return wanxiang.RIME_PROCESS_RESULTS.kNoop
end

local F = {}

---@param env Env
function F.init(env)
    local config = env.engine.schema.config

    local english_spacing_mode = config:get_string("wanxiang_english/english_spacing") or "off"
    local spacing_timeout = config:get_double("wanxiang_english/spacing_timeout") or 0

    local user_dict_trigger = config:get_string("wanxiang_english/user_dict_trigger")
    if not user_dict_trigger or user_dict_trigger == "" then
        user_dict_trigger = "\\"
    end
    if #user_dict_trigger > 1 then
        user_dict_trigger = user_dict_trigger:sub(1, 1)
    end
    ---@cast user_dict_trigger string

    local delimiter_str = config:get_string("speller/delimiter") or " '"
    local escaped_delims = delimiter_str:gsub("([%%%^%$%(%)%%%.%[%]%*%+%-%?])", "%%%1")
    local split_pattern = "[^" .. escaped_delims .. "]+"
    local delim_check_pattern = "[" .. escaped_delims .. "]"

    env.english_config = {
        english_spacing_mode = english_spacing_mode,
        spacing_timeout = spacing_timeout,
        user_dict_trigger = user_dict_trigger,
        split_pattern = split_pattern,
        delim_check_pattern = delim_check_pattern,
    }

    local update_notifier = env.engine.context.update_notifier:connect(function(ctx)
        local state = env.english_state
        assert(state)

        local input = ctx.input

        if input == "" then
            state.comp_start_time = nil
        elseif state.comp_start_time == nil then
            state.comp_start_time = wanxiang.now()
        end
    end)

    local commit_notifier = env.engine.context.commit_notifier:connect(function(ctx)
        local state = env.english_state
        assert(state)

        local commit_text = ctx:get_commit_text()
        local text_no_space = commit_text:gsub("%s", "")
        local is_english = is_english_phrase(text_no_space)

        state.is_prev_commit_english = is_english
        if is_english then
            state.last_commit_time = wanxiang.now()
        else
            state.last_commit_time = 0
        end
        ctx:set_property("english_spacing", "")
    end)

    env.english_state = {
        is_prev_commit_english = false,
        last_commit_time = 0,
        comp_start_time = nil,
        update_notifier = update_notifier,
        commit_notifier = commit_notifier,
    }
end

---@param env Env
function F.fini(env)
    assert(env.english_state)
    env.english_state.update_notifier:disconnect()
    env.english_state.commit_notifier:disconnect()
    env.english_config = nil
    env.english_state = nil
end

---@param input Translation
---@param env Env
function F.func(input, env)
    local context = env.engine.context

    local config = env.english_config
    assert(config)
    local state = env.english_state
    assert(state)

    local code = context.input
    if not has_letters(code) then
        for cand in input:iter() do
            yield(cand)
        end
        return
    end

    local code_len = #code

    -- Forced English word creation: trailing `\\` triggers a raw English commit.
    if code_len > 2 and code:sub(-2) == config.user_dict_trigger .. config.user_dict_trigger then
        local raw_text = code:sub(1, code_len - 2)
        if is_english_phrase(raw_text) then
            if context.composition and not context.composition:empty() then
                local segment = context.composition:back()
                if segment then
                    segment.prompt = "〔英文造词〕"
                end
            end
            local cand = Candidate("english", 0, code_len, raw_text, "")
            cand.preedit = raw_text
            yield(cand)
            return
        end
    end

    if context:get_property("english_spacing") == "true" then
        state.is_prev_commit_english = false
    elseif state.is_prev_commit_english and config.spacing_timeout > 0 then
        local check_time = state.comp_start_time or wanxiang.now()
        if (check_time - state.last_commit_time) > config.spacing_timeout then
            state.is_prev_commit_english = false
        end
    end

    ---@type CodeContext
    local code_ctx = {
        raw_input = code,
        spacing_mode = config.english_spacing_mode,
        is_prev_commit_english = state.is_prev_commit_english,
    }

    ---@type Candidate[]
    local single_chars = {}
    local single_chars_len = 0
    local single_char_injected = false

    if code_len == 1 then
        local b = code:byte()
        local is_upper = (b >= 65 and b <= 90)
        local is_lower = (b >= 97 and b <= 122)
        if is_upper or is_lower then
            local t1 = code
            local t2 = is_upper and code:lower() or code:upper()
            single_chars_len = single_chars_len + 1
            single_chars[single_chars_len] = Candidate("completion", 0, 1, t1, "")
            single_chars_len = single_chars_len + 1
            single_chars[single_chars_len] = Candidate("completion", 0, 1, t2, "")
        end
    else
        single_char_injected = true
    end

    for cand in input:iter() do
        local c_type = cand.type
        local raw_text = cand.text

        -- Junk filter: skip raw segments and dedupe single-letter candidates.
        if (c_type == "raw") or (code_len == 1 and has_letters(code) and raw_text:lower() == code:lower()) then
            goto continue
        end

        local is_ascii = is_english_phrase(raw_text)

        local good_cand = restore_sentence_spacing(cand, config.split_pattern, config.delim_check_pattern)
        local fmt_cand = apply_formatting(good_cand, code_ctx)

        if fmt_cand.type == "user_table" or fmt_cand.type == "phrase" or not is_ascii then
            -- Emit user_table, Chinese candidates etc. directly; do not let single-letter cut in.
            yield(fmt_cand)
            goto continue
        end

        -- Allow single-letter to cut in front of regular ASCII candidates.
        if next(single_chars) ~= nil and not single_char_injected then
            for _, c in ipairs(single_chars) do
                yield(c)
            end
            single_char_injected = true
        end

        yield(fmt_cand)

        ::continue::
    end
end

return { P = P, F = F }
