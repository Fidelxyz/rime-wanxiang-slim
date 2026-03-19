-- lua/force_upper_aux.lua
-- @description: 自动施加辅助码。按一下：全长度N锁定当前；按两下：N-1长度回退历史。
-- @author: amzxyz

local ForceUpperAux = {}
local wanxiang = require("wanxiang/wanxiang")

-- 获取 UTF-8 字符
local function get_utf8_char(str, index)
    local start_byte = utf8.offset(str, index)
    if not start_byte then
        return nil
    end
    local end_byte = utf8.offset(str, index + 1)
    return string.sub(str, start_byte, (end_byte and end_byte - 1) or nil)
end

-- 获取 UTF-8 前缀
local function get_utf8_prefix(str, n)
    if not str or str == "" or n <= 0 then
        return ""
    end
    local offset = utf8.offset(str, n + 1)
    return offset and string.sub(str, 1, offset - 1) or str
end

-- 获取分隔符
local function get_delimiters(ctx)
    local cfg = ctx.engine and ctx.engine.schema and ctx.engine.schema.config
    local delimiter = (cfg and cfg:get_string("speller/delimiter")) or " '"
    local d1 = get_utf8_char(delimiter, 1) or " "
    local d2 = get_utf8_char(delimiter, 2) or "'"
    return d1, d2
end

-- 转义正则符号
local function esc_class(c)
    return (c:gsub("([%%%^%]%-])", "%%%1"))
end

