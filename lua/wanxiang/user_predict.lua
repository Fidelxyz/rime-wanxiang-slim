---Implements an advanced predictive text engine featuring n-gram models, time-decayed ranking, cross-device synchronization, and context-aware candidate prediction and filtering.
---@module "wanxiang.user_predict"
---@author amzxyz
---@author Fidel Yin <fidel.yin@hotmail.com>

-- 架构层: Processor (物理按键截取与逻辑分发) + Translator (候选词生成与上屏) + Filter (输入调频)
-- 算法层:
-- 1. 瀑布流查询模型 (S-Gram -> 2-Gram 精确 -> 1-Gram 断崖回退 -> P-Gram 模糊抗抖动)
-- 2. 双重衰减排名 (时间指数衰减 + 频次基础权重)
-- 3. 数据淘汰系统 (P记录30天清理 + 1/2记录90天生命周期)
-- 4. 事务级回滚机制 (拦截上屏立即退格，复原上次数据库操作)
-- 5. LWW 智能合并 (导入数据时采用 Last Write Wins 策略，保留最新时间戳数据)
-- 6. ABA 防折返输入 (拦截如"你好"->"你好"的自我循环，减少数据库无效记录)
-- 7. 继承原生主动删除 (Ctrl+Del / Shift+Del 物理销毁当前候选词的多维关联)
-- 8. 语境隔离与时效防御 (精准识别标点断句，外加 5秒 语境超时自动熔断防穿透)
-- 9. 语气助词智能白名单 (特许“吧呢吗”等助词接标点的合法性，实现终结符平滑解耦)
-- 10. 跨平台双层按键防线 (针对移动端软键盘强删字节的底层特性，彻底免疫退格乱码)

---@class UserPredictConfig
---@field max_candidates integer
---@field max_predictions integer
---@field expiry_seconds integer
---@field p_expiry_seconds integer
---@field activation_seconds integer
---@field max_memory_branches integer
---@field decay_rate number
---@field enable_predict_space boolean
---@field context_timeout_ms integer
---@field enable_post_predict boolean
---@field enable_context_reorder boolean
---@field db_name string
---@field page_size integer

---@class UserPredictProcessorState
---@field need_push boolean
---@field last_written_keys table<string, string>
---@field undo_stack table<string, string>[]
---@field just_committed boolean
---@field last_action_time number
---
---@field commit_notifier Connection
---@field update_notifier Connection
---@field db WrappedUserDb?

---@class UserPredictTranslatorState
---@field db WrappedUserDb?

---@class UserPredictFilterState
---@field reorder_map table<string, integer>
---@field db WrappedUserDb?

---@class Env
---@field user_predict_config UserPredictConfig?
---@field user_predict_processor_state UserPredictProcessorState?
---@field user_predict_translator_state UserPredictTranslatorState?
---@field user_predict_filter_state UserPredictFilterState?

---@class Prediction
---@field word string
---@field weight number
---@field db_key string

local wanxiang = require("wanxiang.wanxiang")
local userdb = require("wanxiang.userdb")

local SCAN_LIMIT = 80

-- 语气助词白名单与高频句末白名单
local PARTICLE_WHITELIST = {
    ["吧"] = true,
    ["呢"] = true,
    ["吗"] = true,
    ["啦"] = true,
    ["嘛"] = true,
    ["呀"] = true,
    ["恩"] = true,
    ["欸"] = true,
    ["哒"] = true,
    ["哈"] = true,
    ["哇"] = true,
    ["啊"] = true,
    ["哦"] = true,
    ["噢"] = true,
    ["咯"] = true,
    ["呗"] = true,
    ["哟"] = true,
    ["呦"] = true,
    ["哎"] = true,
    ["嗯"] = true,
    ["么"] = true,
    ["啥"] = true,
    ["谁"] = true,
    ["哪"] = true,
    ["里"] = true,
    ["儿"] = true,
    ["了"] = true,
    ["的"] = true,
    ["过"] = true,
    ["好"] = true,
    ["行"] = true,
    ["对"] = true,
    ["成"] = true,
}

---@param text string
---@return boolean
local function is_tone_symbol(text)
    return text:match("^[！？，。～]+$") ~= nil
end

