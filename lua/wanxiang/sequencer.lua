---Provides manual candidate sorting and synchronization across devices by managing a local sequence database with tombstones for deleted items.
---@module "wanxiang.sequencer"
---@author amzxyz
---@author Fidel Yin <fidel.yin@hotmail.com>

-- 手动排序
-- 1) p>0：有效排序（DB insert + 导出）
-- 2) p=0：墓碑（DB 删除 + 导出墓碑）
-- 3) 初始化：先 flush 本机增量到导出 → 外部合并(所有设备文件+本机DB，LWW) → 重写本机导出(含墓碑) → 导入覆盖DB，p=0删除键，不导入
-- 4) 关于同步的使用方法：先点击同步确保同步目录已经创建，建立sequence_device_list.txt设备清单，内部填写不同设备导出文件名称
-- sequence_<installation_id>，来自 winstallation.yaml
-- 清单有什么文件就会读取什么文件
-- 仅使用 installation.yaml 的 sync_dir；读不到就回退到 user_dir/sync

local wanxiang = require("wanxiang.wanxiang")
local userdb = require("wanxiang.userdb")

---@class SequencerConfig
---@field seq_keys SeqKeys

---@class SequencerProcessorState
---@field db WrappedUserDb?

---@class SequencerFilterState
---@field db WrappedUserDb?

---@class Env
---@field sequencer_config SequencerConfig?
---@field sequencer_processor_state SequencerProcessorState?
---@field sequencer_filter_state SequencerFilterState?

---@class SeqKeys
---@field up string
---@field down string
---@field reset string
---@field pin string

local SYNC_FILE_PREFIX, SYNC_FILE_SUFFIX = "sequence", ".txt"
local RUNTIME_EXPORT = false
local MANIFEST_FILE = "sequence_device_list.txt"

------------------------------------------------------------
-- 通用工具（路径处理）
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
local function strip(s)
    return (s:gsub("^%s+", ""):gsub("%s+$", ""))
end

------------------------------------------------------------
-- 安装信息 & 同步目录
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
        local cleaned = line:gsub("%s+#.*$", "")
        ---@type string?, string?
        local key, val = cleaned:match("^%s*([%w_]+)%s*:%s*(.+)$")
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
        local name = strip(raw or "")
        local m = name:match("^sequence_(.+)%.txt$")
        if m and not is_absolute_path(name) then
            return san(m)
        end
    end

    return "device"
end

------------------------------------------------------------
-- DB 与状态
------------------------------------------------------------

local shared_state = {
    ---@type string?
    highlight_candidate = nil,
    ---@type integer?
    highlight_index = nil,
}

---@param env Env
---@return WrappedUserDb?
local function init_db(env)
    local rime_config = env.engine.schema.config

    local db_name = rime_config:get_string("sequencer/db_name")
    if db_name and db_name ~= "" then
        db_name = db_name:gsub("\\", "/"):gsub("^/+", "")
        while db_name:match("%.%./") do
            ---@type string
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

------------------------------------------------------------
-- 记录解析
------------------------------------------------------------

---@class Adjustment
---@field item string
---@field fixed_position integer? Starts from 1.
---@field offset integer
---@field updated_at number

---@param adj Adjustment?
---@return boolean
local function is_valid_adjustment(adj)
    if not adj then
        return false
    end
    if adj.fixed_position and adj.fixed_position <= 0 then
        return false
    end
    if not adj.fixed_position and adj.offset == 0 then
        return false
    end
    return true
end

---@param str string
---@return string? item
---@return Adjustment? adjustment
local function parse_adjustment_item(str)
    ---@type string?, string?, string?, string?
    local item, p, o, updated_at = str:match("i=(.+) p=(%S+) o=(%S*) t=(%S+)")
    if not item then
        return
    end

    local fixed_position = p and tonumber(p)
    if fixed_position == 0 then
        fixed_position = nil
    end

    local offset = o and tonumber(o) or 0

    ---@type Adjustment
    local adjustment = {
        item = item,
        fixed_position = fixed_position,
        offset = offset,
        updated_at = tonumber(updated_at) or 0,
    }

    if not is_valid_adjustment(adjustment) then
        return
    end

    return item, adjustment
end

---@param str string
---@return table<string, Adjustment>?
local function parse_adjustments_map(str)
    ---@type table<string, Adjustment>
    local map = {}
    for seg in str:gmatch("[^\t]+") do
        local item, adj = parse_adjustment_item(seg)
        if item then
            map[item] = adj
        end
    end
    return next(map) and map
end

