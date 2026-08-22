---Automatically add new phrases to user dictionaries.
---
---Dependencies:
---  filters:
---    - lua_filter@*utils.candidate_code_recorder*F
---
---@author amzxyz
---@author Fidel Yin <fidel.yin@hotmail.com>

---@class AutoPhraseConfig
---@field split_code_pattern string

---@class AutoPhraseState
---@field memory Memory?
---
---@field commit_notifier Connection?

---@diagnostic disable-next-line: duplicate-type
---@class Env
---@field auto_phrase_config AutoPhraseConfig?
---@field auto_phrase_state AutoPhraseState?

local utils = require("utils.utils")
local candidate_code_recorder = require("wanxiang.candidate_code_recorder")

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
    local state = env.auto_phrase_state
    assert(state)

    if not state.memory then
        return
    end

    local commit_text = ctx:get_commit_text()

    local segments = ctx.composition:toSegmentation():get_segments()
    local segments_count = #segments

    if segments_count <= 1 or utf8.len(commit_text) <= 1 or not is_chinese_phrase(commit_text) then
        return
    end

    local config = env.auto_phrase_config
    assert(config)

    ---@type string[]
    local codes = {}
    local codes_len = 0

    -- Walk all segments and collect their codes.
    for _, seg in ipairs(segments) do
        local cand = seg and seg:get_selected_candidate()
        local code = cand and candidate_code_recorder.get(cand.text)
        if not code then
            return
        end

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

    local code = table.concat(codes, " ")
    state.memory:update_userdict(utils.make_dict_entry(commit_text, code), 1, "")
end

local P = {}

---@param env Env
function P.init(env)
    local rime_config = env.engine.schema.config
    local context = env.engine.context

    local delimiter = rime_config:get_string("speller/delimiter") or " '"
    local split_code_pattern = "[^" .. utils.escape_for_pattern(delimiter) .. "]+"

    local auto_phrase_enabled = rime_config:get_bool("user_dict_appender/enable_auto_phrase")
    if auto_phrase_enabled == nil then
        auto_phrase_enabled = false
    end

    local user_dict_enabled = rime_config:get_bool("user_dict_appender/enable_user_dict")
    if user_dict_enabled == nil then
        user_dict_enabled = false
    end

    local enabled = auto_phrase_enabled and user_dict_enabled

    ---@type Memory?
    local memory = nil
    ---@type Connection?
    local commit_notifier = nil

    if enabled then
        candidate_code_recorder.enable()
        memory = Memory(env.engine, env.engine.schema, "user_dict_appender")
        commit_notifier = context.commit_notifier:connect(function(ctx)
            commit_handler(ctx, env)
        end)
    end

    env.auto_phrase_config = {
        split_code_pattern = split_code_pattern,
    }

    env.auto_phrase_state = {
        memory = memory,
        commit_notifier = commit_notifier,
    }
end

---@param env Env
function P.fini(env)
    assert(env.auto_phrase_state)
    assert(env.auto_phrase_config)

    if env.auto_phrase_state.memory then
        env.auto_phrase_state.memory:disconnect()
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
