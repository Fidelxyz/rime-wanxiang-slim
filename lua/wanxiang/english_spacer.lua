---Adds spaces around committed English words (Smart Spacing) and tracks spacing state across commits.
---
---@author amzxyz
---@author Fidel Yin <fidel.yin@hotmail.com>

---@class EnglishSpacerConfig
---@field english_spacing_mode EnglishSpacingMode
---@field spacing_timeout number For smart mode only.

---@class EnglishSpacerState
---@field is_prev_commit_english boolean For smart mode only.
---@field last_commit_time number For smart mode only.
---@field comp_start_time number? For smart mode only.
---
---@field update_notifier Connection? For smart mode only.
---@field commit_notifier Connection? For smart mode only.

---@diagnostic disable-next-line: duplicate-type
---@class Env
---@field english_spacer_config EnglishSpacerConfig?
---@field english_spacer_state EnglishSpacerState?

---@enum EnglishSpacingMode
local EnglishSpacingMode = {
    OFF = 0,
    SMART = 1,
    BEFORE = 2,
    AFTER = 3,
}

local utils = require("utils.utils")

---@param env Env
---@return EnglishSpacerConfig
local function read_config(env)
    local config = env.engine.schema.config

    local english_spacing_mode_str = config:get_string("wanxiang_english/english_spacing")
    local english_spacing_mode
    if english_spacing_mode_str == "off" then
        english_spacing_mode = EnglishSpacingMode.OFF
    elseif english_spacing_mode_str == "smart" then
        english_spacing_mode = EnglishSpacingMode.SMART
    elseif english_spacing_mode_str == "before" then
        english_spacing_mode = EnglishSpacingMode.BEFORE
    elseif english_spacing_mode_str == "after" then
        english_spacing_mode = EnglishSpacingMode.AFTER
    else
        english_spacing_mode = EnglishSpacingMode.OFF
        log.warning(
            ("Invalid config value for wanxiang_english/english_spacing: %s. Defaulting to 'off'."):format(
                english_spacing_mode_str
            )
        )
    end

    local spacing_timeout = config:get_double("wanxiang_english/spacing_timeout") or 0

    return {
        english_spacing_mode = english_spacing_mode,
        spacing_timeout = spacing_timeout,
    }
end

local P = {}

---@param env Env
function P.init(env)
    env.english_spacer_config = read_config(env)
end

---@param env Env
function P.fini(env)
    env.english_spacer_config = nil
end

---@param key_event KeyEvent
---@param env Env
---@return ProcessResult
function P.func(key_event, env)
    if key_event:release() then
        return utils.RIME_PROCESS_RESULTS.kNoop
    end

    local config = env.english_spacer_config
    assert(config)

    -- The processor is for smart mode only.
    if config.english_spacing_mode ~= EnglishSpacingMode.SMART then
        return utils.RIME_PROCESS_RESULTS.kNoop
    end

    local context = env.engine.context
    local keycode = key_event.keycode

    if context.composition:empty() then
        if keycode == 0xff0d or keycode == 0xff8d or keycode == 0x20 then
            context:set_property("reset_english_spacing", "true")
        end
    end

    return utils.RIME_PROCESS_RESULTS.kNoop
end

local F = {}

---@param env Env
function F.init(env)
    local config = read_config(env)

    ---@type Connection?
    local update_notifier = nil
    ---@type Connection?
    local commit_notifier = nil

    if config.english_spacing_mode == EnglishSpacingMode.SMART then
        update_notifier = env.engine.context.update_notifier:connect(function(ctx)
            local state = env.english_spacer_state
            assert(state)

            local input = ctx.input

            if input == "" then
                state.comp_start_time = nil
            elseif state.comp_start_time == nil then
                state.comp_start_time = utils.now()
            end
        end)

        commit_notifier = env.engine.context.commit_notifier:connect(function(ctx)
            local state = env.english_spacer_state
            assert(state)

            -- Whitespace is stripped from the commit text.
            local commit_text = ctx:get_commit_text():gsub("%s", "")
            local is_english = utils.is_english_phrase(commit_text)

            state.is_prev_commit_english = is_english
            if is_english then
                state.last_commit_time = utils.now()
            else
                state.last_commit_time = 0
            end
            ctx:set_property("reset_english_spacing", "")
        end)
    end

    env.english_spacer_config = config

    env.english_spacer_state = {
        is_prev_commit_english = false,
        last_commit_time = 0,
        comp_start_time = nil,
        update_notifier = update_notifier,
        commit_notifier = commit_notifier,
    }
end

---@param env Env
function F.fini(env)
    assert(env.english_spacer_state)

    if env.english_spacer_state.update_notifier then
        env.english_spacer_state.update_notifier:disconnect()
    end
    if env.english_spacer_state.commit_notifier then
        env.english_spacer_state.commit_notifier:disconnect()
    end

    env.english_spacer_config = nil
    env.english_spacer_state = nil
end

---@param input Translation
---@param env Env
function F.func(input, env)
    local config = env.english_spacer_config
    assert(config)
    local state = env.english_spacer_state
    assert(state)

    local mode = config.english_spacing_mode

    for cand in input:iter() do
        local text = cand.text
        if text == "" or not utils.is_english_phrase(text) then
            yield(cand)
            goto continue
        end

        local changed = false

        -- For smart mode, is_prev_commit_english is checked in the tags_match function.
        if mode == EnglishSpacingMode.SMART or mode == EnglishSpacingMode.BEFORE then
            if not text:find("^%s") then
                text = " " .. text
                changed = true
            end
        elseif mode == EnglishSpacingMode.AFTER then
            if not text:find("%s$") then
                text = text .. " "
                changed = true
            end
        end

        if changed then
            local new_cand = Candidate(cand.type, cand.start, cand._end, text, cand.comment)
            new_cand.preedit = cand.preedit
            yield(new_cand)
        else
            yield(cand)
        end

        ::continue::
    end
end

---@param env Env
---@return boolean
function F.tags_match(_, env)
    local config = env.english_spacer_config
    assert(config)

    if config.english_spacing_mode == EnglishSpacingMode.OFF then
        return false
    end

    local context = env.engine.context
    local state = env.english_spacer_state
    assert(state)

    -- Check for smart mode.
    if config.english_spacing_mode == EnglishSpacingMode.SMART then
        -- Handle the reset of the English spacing state.
        if state.is_prev_commit_english then
            if context:get_property("reset_english_spacing") == "true" then
                state.is_prev_commit_english = false
            elseif config.spacing_timeout > 0 then
                -- Reset the English spacing state if the time since the last commit exceeds the timeout.
                local comp_start_time = state.comp_start_time or utils.now()
                if comp_start_time - state.last_commit_time > config.spacing_timeout then
                    state.is_prev_commit_english = false
                end
            end
        end

        -- Only apply spacing if the previous commit was an English word.
        if not state.is_prev_commit_english then
            return false
        end
    end

    return true
end

return { P = P, F = F }
