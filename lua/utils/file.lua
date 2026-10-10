---Shared file I/O and Rime data-directory path resolution.
---I/O helpers return errors for callers to log with their module context.
---@author amzxyz
---@author Fidel Yin <fidel.yin@hotmail.com>

---Whether `path` is an absolute path (starts with `/`, `\`, or a Windows drive letter).
---@param path string
---@return boolean
local function is_absolute_path(path)
    if path:sub(1, 1) == "/" or path:sub(1, 1) == "\\" then
        return true
    end
    if path:match("^[a-zA-Z]:[\\/]") then
        return true
    end
    return false
end

local M = {}

---Read an entire file, returning the failed operation and path on error.
---@param path string
---@return string? content
---@return string? err
function M.read_file(path)
    local file, err = io.open(path, "rb")
    if not file then
        return nil, ("failed to open %q for reading: %s"):format(path, err)
    end
    local content, read_err = file:read("*a")
    local closed, close_err = file:close()
    if not content then
        return nil, ("failed to read %q: %s"):format(path, read_err)
    end
    if not closed then
        return nil, ("failed to close %q: %s"):format(path, close_err)
    end
    return content
end

---Write an entire file, checking buffered writes flushed on close.
---@param path string
---@param content string
---@return boolean ok
---@return string? err
function M.write_file(path, content)
    local file, err = io.open(path, "wb")
    if not file then
        return false, ("failed to open %q for writing: %s"):format(path, err)
    end
    local written, write_err = file:write(content)
    local closed, close_err = file:close()
    if not written then
        return false, ("failed to write %q: %s"):format(path, write_err)
    end
    if not closed then
        return false, ("failed to close %q: %s"):format(path, close_err)
    end
    return true
end

---Copy a file, returning the source or destination error on failure.
---@param src string
---@param dest string
---@return boolean ok
---@return string? err
function M.copy_file(src, dest)
    local content, err = M.read_file(src)
    if not content then
        return false, err
    end
    return M.write_file(dest, content)
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
function M.resolve_data_file(filename)
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
---@param mode? openmode
---@return file*? file
---@return string? err
function M.open_data_file(filename, mode)
    mode = mode or "r"

    local _filename = M.resolve_data_file(filename)

    ---@type file*?, string?
    local file, err

    if _filename then
        file, err = io.open(_filename, mode)
    end

    return file, err
end

return M