-- 动态加载 YAML 方案配置
---@param env Env
---@return UserPredictConfig
local function load_config(env)
    local rime_config = env.engine.schema.config

    local max_candidates = rime_config:get_int("user_predict/max_candidates") or 5
    local max_predictions = rime_config:get_int("user_predict/max_predictions") or 3
    local expiry_seconds = (rime_config:get_int("user_predict/expiry_days") or 90) * 86400
    local activation_seconds = (rime_config:get_int("user_predict/activation_days") or 7) * 86400
    local max_memory_branches = rime_config:get_int("user_predict/max_memory_branches") or 15
    local decay_rate = rime_config:get_double("user_predict/decay_rate") or 0.85

    local enable_predict_space = rime_config:get_bool("user_predict/enable_predict_space")
    if enable_predict_space == nil then
        enable_predict_space = false
    end

    local context_timeout_ms = rime_config:get_int("user_predict/context_timeout")
    if context_timeout_ms == nil then
        context_timeout_ms = 5000
    end

    local enable_post_predict = rime_config:get_bool("user_predict/enable_post_predict")
    if enable_post_predict == nil then
        enable_post_predict = true
    end

    local enable_context_reorder = rime_config:get_bool("user_predict/enable_context_reorder")
    if enable_context_reorder == nil then
        enable_context_reorder = true
    end

    local db_name = rime_config:get_string("user_predict/db_name") or "lua/predict"

    local page_size = rime_config:get_int("user_predict/page_size") or 6

    ---@type UserPredictConfig
    local config = {
        max_candidates = max_candidates,
        max_predictions = max_predictions,
        expiry_seconds = expiry_seconds,
        p_expiry_seconds = 30 * 24 * 3600,
        activation_seconds = activation_seconds,
        max_memory_branches = max_memory_branches,
        decay_rate = decay_rate,
        enable_predict_space = enable_predict_space,
        context_timeout_ms = context_timeout_ms,
        enable_post_predict = enable_post_predict,
        enable_context_reorder = enable_context_reorder,
        db_name = db_name,
        page_size = page_size,
    }

    return config
end

local PH_CHAR = "›"

---@class UserPredictSharedState
---@field history string[]
---@field last_commit string
---@field last_commit_time number
---@field predict_count integer
---@field is_predicting boolean
---@field pending_cands Prediction[]?
local shared_state = {
    history = {},
    last_commit = "",
    last_commit_time = 0,
    predict_count = 0,
    is_predicting = false,
    pending_cands = nil,
}

-- 内存阻断模块：打断语境后洗白临时记忆链，防止长距离上下文穿透
---@param state UserPredictProcessorState
local function reset_memory_chain(state)
    for i = 1, #shared_state.history do
        shared_state.history[i] = nil
    end
    shared_state.last_commit = ""
    shared_state.last_commit_time = 0
    shared_state.predict_count = 0
    shared_state.is_predicting = false
    shared_state.pending_cands = nil
    state.need_push = false
end

-- 语境分割算法 (纯汉字白名单)

---@param text string
---@return boolean
local function is_valid_commit_text(text)
    if text == "" then
        return false
    end

    if is_tone_symbol(text) then
        return true -- 特许白名单语气标点通行
    end

    for c in text:gmatch("[%z\1-\127\194-\244][\128-\191]*") do
        if not wanxiang.is_chinese_char(c) then
            return false
        end
    end
    return true
end

-- 分词聚集算法
---@param str string
---@return string[]
local function get_utf8_chars(str)
    if str == "" then
        return {}
    end

    if str:match("^[a-zA-Z0-9]+$") or is_tone_symbol(str) then
        return { str }
    end

    ---@type string[]
    local chars = {}
    for c in str:gmatch("[%z\1-\127\194-\244][\128-\191]*") do
        table.insert(chars, c)
    end
    return chars
end

-- 模糊查询降级参数 (现在统一供 1 和 P 使用)
local function get_suffix_lengths(len)
    if len >= 4 then
        return { 4, 3, 2 }
    elseif len == 3 then
        return { 3, 2 }
    elseif len == 2 then
        return { 2 }
    elseif len == 1 then
        return { 1 }
    end
    return {}
end

