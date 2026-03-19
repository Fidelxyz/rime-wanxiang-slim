--@amzxyz https://github.com/amzxyz/rime_wanxiang

local wanxiang = require("wanxiang/wanxiang")

local tone_map = {
    ["ā"] = "a",
    ["á"] = "a",
    ["ǎ"] = "a",
    ["à"] = "a",
    ["ē"] = "e",
    ["é"] = "e",
    ["ě"] = "e",
    ["è"] = "e",
    ["ī"] = "i",
    ["í"] = "i",
    ["ǐ"] = "i",
    ["ì"] = "i",
    ["ō"] = "o",
    ["ó"] = "o",
    ["ǒ"] = "o",
    ["ò"] = "o",
    ["ň"] = "n",
    ["ū"] = "u",
    ["ú"] = "u",
    ["ǔ"] = "u",
    ["ù"] = "u",
    ["ǹ"] = "n",
    ["ǖ"] = "ü",
    ["ǘ"] = "ü",
    ["ǚ"] = "ü",
    ["ǜ"] = "ü",
    ["ń"] = "n",
}

local function remove_pinyin_tone(s)
    local result = {}
    for uchar in s:gmatch("[%z\1-\127\194-\244][\128-\191]*") do
        table.insert(result, tone_map[uchar] or uchar)
    end
    return table.concat(result)
end

-- ----------------------
-- # 辅助码拆分提示模块
-- PRO 专用
-- ----------------------
local CF = {}
function CF.init(env)
    if wanxiang.is_pro_scheme(env) then -- pro 版直接初始化
        CF.get_dict(env)
    end
end

function CF.fini(env)
    env.chaifen_dict = nil
    collectgarbage()
end

function CF.get_dict(env)
    if env.chaifen_dict == nil then
        env.chaifen_dict = ReverseLookup("wanxiang_chaifen")
    end
    return env.chaifen_dict
end

function CF.get_comment(cand, env)
    local dict = CF.get_dict(env)
    if not dict then
        return ""
    end

    local raw = dict:lookup(cand.text)
    if not raw or raw == "" then
        return ""
    end

    local tpl = (env and env.settings and env.settings.chaifen) or ""

    if tpl ~= "" then
        -- 取 chaifen 左右两边
        local left, right = tpl:match("^(.-)chaifen(.-)$")
        if left then
            return left .. raw .. right
        end
    end

    return raw
end

-- ----------------------
-- # 错音错字提示模块
-- ----------------------
local CR = {}
local corrections_cache = nil -- 用于缓存已加载的词典
function CR.init(env)
    CR.style = env.settings.corrector_type or "{comment}"
    --if corrections_cache then return end
    local auto_delimiter = env.settings.auto_delimiter
    local is_pro = wanxiang.is_pro_scheme(env)
    -- 根据方案选择加载路径
    local path = (is_pro and "dicts/cuoyin.pro.dict.yaml") or "dicts/cuoyin.dict.yaml"
    local file, close_file, err = wanxiang.load_file_with_fallback(path)
    if not file then
        log.error(string.format("[super_comment]: 加载失败 %s，错误: %s", path, err))
        return
    end
    corrections_cache = {}
    for line in file:lines() do
        if not line:match("^#") then
            local text, code, weight, comment = line:match("^(.-)\t(.-)\t(.-)\t(.-)$")
            if text and code then
                text = text:match("^%s*(.-)%s*$")
                code = code:match("^%s*(.-)%s*$")
                comment = comment and comment:match("^%s*(.-)%s*$") or ""
                comment = comment:gsub("%s+", auto_delimiter)
                code = code:gsub("%s+", auto_delimiter)
                corrections_cache[code] = { text = text, comment = comment }
            end
        end
    end
    close_file()
end

function CR.get_comment(cand)
    local correction = corrections_cache and corrections_cache[cand.comment] or nil
    if not (correction and cand.text == correction.text) then
        return nil
    end
    -- 只认占位符 `comment`，按“刀法”切分
    local tpl = CR.style or "comment"
    local left, right = tpl:match("^(.-)comment(.-)$")

    if left then
        return left .. correction.comment .. right
    else
        return correction.comment
    end
end