---@param adjustments table<string, Adjustment>
---@return string
local function serialize_adjustments_for_code(adjustments)
    ---@type string[]
    local strs = {}
    for _, adj in pairs(adjustments) do
        strs[#strs + 1] = ("i=%s p=%s o=%s t=%s"):format(adj.item, adj.fixed_position or 0, adj.offset, adj.updated_at)
    end
    return table.concat(strs, "\t")
end

---@param code string
---@param adjustments Adjustment
---@return string
local function serialize_adjustment(code, adjustments)
    return ("%s\ti=%s p=%s o=%s t=%s"):format(
        code,
        adjustments.item,
        adjustments.fixed_position or 0,
        adjustments.offset,
        adjustments.updated_at
    )
end

---Fetch and parse adjustments map for a given code from the database.
---@param code string
---@param db WrappedUserDb
---@return table<string, Adjustment>?
local function get_adjustments_for_code(code, db)
    local str = db:fetch(code)
    return str and parse_adjustments_map(str)
end

------------------------------------------------------------
-- 导出缓冲
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
        seen[strip(n)] = true
    end

    if not seen[export_name] then
        names[#names + 1] = export_name
        write_lines(manifest, names)
    end

    return true
end

---@param code string
---@param item string
---@param adj Adjustment
function seq_data.enqueue_export(code, item, adj)
    local k = code .. "\t" .. item
    seq_data.pending_map[k] = serialize_adjustment(code, adj) .. "\n"
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
-- 保存与合并
------------------------------------------------------------
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
        seen[strip(n)] = true
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

    -- Get a sorted list of codes
    ---@type string[]
    local codes = {}
    for code, _ in pairs(adjustments) do
        codes[#codes + 1] = code
    end
    table.sort(codes)

    for _, code in ipairs(codes) do
        local items = adjustments[code]

        -- Get a sorted list of items for the current code
        ---@type string[]
        local keys = {}
        for item, _ in pairs(items) do
            keys[#keys + 1] = item
        end
        table.sort(keys)

        for _, item in ipairs(keys) do
            local adj = items[item]
            if is_valid_adjustment(adj) then
                lines[#lines + 1] = serialize_adjustment(code, adj)
            end
        end
    end

    local new_content = table.concat(lines, "\n") .. "\n"

    local f_read = io.open(export_path, "r")
    ---@type string?
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

---@param code string
---@param adjustments table<string, Adjustment>
---@param db WrappedUserDb
local function write_adjustments_for_code_to_db(code, adjustments, db)
    ---@type table<string, Adjustment>
    local valid_adjs = {}
    for item, adj in pairs(adjustments) do
        if is_valid_adjustment(adj) then
            valid_adjs[item] = adj
        end
    end

    if next(valid_adjs) ~= nil then
        db:update(code, serialize_adjustments_for_code(valid_adjs))
    else
        db:erase(code)
    end
end

---@param adjustments table<string, table<string, Adjustment>>
---@param db WrappedUserDb
local function write_adjustments_to_db(adjustments, db)
    for code, code_adjs in pairs(adjustments) do
        write_adjustments_for_code_to_db(code, code_adjs, db)
    end
end

---@param code string
---@param item string
---@param adjustment Adjustment
---@param db WrappedUserDb?
---@param no_export boolean
local function save_adjustment(code, item, adjustment, db, no_export)
    if item == "" then
        return
    end

    if db then
        local adj_map = get_adjustments_for_code(code, db) or {}
        adj_map[item] = adjustment
        write_adjustments_for_code_to_db(code, adj_map, db)
    end

    if not no_export and RUNTIME_EXPORT then
        seq_data.enqueue_export(code, item, adjustment)
    end
end

---Add adjustment to the adjustments map. If there is an existing adjustment, keep the latest one.
---@param adjustments table<string, table<string, Adjustment>>
---@param code string
---@param item string
---@param adjustment Adjustment
local function add_adjustments(adjustments, code, item, adjustment)
    if not adjustments[code] then
        adjustments[code] = {}
    end
    local old = adjustments[code][item]
    if not old or adjustment.updated_at > old.updated_at then
        adjustments[code][item] = adjustment
    end
end

---@param db WrappedUserDb?
---@return table<string, table<string, Adjustment>>
local function read_adjustments_from_all_sources(db)
    ---@type table<string, table<string, Adjustment>>
    local adjustments = {}

    if db then
        -- Read from database
        db:query_with("", function(key, value)
            local adj_map = parse_adjustments_map(value)
            if adj_map then
                for item, adj in pairs(adj_map) do
                    add_adjustments(adjustments, key, item, adj)
                end
            end
        end)
    end

    -- Read from sync files
    local dir = sync_dir()
    local filenames = read_lines(path_join(dir, MANIFEST_FILE))
    for _, filename in ipairs(filenames) do
        filename = strip(filename)
        if filename == "" or filename:sub(1, 1) == "#" then
            goto continue
        end

        if
            filename:sub(1, #SYNC_FILE_PREFIX) ~= SYNC_FILE_PREFIX
            or filename:sub(-#SYNC_FILE_SUFFIX) ~= SYNC_FILE_SUFFIX
        then
            goto continue
        end

        local path = is_absolute_path(filename) and filename or path_join(dir, filename)
        local f = io.open(path, "r")
        if not f then
            goto continue
        end

        -- Read sync file
        for line in f:lines() do
            if line == "" or line:sub(1, 2) == "\001/" then
                goto continue_line
            end

            ---@type string?, string?
            local code, adj_str = line:match("^(%S+)\t(.+)$")
            if not code or not adj_str then
                goto continue_line
            end

            -- Try parsing as single item
            do
                local item, adj = parse_adjustment_item(adj_str)
                if item and adj then
                    add_adjustments(adjustments, code, item, adj)
                    goto continue_line
                end
            end

            -- Try parsing as multiple items
            local map = parse_adjustments_map(adj_str)
            if map then
                for item, adj in pairs(map) do
                    add_adjustments(adjustments, code, item, adj)
                end
            end

            ::continue_line::
        end
        f:close()

        ::continue::
    end
    return adjustments
end

------------------------------------------------------------
-- Processor
------------------------------------------------------------

---@param context Context
local function refresh_candidates(context)
    -- Preserve current highlight index
    local highlight_candidate = context:get_selected_candidate()
    shared_state.highlight_candidate = highlight_candidate and highlight_candidate.text

    -- Refresh candidates to show/hide markers
    -- Filter is called, which updates highlight_index
    context:refresh_non_confirmed_composition()

    -- Recover highlight
    if shared_state.highlight_index then
        context:highlight(shared_state.highlight_index)
    end
    shared_state.highlight_candidate = nil
    shared_state.highlight_index = nil
end

---@param show_markers boolean
---@param context Context
local function switch_markers(show_markers, context)
    local show_markers_curr = context:get_option("_seq_show_markers")
    if show_markers_curr == show_markers then
        return
    end

    -- Preserve current highlight index
    local segment = context.composition:back()
    local highlight_index = segment and segment.selected_index

    -- Switch marker visibility
    context:set_option("_seq_show_markers", show_markers)

    -- Refresh candidates to show/hide markers
    context:refresh_non_confirmed_composition()

    -- Recover highlight
    if highlight_index then
        context:highlight(highlight_index)
    end
end

---@class Processor
local P = {}

---@param env Env
function P.init(env)
    local rime_config = env.engine.schema.config

    local key_namespace = "sequencer/"
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

    env.sequencer_config = { seq_keys = seq_keys }

    env.sequencer_processor_state = { db = db }
end

---@param env Env
function P.fini(env)
    if RUNTIME_EXPORT then
        seq_data.try_export(true)
    end
    env.sequencer_config = nil
    env.sequencer_processor_state = nil
end

---@param key_event KeyEvent
---@param env Env
---@return ProcessResult
function P.func(key_event, env)
    local context = env.engine.context

    local config = env.sequencer_config
    assert(config)
    local state = env.sequencer_processor_state
    assert(state)

    -- Adjustment is not allowed in function mode
    if wanxiang.is_function_mode_active(context) then
        return wanxiang.RIME_PROCESS_RESULTS.kNoop
    end

    local keycode = key_event.keycode
    -- Ctrl 监听，用于开关可视化标记
    -- 0xffe3 = Left Ctrl, 0xffe4 = Right Ctrl
    if keycode == 0xffe3 or keycode == 0xffe4 then
        if context.composition:empty() then
            return wanxiang.RIME_PROCESS_RESULTS.kNoop
        end

        -- 按下为true，松开为false
        switch_markers(not key_event:release(), context)

        return wanxiang.RIME_PROCESS_RESULTS.kNoop
    end

    -- Exit if no candidate or no composition
    local selected_cand = context:get_selected_candidate()
    if not context:has_menu() or not selected_cand or not selected_cand.text then
        if context:get_option("_seq_show_markers") then
            context:set_option("_seq_show_markers", false)
        end
        return wanxiang.RIME_PROCESS_RESULTS.kNoop
    end

    local code = context.input:sub(1, context.caret_pos)
    local item = selected_cand.text
    local adjustments = state.db and get_adjustments_for_code(code, state.db) or {}

    -- Initiate an empty adjustment to be filled later
    ---@type Adjustment?
    local new_adjustment = nil

    local key_repr = key_event:repr()
    if key_repr == config.seq_keys.up then
        -- UP
        local old_adj = adjustments[item]
        new_adjustment = {
            item = item,
            fixed_position = old_adj and old_adj.fixed_position or nil,
            offset = (old_adj and old_adj.offset or 0) - 1,
            updated_at = wanxiang.now(),
        }
    elseif key_repr == config.seq_keys.down then
        -- DOWN
        local old_adj = adjustments[item]
        new_adjustment = {
            item = item,
            fixed_position = old_adj and old_adj.fixed_position or nil,
            offset = (old_adj and old_adj.offset or 0) + 1,
            updated_at = wanxiang.now(),
        }
    elseif key_repr == config.seq_keys.reset then
        -- RESET
        new_adjustment = {
            item = item,
            fixed_position = nil,
            offset = 0,
            updated_at = wanxiang.now(),
        }
    elseif key_repr == config.seq_keys.pin then
        -- PIN
        new_adjustment = {
            item = item,
            fixed_position = 1,
            offset = 0,
            updated_at = wanxiang.now(),
        }
    else -- Unrelated key, exit
        switch_markers(false, context)
        return wanxiang.RIME_PROCESS_RESULTS.kNoop
    end

    if new_adjustment then
        adjustments[item] = new_adjustment
        save_adjustment(code, item, new_adjustment, state.db, false)
    end

    if RUNTIME_EXPORT then
        seq_data.try_export()
    end

    refresh_candidates(context)
    return wanxiang.RIME_PROCESS_RESULTS.kAccepted
end

------------------------------------------------------------
-- Filter
------------------------------------------------------------
---@param candidates Candidate[]
---@param adjustments table<string, Adjustment>
local function apply_adjustments(candidates, adjustments)
    -- Get a sorted list of adjustments based on their updated_at timestamp
    ---@type Adjustment[]
    local adjs_list = {}
    for _, adj in pairs(adjustments) do
        if is_valid_adjustment(adj) then
            adjs_list[#adjs_list + 1] = adj
        end
    end
    table.sort(adjs_list, function(a, b)
        return a.updated_at < b.updated_at
    end)

    local candidates_num = #candidates

    for _, adj in ipairs(adjs_list) do
        -- Find the candidate with the matching text
        local from_pos = nil
        for index, cand in ipairs(candidates) do
            if cand.text == adj.item then
                from_pos = index
                break
            end
        end
        if not from_pos then
            goto continue
        end

        local to_pos = (adj.fixed_position or from_pos) + adj.offset

        if to_pos < 1 then
            to_pos = 1
        elseif to_pos > candidates_num then
            to_pos = candidates_num
        end

        if from_pos ~= to_pos then
            local cand = table.remove(candidates, from_pos)
            table.insert(candidates, to_pos, cand)
        end

        ::continue::
    end
end

---@class Filter
local F = {}

---@param env Env
function F.init(env)
    local db = init_db(env)

    env.sequencer_filter_state = { db = db }
end

---@param env Env
function F.fini(env)
    env.sequencer_filter_state = nil
end

---@param input Translation
---@param env Env
function F.func(input, env)
    local context = env.engine.context

    local state = env.sequencer_filter_state
    assert(state)

    local function yield_original()
        for cand in input:iter() do
            yield(cand)
        end
    end

    -- Adjustment is not allowed in function mode
    if wanxiang.is_function_mode_active(context) then
        yield_original()
        return
    end

    local code = context.input:sub(1, context.caret_pos)
    if not code then
        yield_original()
        return
    end

    -- Fetch previous adjustments for this code from the database
    local adjustments = state.db and get_adjustments_for_code(code, state.db)
    if not adjustments then
        yield_original()
        return
    end

    ---@type Candidate[]
    local cands = {}
    ---@type table<string, boolean>
    local seen = {}
    for cand in input:iter() do
        local phrase = cand.text
        if not seen[phrase] then
            cands[#cands + 1] = cand
            seen[phrase] = true
        end
    end

    ---@type table<string, integer>
    local orig_positions = {}
    for index, cand in ipairs(cands) do
        local item = cand.text
        if adjustments[item] then
            orig_positions[item] = index
        end
    end

    apply_adjustments(cands, adjustments)

    local show_markers = context:get_option("_seq_show_markers")
    for curr_pos, cand in ipairs(cands) do
        local item = cand.text
        -- Display markers
        if show_markers and adjustments[item] then
            local orig_pos = orig_positions[item]

            local diff = -(curr_pos - orig_pos) -- Invert the difference to show movement direction
            local mark = ""
            if diff > 0 then
                mark = "+" .. diff -- 提升，显示 +N
            elseif diff < 0 then
                mark = tostring(diff) -- 下降，显示 -N (diff自带负号)
            else
                mark = " ●" -- 原地不动
            end
            cand.comment = cand.comment .. mark
        end

        if cand.text == shared_state.highlight_candidate then
            shared_state.highlight_index = curr_pos - 1
        end

        yield(cand)
    end
end

return { P = P, F = F }
