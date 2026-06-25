---Provide english word creation functionality.
---
---Features:
---- Provide raw English candidate in word-creation mode.
---- Append committed English phrases to the English user dictionary.
---
---@author amzxyz
---@author Fidel Yin <fidel.yin@hotmail.com>

---@class EnglishUserDictAppenderConfig
---@field trigger string?

---@class EnglishUserDictAppenderState
---@field memory Memory?
---@field commit_notifier Connection?

---@diagnostic disable-next-line: duplicate-type
---@class Env
---@field english_user_dict_appender_config EnglishUserDictAppenderConfig?
---@field english_user_dict_appender_state EnglishUserDictAppenderState?

local utils = require("utils.utils")

---Return if the text is a non-empty ASCII word.
---@param text string
---@return boolean
local function is_english_phrase(text)
    -- consists of ASCII characters & contains at least one letter.
    return text:match("^[%z\1-\127]+$") ~= nil and text:match("[A-Za-z]") ~= nil
end

-- English phrase creation handler.
---@param ctx Context
---@param env Env
local function commit_handler(ctx, env)
    local config = env.english_user_dict_appender_config
    assert(config)
    local state = env.english_user_dict_appender_state
    assert(state)

    local trigger = config.trigger
    assert(trigger)

    local raw_input = ctx.input
    if raw_input == "" or raw_input:sub(-1) ~= trigger then
        return
    end

    local commit_text = ctx:get_commit_text()
    if not is_english_phrase(commit_text) then
        return
    end

    -- Strip trigger and trailing whitespace from raw input to get the code body.
    local code_body = raw_input:gsub(trigger .. "+$", ""):gsub("%s+$", "")
    -- Strip trigger from commit text to get the clean phrase.
    local clean_commit_text = commit_text:gsub(trigger .. "+$", "")
    if code_body == "" or clean_commit_text == "" then
        return
    end

    local memory = state.memory
    if not memory then
        return
    end

    -- Add the original-cased code to the user dictionary.
    memory:update_userdict(utils.make_dict_entry(clean_commit_text, code_body), 1, "")

    -- Add the lowercased code to the user dictionary if it's different from the original.
    local lower_code = code_body:lower()
    if lower_code ~= code_body then
        memory:update_userdict(utils.make_dict_entry(clean_commit_text, lower_code), 1, "")
    end
end

local F = {}

---@param env Env
function F.init(env)
    local rime_config = env.engine.schema.config
    local context = env.engine.context

    local trigger = rime_config:get_string("wanxiang_english/user_dict_trigger")
    if trigger == "" then
        trigger = nil
    end
    if trigger and #trigger > 1 then
        trigger = trigger:sub(1, 1)
    end

    ---@type Memory?
    local memory = nil
    ---@type Connection?
    local commit_notifier = nil

    if trigger then
        memory = Memory(env.engine, env.engine.schema, "wanxiang_english")
        commit_notifier = context.commit_notifier:connect(function(ctx)
            commit_handler(ctx, env)
        end)
    end

    env.english_user_dict_appender_config = {
        trigger = trigger,
    }

    env.english_user_dict_appender_state = {
        memory = memory,
        commit_notifier = commit_notifier,
    }
end

---@param env Env
function F.fini(env)
    assert(env.english_user_dict_appender_state)

    if env.english_user_dict_appender_state.memory then
        env.english_user_dict_appender_state.memory:disconnect()
    end
    if env.english_user_dict_appender_state.commit_notifier then
        env.english_user_dict_appender_state.commit_notifier:disconnect()
    end

    env.english_user_dict_appender_config = nil
    env.english_user_dict_appender_state = nil
end

---@param input Translation
---@param env Env
function F.func(input, env)
    local config = env.english_user_dict_appender_config
    assert(config)

    local trigger = config.trigger
    local code = env.engine.context.input

    -- Forced English word creation: a leading trigger offers a raw English commit.
    if trigger and code:sub(1, #trigger) == trigger then
        local raw_text = code:sub(#trigger + 1)
        if is_english_phrase(raw_text) then
            local cand = Candidate("english", 0, #code, raw_text, "")
            cand.preedit = raw_text
            yield(cand)
            return
        end
    end

    for cand in input:iter() do
        yield(cand)
    end
end

return F
