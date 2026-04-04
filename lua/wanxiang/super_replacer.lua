---Provides flexible text replacement for candidates (such as emoji insertion or Traditional/Simplified Chinese conversion) serving as an alternative to OpenCC with configurable replacement pipelines.
---@module "wanxiang.super_replacer"
---@author amzxyz
---@author Fidel Yin <fidel.yin@hotmail.com>

---@class SuperReplacerConfig
---@field split_pattern string
---@field comment_format string
---@field is_chain boolean
---@field rules Rule[]

---@class SuperReplacerState
---@field input_type string
---@field fmm_cache table<string, string|false>
---@field db WrappedUserDb?

---@class Env
---@field super_replacer_config SuperReplacerConfig?
---@field super_replacer_state SuperReplacerState?

---@class Task
---@field path string
---@field prefix string

---@class Rule
---@field triggers (boolean|string)[]
---@field tags string[]
---@field prefix string
---@field mode string
---@field always_qty integer
---@field always_idx integer
---@field comment_mode string
---@field fmm boolean
---@field cand_type string?

local userdb = require("wanxiang.userdb")
local wanxiang = require("wanxiang.wanxiang")

---@type WrappedUserDb?
local db_instance = nil

---@type { text: string, comment: string }[]
local shared_pending = {}
---@type string[]
local shared_comments = {}

---@param t table<integer, any>
local function clear_list(t)
    for i = 1, #t do
        t[i] = nil
    end
end

