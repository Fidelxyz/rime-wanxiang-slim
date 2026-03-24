---@class SuperCommentConfig
---@field auto_delimiter string
---@field candidate_length integer

---@class SuperCommentDecompositorConfig
---@field display_left string
---@field display_right string

---@class SuperCommentDecompositorState
---@field decomp_dict ReverseLookup?

---@class SuperCommentCorrectorConfig
---@field enabled boolean
---@field display_left string
---@field display_right string

---@class SuperCommentCorrectorState
---@field corrections_cache table<string, {text: string, comment: string}>

---@class Env
---@field super_comment_config SuperCommentConfig?
---@field super_comment_decompositor_config SuperCommentDecompositorConfig?
---@field super_comment_decompositor_state SuperCommentDecompositorState?
---@field super_comment_corrector_config SuperCommentCorrectorConfig?
---@field super_comment_corrector_state SuperCommentCorrectorState?

local wanxiang = require("wanxiang.wanxiang")

---@type table<string, string>
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

---@param s string
---@return string
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
local decompositor = {}

---@param state SuperCommentDecompositorState
---@return ReverseLookup
function decompositor.get_dict(state)
    if not state.decomp_dict then
        state.decomp_dict = ReverseLookup("wanxiang_chaifen")
    end
    return state.decomp_dict
end

---@param cand Candidate
---@param config SuperCommentDecompositorConfig
---@param state SuperCommentDecompositorState
---@return string
function decompositor.get_comment(cand, config, state)
    local dict = decompositor.get_dict(state)

    local raw = dict:lookup(cand.text)
    if raw == "" then
        return ""
    end

    return config.display_left .. raw .. config.display_right
end

---@param env Env
function decompositor.init(env)
    local rime_config = env.engine.schema.config

    local format = rime_config:get_string("super_comment/chaifen") or "〔chaifen〕"
    local display_left, display_right = format:match("^(.-)chaifen(.-)$")

    env.super_comment_decompositor_config = {
        display_left = display_left or "",
        display_right = display_right or "",
    }

    env.super_comment_decompositor_state = {
        decomp_dict = nil,
    }

    if wanxiang.is_pro_scheme(env) then
        decompositor.get_dict(env.super_comment_decompositor_state)
    end
end

---@param env Env
function decompositor.fini(env)
    env.super_comment_decompositor_state = nil
end

-- ----------------------
-- # 错音错字提示模块
-- ----------------------

local corrector = {}

---@param cand Candidate
---@param config SuperCommentCorrectorConfig
---@param state SuperCommentCorrectorState
---@return string?
function corrector.get_comment(cand, config, state)
    local correction = state.corrections_cache[cand.comment]
    if not correction or cand.text ~= correction.text then
        return nil
    end

    return config.display_left .. correction.comment .. config.display_right
end

---@param env Env
function corrector.init(env)
    local config = env.engine.schema.config

    local format = config:get_string("super_comment/corrector_type") or "{comment}"
    local display_left, display_right = format:match("^(.-)comment(.-)$")

    env.super_comment_corrector_config = {
        enabled = config:get_bool("super_comment/corrector") or true,
        display_left = display_left or "",
        display_right = display_right or "",
    }

    env.super_comment_corrector_state = {
        corrections_cache = {},
    }

    local auto_delimiter = env.super_comment_config.auto_delimiter

    local is_pro = wanxiang.is_pro_scheme(env)
    local path = is_pro and "dicts/cuoyin.pro.dict.yaml" or "dicts/cuoyin.dict.yaml"

    local file, close_file, err = wanxiang.load_file_with_fallback(path)

    if not file then
        log.error(("[super_comment]: 加载失败 %s，错误: %s"):format(path, err))
        return
    end

    for line in file:lines() do
        if not line:match("^#") then
            ---@type string, string, string, string?
            local text, code, _, comment = line:match("^(.-)\t(.-)\t(.-)\t(.-)$")
            if text and code then
                ---@type string
                text = text:match("^%s*(.-)%s*$")
                ---@type string
                code = code:match("^%s*(.-)%s*$")
                ---@type string
                comment = comment and comment:match("^%s*(.-)%s*$") or ""

                comment = comment:gsub("%s+", auto_delimiter)
                code = code:gsub("%s+", auto_delimiter)

                env.super_comment_corrector_state.corrections_cache[code] = { text = text, comment = comment }
            end
        end
    end

    close_file()
