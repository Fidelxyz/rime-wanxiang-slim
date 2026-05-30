---Automatically add new phrases to user dictionaries.
---
---Dependencies:
---  filters:
---    - lua_filter@*utils.candidate_code_recorder*F
---
---@author amzxyz
---@author Fidel Yin <fidel.yin@hotmail.com>

---@class AutoPhraseConfig
---@field en_user_dict_trigger string?
---@field split_code_pattern string

---@class AutoPhraseState
---@field zh_memory Memory?
---@field en_memory Memory?
---
---@field commit_notifier Connection?

---@diagnostic disable-next-line: duplicate-type
---@class Env
---@field auto_phrase_config AutoPhraseConfig?
---@field auto_phrase_state AutoPhraseState?

local utils = require("utils.utils")
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
        if not utils.is_chinese_codepoint(cp) then
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

    local commit_text = ctx:get_commit_text()
    local raw_input = ctx.input

    if raw_input ~= "" and raw_input:sub(-1) == config.en_user_dict_trigger and is_english_phrase(commit_text) then
        -- English phrase creation.

        -- Strip trigger and trailing whitespace from raw input to get the code body.
        local code_body = raw_input:gsub(config.en_user_dict_trigger .. "+$", ""):gsub("%s+$", "")
        -- Strip trigger from commit text to get the clean phrase.
        local clean_commit_text = commit_text:gsub(config.en_user_dict_trigger .. "+$", "")
        if code_body ~= "" and clean_commit_text ~= "" and state.en_memory then
            state.en_memory:update_userdict(utils.make_dict_entry(clean_commit_text, code_body), 1, "")

            local lower_code = code_body:lower()
            if lower_code ~= code_body then
                state.en_memory:update_userdict(utils.make_dict_entry(clean_commit_text, lower_code), 1, "")
            end
        end
    elseif state.zh_memory then
        -- Chinese auto phrase creation.

        local segments = ctx.composition:toSegmentation():get_segments()
        local segments_count = #segments

        if segments_count <= 1 or utf8.len(commit_text) <= 1 or not is_chinese_phrase(commit_text) then
            return
        end

        ---@type string[]
        local codes = {}
        local codes_len = 0

        -- Walk all segments and collect their codes.
        for _, seg in ipairs(segments) do
            local cand = seg and seg:get_selected_candidate()
            if not cand then
                -- No candidate: likely a punctuation segment.
                return
            end

            -- Look up this candidate's comment (its code).
            local code = candidate_code_recorder.get(cand.text)
            if not code then
                return
            end

            -- Code present: split and append.
            for part in code:gmatch(config.split_code_pattern) do
                codes_len = codes_len + 1
                codes[codes_len] = part
            end
        end
        if codes_len == 0 then
            return
        end

        -- Number of code pieces must equal the number of characters in commit_text.
        local total_chars = utf8.len(commit_text)
        if codes_len ~= total_chars then
            return
        end

        -- Write to the user dictionary.
        local code = table.concat(codes, " ")
        state.zh_memory:update_userdict(utils.make_dict_entry(commit_text, code), 1, "")
    end
end

local P = {}

---@param env Env
function P.init(env)
    local rime_config = env.engine.schema.config
    local context = env.engine.context

    local en_user_dict_trigger = rime_config:get_string("wanxiang_english/user_dict_trigger")
    if en_user_dict_trigger == "" then
        en_user_dict_trigger = nil
    end
    if en_user_dict_trigger and #en_user_dict_trigger > 1 then
        en_user_dict_trigger = en_user_dict_trigger:sub(1, 1)
    end

    local delimiter = rime_config:get_string("speller/delimiter") or " '"
    local split_code_pattern = "[^" .. utils.escape_for_pattern(delimiter) .. "]+"

    -- Chinese auto-phrase switch (only controls user_dict_appender).
    local auto_phrase_enabled = rime_config:get_bool("user_dict_appender/enable_auto_phrase")
    if auto_phrase_enabled == nil then
        auto_phrase_enabled = false
    end

    local user_dict_enabled = rime_config:get_bool("user_dict_appender/enable_user_dict")
    if user_dict_enabled == nil then
        user_dict_enabled = false
    end

    -- Chinese: user_dict_appender, controlled by the switches above.
    local zh_memory = (auto_phrase_enabled and user_dict_enabled)
            and Memory(env.engine, env.engine.schema, "user_dict_appender")
        or nil
    if zh_memory then
        candidate_code_recorder.enable()
    end

    -- English: always enabled regardless of the switches.
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
        en_user_dict_trigger = en_user_dict_trigger,
        split_code_pattern = split_code_pattern,
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
    return utils.RIME_PROCESS_RESULTS.kNoop
end

return P
