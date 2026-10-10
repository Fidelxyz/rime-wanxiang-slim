---Pin and unpin candidates that come from compiled dictionaries.
---
---Dependencies:
---  translators:
---    - lua_translator@*wanxiang.candidate_pinner*T (before the main translator)
---  filters:
---    - lua_filter@*wanxiang.candidate_code_recorder*F
---
---@author Fidel Yin <fidel.yin@hotmail.com>

---@class CandidatePinnerProcessorConfig
---@field enabled boolean
---@field pin_key string?
---@field unpin_key string?

---@class CandidatePinnerProcessorState
---@field memory Memory

---@class CandidatePinnerTranslatorConfig
---@field enabled boolean

---@class CandidatePinnerTranslatorState
---@field translator ScriptTranslator?

---@diagnostic disable-next-line: duplicate-type
---@class Env
---@field candidate_pinner_processor_config CandidatePinnerProcessorConfig?
---@field candidate_pinner_processor_state CandidatePinnerProcessorState?
---@field candidate_pinner_translator_config CandidatePinnerTranslatorConfig?
---@field candidate_pinner_translator_state CandidatePinnerTranslatorState?

local utils = require("utils.utils")
local candidate_code_recorder = require("wanxiang.candidate_code_recorder")

-- Candidate types that may be pinned.
-- Limited to entries that come straight from a compiled dictionary.
---@type table<string, boolean>
local PINNABLE_TYPES = {
    phrase = true,
    table = true,
}

local P = {}

---@param env Env
function P.init(env)
    local rime_config = env.engine.schema.config
    assert(rime_config)

    local enabled = rime_config:get_bool("candidate_pinner/enabled")
    if enabled == nil then
        enabled = false
    end
    if enabled then
        candidate_code_recorder.enable()
    end

    local pin_key = rime_config:get_string("candidate_pinner/pin_key")
    if pin_key == "" then
        pin_key = nil
    end

    local unpin_key = rime_config:get_string("candidate_pinner/unpin_key")
    if unpin_key == "" then
        unpin_key = nil
    end

    env.candidate_pinner_processor_config = {
        pin_key = pin_key,
        unpin_key = unpin_key,
        enabled = enabled,
    }

    env.candidate_pinner_processor_state = {
        memory = Memory(env.engine, env.engine.schema, "candidate_pinner"),
    }
end

---@param env Env
function P.fini(env)
    if env.candidate_pinner_processor_state then
        env.candidate_pinner_processor_state.memory:disconnect()
    end
    env.candidate_pinner_processor_config = nil
    env.candidate_pinner_processor_state = nil
end

---@param key KeyEvent
---@param env Env
---@return ProcessResult
function P.func(key, env)
    if key:release() then
        return utils.RIME_PROCESS_RESULTS.kNoop
    end

    local config = env.candidate_pinner_processor_config
    assert(config)

    if not config.enabled then
        return utils.RIME_PROCESS_RESULTS.kNoop
    end

    local pin = utils.key_matches(key, config.pin_key)
    local unpin = utils.key_matches(key, config.unpin_key)
    if not pin and not unpin then
        return utils.RIME_PROCESS_RESULTS.kNoop
    end

    local context = env.engine.context
    local cand = context:get_selected_candidate()
    if not cand then
        return utils.RIME_PROCESS_RESULTS.kNoop
    end

    -- Inspect the genuine candidate so wrappers don't hide the underlying type.
    local genuine = cand:get_genuine()
    if genuine.text == "" then
        return utils.RIME_PROCESS_RESULTS.kNoop
    end

    -- Pinning enforces the dictionary-only policy. Unpinning falls through so resurfaced entries (emitted as `pinned`
    -- by the candidate_pinner translator) can still be removed.
    if pin and not PINNABLE_TYPES[genuine.type] then
        return utils.RIME_PROCESS_RESULTS.kNoop
    end

    local code = candidate_code_recorder.get(genuine.text)
    if not code then
        return utils.RIME_PROCESS_RESULTS.kNoop
    end

    local state = env.candidate_pinner_processor_state
    assert(state)

    if pin then
        -- Positive commits add or strengthen the entry.
        local entry = utils.make_dict_entry(genuine.text, code)
        local commits = 1
        local prefix = ""
        if not state.memory:update_userdict(entry, commits, prefix) then
            log.error(
                (
                    "candidate_pinner: update_userdict failed: "
                    .. "namespace=%q, text=%q, custom_code=%q, commits=%d, prefix=%q"
                ):format("candidate_pinner", entry.text, entry.custom_code, commits, prefix)
            )
            return utils.RIME_PROCESS_RESULTS.kAccepted
        end
        log.info(("candidate_pinner: pinned candidate '%s' with code '%s'"):format(genuine.text, code))
    else
        if state.memory:user_lookup(code, false) then
            -- Negative commits soft-delete the entry.
            local entry = utils.make_dict_entry(genuine.text, code)
            local commits = -1
            local prefix = ""
            if not state.memory:update_userdict(entry, commits, prefix) then
                log.error(
                    (
                        "candidate_pinner: update_userdict failed: "
                        .. "namespace=%q, text=%q, custom_code=%q, commits=%d, prefix=%q"
                    ):format("candidate_pinner", entry.text, entry.custom_code, commits, prefix)
                )
                return utils.RIME_PROCESS_RESULTS.kAccepted
            end
            log.info(("candidate_pinner: unpinned candidate '%s' with code '%s'"):format(genuine.text, code))
        end
    end

    context:refresh_non_confirmed_composition()
    return utils.RIME_PROCESS_RESULTS.kAccepted
end

local T = {}

---@param env Env
function T.init(env)
    local rime_config = env.engine.schema.config
    assert(rime_config)

    local enabled = rime_config:get_bool("candidate_pinner/enabled")
    if enabled == nil then
        enabled = false
    end

    env.candidate_pinner_translator_config = {
        enabled = enabled,
    }

    local translator =
        Component.ScriptTranslator(env.engine, env.engine.schema, "candidate_pinner", "script_translator")
    if translator then
        -- Only the processor writes pinned entries; committing candidates must not add entries automatically.
        translator:set_memorize_callback(
            ---@return boolean
            function(_, _)
                return true
            end
        )
    else
        log.error("candidate_pinner: failed to create script translator")
    end

    env.candidate_pinner_translator_state = {
        translator = translator,
    }
end

---@param env Env
function T.fini(env)
    local state = env.candidate_pinner_translator_state
    assert(state)
    if state.translator then
        state.translator:disconnect()
    end
    env.candidate_pinner_translator_state = nil
    env.candidate_pinner_translator_config = nil
end

---@param input string
---@param segment Segment
---@param env Env
function T.func(input, segment, env)
    local config = env.candidate_pinner_translator_config
    assert(config)
    if not config.enabled then
        return
    end

    local state = env.candidate_pinner_translator_state
    assert(state)
    if not state.translator then
        return
    end

    -- The dictionary prism maps valid input spellings to the original codes stored in pinned.userdb.
    local translation = state.translator:query(input, segment)
    if not translation then
        return
    end

    for cand in translation:iter() do
        -- Ignore system entries and pinned prefixes of a longer input segment.
        if cand.type == "user_phrase" and cand.start == segment.start and cand._end == segment._end then
            local pinned = Candidate("pinned", cand.start, cand._end, cand.text, cand.comment)
            pinned.preedit = cand.preedit
            pinned.quality = 100
            yield(pinned)
        end
    end
end

return { P = P, T = T }
