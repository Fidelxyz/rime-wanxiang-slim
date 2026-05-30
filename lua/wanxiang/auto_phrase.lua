---Automatically add new phrases to user dictionaries.
---
---Dependencies:
---  filters:
---    - lua_filter@*wanxiang.candidate_code_recorder*F
---
---@author amzxyz
---@author Fidel Yin <fidel.yin@hotmail.com>

---@class AutoPhraseConfig
---@field escaped_delimiter string

---@class AutoPhraseState
---@field zh_memory Memory?
---@field en_memory Memory?
---
---@field commit_notifier Connection?

---@diagnostic disable-next-line: duplicate-type
---@class Env
---@field auto_phrase_config AutoPhraseConfig?
---@field auto_phrase_state AutoPhraseState?

local wanxiang = require("wanxiang.wanxiang")
local candidate_code_recorder = require("wanxiang.candidate_code_recorder")

---Return if the text is a non-empty ASCII word.
---@param text string
---@return boolean
local function is_english_phrase(text)
    -- consists of ASCII characters & contains at least one letter
    return text:match("^[%z\1-\127]+$") ~= nil and text:match("[A-Za-z]") ~= nil
end

---@param text string
---@return boolean
local function is_chinese_phrase(text)
    if text == "" then
        return false
    end

    for _, cp in utf8.codes(text) do
        -- Reject ASCII (covers letters, digits, punctuation)
        if cp <= 127 then
            return false
        end
        if not wanxiang.is_chinese_codepoint(cp) then
            return false
        end
    end

    return true
end

-- Phrase creation handler.
---@param ctx Context
---@param env Env
local function commit_handler(ctx, env)
    local config = env.auto_phrase_config
    assert(config)
    local state = env.auto_phrase_state
    assert(state)

    local segments = ctx.composition:toSegmentation():get_segments()
    local segments_count = #segments
    local commit_text = ctx:get_commit_text()
    local raw_input = ctx.input

    -- English phrase creation (kept as-is, hardcoded "\").
    if raw_input ~= "" and raw_input:sub(-1) == "\\" and is_english_phrase(commit_text) then
        local code_body = raw_input:gsub("\\+$", "")
        local clean_commit_text = commit_text:gsub("\\+$", "")
        code_body = code_body:gsub("%s+$", "")
        if code_body ~= "" and clean_commit_text ~= "" and state.en_memory then
            ---@param code string
            local function save_entry(code)
                local entry = DictEntry()
                entry.text = clean_commit_text
                entry.weight = 1
                entry.custom_code = code .. " "
                state.en_memory:update_userdict(entry, 1, "")
            end

            save_entry(code_body)
            local lower_code = code_body:lower()
            if lower_code ~= code_body then
                save_entry(lower_code)
            end
        end

        return
    end

    -- Chinese auto phrase creation.
    if not state.zh_memory then
        return
    end

    -- Basic checks.
    if segments_count <= 1 or utf8.len(commit_text) <= 1 then
        return
    end
    if not is_chinese_phrase(commit_text) then
        return
    end

    ---@type string[]
    local codes = {}
    local codes_len = 0

    -- Walk all segments and collect their codes.
    for _, seg in ipairs(segments) do
        local cand = seg and seg:get_selected_candidate()

        -- No candidate: likely a punctuation segment.
        if not cand then
            return
        end

        -- Look up this candidate's comment (its code).
        local code = candidate_code_recorder.get(cand.text)

        -- Candidate present but no code recorded.
        if not code then
            return
        end

        -- Code present: split and append.
        for part in code:gmatch("[^" .. config.escaped_delimiter .. "]+") do
            codes_len = codes_len + 1
            codes[codes_len] = part
        end
    end

    -- We need at least one code piece.
    if #codes == 0 then
        return
    end

    -- Number of code pieces must equal the number of characters in commit_text.
    local total_chars = utf8.len(commit_text)
    if #codes ~= total_chars then
        return
    end

    -- Write to the user dictionary.
    local entry = DictEntry()
    entry.text = commit_text
    entry.weight = 1
    entry.custom_code = table.concat(codes, " ") .. " "
    state.zh_memory:update_userdict(entry, 1, "")
end

local P = {}

---@param env Env
function P.init(env)
    local rime_config = env.engine.schema.config
    local context = env.engine.context

    local delimiter = rime_config:get_string("speller/delimiter") or " '"
    local escaped_delimiter = delimiter:gsub("(%W)", "%%%1")

    -- Chinese auto-phrase switch (only controls user_dict_appender).
    local auto_phrase_enabled = rime_config:get_bool("user_dict_appender/enable_auto_phrase")
    if auto_phrase_enabled == nil then
        auto_phrase_enabled = false
    end

    local user_dict_enabled = rime_config:get_bool("user_dict_appender/enable_user_dict")
    if user_dict_enabled == nil then
        user_dict_enabled = false
    end

    -- Chinese: user_dict_appender, controlled by the add_* switches above.
    local zh_memory = (auto_phrase_enabled and user_dict_enabled)
            and Memory(env.engine, env.engine.schema, "user_dict_appender")
        or nil
    if zh_memory then
        candidate_code_recorder.enable()
    end

    -- English: enuser memory, always enabled regardless of add_* switches.
    local en_memory = Memory(env.engine, env.engine.schema, "wanxiang_english")

    ---@type Connection?
    local commit_notifier = nil
    ---@type Connection?
    local delete_notifier = nil
    if zh_memory or en_memory then
        -- Hook commit/delete notifiers if either memory is active.
        commit_notifier = context.commit_notifier:connect(function(ctx)
            commit_handler(ctx, env)
        end)
    end

    env.auto_phrase_config = {
        escaped_delimiter = escaped_delimiter,
    }

    env.auto_phrase_state = {
        zh_memory = zh_memory,
        en_memory = en_memory,
        commit_notifier = commit_notifier,
        delete_notifier = delete_notifier,
    }
end

---@param env Env
function P.fini(env)
    assert(env.auto_phrase_state)
    assert(env.auto_phrase_config)

    if env.auto_phrase_state.zh_memory then
        env.auto_phrase_state.zh_memory:disconnect()
    end
    if env.auto_phrase_state.en_memory then
        env.auto_phrase_state.en_memory:disconnect()
    end

    if env.auto_phrase_state.commit_notifier then
        env.auto_phrase_state.commit_notifier:disconnect()
    end

    env.auto_phrase_config = nil
    env.auto_phrase_state = nil
end

function P.func(_, _)
    return wanxiang.RIME_PROCESS_RESULTS.kNoop
end

return P
