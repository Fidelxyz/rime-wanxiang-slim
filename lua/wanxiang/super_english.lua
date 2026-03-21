-- lua/super_english.lua
-- https://github.com/amzxyz/rime_wanxiang
-- @description: 英文全能处理器 (Filter Only: 锚点切分 + 动态分隔符 + 超时销毁 + 性能极速优化)
-- @author: amzxyz

-- 核心功能清单:
-- 1. [Format] 语句级英文大写格式化,逐词大小写对应 (look HELLO -> look HELLO)
-- 2. [Spacing] 智能语句空格切分，智能单词上屏加空格 (Smart Spacing) 与无损分词还原
-- 3. [Memory] 全量历史缓存，完美解决回删乱码问题
-- 4. [Construct] 原生优先构造策略 (短词无分词则重置为原生输入)
-- 5. [Order] 单字母(a/A) 智能插队排序,补齐单字母候选
-- 6. [Limit & Perf] 纯英文数量限制，并增加极速防卡顿熔断机制

---@class SuperEnglishConfig
---@field english_spacing_mode string|"off"|"smart"|"before"|"after"
---@field spacing_timeout number
---@field max_eng_cands integer
---@field phrase_trigger string
---@field split_pattern string
---@field delim_check_pattern string

---@class SuperEnglishState
---@field prev_commit_is_eng boolean
---@field last_commit_time number
---@field comp_start_time number?
---@field sticky_countdown integer
---@field block_derivation boolean
---@field memory table<string, { text: string, preedit: string }>
---
---@field update_notifier Connection
---@field commit_notifier Connection

---@class Env
---@field super_english_config SuperEnglishConfig?
---@field super_english_state SuperEnglishState?

---@class CodeContext
---@field raw_input string
---@field spacing_mode string|"off"|"smart"|"before"|"after"
---@field prev_is_eng boolean

local wanxiang = require("wanxiang.wanxiang")

local STICKY_BUFFER_SIZE = 2

---@param s string
---@return string
local function normalize_word(s)
    return s:gsub("[^a-zA-Z]", ""):lower()
end

---@type table<string, boolean>
local no_spacing_words = {
    ["http"] = true,
    ["https"] = true,
    ["www"] = true,
    ["ftp"] = true,
    ["ssh"] = true,
    ["mailto"] = true,
    ["file"] = true,
    ["tel"] = true,
}

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

-- 必须包含至少一个英文字母，否则纯数字/符号直接返回 false
---@param s string
---@return boolean
local function is_ascii_phrase_fast(s)
    if s == "" then
        return false
    end

    local has_alpha = false
    for i = 1, #s do
        local b = s:byte(i)
        local is_upper = (b >= 65 and b <= 90)
        local is_lower = (b >= 97 and b <= 122)

        if is_upper or is_lower then
            has_alpha = true
        elseif not allowed_ascii_symbols[b] then
            return false
        end
    end
    return has_alpha
end

---@param s string
---@return integer?
local function has_letters(s)
    return s:find("[a-zA-Z]")
end

---@param text string
---@param start_pos integer
---@param target_fp string
---@return integer?
---@return integer?
local function find_target_in_text(text, start_pos, target_fp)
    local text_len = #text
    local target_len = #target_fp

    if target_len == 0 then
        return nil, nil
    end

    local match_start = nil
    local target_idx = 1
    local scan_pos = start_pos

    while scan_pos <= text_len and target_idx <= target_len do
        local text_char = text:sub(scan_pos, scan_pos)
        local target_char = target_fp:sub(target_idx, target_idx)

        if text_char:lower() == target_char then
            if target_idx == 1 then
                match_start = scan_pos -- Record where the match begins
            end
            target_idx = target_idx + 1
        end

        scan_pos = scan_pos + 1
    end

    local matched_all = target_idx > target_len
    if matched_all then
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
    local guide = cand.preedit or ""
    if not guide:find(check_pattern) then
        return cand
    end

    local text = cand.text

    ---@type string[]
    local targets = {}
    for seg in guide:gmatch(split_pattern) do
        local t = normalize_word(seg)
        if #t > 0 then
            table.insert(targets, t)
        end
    end
    if #targets == 0 then
        return cand
    end

    ---@type integer[]
    local starts = {}
    local p = 1
    for _, target in ipairs(targets) do
        local s, e = find_target_in_text(text, p, target)
        if not s then
            return cand
        end
        table.insert(starts, s)
        p = e + 1
    end

    ---@type string[]
    local parts = {}
    if starts[1] > 1 then
        table.insert(parts, text:sub(1, starts[1] - 1))
    end
    for i = 1, #starts do
        local current_s = starts[i]
        local next_s = starts[i + 1]
        local chunk_end = next_s and (next_s - 1) or #text
        table.insert(parts, text:sub(current_s, chunk_end))
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
    new_cand.preedit = cand.preedit
    return new_cand
