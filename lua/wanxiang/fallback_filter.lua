---Records the first single-character Chinese candidate at segment length 2.
---When segment length is 3 and no candidates arrive from upstream, yields the
---recorded character as a lightweight fallback candidate with a split preedit.
---@author amzxyz
---@author Fidel Yin <fidel.yin@hotmail.com>

---@class FallbackFilterState
---@field last_2code_char string?

---@diagnostic disable-next-line: duplicate-type
---@class Env
---@field fallback_filter_state FallbackFilterState?

---Byte-level scan for ASCII letters (A-Z, a-z).
---Returns true as soon as any letter byte is found.
---@param s string
---@return boolean
local function has_english_token_fast(s)
    local len = #s
    for i = 1, len do
        local b = s:byte(i)
        if b < 0x80 then
            -- A-Z (0x41-0x5A) or a-z (0x61-0x7A)
            if (b >= 0x41 and b <= 0x5A) or (b >= 0x61 and b <= 0x7A) then
                return true
            end
        end
    end
    return false
end

local M = {}

---@param env Env
function M.init(env)
    env.fallback_filter_state = {
        last_2code_char = nil,
    }
end

---@param env Env
function M.fini(env)
    env.fallback_filter_state = nil
end

---Pass through all candidates while tracking the first single Chinese character
---at segment length 2. When segment length is 3 and no candidates exist, yield
---the recorded character as a fallback with a split preedit ("ab c").
---@param translation Translation
---@param env Env
function M.func(translation, env)
    local context = env.engine.context

    local state = env.fallback_filter_state
    assert(state)

    local code = context.input
    local comp = context.composition

    -- Compute current segment length from composition.
    local seg = comp:back()
    local code_len = seg and (seg._end - seg.start) or 0

    -- Clear fallback data and skip when segment is too short.
    if code_len <= 1 then
        state.last_2code_char = nil
        for cand in translation:iter() do
            yield(cand)
        end
        return
    end

    local count = 0

    for cand in translation:iter() do
        -- At segment length 2, record the first single Chinese character.
        if count == 0 and code_len == 2 then
            local txt = cand.text
            if (utf8.len(txt) or 0) == 1 and not has_english_token_fast(txt) then
                state.last_2code_char = txt
            end
        end

        yield(cand)
        count = count + 1
    end

    -- Three-code empty-candidate fallback: yield the recorded character.
    if count == 0 and code_len == 3 then
        assert(seg)
        local fallback_text = state.last_2code_char
        if fallback_text then
            local start_pos = seg.start
            local end_pos = seg._end
            local new_cand = Candidate("fallback", start_pos, end_pos, fallback_text, "")

            -- Split preedit: "abc" → "ab c"
            local seg_str = code:sub(start_pos + 1, end_pos)
            if #seg_str >= 3 then
                new_cand.preedit = seg_str:sub(1, 2) .. " " .. seg_str:sub(3)
            else
                new_cand.preedit = seg_str
            end

            yield(new_cand)
        end
    end
end

return M
