-- lua/super_processor.lua
-- @amzxyz
-- https://github.com/amzxyz/rime_wanxiang
-- 全能按键处理器：整合 KP小键盘、字母选词、超强分词、重复限制、退格限制、以词定字
--
-- 用法: 在 schema.yaml 中 engine/processors 列表添加 - lua_processor@*super_processor

---@class SuperProcessorConfig
---
---Config for LimitRepeated
---@field limit_repeated_enabled boolean
---@field backspace_limit_enabled boolean
---@field seg_loop_enabled boolean
---@field predict_space_enabled boolean
---@field max_repeat integer
---@field max_segments integer
---
---Config for SelectCharacter
---@field sc_first_key string?
---@field sc_last_key string?
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
---Config for LetterSelector
---@field letter_selector_active boolean
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

-- [LetterSelector] 字母选词键码映射 (qwert...)
local LETTER_SEL_MAP = {
    [0x71] = 1,
    [0x77] = 2,
    [0x65] = 3,
    [0x72] = 4,
    [0x74] = 5,
    [0x79] = 6,
    [0x75] = 7,
    [0x69] = 8,
    [0x6F] = 9,
    [0x70] = 10,
}

-- [LimitRepeated] 重复限制默认配置 (现已支持配置覆盖)
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
---@param a any[]
---@return string
local function key_of(a)
    return table.concat(a, ",")
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
    if md and md ~= "" then
        s = s:gsub(escp(md), "")
    end
    if ad and ad ~= "" then
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
---@param s string
---@param md string
---@param ad string
---@return number[]
local function lens_from_string(s, md, ad)
    if s == "" then
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
    local cand = seg and seg:get_selected_candidate() or nil
    return lens_from_string(cand and cand.preedit or nil, md, ad)
end

---增强版 UTF-8 长度计算 (Super Segmentation 使用)
---@param s string
---@return number
local function ulen(s)
    if not s or s == "" then
        return 0
    end
    if utf8 and utf8.len then
        local ok, n = pcall(utf8.len, s)
        if ok and n then
            return n
        end
    end
    local n = 0
    if utf8 and utf8.codes then
        for _ in utf8.codes(s) do
            n = n + 1
        end
        return n
    end
    return #s
end

---检查数字后是否紧跟功能编码 (KpNumber 使用)
---@param digit_char string
---@param config SuperProcessorConfig
---@param ctx Context
---@return boolean
local function is_function_code_after_digit(digit_char, config, ctx)
    if not ctx or not digit_char or digit_char == "" then
        return false
    end
    local code = ctx.input or ""
    local s = code .. digit_char
    local patterns = config.kp_func_patterns
    if not patterns then
        return false
    end
    for _, pat in ipairs(patterns) do
        if s:match(pat) then
            return true
        end
    end
    return false
end

---计算尾部重复字符数 (LimitRepeated 使用)
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

---设置候选框提示 (LimitRepeated 使用)
---@param ctx Context
---@param msg string
local function prompt(ctx, msg)
    local comp = ctx.composition
    if comp and not comp:empty() then
        comp:back().prompt = msg
    end
end

-- 4. 逻辑分发处理

-- [Predict Space] 联想空格接力起跑点
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

    local last_input = state.seg_last_input_caret or ctx.input or ""
    local last_caret = state.seg_last_caret_pos
    if not last_caret or last_caret ~= ulen(last_input) then
        state.seg_core, state.seg_start_idx, state.seg_n, state.seg_base = nil, nil, nil, nil
        return false
    end

    local md = config.seg_manual_delim
    local before = ctx.input or ""
    local after = before .. md
    local tlen = count_trailing(after, md)
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

    if conf and state.seg_start_idx == nil then
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

    if tlen == 1 then
        ctx.input = after
        return true
    end

    if not conf then
        ctx.input = after
        return true
    end

    local m = #conf.all
    local k = tlen - 1

    local function restore()
        ctx.input = (state.seg_base or head) .. md
        state.seg_core, state.seg_start_idx, state.seg_n, state.seg_base = nil, nil, nil, nil
        state.seg_core = core
        state.seg_n = n
    end

    if state.seg_start_idx and state.seg_start_idx ~= 0 then
        local cycle_len = m
        local r = k % cycle_len
        if r == 0 then
            restore()
            return true
        end
        local idx = ((state.seg_start_idx - 1 + r) % m) + 1
        local rebuilt = build_by_groups(core, md, conf.all[idx])
        ctx.input = rebuilt .. md:rep(tlen)
        return true
    else
        local cycle_len = m + 1
        local r = k % cycle_len
        if r == 0 then
            restore()
            return true
        end
        local idx = ((r - 1) % m) + 1
        local rebuilt = build_by_groups(core, md, conf.all[idx])
        ctx.input = rebuilt .. md:rep(tlen)
        return true
    end
end

