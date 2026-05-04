---Provides core shared utilities, constants, and environment variables used across the various Lua modules in the Wanxiang schema.
---@author amzxyz
---@author Fidel Yin <fidel.yin@hotmail.com>

local M = {}

-- x-release-please-start-version
M.version = "v15.9.4"
-- x-release-please-end

---@alias PROCESS_RESULT ProcessResult
M.RIME_PROCESS_RESULTS = {
    kRejected = 0, -- 表示处理器明确拒绝了这个按键，停止处理链但不返回 true
    kAccepted = 1, -- 表示处理器成功处理了这个按键，停止处理链并返回 true
    kNoop = 2, -- 表示处理器没有处理这个按键，继续传递给下一个处理器
}

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
        ---@diagnostic disable: undefined-global
        if jit and jit.os then
            if jit.os:lower():find("android") then
                return true
            end
        end
        ---@diagnostic enable: undefined-global

        -- 所有检查未通过则默认为桌面设备
        return false
    end

    if is_mobile_device == nil then
        is_mobile_device = _is_mobile_device()
    end
    return is_mobile_device
end

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
---@param mode iolib.OpenMode
---@return file? file
---@return string? err
function M.load_file_with_fallback(filename, mode)
    mode = mode or "r" -- 默认读取模式

    local _filename = M.get_filename_with_fallback(filename)

    ---@type file?, string?
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
---TODO: Fixed in https://github.com/rime/weasel/pull/1653. Remove this workaround when next release includes that fix.
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
    ["Ⅺ"] = "zrlong", --自然龙
    ["Ⅻ"] = "hxlong", --汉心龙
    ["Ⅼ"] = "lxsq", --乱序17
    ["ⅲ"] = "ⅲ", -- 间接辅助标记：命中则额外返回 md="ⅲ"
}

return M
