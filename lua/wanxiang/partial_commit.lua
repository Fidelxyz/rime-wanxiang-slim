-- @amzxyz  https://github.com/amzxyz/rime_wanxiang
-- Ctrl+1..9,0：上屏首选前 N 字；按 preedit/script_text 的前 N 音节对齐 raw input
local wanxiang = require("wanxiang/wanxiang")

local M = {}

-- 数字键映射（主键盘 + 小键盘）
local DIGIT = {
    [0x31] = 1,
    [0x32] = 2,
    [0x33] = 3,
    [0x34] = 4,
    [0x35] = 5,
    [0x36] = 6,
    [0x37] = 7,
    [0x38] = 8,
    [0x39] = 9,
    [0x30] = 10,
}
local KP = {
    [0xFFB1] = 1,
    [0xFFB2] = 2,
    [0xFFB3] = 3,
    [0xFFB4] = 4,
    [0xFFB5] = 5,
    [0xFFB6] = 6,
    [0xFFB7] = 7,
    [0xFFB8] = 8,
    [0xFFB9] = 9,
    [0xFFB0] = 10,
}

-- 工具：安全获取 UTF-8 字符
local function get_utf8_char(str, index)
    if not str or str == "" then
        return nil
    end
    local start_byte = utf8.offset(str, index)
    if not start_byte then
        return nil
    end
    local end_byte = utf8.offset(str, index + 1)
    return string.sub(str, start_byte, (end_byte and end_byte - 1) or nil)
end

-- 工具：获取分隔符
local function get_delimiters(ctx)
    local cfg = ctx.engine and ctx.engine.schema and ctx.engine.schema.config
    local delimiter = (cfg and cfg:get_string("speller/delimiter")) or " '"
    return get_utf8_char(delimiter, 1) or " ", get_utf8_char(delimiter, 2) or "'"
end

-- 放进字符类 [...] 使用的转义（只转义 % ^ ] -）
local function esc_class(c)
    if not c or c == "" then
        return ""
    end
    return (c:gsub("([%%%^%]%-])", "%%%1"))
end

-- 普通模式串位置的单字符转义
local function esc_pat(s)
    if not s or s == "" then
        return ""
    end
    return (s:gsub("[%^%$%(%)%%%.%[%]%*%+%-%?]", "%%%1"))
end

-- 清洗整串 raw：去掉手动分隔符
local function clean_raw(ctx, raw)
    if not raw or raw == "" then
        return ""
    end
    local _, manual = get_delimiters(ctx)
    if manual and manual ~= "" then
        raw = raw:gsub(esc_pat(manual), "")
    end
    return raw
end

-- 取候选前 n 个字符
local function utf8_head(s, n)
    if not s or s == "" or n <= 0 then
        return ""
    end
    local offset = utf8.offset(s, n + 1)
    return offset and s:sub(1, offset - 1) or s
end

-- 生成 target：按分隔符切 preedit/script_text，取前 n 个并去分隔符拼接
local function script_prefix(ctx, n)
    local raw_in = ctx.input or ""
    local prop_key = ctx:get_property("sequence_preedit_key") or ""
    local prop_val = ctx:get_property("sequence_preedit_val") or ""
    local script_txt = ctx:get_script_text() or ""

    local s
    if prop_key == raw_in and prop_val ~= "" then
        s = prop_val
    else
        s = script_txt
    end
    if s == "" then
        return ""
    end

    local auto, manual = get_delimiters(ctx)
    local pat = "[^" .. esc_class(auto) .. esc_class(manual) .. "%s]+"

    local parts = {}
    for w in s:gmatch(pat) do
        parts[#parts + 1] = w
    end
    if #parts == 0 then
        return ""
    end

    local upto = math.min(n, #parts)
    local target = table.concat({ table.unpack(parts, 1, upto) }, "")
    return target
end

-- 对齐“去分隔符后的 raw_clean”与 target；返回消耗长度（基于 raw_clean）
local function eat_len_by_target(ctx, target)
    if target == "" then
        return 0
    end
    local raw = ctx.input or ""
    if raw == "" then
        return 0
    end
    local clean = clean_raw(ctx, raw)
    local i, j, Lc, Lt = 1, 1, #clean, #target
    while i <= Lc and j <= Lt do
        if clean:sub(i, i) ~= target:sub(j, j) then
            return 0
        end
        i, j = i + 1, j + 1
    end
    if j <= Lt then
        return 0
    end
    return i - 1
end

local function set_pending(env, rest)
    env._cpc_pending_rest = rest or ""
end
local function has_pending(env)
    return type(env._cpc_pending_rest) == "string" and env._cpc_pending_rest ~= nil
end
local function take_pending(env)
    local r = env._cpc_pending_rest
    env._cpc_pending_rest = nil
    return r
end

function M.init(env)
    local ctx = env.engine.context

    env._cpc_update_conn = ctx.update_notifier:connect(function(c)
        if not has_pending(env) then
            return
        end
        local rest = take_pending(env) or ""

        c.input = rest
        if c.clear_non_confirmed_composition then
            c:clear_non_confirmed_composition()
        end
        if c.caret_pos ~= nil then
            c.caret_pos = #rest
        end
    end)

    env._cpc_key_handler = function(key)
        if not key:ctrl() or key:release() then
            return wanxiang.RIME_PROCESS_RESULTS.kNoop
        end

        local n = DIGIT[key.keycode] or KP[key.keycode]
        if not n then
            return wanxiang.RIME_PROCESS_RESULTS.kNoop
        end

        local c = env.engine.context
        if not c:is_composing() then
            return wanxiang.RIME_PROCESS_RESULTS.kNoop
        end

        local cand = c:get_selected_candidate() or c:get_candidate(0)
        if not cand or not cand.text or #cand.text == 0 then
            return wanxiang.RIME_PROCESS_RESULTS.kNoop
        end

        local head = utf8_head(cand.text, n)
        if head == "" then
            return wanxiang.RIME_PROCESS_RESULTS.kNoop
        end

        local target = script_prefix(c, n)
        if target == "" then
            return wanxiang.RIME_PROCESS_RESULTS.kNoop
        end

        local consumed = eat_len_by_target(c, target)
        if consumed == 0 then
            return wanxiang.RIME_PROCESS_RESULTS.kNoop
        end

        local raw_clean = clean_raw(c, c.input or "")
        local rest = raw_clean:sub(consumed + 1)

        env.engine:commit_text(head)
        set_pending(env, rest)
        c:refresh_non_confirmed_composition()

        return wanxiang.RIME_PROCESS_RESULTS.kAccepted
    end
end

function M.fini(env)
    if env._cpc_update_conn then
        env._cpc_update_conn:disconnect()
        env._cpc_update_conn = nil
    end
    env._cpc_key_handler = nil
end

function M.func(key, env)
    if not env._cpc_key_handler then
        return wanxiang.RIME_PROCESS_RESULTS.kNoop
    end
    return env._cpc_key_handler(key)
end

return M