end

---@param env Env
function corrector.fini(env)
    env.super_comment_corrector_config = nil
    env.super_comment_corrector_state = nil
end

-- ----------------------
-- 部件组字返回的注释
-- ----------------------
---@param text string
---@return string?
local function get_charset_label(text)
    if text == "" then
        return nil
    end

    local code = utf8.codepoint(text)
    if not code then
        return nil
    end

    -- 按照 Unicode 区块频率排序
    if code >= 0x4E00 and code <= 0x9FFF then
        return "基本"
    end
    if code >= 0x3400 and code <= 0x4DBF then
        return "扩A"
    end
    if code >= 0x20000 and code <= 0x2A6DF then
        return "扩B"
    end
    if code >= 0x2A700 and code <= 0x2B73F then
        return "扩C"
    end
    if code >= 0x2B740 and code <= 0x2B81F then
        return "扩D"
    end
    if code >= 0x2B820 and code <= 0x2CEAF then
        return "扩E"
    end
    if code >= 0x2CEB0 and code <= 0x2EBEF then
        return "扩F"
    end
    if code >= 0x2EBF0 and code <= 0x2EE5F then
        return "扩I"
    end
    if code >= 0x30000 and code <= 0x3134F then
        return "扩G"
    end
    if code >= 0x31350 and code <= 0x323AF then
        return "扩H"
    end

    -- 兼容区
    if code >= 0xF900 and code <= 0xFAFF then
        return "兼容"
    end
    if code >= 0x2F800 and code <= 0x2FA1F then
        return "兼容"
    end

    return nil
end

---@param cand Candidate
---@param initial_comment string
---@return string
local function get_reverse_lookup_comment(cand, initial_comment)
    local inner_parts = {}

    -- 音形注释拆解逻辑
    if initial_comment and initial_comment ~= "" then
        ---@type string[]
        local segments = {}
        for segment in initial_comment:gmatch("[^%s]+") do
            table.insert(segments, segment)
        end

        if #segments > 0 then
            local semicolon_count = select(2, segments[1]:gsub(";", ""))
            local pinyins = {}
            local aux = nil

            for _, segment in ipairs(segments) do
                local pinyin = segment:match("^[^;~]+")
                if pinyin then
                    table.insert(pinyins, pinyin)
                end

                if not aux then
                    local curr_aux = semicolon_count == 1 and segment:match(";(.+)$") or nil
                    if curr_aux and curr_aux ~= "" then
                        aux = curr_aux
                    end
                end
            end

            if #pinyins > 0 then
                local pinyin_str = table.concat(pinyins, ",")
                table.insert(inner_parts, ("音%s"):format(pinyin_str))

                if aux then
                    table.insert(inner_parts, ("辅%s"):format(aux))
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
---@param cand Candidate
---@param initial_comment string
---@param config SuperCommentConfig
---@param ctx Context
---@return string
local function get_aux_comment(cand, initial_comment, config, ctx)
    local length = utf8.len(cand.text)
    if length > config.candidate_length then
        return ""
    end

    local auto_delimiter = config.auto_delimiter or " "

    ---@type string[]
    local segments = {}
    for segment in initial_comment:gmatch("[^" .. auto_delimiter .. "]+") do
        table.insert(segments, segment)
    end

    -- 根据 option 动态决定是否强制使用 tone
    local use_tone = ctx:get_option("tone_hint") or ctx:get_option("toneless_hint")
    local aux_type = use_tone and "tone" or "fuzhu"

    local first_segment = segments[1] or ""
    local semicolon_count = select(2, first_segment:gsub(";", ""))

    ---@type string[]
    local aux_comments = {}
    -- 没有分号的情况
    if semicolon_count == 0 then
        return (initial_comment:gsub(auto_delimiter, " "))
    else
        -- 有分号：按类型提取
        for _, segment in ipairs(segments) do
            if aux_type == "tone" then
                -- 取第一个分号“前”的内容
                local before = segment:match("^(.-);")
                if before and before ~= "" then
                    table.insert(aux_comments, before)
                end
            else -- "fuzhu"
                -- 取第一个分号“后”的内容（到行尾）
                local after = segment:match(";(.+)$")
                if after and after ~= "" then
                    table.insert(aux_comments, after)
                end
            end
        end
    end

    -- 最终拼接输出，fuzhu用 `,`，tone用 /连接
    if #aux_comments > 0 then
        if aux_type == "tone" then
            return table.concat(aux_comments, " ")
        else
            return table.concat(aux_comments, "/")
        end
    else
        return ""
    end
