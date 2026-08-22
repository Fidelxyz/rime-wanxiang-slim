---Provide english word creation functionality.
---
---Features:
---- Provide raw English candidate in word-creation mode.
---- Append committed English phrases to the English user dictionary.
---
---@author amzxyz
---@author Fidel Yin <fidel.yin@hotmail.com>

---@class EnglishUserDictAppenderState
---@field memory Memory?
---@field commit_notifier Connection?

---@diagnostic disable-next-line: duplicate-type
---@class Env
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
    local state = env.english_user_dict_appender_state
    assert(state)

    local memory = state.memory
    if not memory then
        return
    end

    -- Only handle commits in word-creation mode.
    local segment = ctx.composition:back()
    if not segment or not segment:has_tag("user_dict_appender") then
        return
    end

    local segments = ctx.composition:toSegmentation():get_segments()
    -- Skip if there are no real segments.
    -- The first segment is always the trigger segment, so the real segments start from the second one.
    if #segments < 2 then
        return
    end

    local commit_text = ctx:get_commit_text()
    if not is_english_phrase(commit_text) then
        return
    end

    -- Strip the trigger from the raw input to get the code body.
    local code = ctx.input:sub(segments[2].start + 1)
    -- Strip the surrounding whitespace from raw input.
    code = code:gsub("^%s+", ""):gsub("%s+$", "")

    if code == "" then
        return
    end

    -- Add the original-cased code to the user dictionary.
    memory:update_userdict(utils.make_dict_entry(commit_text, code), 1, "")

    -- Add the lowercased code to the user dictionary if it's different from the original.
    local lower_code = code:lower()
    if lower_code ~= code then
        memory:update_userdict(utils.make_dict_entry(commit_text, lower_code), 1, "")
    end
end

local F = {}

---@param env Env
function F.init(env)
    local context = env.engine.context

    ---@type Memory?
    local memory = nil
    ---@type Connection?
    local commit_notifier = nil

    memory = Memory(env.engine, env.engine.schema, "wanxiang_english")
    commit_notifier = context.commit_notifier:connect(function(ctx)
        commit_handler(ctx, env)
    end)

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

    env.english_user_dict_appender_state = nil
end

---@param input Translation
---@param env Env
function F.func(input, env)
    local context = env.engine.context

    -- Forced English word creation. A raw English candidate is provided at the top.
    local segments = context.composition:toSegmentation():get_segments()
    -- Only provide raw English candidate before any Chinese word is selected.
    -- Once a (partial) Chinese word selection is made, the composition splits into multiple segments, and the
    -- English candidate is no longer offered.
    -- The first segment is always the trigger segment, so the real segments start from the second one.
    if #segments == 2 then
        local code = context.input
        local code_start = segments[2].start -- index starts from 0
        local raw_text = code:sub(segments[2].start + 1)
        if is_english_phrase(raw_text) then
            yield(Candidate("english", code_start, #code, raw_text, ""))
        end
    end

    for cand in input:iter() do
        yield(cand)
    end
end

---@param segment Segment
---@return boolean
function F.tags_match(segment, _)
    return segment:has_tag("user_dict_appender")
end

return F
