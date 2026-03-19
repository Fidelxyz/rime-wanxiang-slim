-- @amzxyz  https://github.com/amzxyz/rime_wanxiang
-- 功能 A：候选文本中的转义序列格式化（始终开启）
--         \n \t \r \\ \s(空格) \d(-)
-- 功能 B：候选重排（仅编码长度 2..6 时）
--         - 第一候选不动
--         - 其余按组输出：①不含字母(table/user_table) → ②其他
--         - 若第二候选为 table/user_table，则不排序，直接透传
-- 功能 C 三码空候选轻量兜底（2码记录首选单字，3码无候选时直接兜底）
-- 功能 D 由于在混输场景中输入comment commit等等之类的英文时候，由于直接辅助码的派生能力，会将三个好不想干的单字组合在一起，这会造成不好的体验
--      因此在首选已经是英文的时候，且type=completion且大于等于4个字符，这个时候后面如果有type=sentence的派生词则直接干掉，这个还要依赖，表翻译器
--      权重设置与主翻译器不可相差太大

local wanxiang = require("wanxiang/wanxiang")
local M = {}
--全局通信通道
_G.WanxiangSharedState = _G.WanxiangSharedState
    or {
        sorter_active = false, -- 标记排序脚本是否存活
        last_input = "", -- 记录上一次未打斜杠的拼音
        page_cache = {}, -- 存放排序后的终极缓存
    }
-- 性能优化：本地化字符串函数
local byte = string.byte
local find = string.find
local utf8_len = utf8.len

local function fast_type(c)
    local t = c.type
    if t then
        return t
    end
    local g = c.get_genuine and c:get_genuine() or nil
    return (g and g.type) or ""
end

local function is_table_type(c)
    local t = fast_type(c)
    return t == "table" or t == "user_table" or t == "fixed"
end

local function has_english_token_fast(s)
    local len = #s
    for i = 1, len do
        local b = byte(s, i)
        if b < 0x80 then
            -- A-Z (0x41-0x5A) or a-z (0x61-0x7A)
            if (b >= 0x41 and b <= 0x5A) or (b >= 0x61 and b <= 0x7A) then
                return true
            end
        end
    end
    return false
end
-- 1. 内部常量与工具函数
local escape_map = {
    ["\\n"] = "\n", -- 换行
    ["\\r"] = "\r", -- 回车
    ["\\t"] = "\t", -- 制表符
    ["\\s"] = " ", -- 空格
    ["\\z"] = "\226\128\139", -- 零宽空格
}

local utf8_char_pattern = "[%z\1-\127\194-\244][\128-\191]*"

-- 时辰数据：每个时辰2小时，共8刻，每刻15分钟
local shichen_data = {
    { name = "子时", start_hour = 23, end_hour = 1 },
    { name = "丑时", start_hour = 1, end_hour = 3 },
    { name = "寅时", start_hour = 3, end_hour = 5 },
    { name = "卯时", start_hour = 5, end_hour = 7 },
    { name = "辰时", start_hour = 7, end_hour = 9 },
    { name = "巳时", start_hour = 9, end_hour = 11 },
    { name = "午时", start_hour = 11, end_hour = 13 },
    { name = "未时", start_hour = 13, end_hour = 15 },
    { name = "申时", start_hour = 15, end_hour = 17 },
    { name = "酉时", start_hour = 17, end_hour = 19 },
    { name = "戌时", start_hour = 19, end_hour = 21 },
    { name = "亥时", start_hour = 21, end_hour = 23 },
}

-- 刻数名称：每个时辰有8刻
local ke_names = { "初刻", "二刻", "三刻", "四刻", "五刻", "六刻", "七刻", "八刻" }

-- 获取时辰和刻数
local function get_shichen_and_ke(hour, min)
    local total_minutes = hour * 60 + min

    for _, shichen in ipairs(shichen_data) do
        local shichen_name = shichen.name
        local start_hour = shichen.start_hour
        local end_hour = shichen.end_hour

        local start_minutes = start_hour * 60
        local end_minutes = end_hour * 60
        local is_match = false

        -- 处理跨天的子时
        if start_hour > end_hour then
            if total_minutes >= start_minutes or total_minutes < end_minutes then
                is_match = true
            end
        else
            if total_minutes >= start_minutes and total_minutes < end_minutes then
                is_match = true
            end
        end

        if is_match then
            local calc_minutes = total_minutes
            if start_hour > end_hour and total_minutes < end_minutes then
                calc_minutes = total_minutes + 1440
            end

            local offset_minutes = calc_minutes - start_minutes
            local ke_index = math.floor(offset_minutes / 15)
            if ke_index >= 8 then
                ke_index = 7
            end

            return shichen_name, ke_names[ke_index + 1]
        end
    end

    return "未知时辰", "未知刻"