---@param text string
---@return integer[]
local function utf8_offsets(text)
    ---@type integer[]
    local offsets = {}
    for pos in utf8.codes(text) do
        offsets[#offsets + 1] = pos
    end
    offsets[#offsets + 1] = #text + 1
    return offsets
end

---@param tasks Task[]
---@return string
local function generate_files_signature(tasks)
    local sig_parts = {}
    for _, task in ipairs(tasks) do
        local f = io.open(task.path, "rb")
        if f then
            local size = f:seek("end")
            local head = ""
            local mid = ""
            local tail = ""

            if size > 0 then
                -- 截取头 64 字节
                f:seek("set", 0)
                head = f:read(64) or ""

                -- 截取尾 64 字节
                local tail_pos = size - 64
                if tail_pos < 0 then
                    tail_pos = 0
                end
                f:seek("set", tail_pos)
                tail = f:read(64) or ""

                -- 截取中间 64 字节 (防止同字节数的等长替换)
                local mid_pos = math.floor(size / 2)
                f:seek("set", mid_pos)
                mid = f:read(64) or ""
            end
            f:close()

            -- 将 前缀 + 大小 + 头中尾 拼接成该文件的唯一特征码
            table.insert(sig_parts, task.prefix .. size .. head .. mid .. tail)
        end
    end
    -- 将所有文件的特征码合并
    return table.concat(sig_parts, "||")
end

-- 重建数据库 (仅在 wanxiang 版本变更时运行)
---@param tasks Task[]
---@param db WrappedUserDb
---@param delimiter string
---@return boolean
local function rebuild(tasks, db, delimiter)
    for _, task in ipairs(tasks) do
        local txt_path = task.path
        local prefix = task.prefix

        local f = io.open(txt_path, "r")
        if not f then
            goto continue
        end

        for line in f:lines() do
            if line == "" or line:match("^%s*#") then
                goto continue_line
            end

            ---@type string?, string?
            local k, v = line:match("^([^\t]+)\t+(.+)")
            if not k or not v then
                goto continue_line
            end

            -- 转换完成后，再和 prefix 组合
            ---@type string
            v = v:match("^%s*(.-)%s*$")

            local db_key = prefix .. k
            local existing_v = db:fetch(db_key)
            if existing_v and existing_v ~= "" then
                v = existing_v .. delimiter .. v
            end
            db:update(db_key, v)

            ::continue_line::
        end
        f:close()

        ::continue::
    end
    return true
end

---@param db_name string
---@param current_version string
---@param delimiter string
---@param tasks Task[]
---@param config_sig string
---@param state table
---@return WrappedUserDb?
local function connect_db(db_name, current_version, delimiter, tasks, config_sig, state)
    if db_instance then
        return db_instance
    end

    local db = userdb.LevelDb(db_name)
    if not db then
        return nil
    end

    -- 1. 计算当前所有物理文件的特征码
    local current_signature = generate_files_signature(tasks) .. "||" .. (config_sig or "")

    local needs_rebuild = false
    if db:open_read_only() then
        local db_ver = db:meta_fetch("_wanxiang_ver") or ""
        local db_delim = db:meta_fetch("_delim")
        local db_sig = db:meta_fetch("_files_sig") or "" -- 读取数据库里存的特征码

        -- 版本变了、分隔符变了、或者文件内容被用户改了，触发重建
        if db_ver ~= current_version or db_delim ~= delimiter or db_sig ~= current_signature then
            needs_rebuild = true
        end
        db:close()
    else
        needs_rebuild = true
    end

    if needs_rebuild then
        if db:open() then
            rebuild(tasks, db, delimiter)
            state.fmm_cache = {} --只要词库重建，彻底清空旧缓存
            -- 更新最新的烙印
            db:meta_update("_wanxiang_ver", current_version)
            db:meta_update("_delim", delimiter)
            db:meta_update("_files_sig", current_signature) -- 记下当前的文件特征

            log.info("super_replacer: 数据已重载")
            db:close()
        end
    end

    if db:open_read_only() then
        db_instance = db
        return db
    end

    return nil
end

-- FMM 分词转换算法
---@param text string
---@param db WrappedUserDb?
---@param prefix string
---@param split_pat string
---@param state SuperReplacerState
---@return string
local function segment_convert(text, db, prefix, split_pat, state)
    local offsets = utf8_offsets(text)
    local char_count = #offsets - 1
    local result_parts = {}
    local i = 1
    local MAX_LOOKAHEAD = 6

    while i <= char_count do
        local start_byte = offsets[i]
        local matched = false

        local max_j = i + MAX_LOOKAHEAD
        if max_j > char_count + 1 then
            max_j = char_count + 1
        end

        -- 1. 长词 FMM 循环与缓存拦截
        for j = max_j, i + 2, -1 do
            local end_byte = offsets[j] - 1
            local sub_text = text:sub(start_byte, end_byte)
            local cache_key = prefix .. sub_text

            local val = state.fmm_cache[cache_key]
            if val == nil then
                local db_res = db and db:fetch(cache_key)
                state.fmm_cache[cache_key] = db_res or false
                val = state.fmm_cache[cache_key]
            end

            if val then
                local first_val = val:match(split_pat)
                table.insert(result_parts, first_val or sub_text)
                i = j - 1
                matched = true
                break
            end
        end

        -- 2. 单字/单字符兜底（带缓存）
        if not matched then
            local single_char = text:sub(start_byte, offsets[i + 1] - 1)
            local cache_key = prefix .. single_char

            local val = state.fmm_cache[cache_key]
            if val == nil then
                local db_res = db and db:fetch(cache_key)
                state.fmm_cache[cache_key] = db_res or false
                val = state.fmm_cache[cache_key]
            end

            if val then
                local first_val = val:match(split_pat)
                table.insert(result_parts, first_val or single_char)
            else
                table.insert(result_parts, single_char)
            end
        end

        i = i + 1
    end
    return table.concat(result_parts)
end

local M = {}

---@param env Env
function M.init(env)
    local namespace = env.name_space
    namespace = namespace:gsub("^%*", "")
    ---@type string
    namespace = namespace:match("([^%.]+)$") or namespace

    local rime_config = env.engine.schema.config

    local user_dir = rime_api.get_user_data_dir()
    local shared_dir = rime_api.get_shared_data_dir()

    -- 1. 基础配置
    local db_name = rime_config:get_string(namespace .. "/db_name") or "lua/replacer"
    local delimiter = rime_config:get_string(namespace .. "/delimiter") or "|"

    local input_type = wanxiang.get_input_method_type(env)

    ---@type string
    local split_pattern
    if delimiter == " " then
        split_pattern = "%S+"
    else
        local esc = delimiter:gsub("[%-%.%+%[%]%(%)%$%^%%%?%*]", "%%%1")
        split_pattern = "([^" .. esc .. "]+)"
    end

    ---@param relative string?
    ---@return string?
    local function resolve_path(relative)
        if not relative then
            return nil
        end
        local user_path = user_dir .. "/" .. relative
        local f = io.open(user_path, "r")
        if f then
            f:close()
            return user_path
        end
        local shared_path = shared_dir .. "/" .. relative
        f = io.open(shared_path, "r")
        if f then
            f:close()
            return shared_path
        end
        return user_path
    end

    local rules_path = namespace .. "/rules"
    local rule_list = rime_config:get_list(rules_path)

    ---@type Task[]
    local tasks = {}
    ---@type Rule[]
    local rules = {}

    if rule_list then
        for i = 0, rule_list.size - 1 do
            local entry_path = rules_path .. "/@" .. i

            -- 解析 triggers
            local triggers = {}
            local opts_keys = { "option", "options" }
            for _, key in ipairs(opts_keys) do
                local key_path = entry_path .. "/" .. key
                local list = rime_config:get_list(key_path)
                if list then
                    for k = 0, list.size - 1 do
                        local val = rime_config:get_string(key_path .. "/@" .. k)
                        if val then
                            table.insert(triggers, val)
                        end
                    end
                else
                    if rime_config:get_bool(key_path) == true then
                        table.insert(triggers, true)
                    else
                        local val = rime_config:get_string(key_path)
                        if val and val ~= "true" then
                            table.insert(triggers, val)
                        end
                    end
                end
            end

            -- 解析 Tags
            ---@type table<string, boolean>?
            local target_tags = nil
            local tag_keys = { "tag", "tags" }
            for _, key in ipairs(tag_keys) do
                local key_path = entry_path .. "/" .. key
                local list = rime_config:get_list(key_path)
                if list then
                    if not target_tags then
                        target_tags = {}
                    end
                    for k = 0, list.size - 1 do
                        local val = rime_config:get_string(key_path .. "/@" .. k)
                        if val then
                            target_tags[val] = true
                        end
                    end
                else
                    local val = rime_config:get_string(key_path)
                    if val then
                        if not target_tags then
                            target_tags = {}
                        end
                        target_tags[val] = true
                    end
                end
            end

            if #triggers > 0 then
                local prefix = rime_config:get_string(entry_path .. "/prefix") or ""
                local mode = rime_config:get_string(entry_path .. "/mode") or "append"

                local comment_mode = rime_config:get_string(entry_path .. "/comment_mode") or "comment"
                local fmm = rime_config:get_bool(entry_path .. "/sentence") or false

                -- 解析 cand_type
                local custom_cand_type = rime_config:get_string(entry_path .. "/cand_type")

                local always_qty = 1
                local always_idx = 1
                if mode == "abbrev" then
                    local rule_str = rime_config:get_string(entry_path .. "/abbrev_rule") or "1,1"
                    local qty_str, idx_str = rule_str:match("^(%d+)%s*,%s*(%d+)$")
                    always_qty = tonumber(qty_str) or 1
                    always_idx = tonumber(idx_str) or 1
                end

                table.insert(rules, {
                    triggers = triggers,
                    tags = target_tags,
                    prefix = prefix,
                    mode = mode,
                    always_qty = always_qty,
                    always_idx = always_idx,
                    comment_mode = comment_mode,
                    fmm = fmm,
                    cand_type = custom_cand_type,
                })

                -- 收集文件路径 (仅用于可能发生的 rebuild)
                local keys_to_check = { "files", "file" }
                for _, key in ipairs(keys_to_check) do
                    local d_path = entry_path .. "/" .. key
                    local list = rime_config:get_list(d_path)
                    if list then
                        for j = 0, list.size - 1 do
                            local p = resolve_path(rime_config:get_string(d_path .. "/@" .. j))
                            if p then
                                table.insert(tasks, { path = p, prefix = prefix })
                            end
                        end
                    else
                        local p = resolve_path(rime_config:get_string(d_path))
                        if p then
                            table.insert(tasks, { path = p, prefix = prefix })
                        end
                    end
                end
            end
        end
    end

    local config_sig_parts = {}
    for _, t in ipairs(rules) do
        table.insert(config_sig_parts, (t.cand_type or ""))
    end
    local config_sig = table.concat(config_sig_parts, "|")

    env.super_replacer_config = {
        split_pattern = split_pattern,
        comment_format = rime_config:get_string(namespace .. "/comment_format") or "〔%s〕",
        is_chain = rime_config:get_bool(namespace .. "/chain") or false,
        rules = rules,
    }

    env.super_replacer_state = {
        input_type = input_type,
        fmm_cache = {},
        db = nil,
    }

    -- 3. DB 初始化 (使用单例连接)
    env.super_replacer_state.db =
        connect_db(db_name, wanxiang.version, delimiter, tasks, config_sig, env.super_replacer_state)
end

---@param env Env
function M.fini(env)
    env.super_replacer_config = nil
    env.super_replacer_state = nil
end

---@param input Translation
---@param env Env
function M.func(input, env)
    local config = env.super_replacer_config
    assert(config)
    local state = env.super_replacer_state
    assert(state)

    local ctx = env.engine.context

    local input_code = ctx.input

    if not ctx:is_composing() or ctx.input == "" then
        state.fmm_cache = {}
        collectgarbage("step", 200)
        for cand in input:iter() do
            yield(cand)
        end
        return
    end

    if #config.rules == 0 or not state.db then
        for cand in input:iter() do
            yield(cand)
        end
        return
    end

    local seg = ctx.composition:back()
    local current_seg_tags = seg and seg.tags or {}

    if seg then
        input_code = ctx.input:sub(seg.start + 1, seg._end)
    end

    -- [Helper] 通用处理函数
    ---@param cand Candidate
    ---@return Candidate[]
    local function process_rules(cand)
        ---@type Candidate[]
        local results = {}
        local current_text = cand.text
        local show_main = true
        local current_main_comment = cand.comment
        local matched_cand_type = nil

        clear_list(shared_pending)
        clear_list(shared_comments)

        for _, rule in ipairs(config.rules) do
            if rule.mode ~= "abbrev" then
                local is_active = false
                for _, trigger in ipairs(rule.triggers) do
                    if trigger == true then
                        is_active = true
                        break
                    elseif type(trigger) == "string" and ctx:get_option(trigger) then
                        is_active = true
                        break
                    end
                end

                local is_tag_match = true
                if rule.tags then
                    is_tag_match = false
                    for req_tag, _ in pairs(rule.tags) do
                        if current_seg_tags[req_tag] then
                            is_tag_match = true
                            break
                        end
                    end
                end

                if is_active and is_tag_match then
                    local query_text = config.is_chain and current_text or cand.text
                    local key = rule.prefix .. query_text
                    local val = state.db and state.db:fetch(key)
                    if not val and string.match(query_text, "[A-Z]") then
                        local lower_key = rule.prefix .. string.lower(query_text)
                        val = state.db:fetch(lower_key)
                    end
                    if not val and rule.fmm then
                        local seg_result =
                            segment_convert(query_text, state.db, rule.prefix, config.split_pattern, state)
                        if seg_result ~= query_text then
                            val = seg_result
                        end
                    end

                    if val then
                        matched_cand_type = rule.cand_type or matched_cand_type

                        local rule_comment = ""
                        if rule.comment_mode == "text" then
                            rule_comment = cand.text
                        elseif rule.comment_mode == "comment" then
                            rule_comment = cand.comment
                        end

                        local mode = rule.mode
                        if mode ~= "comment" and rule_comment ~= "" then
                            rule_comment = config.comment_format:format(rule_comment)
                        end

                        if mode == "comment" then
                            ---@type string[]
                            local parts = {}
                            for p in val:gmatch(config.split_pattern) do
                                -- 如果词库提示的简码，刚好等于用户当前已经敲下的编码，则不显示提示
                                if p ~= input_code then
                                    table.insert(parts, p)
                                end
                            end
                            -- 只有当 parts 里有剩余有效提示时，才追加到注释数组里
                            if #parts > 0 then
                                table.insert(shared_comments, table.concat(parts, " "))
                            end
                        elseif mode == "replace" then
                            if config.is_chain then
                                local first = true
                                for p in val:gmatch(config.split_pattern) do
                                    if first then
                                        current_text = p
                                        if rule.comment_mode == "none" then
                                            current_main_comment = ""
                                        elseif rule.comment_mode == "text" then
                                            current_main_comment = cand.text
                                        end
                                        first = false
                                    else
                                        table.insert(shared_pending, { text = p, comment = rule_comment })
                                    end
                                end
                            else
                                show_main = false
                                for p in val:gmatch(config.split_pattern) do
                                    table.insert(shared_pending, { text = p, comment = rule_comment })
                                end
                            end
                        elseif mode == "append" then
                            for p in val:gmatch(config.split_pattern) do
                                table.insert(shared_pending, { text = p, comment = rule_comment })
                            end
                        end
                    end
                end
            end
        end

        if #shared_comments > 0 then
            local comment_str = table.concat(shared_comments, " ")
            local fmt = config.comment_format:format(comment_str)
            if current_main_comment and current_main_comment ~= "" then
                current_main_comment = current_main_comment .. fmt
            else
                current_main_comment = fmt
            end
        end

        if show_main then
            if config.is_chain and current_text ~= cand.text then
                local final_type = matched_cand_type or cand.type or "kv"
                local new_cand = Candidate(final_type, cand.start, cand._end, current_text, current_main_comment)
                new_cand.preedit = cand.preedit
                new_cand.quality = cand.quality
                table.insert(results, new_cand)
            else
                cand.comment = current_main_comment
                table.insert(results, cand)
            end
        end

        for _, item in ipairs(shared_pending) do
            if not (show_main and item.text == current_text) then
                local final_type = matched_cand_type or "derived"
                local new_cand = Candidate(final_type, cand.start, cand._end, item.text, item.comment)
                new_cand.preedit = cand.preedit
                new_cand.quality = cand.quality
                table.insert(results, new_cand)
            end
        end
        return results
    end

    -- 流式拦截器 + 候车室 架构
    local yield_count = 0
    local quality_dropped = false
    local has_exact_phrase = false
    ---@type table<string, boolean>
    local seen_texts = {}
    ---@type table<string, boolean>
    local global_yielded = {}
    ---@type { cand: Candidate, index: integer }[]
    local always_cands = {}
    ---@type Candidate[]
    local lazy_cands = {}
    ---@type Candidate[]
    local top_buffer = {}

    -- 第一步：提前提取简码候选，分配阵营
    for _, t in ipairs(config.rules) do
        if t.mode == "abbrev" then
            local is_active = false
            for _, trigger in ipairs(t.triggers) do
                if trigger == true then
                    is_active = true
                    break
                elseif type(trigger) == "string" and ctx:get_option(trigger) then
                    is_active = true
                    break
                end
            end

            local is_tag_match = true
            if t.tags then
                is_tag_match = false
                for req_tag, _ in pairs(t.tags) do
                    if current_seg_tags[req_tag] then
                        is_tag_match = true
                        break
                    end
                end
            end

            if is_active and is_tag_match and input_code ~= "" then -- 加上输入非空保护
                local key = t.prefix .. input_code
                local val = state.db:fetch(key)
                    or (not input_code:match("[A-Z]") and state.db:fetch(t.prefix .. input_code:upper()))

                if val then
                    local count = 0
                    for p in val:gmatch(config.split_pattern) do
                        if not seen_texts[p] then
                            seen_texts[p] = true

                            -- 简码也支持强制注入 type
                            local final_type = t.cand_type or "abbrev"
                            local abbrev_cand =
                                Candidate(final_type, seg and seg.start or 0, seg and seg._end or #input_code, p, "")

                            count = count + 1

                            if count <= t.always_qty then
                                abbrev_cand.quality = 999
                                table.insert(always_cands, { cand = abbrev_cand, index = t.always_idx + (count - 1) })
                            else
                                abbrev_cand.quality = 98
                                table.insert(lazy_cands, abbrev_cand)
                            end
                        end
                    end
                end
            end
        end
    end

    table.sort(always_cands, function(a, b)
        return a.index < b.index
    end)

    -- 标准吐词函数（含精准定位插队）
    ---@param cand Candidate
    local function output_cand(cand)
        local processed_cands = process_rules(cand)
        for _, pc in ipairs(processed_cands) do
            while #always_cands > 0 and (yield_count + 1) >= always_cands[1].index do
                local ac = table.remove(always_cands, 1)
                local ac_processed = process_rules(ac.cand)
                for _, apc in ipairs(ac_processed) do
                    if not global_yielded[apc.text] then
                        global_yielded[apc.text] = true
                        yield(apc)
                        yield_count = yield_count + 1
                    end
                end
            end
            if not global_yielded[pc.text] then
                global_yielded[pc.text] = true
                yield(pc)
                yield_count = yield_count + 1
            end
        end
    end

    -- 清空候车室机制
    local function flush_buffer()
        if has_exact_phrase then
            -- 正常有词,执行定位插队，替补直接销毁
            for _, cand in ipairs(top_buffer) do
                output_cand(cand)
            end
        else
            -- 空码救场
            for _, cand in ipairs(top_buffer) do
                local processed_cands = process_rules(cand)
                for _, pc in ipairs(processed_cands) do
                    if not global_yielded[pc.text] then
                        global_yielded[pc.text] = true
                        yield(pc)
                        yield_count = yield_count + 1
                    end
                end
            end

            -- 立刻倾泻所有主力简码（无视设定的 index 坑位了，紧紧跟在后面）
            while #always_cands > 0 do
                local ac = table.remove(always_cands, 1)
                local ac_processed = process_rules(ac.cand)
                for _, apc in ipairs(ac_processed) do
                    if not global_yielded[apc.text] then
                        global_yielded[apc.text] = true
                        yield(apc)
                        yield_count = yield_count + 1
                    end
                end
            end

            -- 立刻倾泻所有替补简码
            for _, lc in ipairs(lazy_cands) do
                local lc_processed = process_rules(lc)
                for _, lpc in ipairs(lc_processed) do
                    if not global_yielded[lpc.text] then
                        global_yielded[lpc.text] = true
                        yield(lpc)
                        yield_count = yield_count + 1
                    end
                end
            end
            lazy_cands = {}
        end
        top_buffer = {}
    end

    -- 第二步：遍历底层流
    for cand in input:iter() do
        if cand.type == "phrase" or cand.type == "user_phrase" then
            has_exact_phrase = true
        end
        local q = cand.quality or 0

        if not quality_dropped then
            if q >= 99 then
                table.insert(top_buffer, cand)
            else
                quality_dropped = true
                flush_buffer()
                output_cand(cand)
            end
        else
            output_cand(cand)
        end
    end

    -- 第三步：如果流从头到尾都没跌破 99（很短的流），做最后的兜底收尾
    if not quality_dropped then
        flush_buffer()
    end

    -- 清理残余（应对 index 设定极大，流长度不够的情况）
    while #always_cands > 0 do
        local ac = table.remove(always_cands, 1)
        local ac_processed = process_rules(ac.cand)
        for _, apc in ipairs(ac_processed) do
            if not global_yielded[apc.text] then
                global_yielded[apc.text] = true
                yield(apc)
                yield_count = yield_count + 1
            end
        end
    end
end

return M
