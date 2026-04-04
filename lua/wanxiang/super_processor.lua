-- Features:
-- RepeatLimit: 重复限制
-- KpNumber: 小键盘
-- SuperSegmentation: 超强分词
-- BackspaceLimit: 退格限制

---@class SuperProcessorConfig
---
---Config for RepeatLimit
---@field limit_repeated_enabled boolean
---@field backspace_limit_enabled boolean
---@field seg_loop_enabled boolean
---@field predict_space_enabled boolean
---@field max_repeat integer
---@field max_segments integer
---
---Config for KpNumber
---@field kp_page_size integer
---@field kp_mode "auto"|"compose"
---@field kp_func_patterns string[]
---
---Config for SuperSegmentation
---@field seg_auto_delim string
---@field seg_manual_delim string

---@class SuperProcessorState
---
---States for BackspaceLimit
---@field bs_prev_len integer
---@field bs_sequence boolean
---
---States for KpNumber
---@field kp_is_composing boolean
---@field kp_has_menu boolean
---
---States for SuperSegmentation
---@field seg_core string?
---@field seg_start_idx integer?
---@field seg_n integer?
---@field seg_base string?
---@field seg_last_preedit_lens number[]
---@field seg_last_input_caret string?
---@field seg_last_caret_pos integer?
---
---States for PredictSpace
---@field pending_predict_space boolean
---
---@field conn_update Connection

---@class Env
---@field super_processor_config SuperProcessorConfig?
---@field super_processor_state SuperProcessorState?

local wanxiang = require("wanxiang.wanxiang")

-- [KpNumber] 小键盘键码映射
local KP_MAP = {
    [0xFFB1] = 1,
    [0xFFB2] = 2,
    [0xFFB3] = 3,
    [0xFFB4] = 4,
    [0xFFB5] = 5,
    [0xFFB6] = 6,
    [0xFFB7] = 7,
    [0xFFB8] = 8,
    [0xFFB9] = 9,
    [0xFFB0] = 0,
}

-- [RepeatLimit] 重复限制默认配置 (现已支持配置覆盖)
local INITIALS = "[bpmfdtnlgkhjqxrzcsywiu]"

---[SuperSegmentation] 分词模式配置
---@type table<number, { all: number[][] }>
local SEG_PATTERNS = {
    [3] = { all = { { 2, 1 }, { 1, 2 } } },
    [4] = { all = { { 2, 2 }, { 1, 3 }, { 3, 1 } } },
    [5] = { all = { { 2, 3 }, { 3, 2 } } },
    [6] = { all = { { 2, 2, 2 }, { 3, 3 } } },
    [7] = { all = { { 2, 2, 3 }, { 2, 3, 2 }, { 3, 2, 2 } } },
    [8] = { all = { { 2, 2, 2, 2 }, { 2, 3, 3 }, { 3, 2, 3 }, { 3, 3, 2 } } },
    [10] = { all = { { 2, 2, 2, 2, 2 } } },
}

---字符串转义
---@param ch string
---@return string
local function escp(ch)
    return (ch:gsub("(%W)", "%%%1"))
end

---数组求和
---@param a number[]
---@return number
local function sum(a)
    local s = 0
    for _, v in ipairs(a) do
        s = s + v
    end
    return s
end

---表键生成
---@param list any[]
---@return string
local function key_of(list)
    return table.concat(list, ",")
end

---列表查找索引
---@param list table[]
---@param key string
---@return number?
local function find_idx(list, key)
    for i, t in ipairs(list) do
        if key_of(t) == key then
            return i
        end
    end
end

---统计末尾指定字符数量
---@param s string
---@param ch string
---@return number
local function count_trailing(s, ch)
    local n = 0
    for i = #s, 1, -1 do
        if s:sub(i, i) == ch then
            n = n + 1
        else
            break
        end
    end
    return n
end

---移除末尾指定字符
---@param s string
---@param ch string
---@return string
local function strip_trailing(s, ch)
    return (s:gsub(escp(ch) .. "+$", ""))
end

---移除分隔符 (自动和手动)
---@param s string
---@param md string
---@param ad string
---@return string
local function strip_delims(s, md, ad)
    if md ~= "" then
        s = s:gsub(escp(md), "")
    end
    if ad ~= "" then
        s = s:gsub(escp(ad), "")
    end
    return s
end