end

local NBSP = string.char(0xC2, 0xA0)

---@param text string
---@param input_code string
---@return string
local function apply_segment_formatting(text, input_code)
    if not input_code or input_code == "" then
        return text
    end
    local parts = {}
    local p_code = 1
    for word in text:gmatch("%S+") do
        local clean_word = normalize_word(word)
        local w_len = #clean_word
        if w_len > 0 then
            if word:find("[\128-\255]") then
                local input_remain = #input_code - p_code + 1
                if input_remain > 0 then
                    local check_len = (w_len < input_remain) and w_len or input_remain
                    p_code = p_code + check_len
                end
            else
                local input_remain = #input_code - p_code + 1
                if input_remain > 0 then
                    local check_len = (w_len < input_remain) and w_len or input_remain
                    local segment = input_code:sub(p_code, p_code + check_len - 1)
                    local is_pure_alpha = not word:find("[^a-zA-Z]")
                    if segment:find("^%u%u") and is_pure_alpha then
                        word = word:lower()
                    elseif segment:find("^%u") then
                        word = word:gsub("^%a", string.upper)
                    end
                    p_code = p_code + check_len
                end
            end
        end
        table.insert(parts, word)
    end
    return table.concat(parts, " ")
end

---@param cand Candidate
---@param code_ctx CodeContext
---@return Candidate
local function apply_formatting(cand, code_ctx)
    local text = cand.text
    if not text or text == "" then
        return cand
    end

    local changed = false

    local norm = text:gsub(NBSP, " ")
    if norm ~= text then
        text = norm
        changed = true
    end

    if is_ascii_phrase_fast(text) then
        if code_ctx.raw_input then
            local new_text = apply_segment_formatting(text, code_ctx.raw_input)
            if new_text ~= text then
                text = new_text
                changed = true
            end
        end
        if code_ctx.spacing_mode and code_ctx.spacing_mode ~= "off" then
            local mode = code_ctx.spacing_mode
            if mode == "smart" then
                if code_ctx.prev_is_eng then
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

local M = {}

---@param env Env
function M.init(env)
    local config = env.engine.schema.config

    local english_spacing_mode = config:get_string("wanxiang_english/english_spacing") or "off"
    local spacing_timeout = config:get_double("wanxiang_english/spacing_timeout") or 0
    local lookup_key = config:get_string("wanxiang_lookup/key") or "`"

    local max_eng_cands = config:get_int("wanxiang_english/max_candidates") or 0

    local phrase_trigger = config:get_string("wanxiang_english/trigger")
    if phrase_trigger and phrase_trigger ~= "" then
        phrase_trigger = phrase_trigger:sub(1, 1)
    else
        phrase_trigger = "\\"
    end

    local delimiter_str = config:get_string("speller/delimiter") or " '"
    local escaped_delims = delimiter_str:gsub("([%%%^%$%(%)%%%.%[%]%*%+%-%?])", "%%%1")
    local split_pattern = "[^" .. escaped_delims .. "]+"
    local delim_check_pattern = "[" .. escaped_delims .. "]"

    env.super_english_config = {
        english_spacing_mode = english_spacing_mode,
        spacing_timeout = spacing_timeout,
        max_eng_cands = max_eng_cands,
        phrase_trigger = phrase_trigger,
        split_pattern = split_pattern,
        delim_check_pattern = delim_check_pattern,
    }

    local update_notifier = env.engine.context.update_notifier:connect(function(ctx)
        local state = env.super_english_state
        assert(state)

        local input = ctx.input

        state.block_derivation = (lookup_key and input:find(lookup_key, 1, true)) and true or false

        if input == "" then
            state.comp_start_time = nil
        elseif state.comp_start_time == nil then
            state.comp_start_time = wanxiang.now()
        end
    end)

    local commit_notifier = env.engine.context.commit_notifier:connect(function(ctx)
        local state = env.super_english_state
        assert(state)

        local commit_text = ctx:get_commit_text()
        local text_no_space = commit_text:gsub("%s", "")
        local is_eng = is_ascii_phrase_fast(text_no_space)

        if text_no_space:find("[/\\\\]$") then
            state.sticky_countdown = STICKY_BUFFER_SIZE
            is_eng = false
        elseif state.sticky_countdown > 0 then
            if is_eng then
                state.sticky_countdown = state.sticky_countdown - 1
                is_eng = false
            else
                state.sticky_countdown = 0
            end
        elseif is_eng then
            local clean = commit_text:gsub("%s+$", ""):lower()
            if no_spacing_words[clean] then
                is_eng = false
            end
        end

        state.prev_commit_is_eng = is_eng
        if is_eng then
            state.last_commit_time = wanxiang.now()
        else
            state.last_commit_time = 0
        end
        ctx:set_property("english_spacing", "")
        state.block_derivation = false
    end)

    env.super_english_state = {
        prev_commit_is_eng = false,
        last_commit_time = 0,
        comp_start_time = nil,
        sticky_countdown = 0,
        block_derivation = false,
        memory = {},
        update_notifier = update_notifier,
        commit_notifier = commit_notifier,
    }