end
local time_tokens_pattern = "\\[AGHIKMNOPSTWYdjlmopwy]"
-- 2. 核心：处理动态时间（只负责替换，不负责保护）
local function process_datetime_internal(s)
    if not string.find(s, time_tokens_pattern) then
        return s
    end
    local dt = os.date("*t")

    -- 获取时辰和刻数
    local current_shichen, current_ke = get_shichen_and_ke(dt.hour, dt.min)

    local week_table_big = { "星期日", "星期一", "星期二", "星期三", "星期四", "星期五", "星期六" }
    local week_table_small = { "周日", "周一", "周二", "周三", "周四", "周五", "周六" }

    local h12 = dt.hour % 12
    if h12 == 0 then
        h12 = 12
    end
    local ampm = (dt.hour < 12) and "am" or "pm"
    local raw_tz = os.date("%z") or "+0800"
    local tz_colon
    do
        local sign, h_str, m_str = raw_tz:match("^([%+%-])(%d%d)(%d%d)$")
        if sign then
            tz_colon = sign .. h_str .. ":" .. m_str
        else
            tz_colon = raw_tz
        end
    end

    -- 计算中文时段 A
    local zh_period
    local h = dt.hour
    if h < 6 then
        zh_period = "凌晨"
    elseif h < 12 then
        zh_period = "上午"
    elseif h < 13 then
        zh_period = "中午"
    elseif h < 18 then
        zh_period = "下午"
    else
        zh_period = "晚上"
    end

    local time_map = {
        Y = string.format("%04d", dt.year),
        y = string.format("%02d", dt.year % 100),
        m = string.format("%02d", dt.month),
        d = string.format("%02d", dt.day),
        N = tostring(dt.month), -- 月份不带零（用\N避开\n换行冲突）
        j = tostring(dt.day),
        W = week_table_big[dt.wday],
        w = week_table_small[dt.wday],
        H = string.format("%02d", dt.hour),
        G = tostring(dt.hour),
        I = string.format("%02d", h12),
        l = tostring(h12),
        T = current_shichen,
        K = current_ke,
        M = string.format("%02d", dt.min),
        S = string.format("%02d", dt.sec),
        p = ampm,
        P = ampm:upper(),
        O = tz_colon,
        o = raw_tz,
        A = zh_period,
    }

    return s:gsub("\\(%a)", function(char)
        return time_map[char] or ("\\" .. char)
    end)
end

