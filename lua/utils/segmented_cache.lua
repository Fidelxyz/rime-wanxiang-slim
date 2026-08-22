---A two-generation ("hot"/"cold") memoization cache with O(1) bounded-size
---eviction. New and recently-read entries live in `hot`; once `hot` reaches
---`capacity`, it is demoted to `cold` (dropping the previous `cold`) and a
---fresh `hot` is started. Reads fall back to `cold` and promote the hit back
---into `hot`, so entries used within a generation survive eviction. This
---keeps hot entries alive across evictions without the per-access ordering
---bookkeeping that a true LRU would require.
---
---A cache holds between `capacity` and `2 * capacity` live entries before its
---coldest generation is dropped.
---@author Fidel Yin <fidel.yin@hotmail.com>

---@class SegmentedCache<V>: { hot: table<string, V>, cold: table<string, V>, hot_size: integer, capacity: integer }
local SegmentedCache = {}
SegmentedCache.__index = SegmentedCache

---Insert `value` into the hot generation, rotating generations when full.
---@generic V
---@param key string
---@param value V
function SegmentedCache:insert(key, value)
    self.hot[key] = value
    self.hot_size = self.hot_size + 1
    if self.hot_size >= self.capacity then
        self.cold = self.hot
        self.hot = {}
        self.hot_size = 0
    end
end

---Look up `key`, promoting a cold hit back into the hot generation.
---Returns nil only when the key is absent from both generations.
---@generic V
---@param key string
---@return V?
function SegmentedCache:get(key)
    local value = self.hot[key]
    if value ~= nil then
        return value
    end
    value = self.cold[key]
    if value ~= nil then
        self:insert(key, value)
        return value
    end
    return nil
end

local M = {}

---Create a new segmented cache with the given per-generation `capacity`.
---@generic V
---@param capacity integer
---@return SegmentedCache<V>
function M.new(capacity)
    return setmetatable({ hot = {}, cold = {}, hot_size = 0, capacity = capacity }, SegmentedCache)
end

return M
