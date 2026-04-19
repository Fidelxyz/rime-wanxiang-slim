---Provides core shared utilities, constants, and environment variables used across the various Lua modules in the Wanxiang schema.
---@module "wanxiang.wanxiang"
---@author amzxyz
---@author Fidel Yin <fidel.yin@hotmail.com>

local M = {}

-- x-release-please-start-version
M.version = "v15.5.2"
-- x-release-please-end

---@alias PROCESS_RESULT ProcessResult
M.RIME_PROCESS_RESULTS = {
    kRejected = 0, -- 表示处理器明确拒绝了这个按键，停止处理链但不返回 true
    kAccepted = 1, -- 表示处理器成功处理了这个按键，停止处理链并返回 true
    kNoop = 2, -- 表示处理器没有处理这个按键，继续传递给下一个处理器
}

---@class Env
---@field unicode_trigger string? Trigger key for Unicode input
---@field page_size integer? Number of candidates per page (menu/page_size)

-- 整个生命周期内不变，缓存判断结果
---@type boolean?
local is_mobile_device = nil

---辅助函数：检测路径是否为绝对路径（以 / 或盘符开头）
---@param path string
---@return boolean
local function is_absolute_path(path)
    if not path then
        return false
    end
    if path:sub(1, 1) == "/" or path:sub(1, 1) == "\\" then
        return true
    end
    if path:match("^[a-zA-Z]:[\\/]") then
        return true
    end
    return false
end

-- 判断是否为手机设备
---@return boolean
function M.is_mobile_device()
    local function _is_mobile_device()
        local dist = rime_api.get_distribution_code_name()
        local user_data_dir = rime_api.get_user_data_dir()

        -- 主判断：常见移动端输入法
        local lower_dist = dist:lower()
        if lower_dist == "trime" or lower_dist == "hamster" or lower_dist == "hamster3" then
            return true
        end

        -- 补充判断：路径中包含移动设备特征
        local lower_path = user_data_dir:lower()
        if
            lower_path:find("/android/")
            or lower_path:find("/mobile/")
            or lower_path:find("/sdcard/")
            or lower_path:find("/data/storage/")
            or lower_path:find("/storage/emulated/")
        then
            return true
        end

        -- 特定平台判断（Android/Linux）
        if jit and jit.os then
            if jit.os:lower():find("android") then
                return true
            end
        end

        -- 所有检查未通过则默认为桌面设备
        return false
    end

    if is_mobile_device == nil then
        is_mobile_device = _is_mobile_device()
    end
    return is_mobile_device
end

--- 检测是否为万象专业版
---@param env Env
---@return boolean
function M.is_pro_schema(env)
    return env.engine.schema.schema_id == "wanxiang_pro"
end

-- 以 `tag` 方式检测是否处于反查模式
---@param env Env
---@return boolean
function M.is_reverse_lookup_mode(env)
    local seg = env.engine.context.composition:back()
    return seg and (seg:has_tag("wanxiang_reverse")) or false
end

---判断是否在命令模式
---@param context Context
---@return boolean
function M.is_function_mode_active(context)
    if context.composition:empty() then
        return false
    end

    local seg = context.composition:back()
    if not seg then
        return false
    end

    return seg:has_tag("unicode") -- unicode.lua 输出 Unicode 字符 U+小写字母或数字
end

---@param codepoint integer
---@return boolean
function M.is_chinese_codepoint(codepoint)
    return (codepoint >= 0x4E00 and codepoint <= 0x9FFF) -- Basic
        or (codepoint >= 0x3400 and codepoint <= 0x4DBF) -- Ext A
        or (codepoint >= 0x20000 and codepoint <= 0x2A6DF) -- Ext B
        or (codepoint >= 0x2A700 and codepoint <= 0x2CEAF) -- Ext C/D/E
        or (codepoint >= 0x2CEB0 and codepoint <= 0x2EE5F) -- Ext F/I
        or (codepoint >= 0x30000 and codepoint <= 0x3134F) -- Ext G
        or (codepoint >= 0x31350 and codepoint <= 0x323AF) -- Ext H
        or (codepoint >= 0xF900 and codepoint <= 0xFAFF) -- Compatibility
        or (codepoint >= 0x2F800 and codepoint <= 0x2FA1F) -- Compat Supplement
        or (codepoint >= 0x2E80 and codepoint <= 0x2EFF) -- Radicals Supplement
        or (codepoint >= 0x2F00 and codepoint <= 0x2FDF) -- Kangxi Radicals