--全局过期数据回收
local _last_sweep_memory = 0
---@param db WrappedUserDb
---@param config UserPredictConfig
local function sweep_expired_data(db, config)
    local now = wanxiang.now()

    if (now - _last_sweep_memory) < 86400 then
        return
    end

    local last_sweep_str = db:fetch("\0_last_sweep")
    local db_last_sweep = tonumber(last_sweep_str) or 0

    if (now - db_last_sweep) < 86400 then
        _last_sweep_memory = db_last_sweep
        return
    end

    -- 开启全库扫描
    for k, v in db:query(""):iter() do
        if k:sub(1, 1) ~= "\1" and k:sub(1, 1) ~= "\0" then
            local _, ts_str = v:match("^([^|]+)|?(.*)$")
            local ts = tonumber(ts_str) or 0

            -- 区分 P 记录和正式记录的寿命
            local is_p_gram = (k:sub(1, 2) == "P\t")
            local current_limit = is_p_gram and config.p_expiry_seconds or config.expiry_seconds
            if ts == 0 then
                ts = now - current_limit - 1
            end
            if (now - ts) > current_limit then
                db:erase(k)
            end
        end
    end

    collectgarbage() -- Release DbAccessor

    db:update("\0_last_sweep", tostring(now))
    _last_sweep_memory = now
end