-- ----------------------
-- 部件组字返回的注释
-- ----------------------
local function get_charset_label(text)
    if not text or text == "" then
        return nil
    end
    local cp = utf8.codepoint(text)
    if not cp then
        return nil
    end

    -- 按照 Unicode 区块频率排序
    if cp >= 0x4E00 and cp <= 0x9FFF then
        return "基本"
    end
    if cp >= 0x3400 and cp <= 0x4DBF then
        return "扩A"
    end
    if cp >= 0x20000 and cp <= 0x2A6DF then
        return "扩B"
    end
    if cp >= 0x2A700 and cp <= 0x2B73F then
        return "扩C"
    end
    if cp >= 0x2B740 and cp <= 0x2B81F then
        return "扩D"
    end
    if cp >= 0x2B820 and cp <= 0x2CEAF then
        return "扩E"
    end
    if cp >= 0x2CEB0 and cp <= 0x2EBEF then
        return "扩F"
    end
    if cp >= 0x2EBF0 and cp <= 0x2EE5F then
        return "扩I"
    end
    if cp >= 0x30000 and cp <= 0x3134F then
        return "扩G"
    end
    if cp >= 0x31350 and cp <= 0x323AF then
        return "扩H"
    end

    -- 兼容区
    if cp >= 0xF900 and cp <= 0xFAFF then
        return "兼容"
    end
    if cp >= 0x2F800 and cp <= 0x2FA1F then
        return "兼容"
    end

    return nil
end

local function get_az_comment(cand, env, initial_comment)
    local inner_parts = {}

    -- 音形注释拆解逻辑
    if initial_comment and initial_comment ~= "" then
        local segments = {}
        for segment in string.gmatch(initial_comment, "[^%s]+") do
            table.insert(segments, segment)
        end

        if #segments > 0 then
            local semicolon_count = select(2, string.gsub(segments[1], ";", ""))
            local pinyins = {}
            local fuzhu = nil

            for _, segment in ipairs(segments) do
                local pinyin = string.match(segment, "^[^;~]+")
                local fz = nil

                if semicolon_count == 1 then
                    fz = string.match(segment, ";(.+)$")
                end

                if pinyin then
                    table.insert(pinyins, pinyin)
                end
                if not fuzhu and fz and fz ~= "" then
                    fuzhu = fz
                end
            end

            if #pinyins > 0 then
                local pinyin_str = table.concat(pinyins, ",")
                table.insert(inner_parts, string.format("音%s", pinyin_str))

                if fuzhu then
                    table.insert(inner_parts, string.format("辅%s", fuzhu))
                end
            end
        end
    end

    if cand and cand.text then
        local label = get_charset_label(cand.text)
        if label then
            table.insert(inner_parts, label)
        end
    end

    if #inner_parts == 0 then
        return "〔无〕"
    end
    -- 使用间隔号连接
    return "〔" .. table.concat(inner_parts, "・") .. "〕"
end
-- ----------------------
-- # 辅助码提示或带调全拼注释模块 (Fuzhu)
-- ----------------------
local function get_fz_comment(cand, env, initial_comment)
    local length = utf8.len(cand.text)
    if length > env.settings.candidate_length then
        return ""
    end
    local auto_delimiter = env.settings.auto_delimiter or " "
    local segments = {}
    for segment in string.gmatch(initial_comment, "[^" .. auto_delimiter .. "]+") do
        table.insert(segments, segment)
    end

    -- 根据 option 动态决定是否强制使用 tone
    local use_tone = env.engine.context:get_option("tone_hint") or env.engine.context:get_option("toneless_hint")
    local fuzhu_type = use_tone and "tone" or "fuzhu"

    local first_segment = segments[1] or ""
    local semicolon_count = select(2, first_segment:gsub(";", ""))
    local fuzhu_comments = {}
    -- 没有分号的情况
    if semicolon_count == 0 then
        return initial_comment:gsub(auto_delimiter, " ")
    else
        -- 有分号：按类型提取
        for _, segment in ipairs(segments) do
            if fuzhu_type == "tone" then
                -- 取第一个分号“前”的内容
                local before = segment:match("^(.-);")
                if before and before ~= "" then
                    table.insert(fuzhu_comments, before)
                end
            else -- "fuzhu"
                -- 取第一个分号“后”的内容（到行尾）
                local after = segment:match(";(.+)$")
                if after and after ~= "" then
                    table.insert(fuzhu_comments, after)
                end
            end
        end
    end

    -- 最终拼接输出，fuzhu用 `,`，tone用 /连接
    if #fuzhu_comments > 0 then
        if fuzhu_type == "tone" then
            return table.concat(fuzhu_comments, " ")
        else
            return table.concat(fuzhu_comments, "/")
        end
    else
        return ""
    end
