-- 万象拼音 · 手动自由排序
-- 核心规则： 向前移动 = "Control+j", 向后移动 = "Control+k", 重置 = "Control+l", 置顶 = "Control+p
-- 1) p>0：有效排序（DB upsert + 导出）
-- 2) p=0：墓碑（DB 删除 + 导出墓碑）
-- 3) 初始化：先 flush 本机增量到导出 → 外部合并(所有设备文件+本机DB，LWW) → 重写本机导出(含墓碑) → 导入覆盖DB，p=0删除键，不导入
-- 4) 关于同步的使用方法：先点击同步确保同步目录已经创建，建立sequence_device_list.txt设备清单，内部填写不同设备导出文件名称
-- sequence_ff9b2823-8733-44bb-a497-daf382b74ca5.txt
-- sequence_deepin.txt
-- 可能是自定义名称，可能是随机串号
-- sequence_开头，后面跟着installation_id，这个参数来自用户目录installation.yaml
-- 清单有什么文件就会读取什么文件
-- 仅使用 installation.yaml 的 sync_dir；读不到就回退到 user_dir/sync

local wanxiang = require("wanxiang.wanxiang")
local userdb = require("wanxiang.userdb")

---@class SuperSequenceConfig
---@field seq_keys SeqKeys

---@class SuperSequenceFilterState
---@field db WrappedUserDb?

---@class Env
---@field super_sequence_config SuperSequenceConfig?
---@field super_sequence_filter_state SuperSequenceFilterState?

---@class SeqKeys
---@field up string
---@field down string
---@field reset string
---@field pin string

------------------------------------------------------------
-- 一、常量
------------------------------------------------------------
local SYNC_FILE_PREFIX, SYNC_FILE_SUFFIX = "sequence", ".txt"
local RUNTIME_EXPORT = false
local MANIFEST_FILE = "sequence_device_list.txt"

------------------------------------------------------------
-- 二、通用工具（路径处理）
------------------------------------------------------------
---@param p string
---@return string
local function normalize_path(p)
    if p == "" then
        return ""
    end

    if p:sub(1, 2) == "\\\\" then
        return "//" .. p:sub(3):gsub("\\", "/"):gsub("/+", "/")
    else
        return (p:gsub("\\", "/"):gsub("/+", "/"))
    end
end

---@param p string
---@return boolean
local function is_absolute_path(p)
    p = normalize_path(p)
    return p:sub(1, 2) == "//" or p:match("^[A-Za-z]:/")
end

---@param a string
---@param b string
---@return string
local function path_join(a, b)
    a = normalize_path(a)
    b = normalize_path(b)

    if a == "" then
        return b
    end
    if b == "" then
        return a
    end
    if is_absolute_path(b) then
        return b
    end

    if a:sub(-1) ~= "/" then
        a = a .. "/"
    end

    return a .. b
end

