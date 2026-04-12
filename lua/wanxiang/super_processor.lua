---Enhances input processing by limiting repeated keystrokes and enforcing backspace limits.
---@module "wanxiang.super_processor"
---@author amzxyz
---@author Fidel Yin <fidel.yin@hotmail.com>

-- Features:
-- RepeatLimit: 重复限制
-- BackspaceLimit: 退格限制

---@class SuperProcessorConfig
---
---Config for RepeatLimit
---@field limit_repeated_enabled boolean
---@field backspace_limit_enabled boolean
---@field predict_space_enabled boolean
---@field max_repeat integer
---@field max_segments integer

---@class SuperProcessorState
---
---States for BackspaceLimit
---@field bs_prev_len integer
---@field bs_sequence boolean
---
---States for PredictSpace
---@field pending_predict_space boolean
---
---@field update_notifier Connection

---@class Env
---@field super_processor_config SuperProcessorConfig?
---@field super_processor_state SuperProcessorState?

local wanxiang = require("wanxiang.wanxiang")

-- [RepeatLimit] 重复限制默认配置 (现已支持配置覆盖)
local INITIALS = "[bpmfdtnlgkhjqxrzcsywiu]"

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

local P = {}

---@param env Env
function P.init(env)
    local rime_config = env.engine.schema.config

    local backspace_limit_enabled = rime_config:get_bool("super_processor/enable_backspace_limit")
    if backspace_limit_enabled == nil then
        backspace_limit_enabled = false
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

    -- [2] 统一 Update Notifier (状态缓存与自动处理)
    local update_notifier = env.engine.context.update_notifier:connect(function(ctx)
        local state = env.super_processor_state
        assert(state)

        -- [Predict Space] 联想空格接力起跑点
        if state.pending_predict_space then
            state.pending_predict_space = false
            ctx:set_option("_dummy_predict_update", false)
            ctx:clear()
            env.engine:commit_text(" ")
        end
    end)

    env.super_processor_config = {
        limit_repeated_enabled = limit_repeated_enabled,
        backspace_limit_enabled = backspace_limit_enabled,
        predict_space_enabled = predict_space_enabled,
        max_repeat = max_repeat,
        max_segments = max_segments,
    }

    env.super_processor_state = {
        bs_prev_len = -1,
        bs_sequence = false,
        pending_predict_space = false,
        update_notifier = update_notifier,
    }
end

---@param env Env
function P.fini(env)
    env.super_processor_state.update_notifier:disconnect()
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

    -- 优先处理按键释放
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

    -- TODO: move to english processor
    if context.composition:empty() then
        if kc == 0xff0d or kc == 0xff8d or kc == 0x20 then
            context:set_property("english_spacing", "true")
        end
        if kc == 0x5c or kc == 0x2f then
            context:set_property("force_sticky_code", "true")
        end
    end

    -- [BackspaceLimit] 退格防止删除已上屏内容
    if kc == 0xFF08 then
        if handle_backspace(key, config, state, context) then
            return wanxiang.RIME_PROCESS_RESULTS.kAccepted
        end
    end

    -- [RepeatLimit] 重复输入限制
    if kc >= 0x61 and kc <= 0x7A then
        if handle_limit_repeat(key, config, context) then
            return wanxiang.RIME_PROCESS_RESULTS.kAccepted
        end
    end

    return wanxiang.RIME_PROCESS_RESULTS.kNoop
end

return P