end

---@param char string
---@return boolean
function M.is_chinese_char(char)
    return M.is_chinese_codepoint(utf8.codepoint(char))
end

---@return number
function M.now()
    return rime_api.get_time_ms() / 1000
end

---判断文件是否存在
---@param filename string
---@return boolean
function M.file_exists(filename)
    local f = io.open(filename, "r")
    if f then
        f:close()
        return true
    else
        return false
    end
end

---按照优先顺序获取文件：用户目录 > 系统目录
---@param filename string
---@return string?
function M.get_filename_with_fallback(filename)
    local _path = filename:gsub("^[\\/]+", "")
    local user_dir = rime_api.get_user_data_dir()

    if not is_absolute_path(user_dir) then
        return filename
    end

    local user_path = user_dir .. "/" .. _path
    if M.file_exists(user_path) then
        return user_path
    end

    local shared_dir = rime_api.get_shared_data_dir()

    if not is_absolute_path(shared_dir) then
        return filename
    end
    local shared_path = shared_dir .. "/" .. _path
    if M.file_exists(shared_path) then
        return shared_path
    end
    return nil
end

-- 按照优先顺序加载文件：用户目录 > 系统目录
---@param filename string 相对路径
---@param mode string?
---@return file*? file
---@return string? err
function M.load_file_with_fallback(filename, mode)
    mode = mode or "r" -- 默认读取模式

    local _filename = M.get_filename_with_fallback(filename)

    ---@type file*?, string?
    local file, err

    if _filename then
        file, err = io.open(_filename, mode)
    end

    return file, err
end

local USER_ID_DEFAULT = "unknown"

---作为「小狼毫」和「仓」 `rime_api.get_user_id()` 的一个 workaround
---详见：
---1. https://github.com/rime/weasel/pull/1649
---2. https://github.com/rime/librime/issues/1038
---@return string
function M.get_user_id()
    local user_id = rime_api.get_user_id()
    if user_id ~= USER_ID_DEFAULT then
        return user_id
    end

    local user_data_dir = rime_api.get_user_data_dir()
    local installation_path = user_data_dir .. "/installation.yaml"
    local installation_file, _ = io.open(installation_path, "r")
    if not installation_file then
        return user_id
    end

    for line in installation_file:lines() do
        ---@type string?, string?
        local key, value = line:match('^([^#:]+):%s+"?([^"]%S+[^"])"?')
        if key == "installation_id" and value then
            user_id = value
            break
        end
    end

    installation_file:close()
    return user_id
end

M.INPUT_METHOD_MARKERS = {
    ["Ⅰ"] = "pinyin", --全拼
    ["Ⅱ"] = "zrm", --自然码双拼
    ["Ⅲ"] = "flypy", --小鹤双拼
    ["Ⅳ"] = "mspy", --微软双拼
    ["Ⅴ"] = "sogou", --搜狗双拼
    ["Ⅵ"] = "abc", --智能abc双拼
    ["Ⅶ"] = "ziguang", --紫光双拼
    ["Ⅷ"] = "pyjj", --拼音加加
    ["Ⅸ"] = "gbpy", --国标双拼
    ["Ⅹ"] = "wxsp", --万象双拼
    ["Ⅺ"] = "zrlong", --自然龙
    ["Ⅻ"] = "hxlong", --汉心龙
    ["Ⅼ"] = "lxsq", --乱序17
    ["ⅲ"] = "ⅲ", -- 间接辅助标记：命中则额外返回 md="ⅲ"
}

---@type table<string, string>
local __input_type_cache = {} -- 缓存首个命中的 id（兼容旧用法）
---@type table<string, string>
local __input_md_cache = {} -- 新增：是否命中“ⅲ”（若命中则为 "ⅲ"，否则为 nil）