---@param path string
---@return string[]
local function read_lines(path)
    local f = io.open(path, "r")
    if not f then
        return {}
    end

    ---@type string[]
    local t = {}
    for line in f:lines() do
        t[#t + 1] = line
    end
    f:close()
    return t
end

---@param path string
---@param lines string[]
local function write_lines(path, lines)
    local f = io.open(path, "w")
    if not f then
        return
    end

    for _, line in ipairs(lines) do
        f:write(line, "\n")
    end
    f:close()
end

---@param s string
---@return string
local function trim(s)
    return (s:gsub("^%s+", ""):gsub("%s+$", ""))
end

---@param s string?
---@return boolean
local function is_single_lowercase_letter(s)
    return s ~= nil and #s == 1 and s:match("^[a-z]$") ~= nil
end

------------------------------------------------------------
-- 三、安装信息 & 同步目录
------------------------------------------------------------
---@return string? installation_id
---@return string? sync_dir
local function read_installation_yaml()
    local user_dir = rime_api.get_user_data_dir()
    if user_dir == "" then
        return nil, nil
    end

    local f = io.open(path_join(user_dir, "installation.yaml"), "r")
    if not f then
        return nil, nil
    end

    ---@type string?
    local installation_id = nil
    ---@type string?
    local sync_dir = nil
    ---@type string
    for line in f:lines() do
        ---@type string
        line = line:gsub("%s+#.*$", "")
        ---@type string?, string?
        local key, val = line:match("^%s*([%w_]+)%s*:%s*(.+)$")
        if key and val then
            val = val:gsub('^%s*"(.*)"%s*$', "%1"):gsub("^%s*'(.*)'%s*$", "%1")
            ---@type string
            val = val:gsub("^%s+", ""):gsub("%s+$", "")
            if key == "installation_id" then
                installation_id = val
            elseif key == "sync_dir" then
                sync_dir = normalize_path(val)
            end
        end
    end
    f:close()
    return installation_id, sync_dir
end

---@return string
local function sync_dir()
    local user_dir = rime_api.get_user_data_dir() or ""
    local _, ysync = read_installation_yaml()

    ---@param x string
    ---@return string
    local function fix(x)
        if x == "" then
            return ""
        end
        if x == "sync" then
            return (user_dir ~= "" and path_join(user_dir, "sync")) or "sync"
        end
        return normalize_path(x)
    end

    if ysync and ysync ~= "" then
        return fix(ysync)
    end

    return path_join(user_dir, "sync")
end

---@return boolean, string, string?
local function sync_ready()
    local install_id, ysync = read_installation_yaml()
    local user_dir = rime_api.get_user_data_dir() or ""

    ---@type string
    local dir
    if ysync and ysync ~= "" then
        dir = normalize_path(ysync)
        if dir == "sync" then
            dir = path_join(user_dir, "sync")
        end
    else
        dir = path_join(user_dir, "sync")
    end

    local ok = (install_id and install_id ~= "") and dir ~= "" or false
    return ok, dir, install_id
end

---@return string
local function detect_device_name()
    local installation_id = select(1, read_installation_yaml())

    ---Sanitize the installation_id to be safe for filenames
    ---@param s string
    ---@return string
    local function san(s)
        return (tostring(s):gsub('[%s/\\:%*%?"<>|]', "_"))
    end

    if installation_id and installation_id ~= "" then
        return san(installation_id)
    end

    local dir = sync_dir()
    for _, raw in ipairs(read_lines(path_join(dir, MANIFEST_FILE))) do
        local name = trim(raw or "")
        local m = name:match("^sequence_(.+)%.txt$")
        if m and not is_absolute_path(name) then
            return san(m)
        end
    end

    return "device"
end

------------------------------------------------------------
-- 五、DB 与状态
------------------------------------------------------------
---@param env Env
---@return WrappedUserDb?
local function init_db(env)
    local rime_config = env.engine.schema.config

    local db_name = rime_config:get_string("super_sequence/db_name")

    if db_name and db_name ~= "" then
        db_name = db_name:gsub("\\", "/"):gsub("^/+", "")
        while db_name:match("%.%./") do
            db_name = db_name:gsub("%.%./", "")
        end
        ---@type string
        db_name = db_name:gsub("%./", "")
    end
    if not db_name or db_name == "" then
        db_name = "lua/sequence"
    end

    local db = userdb.LevelDb(db_name)
    if db then
        db:open()
    end

    return db
end

---@param context Context
---@return string?
local function extract_adjustment_code(context)
    if wanxiang.is_function_mode_active(context) then
        return nil
    end
    return context.input:sub(1, context.caret_pos)
end

---@class AdjState
---@field selected_phrase string?
---@field offset integer?
---@field mode ADJUST_MODE
---@field highlight_index integer?
---@field adjust_code string?
---@field adjust_item string?
local adj_state = {}

---@enum ADJUST_MODE
adj_state.ADJUST_MODE = { None = -1, Reset = 0, Pin = 1, Adjust = 2 }

---@type AdjState
adj_state.DEFAULT = {
    selected_phrase = nil,
    offset = 0,
    mode = adj_state.ADJUST_MODE.None,
    highlight_index = nil,
    adjust_code = nil,
    adjust_item = nil,
}

function adj_state.reset()
    if adj_state.mode == adj_state.ADJUST_MODE.None then
        return
    end
    ---@diagnostic disable-next-line: no-unknown
    for k, v in pairs(adj_state.DEFAULT) do
        ---@type any
        adj_state[k] = v
    end
end

---@return boolean
function adj_state.is_pin_mode()
    return adj_state.mode == adj_state.ADJUST_MODE.Pin
end

---@return boolean
function adj_state.is_reset_mode()
    return adj_state.mode == adj_state.ADJUST_MODE.Reset
end

---@return boolean
function adj_state.is_adjust_mode()
    return adj_state.mode == adj_state.ADJUST_MODE.Adjust
end

---@return boolean
function adj_state.has_adjustment()
    return adj_state.mode ~= adj_state.ADJUST_MODE.None
end

------------------------------------------------------------
-- 六、记录解析
------------------------------------------------------------

---@class Adjustment
---@field fixed_position integer
---@field offset integer
---@field updated_at number
---@field raw_position integer?
---@field final_position integer?

---@param adjustment_str string
---@return string?, Adjustment?
local function parse_adjustment_value(adjustment_str)
    local item, p, o, t = adjustment_str:match("i=(.+) p=(%S+) o=(%S*) t=(%S+)")
    if not item then
        return nil, nil
    end
    return item, { fixed_position = tonumber(p) or 0, offset = tonumber(o) or 0, updated_at = tonumber(t) }
end

---@param adjustments_str string
---@return table<string, Adjustment>?
local function parse_adjustments(adjustments_str)
    ---@type table<string, Adjustment>
    local mp = {}
    for seg in adjustments_str:gmatch("[^\t]+") do
        local item, adj = parse_adjustment_value(seg)
        if item then
            mp[item] = adj
        end
    end
    return next(mp) and mp
end

---@param item string
---@param adjustment Adjustment
---@return string
local function serialize_adjustment_db(item, adjustment)
    return ("i=%s p=%s o=%s t=%s"):format(
        item,
        adjustment.fixed_position,
        adjustment.offset or 0,
        adjustment.updated_at or ""
    )
end

---@param code string
---@param item string
---@param adjustment Adjustment
---@return string
local function serialize_adjustment_sync_files(code, item, adjustment)
    return ("%s\ti=%s p=%s o=%s t=%s"):format(
        code,
        item,
        adjustment.fixed_position or 0,
        adjustment.offset or 0,
        adjustment.updated_at or ""
    )
end

---@param code string
---@param db WrappedUserDb
---@return table<string, Adjustment>?
local function get_adjustments_for_code(code, db)
    if code == "" then
        return nil
    end
    local value_str = db:fetch(code)
    return value_str and parse_adjustments(value_str)
end

------------------------------------------------------------
-- 七、导出缓冲
------------------------------------------------------------
---@class SeqData
---@field status string
---@field device_name string
---@field last_export_ts number
---@field export_interval number
---@field pending_map table<string, string>
local seq_data = {
    status = "pending",
    device_name = "device",
    last_export_ts = 0,
    export_interval = 1.2,
    pending_map = {},
}

---@return integer
function seq_data.pending_count()
    local n = 0
    for _ in pairs(seq_data.pending_map) do
        n = n + 1
    end
    return n
end

---@return string export_name
---@return string export_path
---@return string manifest_path
function seq_data.current_paths()
    local dir = sync_dir()
    local device_name = seq_data.device_name or "device"
    local export_name = ("%s_%s%s"):format(SYNC_FILE_PREFIX, device_name, SYNC_FILE_SUFFIX)
    local export_path = path_join(dir, export_name)
    local manifest_path = path_join(dir, MANIFEST_FILE)
    return export_name, export_path, manifest_path
end

---@return boolean
function seq_data.ensure_export_file()
    local ok = sync_ready()
    if not ok then
        return false
    end

    local export_name, export_path, manifest = seq_data.current_paths()
    if not wanxiang.file_exists(manifest) then
        local mf = io.open(manifest, "w")
        if not mf then
            return false
        end
        mf:close()
    end
    if not wanxiang.file_exists(export_path) then
        local f = io.open(export_path, "w")
        if not f then
            return false
        end
        local user_id = wanxiang.get_user_id()
        if user_id then
            f:write("\001/user_id\t", user_id, "\n")
        end
        f:write("\001/device_name\t", seq_data.device_name or "device", "\n")
        f:close()
    end

    local names = read_lines(manifest)

    ---@type table<string, boolean>
    local seen = {}
    for _, n in ipairs(names) do
        seen[trim(n)] = true
    end

    if not seen[export_name] then
        names[#names + 1] = export_name
        write_lines(manifest, names)
    end

    return true
end

---@param code string
---@param item string
---@param adjustment Adjustment
function seq_data.enqueue_export(code, item, adjustment)
    local key = code .. "\t" .. item
    seq_data.pending_map[key] = serialize_adjustment_sync_files(code, item, adjustment) .. "\n"
end

---@param max_lines? integer
function seq_data.flush_pending(max_lines)
    if seq_data.pending_count() == 0 then
        return
    end

    if not seq_data.ensure_export_file() then
        return
    end

    local _, export_path, _ = seq_data.current_paths()
    local f = io.open(export_path, "a")
    if not f then
        return
    end

    local wrote = 0
    for _, line in pairs(seq_data.pending_map) do
        if max_lines and wrote >= max_lines then
            break
        end
        f:write(line)
        wrote = wrote + 1
    end
    f:close()

    seq_data.pending_map = {}
end

---@param force? boolean
function seq_data.try_export(force)
    if force then
        seq_data.flush_pending(nil)
        seq_data.last_export_ts = wanxiang.now()
        return
    end

    if seq_data.pending_count() == 0 then
        return
    end

    local now = wanxiang.now()
    if now - (seq_data.last_export_ts or 0) < (seq_data.export_interval or 1.2) then
        return
    end

    seq_data.flush_pending(200)
    seq_data.last_export_ts = now
end

------------------------------------------------------------
-- 八、保存与合并 (Save & Merge)
------------------------------------------------------------
---@param code string
---@param item string
---@param adjustment Adjustment
---@param db WrappedUserDb?
---@param no_export boolean
local function save_adjustment(code, item, adjustment, db, no_export)
    if code == "" or item == "" then
        return
    end

    local position = adjustment.fixed_position
    local offset = adjustment.offset
    local time = adjustment.updated_at

    if db then
        local adj_map = get_adjustments_for_code(code, db) or {}
        adj_map[item] = { fixed_position = position > 0 and position or 0, offset = offset, updated_at = time }

        ---@type string[]
        local arr = {}
        for it, adj in pairs(adj_map) do
            arr[#arr + 1] = serialize_adjustment_db(it, adj)
        end
        db:update(code, table.concat(arr, "\t"))
    end

    if not no_export and RUNTIME_EXPORT then
        seq_data.enqueue_export(code, item, { fixed_position = position, offset = offset, updated_at = time })
    end
end

---@param adjustments table<string, table<string, Adjustment>>
---@param code string
---@param item string
---@param adj Adjustment
local function add_adjustment(adjustments, code, item, adj)
    adjustments[code] = adjustments[code] or {}
    local prev = adjustments[code][item]
    if (not prev) or ((adj.updated_at or 0) > (prev.updated_at or 0)) then
        adjustments[code][item] = {
            fixed_position = tonumber(adj.fixed_position) or 0,
            offset = tonumber(adj.offset) or 0,
            updated_at = tonumber(adj.updated_at) or 0,
        }
    end
end

---@param db WrappedUserDb?
---@return table<string, table<string, Adjustment>>
local function read_adjustments_from_all_sources(db)
    ---@type table<string, table<string, Adjustment>>
    local adjustments = {}

    if db then
        db:query_with("", function(code, adjs)
            local adj_map = parse_adjustments(adjs)
            if adj_map then
                for item, adj in pairs(adj_map) do
                    add_adjustment(adjustments, code, item, adj)
                end
            end
        end)
    end

    local dir = sync_dir()
    local names = read_lines(path_join(dir, MANIFEST_FILE))
    for _, raw in ipairs(names) do
        local name = trim(raw or "")
        if name == "" or name:sub(1, 1) == "#" then
            goto continue
        end

        if name:sub(1, #SYNC_FILE_PREFIX) ~= SYNC_FILE_PREFIX or name:sub(-#SYNC_FILE_SUFFIX) ~= SYNC_FILE_SUFFIX then
            goto continue
        end

        local path = is_absolute_path(name) and name or path_join(dir, name)
        local f = io.open(path, "r")
        if not f then
            goto continue
        end

        for line in f:lines() do
            if line == "" or line:sub(1, 2) == "\001" .. "/" then
                goto continue_line
            end

            ---@type string?, string?
            local code, value = line:match("^(%S+)\t(.+)$")
            if not code or not value then
                goto continue_line
            end

            do
                local item, adj = parse_adjustment_value(value)
                if item and adj then
                    add_adjustment(adjustments, code, item, adj)
                    goto continue_line
                end
            end

            local adjs = parse_adjustments(value)
            if adjs then
                for item, adj in pairs(adjs) do
                    add_adjustment(adjustments, code, item, adj)
                end
            end

            ::continue_line::
        end
        f:close()

        ::continue::
    end
    return adjustments
end

---@param adjustments table<string, table<string, Adjustment>>
local function write_adjustments_to_sync_files(adjustments)
    local ok = sync_ready()
    if not ok then
        return
    end
    local dir = sync_dir()
    local installation_id = select(1, read_installation_yaml())
    local device_name = (installation_id and installation_id ~= "")
            and tostring(installation_id):gsub('[%s/\\:%*%?"<>|]', "_")
        or "device"
    local export_name = ("%s_%s%s"):format(SYNC_FILE_PREFIX, device_name, SYNC_FILE_SUFFIX)
    local export_path = path_join(dir, export_name)
    local manifest = path_join(dir, MANIFEST_FILE)

    if not wanxiang.file_exists(manifest) then
        local mf = io.open(manifest, "w")
        if mf then
            mf:close()
        end
    end

    local names = read_lines(manifest)
    ---@type table<string, boolean>
    local seen = {}
    for _, n in ipairs(names) do
        seen[trim(n)] = true
    end
    if not seen[export_name] then
        names[#names + 1] = export_name
        write_lines(manifest, names)
    end

    ---@type string[]
    local lines = {}

    local user_id = wanxiang.get_user_id()
    if user_id then
        lines[#lines + 1] = "\001/user_id\t" .. user_id
    end
    lines[#lines + 1] = "\001/device_name\t" .. device_name

    ---@type string[]
    local codes = {}
    for code, _ in pairs(adjustments) do
        codes[#codes + 1] = code
    end
    table.sort(codes)

    for _, code in ipairs(codes) do
        local adjs = adjustments[code]

        -- Get a sorted list of items
        ---@type string[]
        local items = {}
        for item, _ in pairs(adjs) do
            items[#items + 1] = item
        end
        table.sort(items)

        -- Get an ordered list of lines by the order of items
        for _, item in ipairs(items) do
            lines[#lines + 1] = serialize_adjustment_sync_files(code, item, adjs[item])
        end
    end

    local new_content = table.concat(lines, "\n") .. "\n"
    local f_read = io.open(export_path, "r")
    local old_content = f_read and f_read:read("*a")
    if f_read then
        f_read:close()
    end

    if old_content ~= new_content then
        local f_write = io.open(export_path, "w")
        if f_write then
            f_write:write(new_content)
            f_write:close()
        end
    end
end

---@param adjustments table<string, table<string, Adjustment>>
---@param db WrappedUserDb
local function write_adjustments_to_db(adjustments, db)
    for code, adjs in pairs(adjustments) do
        ---@type table<string, Adjustment>
        local keep_adjs = {}
        for item, adj in pairs(adjs) do
            if adj.fixed_position > 0 then
                keep_adjs[item] =
                    { fixed_position = adj.fixed_position, offset = adj.offset or 0, updated_at = adj.updated_at }
            end
        end

        if next(keep_adjs) == nil then
            db:erase(code)
            goto continue
        end

        ---@type string[]
        local arr = {}
        for item, adj in pairs(keep_adjs) do
            arr[#arr + 1] = serialize_adjustment_db(item, adj)
        end
        db:update(code, table.concat(arr, "\t"))

        ::continue::
    end
end

------------------------------------------------------------
-- 九、Processor (含 Ctrl 监听)
------------------------------------------------------------

---@param context Context
local function process_adjustment(context)
    local c = context:get_selected_candidate()
    adj_state.selected_phrase = c and c.text
    context:refresh_non_confirmed_composition()
    if adj_state.highlight_index and adj_state.highlight_index > 0 then
        context:highlight(adj_state.highlight_index)
    end
end

local P = {}

---@param env Env
function P.init(env)
    local rime_config = env.engine.schema.config

    local key_namespace = "super_sequence/"
    ---@type SeqKeys
    local seq_keys = {
        up = rime_config:get_string(key_namespace .. "up") or "Control+j",
        down = rime_config:get_string(key_namespace .. "down") or "Control+k",
        reset = rime_config:get_string(key_namespace .. "reset") or "Control+l",
        pin = rime_config:get_string(key_namespace .. "pin") or "Control+p",
    }

    seq_data.device_name = detect_device_name()
    seq_data.ensure_export_file()
    seq_data.try_export(true)

    local db = init_db(env)
    local adjustments = read_adjustments_from_all_sources(db)
    write_adjustments_to_sync_files(adjustments)
    if db then
        write_adjustments_to_db(adjustments, db)
    end

    env.super_sequence_config = { seq_keys = seq_keys }
end

---@param env Env
function P.fini(env)
    if RUNTIME_EXPORT then
        seq_data.try_export(true)
    end
    env.super_sequence_config = nil
end

---@param key_event KeyEvent
---@param env Env
---@return ProcessResult
function P.func(key_event, env)
    local config = env.super_sequence_config
    assert(config)

    local context = env.engine.context
    local code = key_event.keycode

    -- Ctrl 监听，用于开关可视化标记
    -- 0xffe3 = Left Ctrl, 0xffe4 = Right Ctrl
    if code == 0xffe3 or code == 0xffe4 then
        if context.composition:empty() then
            return wanxiang.RIME_PROCESS_RESULTS.kNoop
        end

        local current = context:get_option("_seq_show_markers")
        local target = not key_event:release() -- 按下为true，松开为false

        if current ~= target then
            -- 获取当前光标位置，并存入全局状态 highlight_index
            local segment = context.composition:back()
            adj_state.highlight_index = segment and segment.selected_index
            -- 切换开关
            context:set_option("_seq_show_markers", target)
            -- 恢复高亮
            process_adjustment(context)
        end
        return wanxiang.RIME_PROCESS_RESULTS.kNoop
    end

    -- 重置状态
    adj_state.reset()

    local selected_cand = context:get_selected_candidate()
    if not context:has_menu() or not selected_cand or not selected_cand.text then
        if context:get_option("_seq_show_markers") then
            context:set_option("_seq_show_markers", false)
        end
        return wanxiang.RIME_PROCESS_RESULTS.kNoop
    end

    local adjust_code = extract_adjustment_code(context)

    if not wanxiang.is_function_mode_active(context) and is_single_lowercase_letter(adjust_code) then
        return wanxiang.RIME_PROCESS_RESULTS.kNoop
    end

    local key_repr = key_event:repr()

    if key_repr == config.seq_keys.up then
        adj_state.offset = -1
        adj_state.mode = adj_state.ADJUST_MODE.Adjust
    elseif key_repr == config.seq_keys.down then
        adj_state.offset = 1
        adj_state.mode = adj_state.ADJUST_MODE.Adjust
    elseif key_repr == config.seq_keys.reset then
        adj_state.offset = nil
        adj_state.mode = adj_state.ADJUST_MODE.Reset
    elseif key_repr == config.seq_keys.pin then
        adj_state.offset = nil
        adj_state.mode = adj_state.ADJUST_MODE.Pin
    else
        if context:get_option("_seq_show_markers") then
            context:set_option("_seq_show_markers", false)
            process_adjustment(context)
        end
        return wanxiang.RIME_PROCESS_RESULTS.kNoop
    end
    process_adjustment(context)
    return wanxiang.RIME_PROCESS_RESULTS.kAccepted
end

------------------------------------------------------------
-- 十、Filter (含标记可视化)
------------------------------------------------------------
---@param candidates Candidate[]
---@param adjustments table<string, Adjustment>
local function apply_prev_adjustments(candidates, adjustments)
    ---@type (Adjustment|{from_position: integer?})[]
    local list = {}
    for _, info in pairs(adjustments or {}) do
        if info.raw_position then
            ---@cast info Adjustment|{from_position: integer}
            info.from_position = info.raw_position
            table.insert(list, info)
        end
    end
    table.sort(list, function(a, b)
        return (a.updated_at or 0) < (b.updated_at or 0)
    end)

    local n = #candidates
    for i, record in ipairs(list) do
        local from_pos = record.from_position
        if not from_pos then
            goto continue
        end

        if (record.fixed_position or 0) <= 0 then
            goto continue
        end

        local top = (record.offset == 0) and record.fixed_position or (record.raw_position + record.offset)
        if top < 1 then
            top = 1
        elseif top > n then
            top = n
        end

        -- 记录初步的最终位置
        record.final_position = top

        if from_pos ~= top then
            local cand = table.remove(candidates, from_pos)
            table.insert(candidates, top, cand)
            local lo, hi = math.min(from_pos, top), math.max(from_pos, top)
            for j = i, #list do
                local r = list[j]
                if lo <= r.from_position and r.from_position <= hi then
                    r.from_position = r.from_position + ((top < from_pos) and 1 or -1)
                end
            end
        end

        ::continue::
    end
end

---@param candidates Candidate[]
---@param adjustment Adjustment?
---@param db WrappedUserDb?
local function apply_curr_adjustment(candidates, adjustment, db)
    if adjustment == nil then
        return
    end

    ---@type integer?
    local from_position = nil
    for position, cand in ipairs(candidates) do
        if cand.text == adj_state.selected_phrase then
            from_position = position
            break
        end
    end
    if from_position == nil then
        return
    end

    local to_position = from_position
    if adj_state.is_adjust_mode() then
        to_position = from_position + adj_state.offset
        adjustment.offset = to_position - adjustment.raw_position
        adjustment.fixed_position = to_position

        local min_position, max_position = 1, #candidates
        if from_position ~= to_position then
            if to_position < min_position then
                to_position = min_position
            elseif to_position > max_position then
                to_position = max_position
            end

            -- 记录当前移动后的最终位置，供标记逻辑使用
            adjustment.final_position = to_position

            local candidate = table.remove(candidates, from_position)
            table.insert(candidates, to_position, candidate)
            save_adjustment(adj_state.adjust_code, adj_state.adjust_item, adjustment, db, true)
        end
    else
        -- 如果不是移动模式（比如点了一下），当前位置也是最终位置
        adjustment.final_position = from_position
    end
    adj_state.highlight_index = to_position - 1
end

local F = {}

---@param env Env
function F.init(env)
    local db = init_db(env)
    env.super_sequence_filter_state = { db = db }
end

---@param env Env
function F.fini(env)
    env.super_sequence_filter_state = nil
end

---@param input Translation
---@param env Env
function F.func(input, env)
    local state = env.super_sequence_filter_state
    assert(state)
    local db = state.db

    local context = env.engine.context

    -- 没有任何排序记录时，原样输出并缓存
    local function original_list()
        for cand in input:iter() do
            yield(cand)
        end
    end

    -- Adjustment is not applicable in function mode
    if wanxiang.is_function_mode_active(context) then
        original_list()
        return
    end

    local adjust_code = extract_adjustment_code(context)
    if not adjust_code then
        original_list()
        return
    end

    local prev_adjustments = db and get_adjustments_for_code(adjust_code, db)
    local curr_adjustment = adj_state.has_adjustment()
            and { fixed_position = 0, offset = 0, updated_at = wanxiang.now() }
        or nil
    if not curr_adjustment and not prev_adjustments then
        original_list()
        return
    end

    ---@type Candidate[]
    local cands = {}
    ---@type table<string, boolean>
    local seen = {}
    local show_markers = context:get_option("_seq_show_markers")

    local pos = 0
    for candidate in input:iter() do
        local phrase = candidate.text
        if not seen[phrase] then
            seen[phrase] = true
            ---@type integer
            pos = pos + 1
            table.insert(cands, candidate)

            if curr_adjustment and adj_state.selected_phrase == phrase then
                adj_state.adjust_code = adjust_code
                adj_state.adjust_item = phrase
                curr_adjustment.raw_position = pos
            end

            if prev_adjustments and prev_adjustments[phrase] then
                prev_adjustments[phrase].raw_position = pos
            end
        end
    end
    prev_adjustments = prev_adjustments or {}

    -- 非位移模式（Reset/Pin）立即存 DB
    if curr_adjustment and not adj_state.is_adjust_mode() then
        curr_adjustment.offset = 0
        local key = tostring(adj_state.adjust_item)
        if adj_state.is_reset_mode() then
            curr_adjustment.fixed_position = 0
            prev_adjustments[key] = nil
            save_adjustment(adj_state.adjust_code, adj_state.adjust_item, curr_adjustment, db, true)
        elseif adj_state.is_pin_mode() then
            curr_adjustment.fixed_position = 1
            curr_adjustment.final_position = 1 -- 置顶的最终位置肯定是1
            prev_adjustments[key] = curr_adjustment
            save_adjustment(adj_state.adjust_code, adj_state.adjust_item, curr_adjustment, db, true)
        end
    end

    apply_prev_adjustments(cands, prev_adjustments)
    apply_curr_adjustment(cands, curr_adjustment, db)

    -- 将当前的实时操作同步到历史记录表中，确保标记逻辑能读到最新状态
    if curr_adjustment and adj_state.adjust_item then
        local key = tostring(adj_state.adjust_item)
        -- 确保 raw_position 不丢失（如果之前没记录，用当前的）
        if not curr_adjustment.raw_position and prev_adjustments[key] then
            curr_adjustment.raw_position = prev_adjustments[key].raw_position
        end
        -- 直接覆盖内存中的旧记录
        prev_adjustments[key] = curr_adjustment
    end

    for _, cand in ipairs(cands) do
        if show_markers and prev_adjustments then
            local adj = prev_adjustments[cand.text]
            -- 必须有有效记录(p>0)且知道原始位置
            if adj and adj.fixed_position > 0 and adj.raw_position then
                -- 获取当前最终位置
                local target = adj.final_position or adj.fixed_position
                local diff = -(target - adj.raw_position)
                local mark = ""
                if diff > 0 then
                    mark = "+" .. diff -- 提升，显示 +N
                elseif diff < 0 then
                    mark = "" .. diff -- 下降，显示 -N (diff自带负号)
                else
                    mark = " ●" -- 原地不动
                end
                cand.comment = (cand.comment or "") .. mark
            end
        end

        yield(cand)
    end

    if RUNTIME_EXPORT and (not adj_state.is_reset_mode()) then
        seq_data.try_export(false)
    end
end

return { P = P, F = F }