---根据分组重构字符串
---@param core string
---@param ch_manual string
---@param groups number[]
---@return string
local function build_by_groups(core, ch_manual, groups)
    if not groups or #groups == 0 or sum(groups) ~= #core then
        return core
    end

    ---@type string[]
    local out = {}
    local i = 1
    for gi, g in ipairs(groups) do
        out[#out + 1] = core:sub(i, i + g - 1)
        i = i + g
        if gi < #groups then
            out[#out + 1] = ch_manual
        end
    end
    return table.concat(out)
end

---从字符串解析分段长度
---@param s string?
---@param md string
---@param ad string
---@return number[]
local function lens_from_string(s, md, ad)
    if not s or s == "" then
        return {}
    end

    ---@type string[]
    local segs = {}
    ---@type string[]
    local buf = {}

    local function flush()
        if #buf > 0 then
            segs[#segs + 1] = table.concat(buf)
            buf = {}
        end
    end

    for i = 1, #s do
        local c = s:sub(i, i)
        if c == md or c == ad or c == " " then
            flush()
        else
            local b = c:byte()
            if b and ((b >= 65 and b <= 90) or (b >= 97 and b <= 122)) then
                buf[#buf + 1] = string.char(b):lower()
            end
        end
    end

    flush()

    if #segs == 0 then
        return {}
    end

    ---@type integer[]
    local lens = {}
    for _, seg in ipairs(segs) do
        lens[#lens + 1] = #seg
    end
    return lens
end

---获取缓存的分段长度
---@param md string
---@param ad string
---@param state SuperProcessorState
---@param ctx Context
---@return number[]
local function get_cached_lens(md, ad, state, ctx)
    local lens = state.seg_last_preedit_lens
    if #lens > 0 then
        return lens
    end
    local seg = ctx.composition:back()
    local cand = seg and seg:get_selected_candidate()
    return lens_from_string(cand and cand.preedit, md, ad)
end

---增强版 UTF-8 长度计算 (Super Segmentation 使用)
---@param s string
---@return number
local function utf8_len(s)
    return utf8.len(s) or #s
end

---检查数字后是否紧跟功能编码 (KpNumber 使用)
---@param digit_char string
---@param config SuperProcessorConfig
---@param ctx Context
---@return boolean
local function is_function_code_after_digit(digit_char, config, ctx)
    if digit_char == "" then
        return false
    end
    local s = ctx.input .. digit_char
    for _, pattern in ipairs(config.kp_func_patterns) do
        if s:match(pattern) then
            return true
        end
    end
    return false
end

---计算尾部重复字符数 (RepeatLimit 使用)
---@param s string
---@return string, number
local function tail_rep(s)
    local last, n = s:sub(-1), 1
    for i = #s - 1, 1, -1 do
        if s:sub(i, i) == last then
            n = n + 1
        else
            break
        end
    end
    return last, n
end

---设置候选框提示 (RepeatLimit 使用)
---@param ctx Context
---@param msg string
local function prompt(ctx, msg)
    local comp = ctx.composition
    if not comp:empty() then
        comp:back().prompt = msg
    end
end

-- 4. 逻辑分发处理

-- [PredictSpace] 联想空格接力起跑点
---@param config SuperProcessorConfig
---@param state SuperProcessorState
---@param ctx Context
---@return boolean
local function handle_predict_space(config, state, ctx)
    if not config.predict_space_enabled then
        return false
    end
    if (not ctx:is_composing() or ctx.input == "") and ctx:has_menu() then
        state.pending_predict_space = true
        ctx:set_option("_dummy_predict_update", true)
        return true
    end
    return false
end

-- [SuperSegmentation] 处理分词符 '
---@param key KeyEvent
---@param config SuperProcessorConfig
---@param state SuperProcessorState
---@param ctx Context
---@return boolean
local function handle_segmentation(key, config, state, ctx)
    if not config.seg_loop_enabled then
        return false
    end

    if key.keycode ~= config.seg_manual_delim:byte() then
        state.seg_core, state.seg_start_idx, state.seg_n, state.seg_base = nil, nil, nil, nil
        return false
    end

    if ctx.composition:empty() then
        return false
    end

    local last_input = state.seg_last_input_caret or ctx.input
    local last_caret = state.seg_last_caret_pos
    if not last_caret or last_caret ~= utf8_len(last_input) then
        state.seg_core, state.seg_start_idx, state.seg_n, state.seg_base = nil, nil, nil, nil
        return false
    end

    local md = config.seg_manual_delim
    local after = ctx.input .. md
    local trailing_len = count_trailing(after, md)
    local head = strip_trailing(after, md)
    local core = strip_delims(head, md, config.seg_auto_delim)
    local n = #core
    local conf = SEG_PATTERNS[n]

    -- 大于 10 码动态构建分词：在2、3码之间循环
    if n > 10 then
        local groups_2 = {}
        for _ = 1, math.floor(n / 2) do
            table.insert(groups_2, 2)
        end
        if n % 2 ~= 0 then
            table.insert(groups_2, n % 2)
        end

        local groups_3 = {}
        for _ = 1, math.floor(n / 3) do
            table.insert(groups_3, 3)
        end
        if n % 3 ~= 0 then
            table.insert(groups_3, n % 3)
        end

        conf = { all = { groups_2, groups_3 } }
    end
    if state.seg_core ~= core or state.seg_n ~= n then
        state.seg_core = core
        state.seg_n = n
        state.seg_start_idx = nil
        state.seg_base = nil
    end

    if state.seg_base == nil then
        state.seg_base = head
    end

    if not conf then
        ctx.input = after
        return true
    end

    if state.seg_start_idx == nil then
        local start_idx = 0
        local lens = get_cached_lens(md, config.seg_auto_delim, state, ctx)
        if sum(lens) ~= n then
            lens = lens_from_string(head, md, config.seg_auto_delim)
        else
            local idx = find_idx(conf.all, key_of(lens))
            if idx then
                start_idx = idx
            end
        end
        state.seg_start_idx = start_idx
    end

    if trailing_len == 1 then
        ctx.input = after
        return true
    end

    local m = #conf.all
    local k = trailing_len - 1

    local function restore()
        ctx.input = (state.seg_base or head) .. md
        state.seg_core = core
        state.seg_n = n
        state.seg_start_idx = nil
        state.seg_base = nil
    end

    ---@type integer
    local idx
    if state.seg_start_idx and state.seg_start_idx ~= 0 then
        local cycle_len = m
        local r = k % cycle_len
        if r == 0 then
            restore()
            return true
        end
        idx = ((state.seg_start_idx - 1 + r) % m) + 1
    else
        local cycle_len = m + 1
        local r = k % cycle_len
        if r == 0 then
            restore()
            return true
        end
        idx = ((r - 1) % m) + 1
    end
    local rebuilt = build_by_groups(core, md, conf.all[idx] or {})
    ctx.input = rebuilt .. md:rep(trailing_len)
    return true
end

-- [BackspaceLimit] 退格限制
---@param key KeyEvent
---@param config SuperProcessorConfig
---@param state SuperProcessorState
---@param ctx Context
---@return boolean
local function handle_backspace(key, config, state, ctx)
    if not config.backspace_limit_enabled then
        return false
    end

    if key.keycode ~= 0xFF08 or key:release() then
        state.bs_sequence = false
        state.bs_prev_len = -1
        return false
    end

    local curr_len = #ctx.input
    if state.bs_sequence then
        if not wanxiang.is_mobile_device() then
            if state.bs_prev_len == 1 and curr_len == 0 then
                return true
            end
        end
        state.bs_prev_len = curr_len
        return false
    end
    state.bs_sequence = true
    state.bs_prev_len = curr_len
    return false
end

-- [RepeatLimit] 重复输入限制
---@param key KeyEvent
---@param config SuperProcessorConfig
---@param ctx Context
---@return boolean
local function handle_limit_repeat(key, config, ctx)
    if not config.limit_repeated_enabled then
        return false
    end

    local keycode = key.keycode
    if not (keycode >= 0x61 and keycode <= 0x7A) then
        return false
    end

    local cand = ctx:get_selected_candidate()
    local preedit = cand and (cand.preedit or cand:get_genuine().preedit) or ""
    local segs = 1
    for _ in preedit:gmatch("[%'%s]") do
        segs = segs + 1
    end

    local ch = string.char(keycode)
    local next_input = ctx.input .. ch
    local last, rep_n = tail_rep(next_input)

    if last:match(INITIALS) and rep_n > config.max_repeat then
        prompt(ctx, " 〔已超最大重复声母〕")
        return true
    end

    if segs >= config.max_segments then
        prompt(ctx, " 〔已超最大输入长度〕")
        return true
    end
    return false
end

-- [KpNumber] 数字键综合逻辑
---@param key KeyEvent
---@param config SuperProcessorConfig
---@param state SuperProcessorState
---@param ctx Context
---@return boolean
local function handle_number_logic(key, config, state, ctx)
    local input = ctx.input
    local kp_num = KP_MAP[key.keycode]

    -- A. 小键盘处理 (KpNumber)
    -- 桌面端专属：小键盘不上屏处理 (移动端直接跳过此区)
    if kp_num and not wanxiang.is_mobile_device() then
        if key:ctrl() or key:alt() or key:super() or key:shift() then
            return false
        end

        local ch = tostring(kp_num)

        -- 1. 正则拦截
        if is_function_code_after_digit(ch, config, ctx) then
            if ctx.push_input then
                ctx:push_input(ch)
            else
                ctx.input = input .. ch
            end
            return true
        end

        -- 2. 模式处理
        if config.kp_mode == "auto" then
            if state.kp_is_composing then
                if ctx.push_input then
                    ctx:push_input(ch)
                else
                    ctx.input = input .. ch
                end
            else
                return false -- Noop
            end
        else -- compose mode
            if ctx.push_input then
                ctx:push_input(ch)
            else
                ctx.input = input .. ch
            end
        end

        return true
    end

    -- B. 主键盘数字
    local digit_str = nil
    local r = key:repr()
    if r:match("^[0-9]$") then
        digit_str = r
    elseif kp_num and wanxiang.is_mobile_device() then
        digit_str = tostring(kp_num) -- 移动端小键盘视为标准数字
    end
    if not digit_str then
        return false
    end

    if key:ctrl() or key:alt() or key:super() then
        return false
    end

    -- 正则拦截
    if is_function_code_after_digit(digit_str, config, ctx) then
        if ctx.push_input then
            ctx:push_input(digit_str)
        else
            ctx.input = input .. digit_str
        end
        return true
    end

    -- 候选选词
    if not state.kp_has_menu then
        return false
    end

    local digit = tonumber(digit_str)
    if digit == 0 then
        digit = 10
    end
    if digit > config.kp_page_size then
        return false
    end

    local comp = ctx.composition
    if comp:empty() then
        return false
    end

    local seg = comp:back()
    local menu = seg and seg.menu
    if not menu or menu:empty() then
        return false
    end

    local selected_index = seg and seg.selected_index or 0
    local page_start = math.floor(selected_index / config.kp_page_size) * config.kp_page_size
    local index = page_start + (digit - 1)
    if index >= menu:candidate_count() then
        return false
    end

    -- 这里执行纯净的 ctx:select，不干涉物理按键事件
    return ctx:select(index)
end

local P = {}

---@param env Env
function P.init(env)
    local rime_config = env.engine.schema.config

    -- [1] 配置加载 (按功能模块分类)

    local backspace_limit_enabled = rime_config:get_bool("super_processor/enable_backspace_limit")
    if backspace_limit_enabled == nil then
        backspace_limit_enabled = true
    end

    local seg_loop_enabled = rime_config:get_bool("super_processor/enable_seg_loop")
    if seg_loop_enabled == nil then
        seg_loop_enabled = true
    end

    local predict_space_enabled = rime_config:get_bool("super_processor/enable_predict_space")
    if predict_space_enabled == nil then
        predict_space_enabled = true
    end

    -- [RepeatLimit]
    ---Example: false, "", "8,40"
    ---@type boolean|string?
    local limit_repeated = rime_config:get_bool("super_processor/limit_repeated")
    if limit_repeated == nil then
        limit_repeated = rime_config:get_string("super_processor/limit_repeated")
    end

    local limit_repeated_enabled = true
    local max_repeat = 8
    local max_segments = 40
    if type(limit_repeated) == "boolean" then
        if not limit_repeated then
            limit_repeated_enabled = false
        end
    elseif type(limit_repeated) == "string" then
        local str_trim = limit_repeated:match("^%s*(.-)%s*$") -- Strip whitespace
        if str_trim == "" or str_trim:lower() == "false" then
            limit_repeated_enabled = false
        else
            ---@type string?, string?
            local max_repeat_str, max_segments_str = str_trim:match("^(%d+)%s*,%s*(%d+)$")
            if max_repeat_str and max_segments_str then
                local max_repeat_num = tonumber(max_repeat_str)
                if max_repeat_num then
                    max_repeat = math.floor(max_repeat_num)
                end
                local max_segments_num = tonumber(max_segments_str)
                if max_segments_num then
                    max_segments = math.floor(max_segments_num)
                end
            end
        end
    end

    -- [KpNumber] 小键盘
    local kp_page_size = rime_config:get_int("menu/page_size") or 6
    local m = rime_config:get_string("super_processor/kp_number_mode") or "auto"
    local kp_mode = (m == "auto" or m == "compose") and m or "auto"
    local kp_func_patterns = wanxiang.load_regex_patterns(rime_config, "recognizer/patterns")

    -- [SuperSegmentation] 超强分词
    local delim = rime_config:get_string("speller/delimiter") or " '"
    local seg_auto_delim = delim:sub(1, 1)
    local seg_manual_delim = delim:sub(2, 2)

    -- [2] 统一 Update Notifier (状态缓存与自动处理)
    local conn_update = env.engine.context.update_notifier:connect(function(ctx)
        local config = env.super_processor_config
        assert(config)
        local state = env.super_processor_state
        assert(state)

        local input = ctx.input

        -- [Predict Space] 联想空格接力起跑点
        if state.pending_predict_space then
            state.pending_predict_space = false
            ctx:set_option("_dummy_predict_update", false)
            ctx:clear()
            env.engine:commit_text(" ")
        end

        -- A. [SuperSegmentation] 缓存数据
        local seg = ctx.composition:back()
        local cand = seg and seg:get_selected_candidate()
        local pre = cand and cand.preedit
        state.seg_last_preedit_lens = lens_from_string(pre, config.seg_manual_delim, config.seg_auto_delim)
        state.seg_last_input_caret = input
        state.seg_last_caret_pos = ctx.caret_pos

        -- C. [KpNumber] 缓存状态
        state.kp_is_composing = ctx:is_composing()
        state.kp_has_menu = ctx:has_menu()
    end)

    env.super_processor_config = {
        limit_repeated_enabled = limit_repeated_enabled,
        backspace_limit_enabled = backspace_limit_enabled,
        seg_loop_enabled = seg_loop_enabled,
        predict_space_enabled = predict_space_enabled,
        max_repeat = max_repeat,
        max_segments = max_segments,
        kp_page_size = kp_page_size,
        kp_mode = kp_mode,
        kp_func_patterns = kp_func_patterns,
        seg_auto_delim = seg_auto_delim,
        seg_manual_delim = seg_manual_delim,
    }

    env.super_processor_state = {
        bs_prev_len = -1,
        bs_sequence = false,
        kp_is_composing = false,
        kp_has_menu = false,
        seg_core = nil,
        seg_start_idx = nil,
        seg_n = nil,
        seg_base = nil,
        seg_last_preedit_lens = {},
        seg_last_input_caret = nil,
        seg_last_caret_pos = nil,
        pending_predict_space = false,
        conn_update = conn_update,
    }
end

---@param env Env
function P.fini(env)
    env.super_processor_state.conn_update:disconnect()
    env.super_processor_config = nil
    env.super_processor_state = nil
end

---@param key KeyEvent
---@param env Env
---@return integer
function P.func(key, env)
    local context = env.engine.context

    local config = env.super_processor_config
    assert(config)
    local state = env.super_processor_state
    assert(state)

    -- 1. 优先处理按键释放
    if key:release() then
        handle_backspace(key, config, state, context)
        return wanxiang.RIME_PROCESS_RESULTS.kNoop
    end

    local kc = key.keycode

    -- [Predict Space] 联想空格
    if kc == 0x20 then
        if handle_predict_space(config, state, context) then
            return wanxiang.RIME_PROCESS_RESULTS.kAccepted
        end
    end

    if context.composition:empty() then
        if kc == 0xff0d or kc == 0xff8d or kc == 0x20 then
            context:set_property("english_spacing", "true")
        end
        if kc == 0x5c or kc == 0x2f then
            context:set_property("force_sticky_code", "true")
        end
    end

    -- 2. [BackspaceLimit] 退格防止删除已上屏内容
    if kc == 0xFF08 then
        if handle_backspace(key, config, state, context) then
            return wanxiang.RIME_PROCESS_RESULTS.kAccepted
        end
    end

    -- 4. 分词符 ' [SuperSegmentation] 处理分词符 '
    if kc == 0x27 then
        if handle_segmentation(key, config, state, context) then
            return wanxiang.RIME_PROCESS_RESULTS.kAccepted
        end
    end

    -- 5. [RepeatLimit] 重复输入限制
    if kc >= 0x61 and kc <= 0x7A then
        if handle_limit_repeat(key, config, context) then
            return wanxiang.RIME_PROCESS_RESULTS.kAccepted
        end
    end

    -- 7. 数字键 (小键盘 + 选词)[KpNumber] 数字键综合逻辑
    if (kc >= 0xFFB0 and kc <= 0xFFB9) or (kc >= 0x30 and kc <= 0x39) then
        if handle_number_logic(key, config, state, context) then
            return wanxiang.RIME_PROCESS_RESULTS.kAccepted
        end
    end

    return wanxiang.RIME_PROCESS_RESULTS.kNoop
end

return P