end

local SV = {}

-- 工具：取光标前的编码（安全处理 caret 越界）
local function front_input(ctx)
    if not ctx then
        return ""
    end
    local raw_full = ctx.input or ""
    local caret = ctx.caret_pos or #raw_full
    if caret < 0 then
        caret = 0
    elseif caret > #raw_full then
        caret = #raw_full
    end
    return raw_full:sub(1, caret)
end

-- 这个模块主要用于将滤镜阶段未修改前的注释或者 preedit
-- 存到上下文变量里，按键处理阶段使用；update_notifier 保证一致性
function SV.init(env)
    env._sv_seq_sig = ""
    env._sv_last_pre = "" -- 最近一次要写入的 preedit
    env._saved_input_for_seq = "" -- 上次对应的 raw_in（光标前编码）

    local ctx = env.engine.context

    env._sv_ctx_conn = ctx.update_notifier:connect(function(c)
        local raw_in = front_input(c)

        local pre = env._sv_last_pre or ""
        if pre == "" or raw_in == "" then
            return
        end

        -- 不重写：光标前编码 + preedit
        local sig = raw_in .. "\t" .. pre
        if env._sv_seq_sig == sig then
            return
        end

        c:set_property("sequence_preedit_key", raw_in)
        c:set_property("sequence_preedit_val", pre)
        env._sv_seq_sig = sig
    end)
end

-- 断开 notifier，清理状态
function SV.fini(env)
    if env._sv_ctx_conn then
        env._sv_ctx_conn:disconnect()
        env._sv_ctx_conn = nil
    end
    env._sv_seq_sig = nil
    env._sv_last_pre = nil
    env._saved_input_for_seq = nil
end

-- 限制更新范围：同一个 raw_in 只记第一次的 preedit
function SV.update_preedit(env, preedit)
    local ctx = env.engine.context
    if not ctx then
        return
    end

    local raw_in = front_input(ctx)
    preedit = preedit or ""

    if raw_in == "" or preedit == "" then
        return
    end

    if env._saved_input_for_seq ~= raw_in then
        env._saved_input_for_seq = raw_in
        env._sv_last_pre = preedit
    end
end
-- 对 cand.preedit 应用转换：隐藏双大写辅助码
local function apply_aux_preedit(env, cand)
    if not cand or not cand.preedit or cand.preedit == "" then
        return
    end

    local engine = env.engine
    local ctx = engine and engine.context
    local input = ctx and ctx.input or ""

    -- 1. 基础拦截：如果输入包含连续数字（如小键盘），或者首选就是英文，不转换
    if input:match("%d%d") then
        return
    end

    -- 判断首选是否为纯英文（通过匹配是否全由英文字符组成且不含中文）
    if cand.text:match("^[%a%p%s]+$") then
        return
    end

    -- 2. 加载配置
    local cfg = engine and engine.schema and engine.schema.config
    local aux_symbol = cfg and cfg:get_string("force_upper_aux/symbol")

    -- 如果没配置 symbol，直接跳过大写转换逻辑
    if not aux_symbol or aux_symbol == "" then
        return
    end

    do
        local preedit = cand.preedit
        -- 3. 核心逻辑：排除前两位是大写的情况，只转换后续出现的双大写
        -- ([A-Z][A-Z]+) 匹配后续连续的两个及以上的大写字母。
        local converted = preedit:gsub("^(..?-?)([A-Z][A-Z]+)", function(prefix, upper)
            -- 检查前缀是否包含大写字母。如果前缀里有大写，说明可能是英文输入，不转换。
            if prefix:match("[A-Z]") then
                return prefix .. upper
            else
                return prefix .. aux_symbol
            end
        end)

        -- 处理非行首（音节中间或靠后）的双大写
        -- 比如 "nihaoWS" -> "nihao·"
        converted = converted:gsub("([^%s%^])([A-Z][A-Z]+)", function(prev, upper)
            return prev .. aux_symbol
        end)

        cand.preedit = converted
    end
end