-- 获取输入切分后的拼音部分
local function get_script_text_parts(ctx)
    local raw_in = ctx.input or ""
    local prop_key = ctx:get_property("sequence_preedit_key") or ""
    local prop_val = ctx:get_property("sequence_preedit_val") or ""
    local script_txt = ctx:get_script_text() or ""
    local s = (prop_key == raw_in and prop_val ~= "") and prop_val or script_txt
    if s == "" then
        return {}
    end
    local auto, manual = get_delimiters(ctx)
    local pat = "[^" .. esc_class(auto) .. esc_class(manual) .. "%s]+"
    local parts = {}
    for w in s:gmatch(pat) do
        parts[#parts + 1] = w
    end
    return parts
end

-- 查询辅助码
local function lookup_aux_code(env, char)
    if not env.dict then
        return ""
    end
    if env.aux_cache[char] then
        return env.aux_cache[char]
    end
    local raw_code = env.dict:lookup(char)
    if not raw_code or raw_code == "" then
        return ""
    end
    local aux_part = raw_code:match(";([^,]+)") or raw_code:match("^([^;]+)") or ""
    local final_code = aux_part:gsub("[^a-zA-Z]", ""):sub(1, 2):upper()
    env.aux_cache[char] = final_code
    return final_code
end

-- 初始化
function ForceUpperAux.init(env)
    local config = env.engine.schema.config
    env.trigger_key = config:get_string("force_upper_aux/hotkey") or "Tab"
    env.aux_cache = {}

    local dict_name = config:get_string("translator/dictionary") or "wanxiang_pro"
    env.dict = ReverseLookup(dict_name)

    env.history_first = {}
    env.press_count = 0
    env.is_cycling = false
    env.snapshot_parts = nil
    env.snapshot_current_full = ""

    env.on_update = function(ctx)
        -- 调用外部模块函数，如果在功能模式则不记录历史
        -- 这里 env.is_cycling 起到了锁的作用，防止在按快捷键修改输入时陷入循环
        local is_special_mode = wanxiang.s2t_conversion and wanxiang.s2t_conversion(ctx)
        if env.is_cycling or wanxiang.is_function_mode_active(ctx) or is_special_mode then
            return
        end

        if not ctx:is_composing() then
            env.history_first = {}
            env.press_count = 0
            env.is_cycling = false
            return
        end

        local parts = get_script_text_parts(ctx)
        local parts_count = #parts
        if parts_count == 0 then
            return
        end

        local comp = ctx.composition
        if not comp:empty() then
            local segment = comp:back()
            local cand = segment:get_candidate_at(0)
            if cand and cand.text then
                if not env.history_first[parts_count] then
                    env.history_first[parts_count] = get_utf8_prefix(cand.text, parts_count)
                end
            end
        end
    end
    -- 仅在初始化时连接一次
    env.update_conn = env.engine.context.update_notifier:connect(env.on_update)
end

function ForceUpperAux.fini(env)
    -- 在 fini 周期内统一断开连接器，并释放大对象引用，避免内存泄漏
    if env.update_conn then
        env.update_conn:disconnect()
        env.update_conn = nil
    end
    env.dict = nil
    env.aux_cache = nil
    env.history_first = nil
    env.snapshot_parts = nil
end

-- 核心逻辑
function ForceUpperAux.func(key_event, env)
    if key_event:release() then
        return 2
    end
    local ctx = env.engine.context

    -- 功能模式检查 + 特殊标签检查（数字、标点等）
    local is_special_mode = wanxiang.s2t_conversion and wanxiang.s2t_conversion(ctx)
    if wanxiang.is_function_mode_active(ctx) or is_special_mode then
        return 2
    end

    local current_key = key_event:repr()
    if current_key == env.trigger_key then
        if not ctx:is_composing() then
            return 2
        end

        -- 首次按下捕捉快照
        if env.press_count == 0 then
            env.snapshot_parts = get_script_text_parts(ctx)
            local comp = ctx.composition
            if not comp:empty() then
                local cand = comp:back():get_candidate_at(0)
                if cand then
                    env.snapshot_current_full = get_utf8_prefix(cand.text, #env.snapshot_parts)
                end
            end
        end

        local parts = env.snapshot_parts
        if not parts or #parts == 0 then
            return 2
        end

        env.press_count = env.press_count + 1
        -- 开启循环锁，这样下面修改 ctx.input 触发的 on_update 会被直接拦截
        env.is_cycling = true

        local parts_count = #parts
        local candidate_text = ""
        local apply_until = 0

        if env.press_count % 2 == 1 then
            -- 按一次：全长度 N
            candidate_text = env.snapshot_current_full
            apply_until = parts_count
        else
            -- 按两次：回退 N-1
            local n_minus_1 = math.max(1, parts_count - 1)
            candidate_text = env.history_first[n_minus_1] or get_utf8_prefix(env.snapshot_current_full, n_minus_1)
            apply_until = n_minus_1
        end

        -- 使用表来收集字符串分片，最后使用 table.concat 一次性拼接
        local new_input_parts = {}
        local text_len = utf8.len(candidate_text) or 0
        local found_any_aux = false

        for i = 1, parts_count do
            local syl = parts[i]
            if i <= apply_until and i <= text_len then
                local pinyin_offset = utf8.offset(syl, 3)
                local pinyin = pinyin_offset and string.sub(syl, 1, pinyin_offset - 1) or syl

                local char = get_utf8_char(candidate_text, i)
                local aux = lookup_aux_code(env, char)
                if aux and aux ~= "" then
                    new_input_parts[i] = pinyin .. aux
                    found_any_aux = true
                else
                    new_input_parts[i] = syl
                end
            else
                new_input_parts[i] = syl
            end
        end
        if not found_any_aux then
            env.press_count = 0
            env.is_cycling = false
            env.snapshot_parts = nil
            return 2
        end

        local new_input = table.concat(new_input_parts)

        if new_input ~= "" and new_input ~= ctx.input then
            -- 此时修改 input 会触发 on_update，但会被 env.is_cycling == true 完美拦截
            ctx.input = new_input
        end

        return 1
    else
        -- 任意其他键按下，重置状态机
        env.press_count = 0
        env.is_cycling = false
        env.snapshot_parts = nil
        return 2
    end
end

return ForceUpperAux
