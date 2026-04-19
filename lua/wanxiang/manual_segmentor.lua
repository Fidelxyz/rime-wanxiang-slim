---Providing a manual mechanism to cycle through alternative Pinyin syllable segmentations.
---@module "wanxiang.manual_segmentor"
---@author amzxyz
---@author Fidel Yin <fidel.yin@hotmail.com>

---@class ManualSegmentorConfig
---@field auto_delim string
---@field manual_delim string
---@field enabled boolean

---@class ManualSegmentorState
---@field code string?
---@field seg_patterns integer[][]?
---@field pattern_idx integer?

---@class Env
---@field manual_segmentor_config ManualSegmentorConfig?
---@field manual_segmentor_state ManualSegmentorState?

local wanxiang = require("wanxiang.wanxiang")

---Prebuilt segmentation patterns for short codes
---@type table<integer, integer[][]>
local SEG_PATTERNS_MAP = {
    [3] = { { 2, 1 }, { 1, 2 } },
    [4] = { { 2, 2 }, { 1, 3 }, { 3, 1 } },
    [5] = { { 2, 3 }, { 3, 2 } },
    [6] = { { 2, 2, 2 }, { 3, 3 } },
    [7] = { { 2, 2, 3 }, { 2, 3, 2 }, { 3, 2, 2 } },
    [8] = { { 2, 2, 2, 2 }, { 2, 3, 3 }, { 3, 2, 3 }, { 3, 3, 2 } },
    [10] = { { 2, 2, 2, 2, 2 } },
}

