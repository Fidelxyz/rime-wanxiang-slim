---Provides core shared utilities, constants, and environment variables used across the various Lua modules in the Wanxiang schema.
---@author amzxyz
---@author Fidel Yin <fidel.yin@hotmail.com>

local M = {}

M.VERSION = "v0.6.0-beta.2" -- x-release-please-version

---@alias PROCESS_RESULT ProcessResult
M.RIME_PROCESS_RESULTS = {
    kRejected = 0, -- The processor explicitly rejects this key; halt the chain but do not return true.
    kAccepted = 1, -- The processor handled this key; halt the chain and return true.
    kNoop = 2, -- The processor did not handle this key; pass it on to the next processor.
}

-- Cached for the lifetime of the process; the result never changes.
---@type boolean?
local is_mobile_device = nil

---Whether `path` is an absolute path (starts with `/`, `\`, or a Windows drive letter).
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

---Whether the current process is running on a mobile device.
---@return boolean
function M.is_mobile_device()
    local function _is_mobile_device()
        local dist = rime_api.get_distribution_code_name()
        local user_data_dir = rime_api.get_user_data_dir()

        -- Primary signal: well-known mobile distributions.
        local lower_dist = dist:lower()
        if lower_dist == "trime" or lower_dist == "hamster" or lower_dist == "hamster3" then
            return true
        end

        -- Secondary signal: mobile-flavoured user data paths.
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

        -- Platform check via LuaJIT (Android/Linux).
        ---@diagnostic disable: undefined-global
        if jit and jit.os then
            if jit.os:lower():find("android") then
                return true
            end
        end
        ---@diagnostic enable: undefined-global

        return false
    end

    if is_mobile_device == nil then
        is_mobile_device = _is_mobile_device()
    end
    return is_mobile_device
end

---Whether the context is in function/command mode.
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

    return M.is_function_mode_active_segment(seg)
end

---Whether `segment` is in function/command mode.
---@param segment Segment
function M.is_function_mode_active_segment(segment)
    return segment:has_tag("unicode")
end

---Check whether `key` matches `shortcut`.
---Matches against both `key:repr()` and the literal printable character, so configs can be written
---either as e.g. `"semicolon"` or `";"`.
---@param key KeyEvent
---@param shortcut string?
---@return boolean
function M.key_matches(key, shortcut)
    if not shortcut then
        return false
    end
    if key:repr() == shortcut then
        return true
    end
    if key.keycode >= 0x20 and key.keycode <= 0x7E and string.char(key.keycode) == shortcut then
        return true
    end
    return false
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

---Byte-level scan for ASCII letters (A-Z, a-z).
---Returns true as soon as any letter byte is found.
---@param s string
---@return boolean
function M.has_ascii_letter(s)
    for i = 1, #s do
        local b = s:byte(i)
        if (b >= 0x41 and b <= 0x5A) or (b >= 0x61 and b <= 0x7A) then
            return true
        end
    end
    return false
end

---@type table<string, string>
local TONE_STRIP_MAP = {
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

--- Remove pinyin tone marks from a string.
---@param s string
---@return string
function M.remove_pinyin_tone(s)
    ---@type string[]
    local result = {}
    local result_len = 0
    for uchar in s:gmatch("[%z\1-\127\194-\244][\128-\191]*") do
        result_len = result_len + 1
        result[result_len] = TONE_STRIP_MAP[uchar] or uchar
    end
    return table.concat(result)
end

---Check whether a candidate originates from the table, user_table, or fixed translators.
---@param cand Candidate
---@return boolean
function M.is_table_type_candidate(cand)
    local t = cand.type
    return t == "table" or t == "user_table" or t == "fixed"
end

---@return number
function M.now()
    if rime_api.get_time_ms then
        return rime_api.get_time_ms() / 1000
    end
    -- Fallback to `os.time()` for Weasel which hasn't updated its librime-lua to include `rime_api.get_time_ms()`.
    -- TODO: Remove this fallback on Weasel's next release.
    return os.time()
end

---Whether `filename` exists and is readable.
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

---Resolve `filename` against the user data dir first, then the shared data dir.
---Returns the first path that exists, or nil if neither does.
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

---Open a file searching the user data dir first, then the shared data dir.
---@param filename string Relative path under the data dir.
---@param mode? iolib.OpenMode
---@return file? file
---@return string? err
function M.load_file_with_fallback(filename, mode)
    mode = mode or "r"

    local _filename = M.get_filename_with_fallback(filename)

    ---@type file?, string?
    local file, err

    if _filename then
        file, err = io.open(_filename, mode)
    end

    return file, err
end

local USER_ID_DEFAULT = "unknown"

---Workaround for `rime_api.get_user_id()` returning "unknown" on Weasel and Cang.
---See:
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

return M