-- 3. 主入口：全局保护 [[]] 并执行所有转义逻辑
local function apply_escape_fast(text)
    -- 性能护航：不含反斜杠直接返回
    if not text or not string.find(text, "\\", 1, true) then
        return text, false
    end

    -- 第一步：保护 [[...]]
    local blocks = {}
    local s = text:gsub("%[%[(.-)%]%]", function(txt)
        blocks[#blocks + 1] = txt
        return "\0BLK" .. #blocks .. "\0"
    end)

    -- 第二步：处理基础转义 (\n, \t, \s, \z 等)
    s = s:gsub("\\[ntrsz]", escape_map)

    -- 第三步：处理字符重复 (a\3 => aaa)
    s = s:gsub("(" .. utf8_char_pattern .. ")\\(%d+)", function(char, count)
        local n = tonumber(count)
        if n and n > 0 and n < 200 then
            return string.rep(char, n)
        end
        return char .. "\\" .. count
    end)

    -- 第四步：处理动态时间占位符 (\Y, \T, \A 等)
    s = process_datetime_internal(s)

    -- 第五步：还原 [[...]]
    s = s:gsub("\0BLK(%d+)\0", function(i)
        return blocks[tonumber(i)] or ""
    end)

    return s, s ~= text
end
local function format_and_autocap(cand)
    local text = cand.text
    if not text or text == "" then
        return cand
    end
    local t2, changed = apply_escape_fast(text)
    if not changed then
        return cand
    end
    local nc = Candidate(cand.type, cand.start, cand._end, t2, cand.comment)
    nc.preedit = cand.preedit
    return nc
end

local function clone_candidate(c)
    local nc = Candidate(c.type, c.start, c._end, c.text, c.comment or "")
    nc.preedit = c.preedit
    return nc
end

function M.init(env)
    local cfg = env.engine and env.engine.schema and env.engine.schema.config

    env.locked = false
    -- PageSize & TablePosition
    env.page_size = (cfg and cfg:get_int("menu/page_size"))

    env.table_idx = env.page_size
    if cfg then
        local tp = cfg:get_int("idiom_preposition")
        if tp and tp >= 0 and tp <= env.page_size then
            env.table_idx = tp
        end
    end

    local schema_id = env.engine.schema.schema_id
    env.enable_taichi_filter = (schema_id == "wanxiang" or schema_id == "wanxiang_pro")
    env.page_cache = {}

    -- 【新增】用于2码记录、3码单字兜底的轻量级状态
    env.last_2code_char = nil
end

function M.fini(env)
    env.last_2code_char = nil
end

-- 上屏管道：负责去重、格式化、修饰
local function emit_with_pipeline(wrapper, ctxs)
    local cand = wrapper.cand
    local text = wrapper.text

    -- 2. 太极/句子过滤 (使用缓存的属性)
    if ctxs.enable_taichi_filter and wrapper.has_eng then
        if cand.comment and find(cand.comment, "\226\152\175") then
            return false
        end
    end

    -- 3. 英文长句过滤 (Function E)
    if ctxs.drop_sentence_after_completion then
        if cand.type == "sentence" then
            return false
        end
    end

    -- 4. 最终去重
    if ctxs.suppress_set and ctxs.suppress_set[text] then
        return false
    end

    -- 5. 格式化与修饰
    cand = format_and_autocap(cand)
    cand = ctxs.unify_tail_span(cand)

    yield(cand)
    if #ctxs.env.page_cache < ctxs.cache_limit then
        if not _G.WanxiangSharedState.sorter_active then
            table.insert(ctxs.env.page_cache, clone_candidate(cand))
        end
    end
    return true
end

function M.func(input, env)
    local ctx = env and env.engine and env.engine.context or nil
    local code = ctx and (ctx.input or "") or ""
    local comp = ctx and ctx.composition or nil

    -- 1. 空环境清理
    if not code or code == "" or (comp and comp:empty()) then
        env.last_2code_char = nil
        env.page_cache = {}
        for cand in input:iter() do
            yield(cand)
        end
        return
    end

    -- 计算当前拼音片段长度，用于精确判定2码和3码
    local last_seg = comp and comp:back()
    local code_len = #code
    local seg_len = last_seg and (last_seg._end - last_seg.start) or code_len
    local enable_taichi = env.enable_taichi_filter

    -- 及时清理兜底数据
    if seg_len < 2 or seg_len > 3 then
        env.last_2code_char = nil
    end

    -- 3. 成对符号包裹功能已移除
    env.page_cache = {}
    local fully_consumed = false
    env.locked = false

    local do_group = (env.table_idx > 0) and (code_len >= 2 and code_len <= 6)

    -- 闭包上下文 (Context)
    local function unify_tail_span(c)
        if fully_consumed and last_seg and c and c._end ~= last_seg._end then
            local nc = Candidate(c.type, c.start, last_seg._end, c.text, c.comment)
            nc.preedit = c.preedit
            return nc
        end
        return c
    end

    local emit_ctx = {
        env = env,
        ctx = ctx,
        suppress_set = nil,
        unify_tail_span = unify_tail_span,
        enable_taichi_filter = enable_taichi,
        drop_sentence_after_completion = false, -- 初始化为 false
        cache_limit = (env.page_size or 5) * 2,
    }

    local page_size = env.page_size
    local target_idx = env.table_idx
    local sort_window = 30
    local visual_idx = 0

    -- 通用候选处理 (Wrap -> Emit)
    local function try_process_wrapper(wrapper)
        if emit_with_pipeline(wrapper, emit_ctx) then
            visual_idx = visual_idx + 1
            return true
        end
        return false
    end

    -- 三码空候选轻量兜底执行函数
    local function check_and_yield_fallback()
        if visual_idx == 0 and seg_len == 3 then
            local fallback_text = env.last_2code_char
            if fallback_text then
                local start_pos = last_seg and last_seg.start or (#code - 3)
                if start_pos < 0 then
                    start_pos = 0
                end
                local end_pos = last_seg and last_seg._end or #code
                local nc = Candidate("fallback", start_pos, end_pos, fallback_text, "")
                -- 分割预编辑区，例如输入 "abc" -> 显示 "ab c"
                local seg_str = string.sub(code, start_pos + 1, end_pos)
                if #seg_str >= 3 then
                    nc.preedit = string.sub(seg_str, 1, 2) .. " " .. string.sub(seg_str, 3)
                else
                    nc.preedit = seg_str
                end
                yield(nc)
            end
        end
    end

    -- 模式 1: 非分组 (Direct Pass)
    if not do_group then
        local idx = 0
        for cand in input:iter() do
            idx = idx + 1
            -- 封装 Wrapper，后续逻辑复用属性
            local txt = cand.text
            local w = {
                cand = cand,
                text = txt,
                is_table = is_table_type(cand),
                has_eng = has_english_token_fast(txt),
            }

            if idx == 1 then
                -- 为3码兜底做准备
                if seg_len == 2 and (utf8_len(txt) or 0) == 1 and not w.has_eng then
                    env.last_2code_char = txt
                end

                -- 英文长句过滤触发器
                if w.is_table and #txt >= 4 and w.has_eng then
                    emit_ctx.drop_sentence_after_completion = true
                end
            end

            try_process_wrapper(w)
        end
        -- 单字无候选时兜底
        check_and_yield_fallback()
        return
    end

    -- 模式 2: 分组模式 (Grouping)
    local idx2 = 0
    local mode = "unknown" -- unknown | passthrough | grouping

    local normal_buf = {} -- 存 Normal
    local special_buf = {} -- 存 Table/UserTable

    local function try_flush_page_sort(force_all)
        while true do
            local next_pos = visual_idx + 1
            local current_idx_in_page = ((next_pos - 1) % page_size) + 1
            local is_second_page = (visual_idx >= page_size)

            local allow_special = is_second_page or (current_idx_in_page >= target_idx)

            local w_to_emit = nil
            if force_all then
                if allow_special then
                    if #special_buf > 0 then
                        w_to_emit = table.remove(special_buf, 1)
                    elseif #normal_buf > 0 then
                        w_to_emit = table.remove(normal_buf, 1)
                    end
                else
                    if #normal_buf > 0 then
                        w_to_emit = table.remove(normal_buf, 1)
                    elseif #special_buf > 0 then
                        w_to_emit = table.remove(special_buf, 1)
                    end
                end
                if not w_to_emit then
                    break
                end
            else
                if allow_special then
                    if #special_buf > 0 then
                        w_to_emit = table.remove(special_buf, 1)
                    else
                        if #normal_buf > sort_window then
                            w_to_emit = table.remove(normal_buf, 1)
                        else
                            break
                        end
                    end
                else
                    if #normal_buf > 0 then
                        w_to_emit = table.remove(normal_buf, 1)
                    else
                        break
                    end
                end
            end

            if w_to_emit then
                try_process_wrapper(w_to_emit)
            end
        end
    end

    local grouped_cnt = 0
    local window_closed = false

    for cand in input:iter() do
        idx2 = idx2 + 1
        local txt = cand.text
        local w = {
            cand = cand,
            text = txt,
            is_table = is_table_type(cand),
            has_eng = has_english_token_fast(txt),
        }

        if idx2 == 1 then
            -- 为3码兜底做准备
            if seg_len == 2 and (utf8_len(txt) or 0) == 1 and not w.has_eng then
                env.last_2code_char = txt
            end

            if w.is_table and #txt >= 4 and w.has_eng then
                emit_ctx.drop_sentence_after_completion = true
            end

            try_process_wrapper(w)
        elseif idx2 == 2 and mode == "unknown" then
            if w.is_table then
                mode = "passthrough"
                try_process_wrapper(w)
            else
                mode = "grouping"
                table.insert(normal_buf, w)
                try_flush_page_sort(false)
            end
        else
            if mode == "passthrough" then
                try_process_wrapper(w)
            else
                if (not window_closed) and (grouped_cnt < sort_window) then
                    grouped_cnt = grouped_cnt + 1
                    if w.is_table and not w.has_eng then
                        table.insert(special_buf, w)
                    else
                        table.insert(normal_buf, w)
                    end

                    if grouped_cnt >= sort_window then
                        window_closed = true
                    end
                    try_flush_page_sort(false)
                else
                    if w.is_table and not w.has_eng then
                        table.insert(special_buf, w)
                    else
                        table.insert(normal_buf, w)
                    end
                    try_flush_page_sort(false)
                end
            end
        end
    end

    if mode == "grouping" then
        try_flush_page_sort(true)
    end
    -- 单字无候选时兜底
    check_and_yield_fallback()
end
return M
