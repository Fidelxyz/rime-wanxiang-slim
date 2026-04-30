---Provides a memory-safe wrapper and object pool for Rime UserDb, offering utility methods for meta-data operations
---and memory-managed queries.
---@author amzxyz
---@author Fidel Yin <fidel.yin@hotmail.com>

local META_KEY_PREFIX = "\001" .. "/"

-- UserDb 缓存，使用弱引用表，不阻止垃圾回收并能自动清理
-- Does not need to close manually, as the garbage collector will handle it when there are no more references to the UserDb object.
---@type table<string, UserDb>
local db_pool = setmetatable({}, { __mode = "v" })

-- 用于存放包装器对象的自定义方法
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
    collectgarbage() -- Release DbAccessor
end

local metatable = {
    ---@param wrapper WrappedUserDb
    ---@param key string
    ---@return any
    __index = function(wrapper, key)
        -- 优先使用自定义方法
        if WrappedUserDb[key] then
            return WrappedUserDb[key]
        end

        -- 不是自定义方法，委托给真实的 UserDb 对象
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