-- 读取层预测核心
---@param prev_commit string
---@param db WrappedUserDb
---@param config UserPredictConfig
---@return Prediction[]?
local function get_predictions(prev_commit, db, config)
    if prev_commit == "" then
        return nil
    end

    ---@type Prediction[]
    local cands = {}
    ---@type table<string, boolean>
    local seen = {}

    ---@param query_key string
    ---@param multiplier number
    local function fetch_and_clean(query_key, multiplier)
        local da = db:query(query_key)

        local scan_count = 0
        local now = wanxiang.now()
        ---@type Prediction[]
        local prefix_cands = {}

        for k, v in da:iter() do
            if scan_count >= SCAN_LIMIT or not k:find(query_key, 1, true) then
                break
            end

            if k:sub(1, 1) ~= "\1" then
                local word = k:sub(query_key:len() + 1)
                local c_str, ts_str = v:match("^([^|]+)|?(.*)$")
                local count = tonumber(c_str) or 0
                local ts = tonumber(ts_str) or 0

                local is_p_gram = (k:sub(1, 2) == "P\t")
                local limit = is_p_gram and config.p_expiry_seconds or config.expiry_seconds

                if ts == 0 then
                    ts = now - limit - 1
                end

                if (now - ts) > limit then
                    db:erase(k)
                elseif count > 0 then
                    local age_days = (now - ts) / 86400.0
                    local score = count * (config.decay_rate ^ age_days) * multiplier
                    if score > 0.05 and word ~= "" then
                        table.insert(prefix_cands, { word = word, weight = score, db_key = k })
                    end
                end
            end
            scan_count = scan_count + 1
        end

        if #prefix_cands > 0 then
            table.sort(prefix_cands, function(a, b)
                return a.weight > b.weight
            end)
            for i, c in ipairs(prefix_cands) do
                if i <= config.max_memory_branches then
                    if not seen[c.word] then
                        table.insert(cands, c)
                        seen[c.word] = true
                    end
                else
                    db:update(c.db_key, "0|" .. tostring(now))
                end
            end
        end

        da = nil ---@diagnostic disable-line: cast-local-type
        collectgarbage() -- Release DbAccessor
    end

    -- S先读
    if #shared_state.history >= 1 then
        fetch_and_clean("S\t" .. shared_state.history[#shared_state.history] .. "\t", 1000000)
    end

    -- 小于等于2先找上文组合查 2-Gram
    if #shared_state.history >= 2 then
        local u1 = shared_state.history[#shared_state.history]
        if #get_utf8_chars(u1) <= 2 then
            fetch_and_clean("2\t" .. shared_state.history[#shared_state.history - 1] .. "\t" .. u1 .. "\t", 10000)
        end
    end

    -- 查 1-Gram
    if #cands < config.max_candidates and #shared_state.history >= 1 then
        local u1 = shared_state.history[#shared_state.history]
        local chars = get_utf8_chars(u1)
        local len_u1 = #chars

        local max_len = math.min(len_u1, 4)
        local min_len = (len_u1 >= 2) and 2 or 1

        for l = max_len, min_len, -1 do
            local lookup_u1 = table.concat(chars, "", len_u1 - l + 1, len_u1)
            fetch_and_clean("1\t" .. lookup_u1 .. "\t", 100)
            if #cands > 0 then
                break
            end
        end
    end

    -- 查不到再去拿 P 去匹配
    if #cands < config.max_candidates then
        local chars = get_utf8_chars(prev_commit)
        local lengths_to_query = get_suffix_lengths(#chars)
        for _, l in ipairs(lengths_to_query) do
            fetch_and_clean("P\t" .. table.concat(chars, "", #chars - l + 1, #chars) .. "\t", 1)
            if #cands > 0 then
                break
            end
        end
    end

    if #cands > 0 then
        table.sort(cands, function(a, b)
            return a.weight > b.weight
        end)
        return cands
    end
    return nil
end

local P = {}

---@param env Env
function P.init(env)
    env.user_predict_config = load_config(env)
    local config = env.user_predict_config
    assert(config)

    local db = userdb.LevelDb(config.db_name)
    if db then
        db:open()
        sweep_expired_data(db, config)
    end

    local commit_notifier = env.engine.context.commit_notifier:connect(function(ctx)
        local config = env.user_predict_config
        assert(config)
        local state = env.user_predict_processor_state
        assert(state)

        local text = ctx:get_commit_text()

        if not is_valid_commit_text(text) then
            reset_memory_chain(state) -- 非纯汉字阻断
            return
        end

        local current_time = rime_api.get_time_ms()
        if
            shared_state.last_commit ~= ""
            and (current_time - shared_state.last_commit_time) > config.context_timeout_ms
        then
            reset_memory_chain(state) -- 输入超时
        end

        if not shared_state.is_predicting then
            shared_state.is_predicting = true
            shared_state.predict_count = 1
        else
            shared_state.predict_count = shared_state.predict_count + 1
        end

        if shared_state.predict_count > config.max_predictions then
            shared_state.is_predicting = false
            shared_state.predict_count = 0
            shared_state.pending_cands = nil
            return
        end

        state.last_written_keys = {}

        ---@param key string
        ---@param is_tone boolean
        local function update_memory(key, is_tone)
            if not db then
                return
            end

            local val = db:fetch(key)
            local now = wanxiang.now()
            state.last_written_keys[key] = val or ""

            if not val or val == "" then
                if is_tone then
                    db:update(key, "1|" .. tostring(now))
                else
                    db:update(key, "0|" .. tostring(now))
                end
            else
                local c_str, ts_str = val:match("^([^|]+)|?(.*)$")
                local count = tonumber(c_str) or 0
                local ts = tonumber(ts_str) or 0
                local age = now - ts
                if age > config.expiry_seconds then
                    db:update(key, "0|" .. tostring(now))
                elseif count == 0 then
                    if age <= config.activation_seconds then
                        db:update(key, "1|" .. tostring(now))
                    else
                        db:update(key, "0|" .. tostring(now))
                    end
                else
                    db:update(key, tostring(count + 1) .. "|" .. tostring(now))
                end
            end
        end

        current_time = rime_api.get_time_ms()

        local should_record = true
        local is_terminal_symbol = false
        local text_chars = get_utf8_chars(text)
        local len_text = #text_chars

        -- 基础规则：单次上屏超过 4 个字不记录
        if len_text > 4 then
            should_record = false
        end

        -- 基础规则：标点与助词白名单隔离
        if should_record and is_tone_symbol(text) then
            local prev_chars = get_utf8_chars(shared_state.last_commit)
            local last_char = prev_chars[#prev_chars] or ""

            if not PARTICLE_WHITELIST[last_char] then
                should_record = false
                reset_memory_chain(state) -- 非助词接标点
            else
                is_terminal_symbol = true
            end
        end

        -- 基础规则：防折返输入
        if should_record and shared_state.last_commit == text then
            should_record = false
        end
        if should_record and #shared_state.history >= 2 then
            if text == shared_state.history[#shared_state.history - 1] then
                should_record = false
                table.remove(shared_state.history, #shared_state.history)
                shared_state.last_commit = shared_state.history[#shared_state.history] or ""
            end
        end

        -- 核心录入逻辑区
        if db and should_record then
            local text_is_tone = is_tone_symbol(text)

            -- 常规上文级联录入
            if shared_state.last_commit ~= "" then
                local u1_chars = get_utf8_chars(shared_state.last_commit)
                local len_u1 = #u1_chars

                -- P-Gram
                local lengths_to_learn = get_suffix_lengths(len_u1)
                for _, l in ipairs(lengths_to_learn) do
                    if l < len_u1 or len_u1 >= 4 then
                        update_memory(
                            "P\t" .. table.concat(u1_chars, "", len_u1 - l + 1, len_u1) .. "\t" .. text,
                            text_is_tone
                        )
                    end
                end

                -- 1-Gram
                if len_u1 <= 4 and #shared_state.history >= 1 then
                    update_memory("1\t" .. shared_state.last_commit .. "\t" .. text, text_is_tone)
                end

                -- 2-Gram
                if len_u1 <= 4 and #shared_state.history >= 2 then
                    local u0 = shared_state.history[#shared_state.history - 1]
                    local len_u0 = u0 and #get_utf8_chars(u0) or 0
                    if (len_u0 + len_u1) <= 5 then
                        update_memory("2\t" .. u0 .. "\t" .. shared_state.last_commit .. "\t" .. text, text_is_tone)
                    end
                end
            end

            -- 四字成语的 2+2 自我拆分学习
            if len_text == 4 then
                local part1 = text_chars[1] .. text_chars[2]
                local part2 = text_chars[3] .. text_chars[4]

                local is_known_prefix = false
                for _, prefix in ipairs({ "1", "P" }) do
                    local query_key = prefix .. "\t" .. part1 .. "\t"
                    local da = db:query(query_key)
                    if da then
                        for k, _ in da:iter() do
                            if k:find(query_key, 1, true) then
                                is_known_prefix = true
                                break
                            end
                        end
                    end
                    if is_known_prefix then
                        break
                    end
                end
                collectgarbage() -- Release DbAccessor

                if is_known_prefix then
                    update_memory("1\t" .. part1 .. "\t" .. part2, false)
                end
            end
        end

        -- 调用逻辑解耦
        if should_record then
            if is_terminal_symbol then
                reset_memory_chain(state) -- 终结符上屏完毕
            else
                table.insert(shared_state.history, text)
                if #shared_state.history > 2 then
                    table.remove(shared_state.history, 1)
                end
                shared_state.last_commit = text
            end
        end

        -- 事务入栈：把本次写库的记录推入回滚栈（最大保留 3 级）
        state.undo_stack = state.undo_stack or {}
        if next(state.last_written_keys) ~= nil then
            table.insert(state.undo_stack, state.last_written_keys)
            if #state.undo_stack > 3 then
                table.remove(state.undo_stack, 1)
            end
        end

        shared_state.last_commit_time = current_time
        state.last_action_time = current_time
        state.just_committed = true

        -- 如果两个开关都没开，绝对不去查库！绝对不建缓存
        if
            db
            and shared_state.predict_count <= config.max_predictions
            and ctx:get_option("prediction")
            and (config.enable_post_predict or config.enable_context_reorder)
        then
            shared_state.pending_cands = get_predictions(shared_state.last_commit, db, config)
            if shared_state.pending_cands and config.enable_post_predict then
                state.need_push = true
            else
                shared_state.predict_count = 0
                shared_state.is_predicting = false
            end
        else
            shared_state.predict_count = 0
            shared_state.is_predicting = false
            shared_state.pending_cands = nil
        end
    end)

    local update_notifier = env.engine.context.update_notifier:connect(function(ctx)
        if not db then
            return
        end

        local state = env.user_predict_processor_state
        assert(state)

        local input = ctx.input

        if input == "/outpredict" then
            ctx:clear()
            local sync_path = rime_api.get_user_data_dir() .. "/predict_export.txt"
            local f = io.open(sync_path, "w")
            if f then
                for k, v in db:query(""):iter() do
                    if k:sub(1, 1) ~= "\1" and k:sub(1, 1) ~= "\0" then
                        f:write(k .. "\t" .. v .. "\n")
                    end
                end
                collectgarbage() -- Release DbAccessor
                f:close()
            end
            reset_memory_chain(state) -- 导出结束
            return
        end

        if input == "/inpredict" then
            ctx:clear()
            local sync_path = rime_api.get_user_data_dir() .. "/predict_import.txt"
            local f = io.open(sync_path, "r")
            if f then
                for line in f:lines() do
                    ---@type string?, string?
                    local k, v = line:match("^(.*)\t([^\t]+)$")
                    if k and v then
                        local old_v = db:fetch(k)
                        if old_v and old_v ~= "" then
                            local _, old_ts = old_v:match("^([^|]+)|?(.*)$")
                            local _, new_ts = v:match("^([^|]+)|?(.*)$")
                            local o_ts = tonumber(old_ts) or 0
                            local n_ts = tonumber(new_ts) or 0

                            if n_ts > o_ts then
                                db:update(k, v)
                            end
                        else
                            db:update(k, v)
                        end
                    end
                end
                f:close()
            end
            reset_memory_chain(state) -- 导入结束
            return
        end

        local expected_ph = PH_CHAR:rep(shared_state.predict_count)
        local expected_len = expected_ph:len()

        if state.need_push and input == "" then
            state.need_push = false
            ctx:push_input(expected_ph)
            ctx.caret_pos = expected_len
            return
        end

        if input:find(PH_CHAR) then
            if input ~= expected_ph then
                local clean_text = input:gsub(PH_CHAR, "")
                ctx:clear()
                shared_state.predict_count = 0
                shared_state.is_predicting = false
                shared_state.pending_cands = nil
                if clean_text ~= "" then
                    ctx:push_input(clean_text)
                end
                return
            else
                if ctx.caret_pos < expected_len then
                    ctx:clear()
                    shared_state.predict_count = 0
                    shared_state.is_predicting = false
                    shared_state.pending_cands = nil
                    return
                end
            end
        end
    end)

    env.user_predict_processor_state = {
        need_push = false,
        last_written_keys = {},
        just_committed = false,
        last_action_time = 0,
        undo_stack = {},
        commit_notifier = commit_notifier,
        update_notifier = update_notifier,
        db = db,
    }
end

---@param env Env
function P.fini(env)
    env.user_predict_processor_state.commit_notifier:disconnect()
    env.user_predict_processor_state.update_notifier:disconnect()
    env.user_predict_config = nil
    env.user_predict_processor_state = nil
end

---@param key KeyEvent
---@param env Env
---@return ProcessResult
function P.func(key, env)
    local config = env.user_predict_config
    assert(config)
    local state = env.user_predict_processor_state
    assert(state)

    local context = env.engine.context

    if key:release() then
        return wanxiang.RIME_PROCESS_RESULTS.kNoop
    end

    local repr = key:repr()
    if
        state.just_committed
        and repr ~= "BackSpace"
        and not repr:match("Shift")
        and not repr:match("Control")
        and not repr:match("Alt")
    then
        state.just_committed = false
    end

    if repr == "BackSpace" then
        local current_time = rime_api.get_time_ms()

        -- 仅在“输入框完全为空”或者“只有联想占位符”时，才允许撤销数据库，彻底防范打拼音时误删！
        local is_safe_to_undo = (not context:is_composing() or shared_state.is_predicting)

        if is_safe_to_undo and #state.undo_stack > 0 then
            -- 延时策略：如果在规定时间内连按退格
            if current_time - state.last_action_time <= config.context_timeout_ms then
                ---@type table<string, string>
                local keys_to_undo = table.remove(state.undo_stack)
                local db = state.db
                if db then
                    for k, v in pairs(keys_to_undo) do
                        if v == "" then
                            db:erase(k)
                        else
                            db:update(k, v)
                        end
                    end
                end
                state.last_action_time = current_time
            else
                state.undo_stack = {}
            end
        end
        state.just_committed = false
        if shared_state.is_predicting then
            context:clear()
            reset_memory_chain(state) -- 退格强清联想
            return wanxiang.RIME_PROCESS_RESULTS.kAccepted
        end
    end

    if shared_state.is_predicting then
        local is_alt_key = (repr == "Tab" or repr == "Alt" or repr == "Alt_L" or repr == "Alt_R")

        -- 根据选词范围分流数字键
        if repr:match("^[0-9]$") or repr:match("^KP_[0-9]$") then
            local digit_str = repr:match("%d")
            local digit = tonumber(digit_str)
            if digit == 0 then
                digit = 10
            end

            local is_valid_candidate = false
            local seg = context.composition:back()
            if seg then
                local current_page = math.floor(seg.selected_index / config.page_size)
                local target_index = current_page * config.page_size + (digit - 1)
                if seg:get_candidate_at(target_index) then
                    is_valid_candidate = true
                end
            end

            if digit > config.page_size or not is_valid_candidate then
                context:clear()
                if reset_memory_chain then
                    reset_memory_chain(state) -- 非选词数字打断联想并上屏
                end
                env.engine:commit_text(digit_str)
                return wanxiang.RIME_PROCESS_RESULTS.kAccepted
            else
                -- 选词范围内的数字（如 1-6）：放行，让 super_processor 去执行正常的选词
                return wanxiang.RIME_PROCESS_RESULTS.kNoop
            end
        end

        if config.enable_predict_space then
            -- enable_predict_space: true
            if key.keycode == 0x20 then
                context:clear()
                reset_memory_chain(state) -- 空格打断联想并上屏
                env.engine:commit_text(" ")
                return wanxiang.RIME_PROCESS_RESULTS.kAccepted
            elseif is_alt_key then
                context:clear()
                reset_memory_chain(state) -- 替身键打断联想
                return wanxiang.RIME_PROCESS_RESULTS.kAccepted
            end
        else
            -- enable_predict_space: false
            if is_alt_key then
                context:clear()
                reset_memory_chain(state) -- 替身键打断联想并上屏空格
                env.engine:commit_text(" ")
                return wanxiang.RIME_PROCESS_RESULTS.kAccepted
            end
        end

        if repr == "Return" then
            context:clear()
            reset_memory_chain(state) -- 打断键清除预测
            return wanxiang.RIME_PROCESS_RESULTS.kAccepted
        end
    end

    if not context:is_composing() then
        if repr == "Return" or repr == "KP_Enter" or key.keycode == 0x20 then
            reset_memory_chain(state) -- 非输入状态排版打断
            return wanxiang.RIME_PROCESS_RESULTS.kNoop
        end
        local symbol_map = { ["?"] = "？", ["!"] = "！", [","] = "，", ["."] = "。" }
        if symbol_map[repr] then
            env.engine:commit_text(symbol_map[repr])
            return wanxiang.RIME_PROCESS_RESULTS.kAccepted
        end
    end

    if
        context:has_menu()
        and (repr:find("Shift") or repr:find("Control"))
        and (repr:find("Delete") or repr:find("BackSpace"))
    then
        local cand = context:get_selected_candidate()
        if cand and cand.type == "predict" then
            local word = cand.text
            local db = state.db

            local exact_key = nil
            if shared_state.pending_cands then
                for _, c in ipairs(shared_state.pending_cands) do
                    if c.word == word then
                        exact_key = c.db_key
                        break
                    end
                end
            end
            if db and exact_key then
                db:erase(exact_key)
            end

            local chars = get_utf8_chars(shared_state.last_commit)
            local lengths = get_suffix_lengths(#chars)
            if db then
                for _, l in ipairs(lengths) do
                    db:erase("P\t" .. table.concat(chars, "", #chars - l + 1, #chars) .. "\t" .. word)
                end
            end

            context:clear()
            reset_memory_chain(state) -- 物理销毁词条
            return wanxiang.RIME_PROCESS_RESULTS.kAccepted
        end
    end
    return wanxiang.RIME_PROCESS_RESULTS.kNoop
end

local T = {}

---@param env Env
function T.init(env)
    env.user_predict_config = load_config(env)
    local config = env.user_predict_config
    assert(config)

    local db = userdb.LevelDb(config.db_name)
    if db then
        db:open()
    end

    env.user_predict_translator_state = {
        db = db,
    }
end

---@param env Env
function T.fini(env)
    env.user_predict_translator_state = nil
    env.user_predict_config = nil
end

---@param input string
---@param seg Segment
---@param env Env
function T.func(input, seg, env)
    local config = env.user_predict_config
    assert(config)

    -- 受总开关与联想开关联合控制
    if not env.engine.context:get_option("prediction") or not config.enable_post_predict then
        return
    end

    if input:match("^[›]+$") and shared_state.pending_cands then
        local count = 0
        for _, c in ipairs(shared_state.pending_cands) do
            if count >= config.max_candidates then
                break
            end
            local cand = Candidate("predict", seg.start, seg._end, c.word, "")
            yield(cand)
            count = count + 1
        end
    end
end

-- Filter (F): 负责输入生命周期内的极速实时调频
local F = {}

---@param env Env
function F.init(env)
    env.user_predict_config = load_config(env)
    local config = env.user_predict_config
    assert(config)

    local db = userdb.LevelDb(config.db_name)
    if db then
        db:open()
    end

    env.user_predict_filter_state = {
        last_commit = "",
        reorder_map = {},
        db = db,
    }
end

---@param env Env
function F.fini(env)
    env.user_predict_config = nil
    env.user_predict_filter_state = nil
end

---@param input Translation
---@param env Env
function F.func(input, env)
    local config = env.user_predict_config
    assert(config)
    local state = env.user_predict_filter_state
    assert(state)

    local context = env.engine.context

    -- 过滤开关规避 (总开关没开、调频没开、或者正在联想)，原样放行，0 损耗
    if not context:get_option("prediction") or not config.enable_context_reorder or context.input:match("^[›]+$") then
        for cand in input:iter() do
            yield(cand)
        end
        return
    end

    -- 独立生命周期管理与“缓存白嫖”机制
    if shared_state.last_commit ~= shared_state.last_commit then
        shared_state.last_commit = shared_state.last_commit
        state.reorder_map = {}

        -- 严格判断调频开关是否开启，没开绝不查库
        if shared_state.last_commit ~= "" and config.enable_context_reorder then
            -- 优先白嫖 P 模块查好的全局缓存，如果 P 模块没查（比如没开联想），F 就自己查一次作为兜底
            local preds = shared_state.pending_cands or get_predictions(shared_state.last_commit, state.db, config)
            if preds then
                state.reorder_map = {}
                for rank, p in ipairs(preds) do
                    state.reorder_map[p.word] = rank
                end
            end
        end
    end

    if next(state.reorder_map) or context.input == "" then
        for cand in input:iter() do
            yield(cand)
        end
        return
    end

    ---@type { cand: Candidate, rank: number }[]
    local boosted = {}
    ---@type Candidate[]
    local normal = {}
    local count = 0
    local max_scan = 50
    local stop_scanning = false
    local target_len = 0 -- 用于记录首选词的字数

    -- 实时匹配与拦截
    for cand in input:iter() do
        if stop_scanning then
            yield(cand)
        else
            count = count + 1
            local text = cand.text or ""

            local current_len = #get_utf8_chars(text)

            if count == 1 then
                target_len = current_len
            end

            if
                cand.type == "raw"
                or cand.type == "english"
                or text:match("^[a-zA-Z]+$")
                or (count > 1 and current_len ~= target_len)
            then
                stop_scanning = true
                -- 结算已经收集到的同等字数的词
                table.sort(boosted, function(a, b)
                    return a.rank < b.rank
                end)
                for _, b in ipairs(boosted) do
                    yield(b.cand)
                end
                for _, n in ipairs(normal) do
                    yield(n)
                end
                yield(cand)
            else
                local rank = state.reorder_map[text]
                if rank then
                    table.insert(boosted, { cand = cand, rank = rank })
                else
                    table.insert(normal, cand)
                end

                if count >= max_scan then
                    stop_scanning = true
                    table.sort(boosted, function(a, b)
                        return a.rank < b.rank
                    end)
                    for _, b in ipairs(boosted) do
                        yield(b.cand)
                    end
                    for _, n in ipairs(normal) do
                        yield(n)
                    end
                end
            end
        end
    end
    -- 兜底排放
    if not stop_scanning then
        table.sort(boosted, function(a, b)
            return a.rank < b.rank
        end)
        for _, b in ipairs(boosted) do
            yield(b.cand)
        end
        for _, n in ipairs(normal) do
            yield(n)
        end
    end
end

return { P = P, T = T, F = F }