-- [Backspace Limit] 退格限制
---@param key KeyEvent
---@param config SuperProcessorConfig
---@param state SuperProcessorState
---@param ctx Context
---@return boolean
local function handle_backspace(key, config, state, ctx)
    if not config.backspace_limit_enabled then
        return false
    end

    local kc = key.keycode
    if kc ~= 0xFF08 or key:release() then
        state.bs_sequence = false
        state.bs_prev_len = -1
        return false
    end

    local cur_len = ctx.input and #ctx.input or 0
    if state.bs_sequence then
        if not wanxiang.is_mobile_device() then
            if state.bs_prev_len == 1 and cur_len == 0 then
                return true
            end
        end
        state.bs_prev_len = cur_len
        return false
    end
    state.bs_sequence = true
    state.bs_prev_len = cur_len
    return false
end

-- [Limit Repeated] 重复输入限制
---@param key KeyEvent
---@param config SuperProcessorConfig
---@param ctx Context
---@return boolean
local function handle_limit_repeat(key, config, ctx)
    if not config.limit_repeated_enabled then
        return false
    end

    local kc = key.keycode
    if not (kc >= 0x61 and kc <= 0x7A) then
        return false
    end

    local cand = ctx:get_selected_candidate()
    local preedit = cand and (cand.preedit or cand:get_genuine().preedit) or ""
    local segs = 1
    for _ in preedit:gmatch("[%'%s]") do
        segs = segs + 1
    end

    local ch = string.char(kc)
    local input = ctx.input or ""
    local nxt = input .. ch
    local last, rep_n = tail_rep(nxt)

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

-- [Letter Selector] 字母选词
---@param key KeyEvent
---@param state SuperProcessorState
---@param ctx Context
---@return boolean
local function handle_letter_select(key, state, ctx)
    if not state.letter_selector_active then
        return false
    end
    if key:ctrl() or key:alt() or key:super() then
        return false
    end
    local idx = LETTER_SEL_MAP[key.keycode]
    if not idx then
        return false
    end

    if ctx.composition:empty() then
        return false
    end
    local seg = ctx.composition:back()
    if not seg or not seg.menu then
        return false
    end

    local count = seg.menu:prepare(9)
    if idx < 1 or idx > count then
        return false
    end

    ctx:select(idx - 1)
    return true
end

-- [Select Character] 以词定字逻辑
---@param key KeyEvent
---@param config SuperProcessorConfig
---@param env Env
---@param ctx Context
---@return boolean
local function handle_select_character(key, config, env, ctx)
    -- 1. 检查配置是否存在
    if not (config.sc_first_key or config.sc_last_key) then
        return false
    end

    -- 2. 状态检查：必须在输入中或有候选菜单
    if not (ctx:is_composing() or ctx:has_menu()) then
        return false
    end

    -- 3. 键值与字符双重匹配（解决 Rime 返回 "bracketleft" 无法匹配 "[" 的问题）
    local repr = key:repr()
    local ch = ""
    if key.keycode >= 0x20 and key.keycode <= 0x7E then
        ch = string.char(key.keycode)
    end

    local is_first = (config.sc_first_key and (repr == config.sc_first_key or ch == config.sc_first_key))
    local is_last = (config.sc_last_key and (repr == config.sc_last_key or ch == config.sc_last_key))
    if not (is_first or is_last) then
        return false
    end

    -- 4. 获取当前选中的候选词或输入
    local text = ctx.input
    local cand = ctx:get_selected_candidate()
    if cand then
        text = cand.text
    end

    -- 5. 执行上屏
    if utf8.len(text) > 1 then
        if is_first then
            -- 上屏第一个字 (sub: 1 到 第二个字偏移量-1)
            env.engine:commit_text(text:sub(1, utf8.offset(text, 2) - 1))
            ctx:clear()
            return true -- Accepted
        elseif is_last then
            -- 上屏最后一个字 (sub: 最后一个字偏移量)
            env.engine:commit_text(text:sub(utf8.offset(text, -1)))
            ctx:clear()
            return true -- Accepted
        end
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
    local kc = key.keycode
    local input = ctx.input or ""

    -- A. 小键盘处理 (KpNumber)
    -- 桌面端专属：小键盘不上屏处理 (移动端直接跳过此区)
    local kp_num = KP_MAP[kc]
    if kp_num ~= nil and not wanxiang.is_mobile_device() then
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
    elseif kp_num ~= nil and wanxiang.is_mobile_device() then
        digit_str = tostring(kp_num) -- 移动端小键盘视为标准数字
    end

    if digit_str then
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
        if state.kp_has_menu then
            local d = tonumber(digit_str)
            if d == 0 then
                d = 10
            end
            if d and d >= 1 and d <= config.kp_page_size then
                local comp = ctx.composition
                if comp and not comp:empty() then
                    local seg = comp:back()
                    local menu = seg and seg.menu
                    if menu and not menu:empty() then
                        local sel_index = seg.selected_index or 0
                        local page_start = math.floor(sel_index / config.kp_page_size) * config.kp_page_size
                        local index = page_start + (d - 1)
                        if index < menu:candidate_count() then
                            -- 这里执行纯净的 ctx:select，不干涉物理按键事件
                            if ctx:select(index) then
                                return true
                            end
                        end
                    end
                end
            end
            return false
        end
    end
    return false
end

local M = {}