end

---@param env Env
function M.fini(env)
    env.super_english_state.update_notifier:disconnect()
    env.super_english_state.commit_notifier:disconnect()
    env.super_english_config = nil
    env.super_english_state = nil
end

---@param input Translation
---@param env Env
function M.func(input, env)
    local context = env.engine.context

    local config = env.super_english_config
    assert(config)
    local state = env.super_english_state
    assert(state)

    if context:get_property("force_sticky_code") == "true" then
        state.sticky_countdown = STICKY_BUFFER_SIZE
        state.prev_commit_is_eng = false
        context:set_property("force_sticky_code", "")
    end

    local curr_input = context.input
    if not has_letters(curr_input) then
        for cand in input:iter() do
            yield(cand)
        end
        return
    end
    -- ===
    local has_valid_candidate = false
    local best_candidate_saved = false
    local code_len = #curr_input

    -- [Feature] 强制英文造词
    if code_len > 2 and curr_input:sub(-2) == config.phrase_trigger .. config.phrase_trigger then
        local raw_text = curr_input:sub(1, code_len - 2)
        if is_ascii_phrase_fast(raw_text) then
            if context.composition and not context.composition:empty() then
                context.composition:back().prompt = "〔英文造词〕"
            end
            local cand = Candidate("english", 0, code_len, raw_text, "")
            cand.preedit = raw_text
            yield(cand)
            return
        end
    end

    local break_signal = (context:get_property("english_spacing") == "true")
    local effective_prev_is_eng = state.prev_commit_is_eng

    if break_signal then
        effective_prev_is_eng = false
        state.prev_commit_is_eng = false
    elseif effective_prev_is_eng and config.spacing_timeout > 0 then
        local check_time = state.comp_start_time or wanxiang.now()
        if (check_time - state.last_commit_time) > config.spacing_timeout then
            effective_prev_is_eng = false
            state.prev_commit_is_eng = false
        end
    end

    local code_ctx = {
        raw_input = curr_input,
        spacing_mode = config.english_spacing_mode,
        prev_is_eng = effective_prev_is_eng,
    }

    ---@type Candidate[]
    local single_chars = {}
    local has_single_chars = false
    local single_char_injected = false

    if code_len == 1 then
        local b = curr_input:byte()
        local is_upper = (b >= 65 and b <= 90)
        local is_lower = (b >= 97 and b <= 122)
        if is_upper or is_lower then
            local t1 = curr_input
            local t2 = is_upper and curr_input:lower() or curr_input:upper()
            table.insert(single_chars, Candidate("completion", 0, 1, t1, ""))
            table.insert(single_chars, Candidate("completion", 0, 1, t2, ""))
            has_single_chars = true
        end
    else
        single_char_injected = true
    end

    local eng_yield_count = 0
    -- 如果存在单字母派生，预先将这两个候选计入配额
    if has_single_chars then
        eng_yield_count = 2
    end

    local consecutive_skips = 0

    for cand in input:iter() do
        local c_type = cand.type
        local raw_text = cand.text

        -- [垃圾词判定]：保护符号，只去重单字母
        if
            (c_type == "raw")
            or (code_len == 1 and has_letters(curr_input) and raw_text:lower() == curr_input:lower())
        then
            goto continue
        end

        local skip_cand = false
        local is_ascii = is_ascii_phrase_fast(raw_text)

        -- [前置判断]
        if is_ascii then
            if c_type == "user_phrase" or c_type == "user_table" then
                -- 命中用户自定义词库(纯英文)，直接放行
            elseif config.max_eng_cands > 0 and eng_yield_count >= config.max_eng_cands then
                skip_cand = true
            else
                eng_yield_count = eng_yield_count + 1
            end
        end

        if skip_cand then
            -- 即使当前的词被丢弃，也要确保单字母（若存在）成功插队输出
            if has_single_chars and not single_char_injected then
                if not best_candidate_saved then
                    state.memory[curr_input] = { text = single_chars[1].text, preedit = curr_input }
                    best_candidate_saved = true
                end
                for _, c in ipairs(single_chars) do
                    yield(c)
                end
                single_char_injected = true
                has_valid_candidate = true
            end

            consecutive_skips = consecutive_skips + 1
            if consecutive_skips > 50 then
                break
            end

            goto continue
        end

        consecutive_skips = 0

        local good_cand = restore_sentence_spacing(cand, config.split_pattern, config.delim_check_pattern)
        local fmt_cand = apply_formatting(good_cand, code_ctx)

        if
            env.engine.schema.schema_id == "wanxiang_english"
            and fmt_cand.comment
            and fmt_cand.comment:find("\226\152\175")
        then
            local new_cand = Candidate(fmt_cand.type, fmt_cand.start, fmt_cand._end, fmt_cand.text, "")
            new_cand.preedit = fmt_cand.preedit
            fmt_cand = new_cand
        end

        has_valid_candidate = true

        if fmt_cand.type == "user_table" or fmt_cand.type == "fixed" or fmt_cand.type == "phrase" or not is_ascii then
            -- VIP 通道：不仅是 user_table，包括汉字等，都直接输出，不让单字母插队
            if not best_candidate_saved and fmt_cand.comment ~= "~" and not state.block_derivation then
                state.memory[curr_input] = {
                    text = fmt_cand.text,
                    preedit = curr_input,
                }
                best_candidate_saved = true
            end
            yield(fmt_cand)
            goto continue
        end

        -- 普通通道：允许单字母插队到前面
        if has_single_chars and not single_char_injected then
            if not best_candidate_saved then
                state.memory[curr_input] = { text = single_chars[1].text, preedit = curr_input }
                best_candidate_saved = true
            end
            for _, c in ipairs(single_chars) do
                yield(c)
            end
            single_char_injected = true
            has_valid_candidate = true
        end

        if not best_candidate_saved and fmt_cand.comment ~= "~" and not state.block_derivation then
            state.memory[curr_input] = {
                text = fmt_cand.text,
                preedit = curr_input,
            }
            best_candidate_saved = true
        end
        yield(fmt_cand)

        ::continue::
    end

    -- [Phase 3] 历史回溯构造 & 统一兜底
    if not has_valid_candidate then
        if state.block_derivation then
            return
        end

        -- 只有在 wanxiang_english 方案下，才进行英文的回溯派生逻辑
        if env.engine.schema.schema_id == "wanxiang_english" and has_letters(curr_input) then
            ---@type { text: string, preedit: string }?
            local anchor = nil
            local diff = ""
            for i = #curr_input - 1, 1, -1 do
                local prefix = curr_input:sub(1, i)
                if state.memory[prefix] then
                    anchor = state.memory[prefix]
                    diff = curr_input:sub(i + 1)
                    break
                end
            end

            if anchor and diff ~= "" then
                local is_code_mode = curr_input:find("[/\\]") or (state.sticky_countdown > 0)

                if is_code_mode then
                    local clean_diff = diff
                    if clean_diff:sub(-1) == config.phrase_trigger then
                        clean_diff = clean_diff:sub(1, -2)
                    end
                    local output_text = anchor.text .. clean_diff
                    local output_preedit = (anchor.preedit or anchor.text) .. diff
                    output_text = apply_segment_formatting(output_text, curr_input)

                    local cand = Candidate("fallback", 0, #curr_input, output_text, "~")
                    cand.preedit = output_preedit
                    cand.quality = 999
                    yield(cand)
                elseif is_ascii_phrase_fast(anchor.text) then
                    -- 纯英文模式（含逗号等）
                    local has_spacing = anchor.text:find(" ")
                    local last_word = anchor.text:match("(%S+)%s*$") or ""
                    local last_len = #last_word
                    local spacer = " "
                    if anchor.text:sub(-1) == " " then
                        spacer = ""
                    end

                    local output_text = ""
                    if has_spacing or last_len > 3 then
                        output_text = anchor.text .. spacer .. diff
                    else
                        output_text = curr_input
                    end

                    output_text = apply_segment_formatting(output_text, curr_input)
                    local cand = Candidate("fallback", 0, #curr_input, output_text, "~")
                    cand.preedit = output_text
                    cand.quality = 999
                    yield(cand)
                end
            end
        end
    end
end

return M
