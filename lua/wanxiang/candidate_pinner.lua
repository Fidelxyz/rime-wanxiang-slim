---Pin and unpin candidates that come from compiled dictionaries.
---
---Dependencies:
---  translators:
---    - table_translator@candidate_pinner
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

---@class CandidatePinnerFilterConfig
---@field enabled boolean

---@class CandidatePinnerTranslatorState
---@field memory Memory

---@diagnostic disable-next-line: duplicate-type
---@class Env
---@field candidate_pinner_processor_config CandidatePinnerProcessorConfig?
---@field candidate_pinner_processor_state CandidatePinnerProcessorState?
---@field candidate_pinner_filter_config CandidatePinnerFilterConfig?
---@field candidate_pinner_translator_state CandidatePinnerTranslatorState?

local wanxiang = require("wanxiang.wanxiang")
local candidate_code_recorder = require("wanxiang.candidate_code_recorder")

-- Candidate types that may be pinned.
-- Limited to entries that come straight from a compiled dictionary.
---@type table<string, boolean>
local PINNABLE_TYPES = {
    phrase = true,
    table = true,
}

---Construct a user dictionary entry for the candidate.
---@param text string
---@param code string
---@return DictEntry
local function make_entry(text, code)
    local entry = DictEntry()
    entry.text = text
    entry.custom_code = code .. " "
    entry.weight = 1
    return entry
end

local P = {}

---@param env Env
function P.init(env)
    local rime_config = env.engine.schema.config

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
        return wanxiang.RIME_PROCESS_RESULTS.kNoop
    end

    local config = env.candidate_pinner_processor_config
    assert(config)

    if not config.enabled then
        return wanxiang.RIME_PROCESS_RESULTS.kNoop
    end

    local pin = wanxiang.key_matches(key, config.pin_key)
    local unpin = wanxiang.key_matches(key, config.unpin_key)
    if not pin and not unpin then
        return wanxiang.RIME_PROCESS_RESULTS.kNoop
    end

    local context = env.engine.context
    local cand = context:get_selected_candidate()
    if not cand then
        return wanxiang.RIME_PROCESS_RESULTS.kNoop
    end

    -- Inspect the genuine candidate so wrappers don't hide the underlying type.
    local genuine = cand:get_genuine()
    if genuine.text == "" then
        return wanxiang.RIME_PROCESS_RESULTS.kNoop
    end

    -- Pinning enforces the dictionary-only policy. Unpinning falls through so resurfaced entries (emitted as `pinned`
    -- by the candidate_pinner filter) can still be removed.
    if pin and not PINNABLE_TYPES[genuine.type] then
        return wanxiang.RIME_PROCESS_RESULTS.kNoop
    end

    local code = candidate_code_recorder.get(genuine.text)
    if not code then
        return wanxiang.RIME_PROCESS_RESULTS.kNoop
    end

    local state = env.candidate_pinner_processor_state
    assert(state)

    if pin then
        -- Positive commits add or strengthen the entry.
        state.memory:update_userdict(make_entry(genuine.text, code), 1, "")
        log.info(("Pinned candidate '%s' with code '%s'"):format(genuine.text, code))
    else
        if state.memory:user_lookup(code, false) then
            -- Negative commits soft-delete the entry.
            state.memory:update_userdict(make_entry(genuine.text, code), -1, "")
            log.info(("Unpinned candidate '%s' with code '%s'"):format(genuine.text, code))
        end
    end

    context:refresh_non_confirmed_composition()
    return wanxiang.RIME_PROCESS_RESULTS.kAccepted
end

local F = {}

---@param env Env
function F.init(env)
    local rime_config = env.engine.schema.config

    local enabled = rime_config:get_bool("candidate_pinner/enabled")
    if enabled == nil then
        enabled = false
    end

    local memory = Memory(env.engine, env.engine.schema, "candidate_pinner")

    env.candidate_pinner_filter_config = {
        enabled = enabled,
    }

    env.candidate_pinner_translator_state = {
        memory = memory,
    }
end

---@param env Env
function F.fini(env)
    if env.candidate_pinner_translator_state then
        env.candidate_pinner_translator_state.memory:disconnect()
    end
    env.candidate_pinner_translator_state = nil
end

---@param translation Translation
---@param env Env
function F.func(translation, env)
    local state = env.candidate_pinner_translator_state
    assert(state)

    ---@type Candidate[]
    local pinned_cands = {}
    local pinned_cands_len = 0
    ---@type Candidate[]
    local regular_cands = {}
    local regular_cands_len = 0

    for cand in translation:iter() do
        -- Pin candidates that have a matching entry in the pinner memory.
        for entry in state.memory:useriter_lookup(cand.comment .. " ", true):iter() do
            if entry.text == cand.text then
                local genuine = cand:get_genuine()
                genuine.type = "pinned"
                pinned_cands_len = pinned_cands_len + 1
                pinned_cands[pinned_cands_len] = genuine
                goto continue
            end
        end

        regular_cands_len = regular_cands_len + 1
        regular_cands[regular_cands_len] = cand

        ::continue::
    end

    -- Yield pinned candidates first, then regular ones.
    for _, cand in ipairs(pinned_cands) do
        yield(cand)
    end
    for _, cand in ipairs(regular_cands) do
        yield(cand)
    end
end

---@param env Env
function F.tags_match(_, env)
    local config = env.candidate_pinner_filter_config
    assert(config)

    return config.enabled
end

return { P = P, F = F }
