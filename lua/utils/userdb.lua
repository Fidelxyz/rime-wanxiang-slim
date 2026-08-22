---Provides a memory-safe wrapper and object pool for Rime UserDb, offering
---utility methods for meta-data operations and memory-managed queries.
---@author amzxyz
---@author Fidel Yin <fidel.yin@hotmail.com>

local META_KEY_PREFIX = "\001" .. "/"

-- UserDb cache. Uses a weak-value table so the GC can reclaim entries when
-- nothing else holds a reference. UserDb instances do not need explicit
-- closing; the GC closes them on collection.
---@type table<string, UserDb>
local db_pool = setmetatable({}, { __mode = "v" })

-- Custom methods exposed on the wrapper object.
---@class WrappedUserDb: UserDb
---@field _db UserDb
---@field meta_fetch fun(self: self, key: string): string|nil
---@field meta_update fun(self: self, key: string, value: string): boolean
---@field query_with fun(self: self, prefix: string, handler: fun(key: string, value: string))
local WrappedUserDb = {}

---@param key string
---@return string?
function WrappedUserDb:meta_fetch(key)
    return self._db:fetch(META_KEY_PREFIX .. key)
end

---@param key string
---@param value string
---@return boolean
function WrappedUserDb:meta_update(key, value)
    return self._db:update(META_KEY_PREFIX .. key, value)
end

---Iterate entries with `prefix`, calling `handler(key, value)` for each.
---Forces a GC cycle afterwards to release the DbAccessor's underlying
---resources promptly.
---@param prefix string
---@param handler fun(key: string, value: string)
function WrappedUserDb:query_with(prefix, handler)
    local da = self._db:query(prefix)
    if da then
        for key, value in da:iter() do
            handler(key, value)
        end
    end
    da = nil
    collectgarbage()
end

local metatable = {
    ---@param wrapper WrappedUserDb
    ---@param key string
    ---@return any
    __index = function(wrapper, key)
        -- Custom methods take precedence.
        if WrappedUserDb[key] then
            return WrappedUserDb[key]
        end

        -- Otherwise delegate to the underlying UserDb. Methods are rebound to
        -- the real db so calls like `wrapper:fetch(...)` work transparently.
        local real_db = wrapper._db
        ---@type any
        local value = real_db[key]

        if type(value) == "function" then
            return function(_, ...)
                return value(real_db, ...)
            end
        end

        return value
    end,
}

local M = {}

---@param db_name string
---@param db_class "userdb" | "plain_userdb" | nil
---@return WrappedUserDb?
function M.UserDb(db_name, db_class)
    db_class = db_class or "userdb"
    local key = db_name .. "." .. db_class

    ---@type UserDb?
    local db = db_pool[key]
    if not db then
        db = UserDb(db_name, db_class)
        db_pool[key] = db
    end

    local wrapper = {
        _db = db,
    }

    return setmetatable(wrapper, metatable)
end

---@param db_name string
---@return WrappedUserDb?
function M.LevelDb(db_name)
    return M.UserDb(db_name, "userdb")
end

---@param db_name string
---@return WrappedUserDb?
function M.TableDb(db_name)
    return M.UserDb(db_name, "plain_userdb")
end

return M