-- ----------------------
-- 主函数：根据优先级处理候选词的注释和preedit
-- ----------------------
local ZH = {}
function ZH.init(env)
    local config = env.engine.schema.config
    local delimiter = config:get_string("speller/delimiter") or " '"
    local auto_delimiter = delimiter:sub(1, 1)
    local manual_delimiter = delimiter:sub(2, 2)
    env.settings = {
        delimiter = delimiter,
        auto_delimiter = auto_delimiter,
        manual_delimiter = manual_delimiter,
        corrector_enabled = config:get_bool("super_comment/corrector") or true,
        corrector_type = config:get_string("super_comment/corrector_type") or "{comment}",
        chaifen = config:get_string("super_comment/chaifen") or "〔chaifen〕",
        candidate_length = tonumber(config:get_string("super_comment/candidate_length")) or 1,
    }
    -- 动态读取 cand_type 配置
    env.cand_type_symbols = {}
    local map = config:get_map("super_comment/cand_type")

    if map then
        -- 直接遍历 map 的 keys
        for _, key in ipairs(map:keys()) do
            -- 拼接路径去取对应的值，比如 "super_comment/cand_type/user_phrase"
            local val = config:get_string("super_comment/cand_type/" .. key)
            if val and val ~= "" then
                env.cand_type_symbols[key] = val
            end
        end
    end
    CR.init(env)
    SV.init(env)
    CF.init(env)
end
function ZH.fini(env)
    -- 清理
    CF.fini(env)
    SV.fini(env)
end
function ZH.func(input, env)
    local config = env.engine.schema.config
    local context = env.engine.context
    local input_str = context.input or ""
    local is_radical_mode = wanxiang.is_in_radical_mode(env)
    local should_skip_candidate_comment = wanxiang.is_function_mode_active(context) or input_str == ""
    local is_tone_comment = env.engine.context:get_option("tone_hint")
    local is_toneless_comment = env.engine.context:get_option("toneless_hint")
    local is_comment_hint = env.engine.context:get_option("fuzhu_hint")
    local is_chaifen_enabled = env.engine.context:get_option("chaifen_switch")
    local index = 0
    -- auto_phrase 相关声明
    local enable_auto_phrase = config:get_bool("add_user_dict/enable_auto_phrase") or false
    local enable_user_dict = config:get_bool("add_user_dict/enable_user_dict") or false

    for cand in input:iter() do
        local genuine_cand = cand:get_genuine()
        local preedit = genuine_cand.preedit or ""
        local initial_comment = genuine_cand.comment
        local final_comment = initial_comment
        index = index + 1

        SV.update_preedit(env, preedit) --储存到环境变量

        -- preedit相关处理只跳过 preedit，不影响注释
        if is_radical_mode then
            goto after_preedit
        end

        ::after_preedit::
        if should_skip_candidate_comment then
            yield(genuine_cand)
            goto continue
        end
        apply_aux_preedit(env, genuine_cand)
        -- 进入注释处理阶段
        -- ① 辅助码注释或者声调注释
        if is_comment_hint then
            local fz_comment = get_fz_comment(cand, env, initial_comment)
            if fz_comment then
                final_comment = fz_comment
            end
        elseif is_tone_comment then
            local fz_comment = get_fz_comment(cand, env, initial_comment)
            if fz_comment then
                final_comment = fz_comment
            end
        elseif is_toneless_comment then
            local fz_comment = get_fz_comment(cand, env, initial_comment)
            if fz_comment then
                -- 获取到带调拼音后，调用 remove_pinyin_tone 去掉声调
                final_comment = remove_pinyin_tone(fz_comment)
            end
        else
            if initial_comment and string.find(initial_comment, "~") then --保留尾部临时英文标记
                final_comment = initial_comment
            else
                final_comment = ""
            end
        end

        -- ② 拆分注释
        if is_chaifen_enabled then
            local cf_comment = CF.get_comment(cand, env)
            if cf_comment and cf_comment ~= "" then --不为空很重要
                final_comment = cf_comment
            end
        end

        -- ③ 错音错字提示
        if env.settings.corrector_enabled then
            local cr_comment = CR.get_comment(cand)
            if cr_comment and cr_comment ~= "" then
                final_comment = cr_comment
            end
        end

        -- ④ 反查模式提示
        if is_radical_mode then
            local az_comment = get_az_comment(cand, env, initial_comment)
            if az_comment and az_comment ~= "" then
                final_comment = az_comment
            end
        end

        -- ⑤ 候选词类型符号追加 (动态读取 cand_type 配置)
        local symbol = env.cand_type_symbols[cand.type]
        if symbol and final_comment ~= "~" then
            final_comment = (final_comment or "") .. symbol
        end
        -- 应用注释
        if final_comment ~= initial_comment then
            genuine_cand.comment = final_comment
        end

        yield(genuine_cand)
        ::continue::
    end
end
return ZH