end

-- ----------------------
-- 主函数：根据优先级处理候选词的注释和preedit
-- ----------------------
--
local M = {}

---@param env Env
function M.init(env)
    local config = env.engine.schema.config

    local delimiter = config:get_string("speller/delimiter") or " '"
    local auto_delimiter = delimiter:sub(1, 1)

    env.super_comment_config = {
        auto_delimiter = auto_delimiter,
        candidate_length = config:get_int("super_comment/candidate_length") or 1,
    }

    decompositor.init(env)
    corrector.init(env)
end

---@param env Env
function M.fini(env)
    decompositor.fini(env)
    corrector.fini(env)
end

---@param input Translation
---@param env Env
function M.func(input, env)
    local config = env.super_comment_config
    assert(config)
    local decompositor_config = env.super_comment_decompositor_config
    assert(decompositor_config)
    local decompositor_state = env.super_comment_decompositor_state
    assert(decompositor_state)
    local corrector_config = env.super_comment_corrector_config
    assert(corrector_config)
    local corrector_state = env.super_comment_corrector_state
    assert(corrector_state)

    local context = env.engine.context
    local input_str = context.input or ""
    local is_reverse_lookup_mode = wanxiang.is_reverse_lookup_mode(env)
    local should_skip_candidate_comment = wanxiang.is_function_mode_active(context) or input_str == ""
    local is_tone_comment = env.engine.context:get_option("tone_hint")
    local is_toneless_comment = env.engine.context:get_option("toneless_hint")
    local is_comment_hint = env.engine.context:get_option("fuzhu_hint")
    local is_decomp_enabled = env.engine.context:get_option("chaifen_switch")
    local index = 0

    for cand in input:iter() do
        local genuine_cand = cand:get_genuine()
        local initial_comment = genuine_cand.comment
        local final_comment = initial_comment
        index = index + 1

        -- preedit相关处理只跳过 preedit，不影响注释
        if is_reverse_lookup_mode then
            goto after_preedit
        end

        ::after_preedit::
        if should_skip_candidate_comment then
            yield(genuine_cand)
            goto continue
        end

        -- 进入注释处理阶段
        -- ① 辅助码注释或者声调注释
        if is_comment_hint then
            local aux_comment = get_aux_comment(cand, initial_comment, config, context)
            if aux_comment then
                final_comment = aux_comment
            end
        elseif is_tone_comment then
            local aux_comment = get_aux_comment(cand, initial_comment, config, context)
            if aux_comment then
                final_comment = aux_comment
            end
        elseif is_toneless_comment then
            local aux_comment = get_aux_comment(cand, initial_comment, config, context)
            if aux_comment then
                -- 获取到带调拼音后，调用 remove_pinyin_tone 去掉声调
                final_comment = remove_pinyin_tone(aux_comment)
            end
        else
            if initial_comment and initial_comment:find("~") or initial_comment:find("\226\152\175") then --保留尾部临时英文标记和太极标记
                final_comment = initial_comment
            else
                final_comment = ""
            end
        end

        -- ② 拆分注释
        if is_decomp_enabled then
            local decomp_comment = decompositor.get_comment(cand, decompositor_config, decompositor_state)
            if decomp_comment and decomp_comment ~= "" then --不为空很重要
                final_comment = decomp_comment
            end
        end

        -- ③ 错音错字提示
        if env.super_comment_corrector_config.enabled then
            local correction_comment = corrector.get_comment(cand, corrector_config, corrector_state)
            if correction_comment and correction_comment ~= "" then
                final_comment = correction_comment
            end
        end

        -- ④ 反查模式提示
        if is_reverse_lookup_mode then
            local reverse_lookup_comment = get_reverse_lookup_comment(cand, initial_comment)
            if reverse_lookup_comment and reverse_lookup_comment ~= "" then
                final_comment = reverse_lookup_comment
            end
        end

        -- 应用注释
        if final_comment ~= initial_comment then
            genuine_cand.comment = final_comment
        end

        yield(genuine_cand)
        ::continue::
    end
end

return M