--- 根据 speller/algebra 中的特殊符号返回输入类型：
--- - 若未命中“ⅲ”，只返回 id（保持旧行为）
--- - 若命中“ⅲ”，返回两个值：id, "ⅲ"
---@param env Env
---@return string id
---@return string? md （仅在命中“ⅲ”时返回 "ⅲ"）
function M.get_input_method_type(env)
    local schema_id = env.engine.schema.schema_id or "unknown"

    -- 命中缓存则按是否有 md 决定返回 1 个或 2 个值
    local cached_id = __input_type_cache[schema_id]
    if cached_id then
        local cached_md = __input_md_cache[schema_id]
        if cached_md then
            return cached_id, cached_md -- 返回两个值：id, "ⅲ"
        else
            return cached_id -- 只返回 id
        end
    end

    local config = env.engine.schema.config
    local result_id = "unknown"
    local md = nil -- 只有命中“ⅲ”时设为 "ⅲ"

    local n = config:get_list_size("speller/algebra")
    for i = 0, n - 1 do
        local s = config:get_string(("speller/algebra/@%d"):format(i))
        if s then
            -- 不提前返回：需要把整段都扫描完，才能知道是否命中“ⅲ”
            for symbol, id in pairs(M.INPUT_METHOD_MARKERS) do
                if s:find(symbol, 1, true) then
                    if symbol == "ⅲ" or id == "ⅲ" then
                        md = "ⅲ" -- 记录辅助标记
                    else
                        if result_id == "unknown" then
                            result_id = id -- 只记录第一个“正常映射”的 id
                        end
                    end
                end
            end
        end
    end

    -- 写缓存
    __input_type_cache[schema_id] = result_id
    __input_md_cache[schema_id] = md -- 命中则为 "ⅲ"，否则为 nil

    -- 返回：命中“ⅲ”→两个值；否则一个值
    if md then
        return result_id, md
    else
        return result_id
    end
end

---@param p string
---@return string
local function ensure_anchor(p)
    if p == "" then
        return ""
    end

    -- 补 $
    local last = p:sub(-1)
    local prev = p:sub(-2, -2)
    if last ~= "$" or (last == "$" and prev == "%") then
        p = p .. "$"
    end

    -- 补 ^
    local first = p:sub(1, 1)
    if first ~= "^" then
        p = "^" .. p
    end

    return p
end