---Build segmentation patterns for longer codes (all combinations of 2 and 3).
---@param code_len integer
---@return integer[][]
local function build_seg_patterns(code_len)
    if code_len <= 10 then
        return SEG_PATTERNS_MAP[code_len]
    end

    ---@type integer[]
    local groups_2 = {}
    for _ = 1, math.floor(code_len / 2) do
        groups_2[#groups_2 + 1] = 2
    end
    if code_len % 2 ~= 0 then
        groups_2[#groups_2 + 1] = code_len % 2
    end

    ---@type integer[]
    local groups_3 = {}
    for _ = 1, math.floor(code_len / 3) do
        groups_3[#groups_3 + 1] = 3
    end
    if code_len % 3 ~= 0 then
        groups_3[#groups_3 + 1] = code_len % 3
    end

    return { groups_2, groups_3 }
end

---Escape special characters in a string for use in Lua patterns.
---@param ch string
---@return string
local function escp(ch)
    return (ch:gsub("(%W)", "%%%1"))
end

---Remove all occurrences of specific chars `manual_delim` and `auto_delim` from a string `s`.
---@param s string
---@param manual_delim string
---@param auto_delim string
---@return string
local function strip_delims(s, manual_delim, auto_delim)
    if manual_delim ~= "" then
        ---@type string
        s = s:gsub(escp(manual_delim), "")
    end
    if auto_delim ~= "" then
        ---@type string
        s = s:gsub(escp(auto_delim), "")
    end
    return s
end

---Apply the given segmentation pattern to the code and join segments with the manual delimiter.
---@param code string
---@param manual_delim string
---@param segmentation integer[]
---@return string
local function apply_segmentation(code, manual_delim, segmentation)
    if #segmentation == 0 then
        return code
    end

    ---@type string[]
    local segments = {}
    local i = 1
    for _, segment_len in ipairs(segmentation) do
        segments[#segments + 1] = code:sub(i, i + segment_len - 1)
        i = i + segment_len
    end
    return table.concat(segments, manual_delim)
end

---Parse and serialize the current segmentation of the input code.
---@param input string
---@param manual_delim string
---@param auto_delim string
---@return number[]
local function parse_segmentation(input, manual_delim, auto_delim)
    ---@type number[]
    local segments = {}

    local seg_len = 0
    for i = 1, #input do
        local char = input:sub(i, i)
        if char == manual_delim or char == auto_delim then
            if seg_len ~= 0 then
                segments[#segments + 1] = seg_len
                seg_len = 0
            end
        else
            seg_len = seg_len + 1
        end
    end
    if seg_len ~= 0 then
        segments[#segments + 1] = seg_len
    end

    return segments
end

---@param a integer[]
---@param b integer[]
---@return boolean
local function compare_lists(a, b)
    if #a ~= #b then
        return false
    end

    for i = 1, #a do
        if a[i] ~= b[i] then
            return false
        end
    end
    return true
end

---Find the index of the given segmentation in the list of all segmentations, or return nil if not found.
---@param seg_patterns integer[][]
---@param segments integer[]
---@return integer?
local function find_segmentation(seg_patterns, segments)
    for i, curr_segments in ipairs(seg_patterns) do
        if compare_lists(curr_segments, segments) then
            return i
        end
    end
    return nil
end

local P = {}

---@param env Env
function P.init(env)
    local rime_config = env.engine.schema.config

    local delim = rime_config:get_string("speller/delimiter") or " '"

    local auto_delim = delim:sub(1, 1)
    local manual_delim = delim:sub(2, 2)

    local enabled = rime_config:get_bool("manual_segmentor/enabled")
    if enabled == nil then
        enabled = true
    end

    env.manual_segmentor_config = {
        auto_delim = auto_delim,
        manual_delim = manual_delim,
        enabled = enabled,
    }

    env.manual_segmentor_state = {
        code = nil,
        code_len = nil,
        input_head = nil,
        pattern_idx = nil,
    }
end

---@param env Env
function P.fini(env)
    env.manual_segmentor_config = nil
    env.manual_segmentor_state = nil
end

---@param key KeyEvent
---@param env Env
---@return integer
function P.func(key, env)
    local config = env.manual_segmentor_config
    assert(config)

    if not config.enabled then
        return wanxiang.RIME_PROCESS_RESULTS.kNoop
    end

    local keycode = key.keycode
    if keycode ~= config.manual_delim:byte() then
        return wanxiang.RIME_PROCESS_RESULTS.kNoop
    end

    local context = env.engine.context

    if context.composition:empty() then
        return wanxiang.RIME_PROCESS_RESULTS.kNoop
    end

    -- Append a manual delimiter if not already present
    if context.input:sub(-1) ~= config.manual_delim then
        context.input = context.input .. config.manual_delim
        return wanxiang.RIME_PROCESS_RESULTS.kAccepted
    end
    -- Start cycling through segmentation patterns for the second and subsequent delimiter presses

    local state = env.manual_segmentor_state
    assert(state)

    -- Current input states
    local input = context.input
    local code = strip_delims(input, config.manual_delim, config.auto_delim)
    local code_len = #code

    -- Reset state if code changed
    if state.code ~= code then
        state.code = code
        state.seg_patterns = build_seg_patterns(code_len)
        state.pattern_idx = nil
    end

    local seg_patterns = state.seg_patterns
    if not seg_patterns then
        return wanxiang.RIME_PROCESS_RESULTS.kAccepted
    end

    local pattern_idx = state.pattern_idx
    if not pattern_idx then
        -- Get the initial pattern index based on the last segmentation result, if available
        local segmentation = parse_segmentation(input, config.manual_delim, config.auto_delim)
        pattern_idx = find_segmentation(seg_patterns, segmentation)
    end

    ---@type integer?
    local new_pattern_idx
    local seg_patterns_num = #seg_patterns
    if pattern_idx then
        -- If the current segmentation matches a known pattern, cycle to the next pattern
        -- new_pattern_idx = ((pattern_idx + 1) - 1) % seg_patterns_num + 1
        new_pattern_idx = pattern_idx % seg_patterns_num + 1
        if new_pattern_idx == 1 then
            new_pattern_idx = nil
        end
    else
        -- If the current segmentation does not match any known pattern, start from the first pattern
        new_pattern_idx = 1
    end
    state.pattern_idx = new_pattern_idx

    context.input = apply_segmentation(code, config.manual_delim, seg_patterns[new_pattern_idx] or {})
        .. config.manual_delim
    return wanxiang.RIME_PROCESS_RESULTS.kAccepted
end

return P