---@param env Env
function M.init(env)
    local engine = env.engine
    local rime_config = engine.schema.config
    local context = engine.context

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

    -- [LimitRepeated]
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

    -- [SelectCharacter] 以词定字配置加载（支持 false, "", "[,]", "bracketleft, bracketright"）
    local has_new_config = false
    ---@type boolean|string?
    local select_character = rime_config:get_bool("super_processor/select_character")
    if select_character == nil then
        select_character = rime_config:get_string("super_processor/select_character")
    end

    ---@type string?
    local sc_first_key = nil
    ---@type string?
    local sc_last_key = nil
    if type(select_character) == "boolean" then
        if not select_character then
            sc_first_key = nil
            sc_last_key = nil
            has_new_config = true
        end
    elseif type(select_character) == "string" then
        ---@type string
        local str_trim = select_character:match("^%s*(.-)%s*$")
        if str_trim == "" or str_trim:lower() == "false" then
            sc_first_key = nil
            sc_last_key = nil
        else
            -- 尝试使用逗号分割
            ---@type string?, string?
            local p1, p2 = str_trim:match("^(.-),(.-)$")
            if p1 and p2 then
                sc_first_key = p1:match("^%s*(.-)%s*$")
                sc_last_key = p2:match("^%s*(.-)%s*$")
            elseif #str_trim >= 2 then
                -- 兜底兼容旧的 "[]" 无逗号写法
                sc_first_key = str_trim:sub(1, 1)
                sc_last_key = str_trim:sub(2, 2)
            end
        end
        has_new_config = true
    end

    if not has_new_config then
        -- 兜底：只有在新配置完全缺失时，才去读旧配置
        sc_first_key = rime_config:get_string("key_binder/select_first_character")
        sc_last_key = rime_config:get_string("key_binder/select_last_character")
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
    local conn_update = context.update_notifier:connect(function(ctx)
        local config = env.super_processor_config
        assert(config)
        local state = env.super_processor_state
        assert(state)

        local input = ctx.input or ""

        -- [Predict Space] 联想空格接力起跑点
        if state.pending_predict_space then
            state.pending_predict_space = false
            ctx:set_option("_dummy_predict_update", false)
            ctx:clear()
            env.engine:commit_text(" ")
        end

        -- A. [SuperSegmentation] 缓存数据
        local seg = ctx.composition:back()
        local cand = seg and seg:get_selected_candidate() or nil
        local pre = cand and cand.preedit or nil
        state.seg_last_preedit_lens = lens_from_string(pre, config.seg_manual_delim, config.seg_auto_delim)
        state.seg_last_input_caret = input
        state.seg_last_caret_pos = ctx.caret_pos

        -- B. [LetterSelector] 缓存激活状态
        state.letter_selector_active = false
        if not ctx.composition:empty() then
            local s = ctx.composition:back()
            if s and (s:has_tag("number") or s:has_tag("Ndate")) then
                state.letter_selector_active = true
            end
        end

        -- C. [KpNumber] 缓存状态
        state.kp_is_composing = ctx:is_composing()
        state.kp_has_menu = ctx:has_menu()
    end)

    env.super_processor_config = {
        limit_repeated_enabled = limit_repeated_enabled,
        backspace_limit_enabled = backspace_limit_enabled,
        seg_loop_enabled = seg_loop_enabled,
        predict_space_enabled = predict_space_enabled,
        enable_limit_repeated = limit_repeated_enabled,
        max_repeat = max_repeat,
        max_segments = max_segments,
        sc_first_key = sc_first_key,
        sc_last_key = sc_last_key,
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
        letter_selector_active = false,
        pending_predict_space = false,
        conn_update = conn_update,
    }
end

---@param env Env
function M.fini(env)
    env.super_processor_state.conn_update:disconnect()
    env.super_processor_config = nil
    env.super_processor_state = nil
end

---@param key KeyEvent
---@param env Env
---@return integer
function M.func(key, env)
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

    -- 2. Backspace 退格防止删除已上屏内容
    if kc == 0xFF08 then
        if handle_backspace(key, config, state, context) then
            return wanxiang.RIME_PROCESS_RESULTS.kAccepted
        end
    end

    -- 3. Select Character 以词定字
    -- 它的优先级很高，因为是针对当前候选的操作
    -- 但必须在 Backspace 之后，防止误操作
    if handle_select_character(key, config, env, context) then
        return wanxiang.RIME_PROCESS_RESULTS.kAccepted
    end

    -- 4. 分词符 ' [SuperSegmentation] 处理分词符 '
    if kc == 0x27 then
        if handle_segmentation(key, config, state, context) then
            return wanxiang.RIME_PROCESS_RESULTS.kAccepted
        end
    end

    -- 5. 字母键[Limit Repeated] 重复输入限制
    if kc >= 0x61 and kc <= 0x7A then
        if handle_limit_repeat(key, config, context) then
            return wanxiang.RIME_PROCESS_RESULTS.kAccepted
        end
    end

    -- 6. (q-o + 特定 Tag)[Letter Selector] 字母选词
    if state.letter_selector_active and (LETTER_SEL_MAP[kc] ~= nil) then
        if handle_letter_select(key, state, context) then
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

return M