---递归展开 ? 量词
---输入: "N[0-9]?A"
---输出: { "N[0-9]A", "NA" }
---@param pattern_list string[]
---@return string[]
local function expand_optional(pattern_list)
    ---@type string[]
    local result = {}
    local has_expansion = false

    for _, pattern in ipairs(pattern_list) do
        -- 寻找第一个未转义的 ? (Regex量词)
        -- 我们需要找到 ? 的位置，并判断它修饰的前一个原子是什么
        local q_idx = nil
        local atom_start = nil
        local atom_end = nil

        local i = 1
        local len = #pattern
        while i <= len do
            local char = pattern:sub(i, i)

            if char == "%" then
                -- 转义符，跳过下一个
                i = i + 2
            elseif char == "[" then
                -- 集合 [...]
                local j = i + 1
                while j <= len do
                    if pattern:sub(j, j) == "]" and pattern:sub(j - 1, j - 1) ~= "%" then
                        break
                    end
                    j = j + 1
                end
                -- 检查后面是不是 ?
                if j < len and pattern:sub(j + 1, j + 1) == "?" then
                    atom_start = i
                    atom_end = j
                    q_idx = j + 1
                    break -- 找到目标
                end
                i = j + 1
            elseif char == "?" then
                -- 找到一个 ?，修饰前面一个字符
                -- 注意：如果前面没有字符（比如开头），则是非法正则，忽略
                if i > 1 then
                    q_idx = i
                    atom_end = i - 1
                    -- 判断前一个字符是否是转义结果 (如 %d)
                    if atom_end > 1 and pattern:sub(atom_end - 1, atom_end - 1) == "%" then
                        atom_start = atom_end - 1
                    else
                        atom_start = atom_end
                    end
                    break
                end
                i = i + 1
            else
                i = i + 1
            end
        end

        if q_idx then
            has_expansion = true
            -- 1. 保留原子 (去掉 ?)
            result[#result + 1] = pattern:sub(1, atom_end) .. pattern:sub(q_idx + 1)
            -- 2. 删除原子 (去掉 原子+?)
            result[#result + 1] = pattern:sub(1, atom_start - 1) .. pattern:sub(q_idx + 1)
        else
            result[#result + 1] = pattern
        end
    end

    if has_expansion then
        if #result > 100 then
            return result
        end
        return expand_optional(result)
    end

    return result
end

-- Wanxiang Regex > lua --不支持断言够用了
local RegexParser = {}

---@param regex string
---@return string
function RegexParser.normalize(regex)
    local p = regex
    p = p:gsub("%(%?%:", "%(") -- 清理 (?:
    -- 基础转义
    p = p:gsub("\\d", "%%d")
    p = p:gsub("\\D", "%%D")
    p = p:gsub("\\w", "%%w")
    p = p:gsub("\\W", "%%W")
    p = p:gsub("\\s", "%%s")
    p = p:gsub("\\S", "%%S")
    -- 符号转义 (注意：\? -> %?，保留字面量问号)
    p = p:gsub("\\%.", "%%.")
    p = p:gsub("\\%^", "%%^")
    p = p:gsub("\\%$", "%%$")
    p = p:gsub("\\%*", "%%*")
    p = p:gsub("\\%+", "%%+")
    p = p:gsub("\\%-", "%%-")
    p = p:gsub("\\%?", "%%?")
    p = p:gsub("\\%(", "%%(")
    p = p:gsub("\\%)", "%%)")
    p = p:gsub("\\%[", "%%[")
    p = p:gsub("\\%]", "%%]")

    return p
end

---@param str string
---@param sep string
---@return string[]
function RegexParser.smart_split(str, sep)
    ---@type string[]
    local results = {}
    local current = ""
    local paren_depth = 0
    local brack_depth = 0
    for i = 1, #str do
        local char = str:sub(i, i)
        local prev = (i > 1) and str:sub(i - 1, i - 1) or ""
        if prev == "%" then
            current = current .. char
        else
            if char == "(" then
                paren_depth = paren_depth + 1
            end
            if char == ")" then
                paren_depth = paren_depth - 1
            end
            if char == "[" then
                brack_depth = brack_depth + 1
            end
            if char == "]" then
                brack_depth = brack_depth - 1
            end
            if char == sep and paren_depth == 0 and brack_depth == 0 then
                results[#results + 1] = current
                current = ""
            else
                current = current .. char
            end
        end
    end
    results[#results + 1] = current
    return results
end

---@param str_list string[]
---@return string[]
function RegexParser.expand_groups(str_list)
    ---@type string[]
    local expanded = {}
    for _, str in ipairs(str_list) do
        local s_idx, e_idx = nil, nil
        local depth = 0
        for i = 1, #str do
            local char = str:sub(i, i)
            local prev = (i > 1) and str:sub(i - 1, i - 1) or ""
            if prev ~= "%" then
                if char == "(" then
                    if depth == 0 then
                        s_idx = i
                    end
                    depth = depth + 1
                elseif char == ")" then
                    depth = depth - 1
                    if depth == 0 and s_idx then
                        e_idx = i
                        break
                    end
                end
            end
        end
        if s_idx and e_idx then
            local prefix = str:sub(1, s_idx - 1)
            local content = str:sub(s_idx + 1, e_idx - 1)
            local suffix = str:sub(e_idx + 1)
            local parts = RegexParser.smart_split(content, "|")
            for _, part in ipairs(parts) do
                expanded[#expanded + 1] = prefix .. part .. suffix
            end
        else
            expanded[#expanded + 1] = str
        end
    end
    return expanded
end

---@param regex_str string
---@return string[]
function RegexParser.convert(regex_str)
    if not regex_str or regex_str == "" then
        return {}
    end
    local norm = RegexParser.normalize(regex_str)
    -- 1. 拆分 |
    local list = RegexParser.smart_split(norm, "|")
    -- 2. 展开 () 分组
    local loop = 0
    local changed = true
    while changed and loop < 5 do
        local new_list = RegexParser.expand_groups(list)
        if #new_list > #list then
            list = new_list
        else
            changed = false
        end
        loop = loop + 1
    end
    -- 3. 展开 ? 量词
    -- 这会将带 ? 的正则裂变成多个确定的正则
    list = expand_optional(list)
    -- 4. 补全锚点
    for i, p in ipairs(list) do
        list[i] = ensure_anchor(p)
    end
    return list
end

---调用加载函数
---@param config Config
---@param path string
---@return string[]
function M.load_regex_patterns(config, path)
    ---@type string[]
    local patterns = {}

    local map = config:get_map(path)
    if not map then
        return patterns
    end

    local keys = map:keys()

    for i = 1, #keys do
        local k_str = keys[i]

        if k_str then
            local val = map:get_value(k_str)
            if val and val.value ~= "" then
                local lua_pats = RegexParser.convert(val.value)
                for _, p in ipairs(lua_pats) do
                    patterns[#patterns + 1] = p
                end
            end
        end
    end

    return patterns
end

return M
