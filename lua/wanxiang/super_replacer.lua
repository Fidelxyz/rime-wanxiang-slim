--[[
super_replacer.lua 一个rime OpenCC替代品，更灵活地配置能力
https://github.com/amzxyz/rime_wanxiang
by amzxyz
路径检测：UserDir > SharedDir
支持 option: true (常驻启用)
super_replacer:
    db_name: lua/replacer
    delimiter: "|"
    comment_format: "〔%s〕"
    chain: true  #true表示流水线作业，上一个option产出交给下一个处理，典型的s2t>t2hk=s2hk，false就是并行，直接用text转换
    types:
      # 场景1：输入 '哈哈' -> 变成 '1.哈哈 2.😄'
      - option: emoji          # 开关名称与上面开关名称保持一致
        mode: append            # 新增候选append 替换原候选replace 替换注释comment
        comment_mode: none      # 注释模式: "append"(原候选注释继承), "text"(原候选文本放在注释), "none"(空，默认)
        tags: [abc]            # 生效的tag
        prefix: "_em_"          # 前缀用于区分同一个数据库的不同用途数据
        files:
          - lua/data/emoji.txt
      # 场景2：用于常驻的直接替换 option: true
      - option: true
        mode: append        # <--- 新增候选模式
        comment_mode: none
        tags: [abc]
        prefix: "_ot_"
        files:
          - lua/data/others.txt
      # 场景4：用于简繁转换的直接替换
      - option: [ s2t, s2hk, s2tw ]  #后面依赖这条流水线有一个开关为true这条流水线就能工作
        mode: replace        # <--- 替换原候选模式
        comment_mode: append
        sentence: true        # <--- 句子级别替换
        tags: [abc]
        prefix: "_s2t_"
        files:
          - lua/data/STCharacters.txt
          - lua/data/STPhrases.txt
      - option: s2hk
        mode: replace        # <--- 替换原候选模式
        comment_mode: append
        sentence: true        # <--- 句子级别替换
        tags: [abc]
        prefix: "_s2hk_"
        files:
          - lua/data/HKVariants.txt
          - lua/data/HKVariantsRevPhrases.txt
      - option: s2tw
        mode: replace        # <--- 替换原候选模式
        comment_mode: append
        sentence: true        # <--- 句子级别替换
        tags: [abc]
        prefix: "_s2tw_"
        files:
          - lua/data/TWVariants.txt
          - lua/data/TWVariantsRevPhrases.txt
      - option: [ abbrev_lazy, abbrev_always ]
        mode: abbrev          # <--- 新增的简码模式
        tags: [abc]
        prefix: "_abbr_"
        files:
          - lua/data/abbrev.txt # 格式：zm\t怎么|在吗
]]


local M = {}

-- 性能优化：本地化常用库函数
local insert = table.insert
local concat = table.concat
local s_match = string.match
local s_gmatch = string.gmatch
local s_format = string.format
local s_byte = string.byte
local s_sub = string.sub
local s_gsub = string.gsub
local s_upper = string.upper
local open = io.open
local type = type
local tonumber = tonumber
local fmm_cache = {}
local replacer_instance = nil

-- 基础依赖
local function safe_require(name)
    local status, lib = pcall(require, name)
    if status then return lib end
    return nil
end

local userdb = safe_require("wanxiang/userdb")
local wanxiang = safe_require("wanxiang/wanxiang")

-- UTF-8 辅助
local function get_utf8_offsets(text)
    local offsets = {}
    local len = #text
    local i = 1
    while i <= len do
        insert(offsets, i)
        local b = s_byte(text, i)
        if b < 128 then i = i + 1
        elseif b < 224 then i = i + 2
        elseif b < 240 then i = i + 3
        else i = i + 4 end
    end
    insert(offsets, len + 1)
    return offsets
end
-- 光速文件特征采样（替代耗时的全量哈希计算）
local function generate_files_signature(tasks)
    local sig_parts = {}
    for _, task in ipairs(tasks) do
        local f = open(task.path, "rb")
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
                if tail_pos < 0 then tail_pos = 0 end
                f:seek("set", tail_pos)
                tail = f:read(64) or ""
                
                -- 截取中间 64 字节 (防止同字节数的等长替换)
                local mid_pos = math.floor(size / 2)
                f:seek("set", mid_pos)
                mid = f:read(64) or ""
            end
            f:close()
            
            -- 将 前缀 + 大小 + 头中尾 拼接成该文件的唯一特征码
            insert(sig_parts, task.prefix .. size .. head .. mid .. tail)
        end
    end
    -- 将所有文件的特征码合并
    return concat(sig_parts, "||")
end
-- 重建数据库 (仅在 wanxiang 版本变更时运行)
local function rebuild(tasks, db)
    if db.empty then db:empty() end
    for _, task in ipairs(tasks) do
        local txt_path = task.path
        local prefix = task.prefix
        -- 获取转换表
        local conversion = task.conversion

        local f = open(txt_path, "r")
        if f then
            for line in f:lines() do
                if line ~= "" and not s_match(line, "^%s*#") then
                    local k, v = s_match(line, "^(%S+)%s+(.+)")
                    if k and v then
                        -- [新增] 逻辑：如果有转换表，先进行按键转换
                        -- 使用 gsub 配合 table 进行单字符映射，非常高效且不关注顺序
                        if conversion then
                            k = s_gsub(k, ".", conversion)
                        end
                        
                        -- 转换完成后，再和 prefix 组合
                        v = s_match(v, "^%s*(.-)%s*$")
                        db:update(prefix .. k, v)
                    end
                end
            end
            f:close()
        end
    end
    return true
end

-- 连接或重连数据库 (Singleton Logic)
-- 连接或重连数据库 (融入光速特征校验)
local function connect_db(db_name, current_version, delimiter, tasks)
    if replacer_instance then
        local status, _ = pcall(function() return replacer_instance:fetch("___test___") end)
        if status then return replacer_instance end
        replacer_instance = nil
    end

    if not userdb then return nil end
    local db = userdb.LevelDb(db_name)
    if not db then return nil end

    -- 1. 瞬间计算当前所有物理文件的特征码
    local current_signature = generate_files_signature(tasks)
    
    local needs_rebuild = false
    if db:open_read_only() then
        local db_ver = db:meta_fetch("_wanxiang_ver") or ""
        local db_delim = db:meta_fetch("_delim")
        local db_sig = db:meta_fetch("_files_sig") or ""  -- 读取数据库里存的特征码
        
        -- 核心优雅点：版本变了、分隔符变了、或者文件内容被用户改了，统统触发重建！
        if db_ver ~= current_version or db_delim ~= delimiter or db_sig ~= current_signature then
            needs_rebuild = true
        end
        db:close()
    else
        needs_rebuild = true
    end

    if needs_rebuild then
        if db:open() then
            -- 优雅地清空旧数据，防止体积无意义膨胀
            if db.clear then db:clear() elseif db.empty then db:empty() end
            
            rebuild(tasks, db)
            fmm_cache = {} --只要词库重建，彻底清空旧缓存
            -- 更新最新的烙印
            db:meta_update("_wanxiang_ver", current_version)
            db:meta_update("_delim", delimiter)
            db:meta_update("_files_sig", current_signature) -- 记下当前的文件特征
            
            if log and log.info then
                log.info("super_replacer: 数据已重载，最新特征已记录")
            end
            db:close()
        end
    end

    if db:open_read_only() then
        replacer_instance = db
        return db
    end
    
    return nil
end

-- FMM 分词转换算法
local function segment_convert(text, db, prefix, split_pat)
    local offsets = get_utf8_offsets(text)
    local char_count = #offsets - 1
    local result_parts = {}
    local i = 1
    local MAX_LOOKAHEAD = 6

    while i <= char_count do
        local start_byte = offsets[i]
        local matched = false
        
        local max_j = i + MAX_LOOKAHEAD
        if max_j > char_count + 1 then max_j = char_count + 1 end

        -- 1. 长词 FMM 循环与缓存拦截
        for j = max_j, i + 2, -1 do
            local end_byte = offsets[j] - 1
            local sub_text = s_sub(text, start_byte, end_byte)
            local cache_key = prefix .. sub_text
            
            local val = fmm_cache[cache_key]
            if val == nil then
                local db_res = db:fetch(cache_key)
                fmm_cache[cache_key] = db_res or false
                val = fmm_cache[cache_key]
            end
          
            if val then
                local first_val = s_match(val, split_pat)
                insert(result_parts, first_val or sub_text)
                i = j - 1
                matched = true
                break
            end
        end
      
        -- 2. 单字/单字符兜底（带缓存）
        if not matched then
            local single_char = s_sub(text, start_byte, offsets[i+1] - 1)
            local cache_key = prefix .. single_char
            
            local val = fmm_cache[cache_key]
            if val == nil then
                local db_res = db:fetch(cache_key)
                fmm_cache[cache_key] = db_res or false
                val = fmm_cache[cache_key]
            end
            
            if val then
                local first_val = s_match(val, split_pat)
                insert(result_parts, first_val or single_char)
            else
                insert(result_parts, single_char)
            end
        end
        
        i = i + 1
    end
    return concat(result_parts)
end
-- 模块接口

function M.init(env)
    local ns = env.name_space
    ns = s_gsub(ns, "^%*", "")
    ns = string.match(ns, "([^%.]+)$") or ns
    local config = env.engine.schema.config
  
    local user_dir = rime_api.get_user_data_dir()
    local shared_dir = rime_api.get_shared_data_dir()

    -- 1. 基础配置
    local db_name = config:get_string(ns .. "/db_name") or "lua/replacer"
    local delim = config:get_string(ns .. "/delimiter") or "|"
    env.delimiter = delim
    env.comment_format = config:get_string(ns .. "/comment_format") or "〔%s〕"
  
    -- 获取全局版本号
    local current_version = "v0.0.0"
    if wanxiang and wanxiang.version then
        current_version = wanxiang.version
    end
  
    env.chain = config:get_bool(ns .. "/chain")
    if env.chain == nil then env.chain = false end

    if delim == " " then env.split_pattern = "%S+"
    else local esc = s_gsub(delim, "[%-%.%+%[%]%(%)%$%^%%%?%*]", "%%%1"); env.split_pattern = "([^" .. esc .. "]+)" end

    -- 2. 解析 Types (这部分必须保留在 init，因为不同 schema 可能配置不同)
    env.types = {}
    local tasks = {} -- 用于重建数据库的文件列表

    local function resolve_path(relative)
        if not relative then return nil end
        local user_path = user_dir .. "/" .. relative
        local f = open(user_path, "r")
        if f then f:close(); return user_path end
        local shared_path = shared_dir .. "/" .. relative
        f = open(shared_path, "r")
        if f then f:close(); return shared_path end
        return user_path
    end

    local types_path = ns .. "/types"
    local type_list = config:get_list(types_path)
  
    if type_list then
        for i = 0, type_list.size - 1 do
            local entry_path = types_path .. "/@" .. i
          
            -- 解析 triggers
            local triggers = {}
            local opts_keys = {"option", "options"}
            for _, key in ipairs(opts_keys) do
                local key_path = entry_path .. "/" .. key
                local list = config:get_list(key_path)
                if list then
                    for k = 0, list.size - 1 do
                        local val = config:get_string(key_path .. "/@" .. k)
                        if val then insert(triggers, val) end
                    end
                else
                    if config:get_bool(key_path) == true then
                        insert(triggers, true)
                    else
                        local val = config:get_string(key_path)
                        if val and val ~= "true" then insert(triggers, val) end
                    end
                end
            end

            -- 解析 Tags
            local target_tags = nil
            local tag_keys = {"tag", "tags"}
            for _, key in ipairs(tag_keys) do
                local key_path = entry_path .. "/" .. key
                local list = config:get_list(key_path)
                if list then
                    if not target_tags then target_tags = {} end
                    for k = 0, list.size - 1 do
                        local val = config:get_string(key_path .. "/@" .. k)
                        if val then target_tags[val] = true end
                    end
                else
                    local val = config:get_string(key_path)
                    if val then
                        if not target_tags then target_tags = {} end
                        target_tags[val] = true
                    end
                end
            end

            if #triggers > 0 then
                local prefix = config:get_string(entry_path .. "/prefix") or ""
                local mode = config:get_string(entry_path .. "/mode") or "append"
                
                -- 解析 编码转换conv
                local conversion_map = nil
                local conversion_str = config:get_string(entry_path .. "/conv")
                if conversion_str then
                    -- 分割 "from>to"，例如 "abc>123"
                    local from_str, to_str = s_match(conversion_str, "^(.-)>(.+)$")
                    if from_str and to_str and #from_str == #to_str then
                        conversion_map = {}
                        -- 构建映射表 {a='1', b='2', ...}
                        for char_idx = 1, #from_str do
                            local f_char = s_sub(from_str, char_idx, char_idx)
                            local t_char = s_sub(to_str, char_idx, char_idx)
                            conversion_map[f_char] = t_char
                        end
                    end
                end

                local comment_mode = config:get_string(entry_path .. "/comment_mode")
                if not comment_mode then comment_mode = "comment" end
                local fmm = config:get_bool(entry_path .. "/sentence")
                if fmm == nil then fmm = false end

                insert(env.types, {
                    triggers = triggers,
                    tags = target_tags,
                    prefix = prefix,
                    mode  = mode,
                    comment_mode = comment_mode,
                    fmm = fmm
                })

                -- 收集文件路径 (仅用于可能发生的 rebuild)
                local keys_to_check = {"files", "file"}
                for _, key in ipairs(keys_to_check) do
                    local d_path = entry_path .. "/" .. key
                    local list = config:get_list(d_path)
                    if list then
                        for j = 0, list.size - 1 do
                            local p = resolve_path(config:get_string(d_path .. "/@" .. j))
                            -- 将 conversion_map 传入任务列表
                            if p then insert(tasks, { path = p, prefix = prefix, conversion = conversion_map }) end
                        end
                    else
                        local p = resolve_path(config:get_string(d_path))
                        -- 将 conversion_map 传入任务列表
                        if p then insert(tasks, { path = p, prefix = prefix, conversion = conversion_map }) end
                    end
                end
            end
        end
    end
    -- 3. DB 初始化 (使用单例连接)
    env.db = connect_db(db_name, current_version, env.delimiter, tasks)
end

function M.fini(env)
    -- 我们只是断开当前 env 对全局 db 的引用
    env.db = nil
end

-- [Core Function] 核心逻辑 (保持原有逻辑不变)
function M.func(input, env)
    local ctx = env.engine.context
    local input_code = ctx.input
    local db = env.db
    local types = env.types
    local split_pat = env.split_pattern
    local comment_fmt = env.comment_format
    local is_chain = env.chain
    local HIGH_THRESHOLD = 99
    local input_type = "unknown"
    if not ctx:is_composing() or ctx.input == "" then
        fmm_cache = {}
    end
    -- 如果数据库未连接，直接透传
    if not env.types or #env.types == 0 or not env.db then
        for cand in input:iter() do yield(cand) end
        return
    end

    if wanxiang and wanxiang.get_input_method_type then
        input_type = wanxiang.get_input_method_type(env)
    end

    local seg = ctx.composition:back()
    local current_seg_tags = seg and seg.tags or {}
    
    -- [Helper] 通用处理函数
    local function process_rules(cand)
        local current_text = cand.text
        local show_main = true
        local current_main_comment = cand.comment
      
        local pending_candidates = {}
        local comments = {}
      
        for _, t in ipairs(types) do
            if t.mode ~= "abbrev" then
                local is_active = false
                for _, trigger in ipairs(t.triggers) do
                    if trigger == true then is_active = true; break
                    elseif type(trigger) == "string" and ctx:get_option(trigger) then is_active = true; break end
                end
              
                local is_tag_match = true
                if t.tags then
                    is_tag_match = false
                    for req_tag, _ in pairs(t.tags) do
                        if current_seg_tags[req_tag] then is_tag_match = true; break end
                    end
                end
              
                if is_active and is_tag_match then
                    local query_text = is_chain and current_text or cand.text
                    local key = t.prefix .. query_text
                    local val = db:fetch(key)
                  
                    if not val and t.fmm then
                        local seg_result = segment_convert(query_text, db, t.prefix, split_pat)
                        if seg_result ~= query_text then val = seg_result end
                    end
                  
                    if val then
                        local mode = t.mode
                        local rule_comment = ""
                        if t.comment_mode == "text" then rule_comment = cand.text
                        elseif t.comment_mode == "comment" then rule_comment = cand.comment end

                        if mode == "comment" then
                            local parts = {}
                            for p in s_gmatch(val, split_pat) do insert(parts, p) end
                            insert(comments, concat(parts, " "))
                          
                        elseif mode == "replace" then
                            if is_chain then
                                local first = true
                                for p in s_gmatch(val, split_pat) do
                                    if first then
                                        current_text = p
                                        if t.comment_mode == "none" then current_main_comment = ""
                                        elseif t.comment_mode == "text" then current_main_comment = cand.text end
                                        first = false
                                    else
                                        insert(pending_candidates, { text=p, comment=rule_comment })
                                    end
                                end
                            else
                                show_main = false
                                for p in s_gmatch(val, split_pat) do
                                    insert(pending_candidates, { text=p, comment=rule_comment })
                                end
                            end
                        elseif mode == "append" then
                            for p in s_gmatch(val, split_pat) do
                                insert(pending_candidates, { text=p, comment=rule_comment })
                            end
                        end
                    end
                end
            end
        end

        if #comments > 0 then
            local comment_str = concat(comments, " ")
            local fmt = s_format(comment_fmt, comment_str)
            if cand.comment and cand.comment ~= "" then
                cand.comment = cand.comment .. fmt
            else
                cand.comment = fmt
            end
        end

        if show_main then
            if is_chain and current_text ~= cand.text then
                local nc = Candidate(cand.type or "kv", cand.start, cand._end, current_text, current_main_comment)
                nc.preedit = cand.preedit
                nc.quality = cand.quality
                yield(nc)
            else
                yield(cand)
            end
        end

        for _, item in ipairs(pending_candidates) do
            if not (show_main and item.text == current_text) then
                local nc = Candidate("derived", cand.start, cand._end, item.text, item.comment)
                nc.preedit = cand.preedit
                nc.quality = cand.quality
                yield(nc)
            end
        end
    end

    -- 核心状态变量
    local pending_cands = {}
    local seen_texts = {} -- 去重表
    local limit = 10
    local has_phrase = false
    local cand_count = 0
    local abbrev_triggered = false 

    -- [Helper 1] 规则处理封装
    local function process_and_record(cand)
        seen_texts[cand.text] = true
        process_rules(cand)
    end

    -- [Helper 2] 融合后的简码逻辑
    local function try_trigger_abbrev_logic(is_empty_override, target_quality)
        for _, t in ipairs(types) do
            if t.mode == "abbrev" and input_type ~= "pinyin" then
                local is_tag_match = true
                if t.tags then
                    is_tag_match = false
                    for req_tag, _ in pairs(t.tags) do
                        if current_seg_tags[req_tag] then is_tag_match = true; break end
                    end
                end

                if is_tag_match then
                    local lazy_switch = t.triggers[1]
                    local always_switch = t.triggers[2]
                    local active_mode = "none"

                    if always_switch then
                        if always_switch == true or (type(always_switch) == "string" and ctx:get_option(always_switch)) then
                            active_mode = "always"
                        end
                    end
                    if active_mode == "none" and lazy_switch then
                        if lazy_switch == true or (type(lazy_switch) == "string" and ctx:get_option(lazy_switch)) then
                            active_mode = "lazy"
                        end
                    end

                    local should_trigger = false
                    if active_mode == "always" then should_trigger = true
                    elseif active_mode == "lazy" and is_empty_override then should_trigger = true
                    end

                    if should_trigger then
                        local key = t.prefix .. input_code
                        local val = db:fetch(key)
                        if not val and not s_match(input_code, "[A-Z]") then
                            val = db:fetch(t.prefix .. s_upper(input_code))
                        end
                        
                        if val then
                            for p in s_gmatch(val, split_pat) do
                                if not seen_texts[p] then
                                    local abbrev_cand = Candidate("abbrev", 0, #input_code, p, "")
                                    abbrev_cand.quality = target_quality
                                    process_and_record(abbrev_cand)
                                end
                            end
                        end
                    end
                end
            end
        end
        abbrev_triggered = true
    end

    -- [主循环]
    for cand in input:iter() do
        cand_count = cand_count + 1
        local q = cand.quality or 0
        
        if cand.type == "phrase" then has_phrase = true end
        
        -- 1. [权重跳水/插队检测]
        if not abbrev_triggered and q < HIGH_THRESHOLD and #pending_cands > 0 then
            local max_q = 0
            local has_high_q = false
            for _, pc in ipairs(pending_cands) do 
                local pq = pc.quality or 0
                if pq > max_q then max_q = pq end
                if pq > HIGH_THRESHOLD then has_high_q = true end
            end
            
            if has_high_q then
                for _, pc in ipairs(pending_cands) do process_and_record(pc) end
                pending_cands = {}
                if not has_phrase then
                    try_trigger_abbrev_logic(true, max_q - 0.001)
                end
            end
        end

        -- 2. [基础缓存逻辑]
        if cand_count <= limit then
            table.insert(pending_cands, cand)
        else
            if cand_count == limit + 1 then
                local has_high_q = false
                for _, pc in ipairs(pending_cands) do 
                    if (pc.quality or 0) > HIGH_THRESHOLD then 
                        has_high_q = true 
                        break
                    end
                end
                
                if not abbrev_triggered then
                    try_trigger_abbrev_logic(not has_phrase, has_high_q and 99 or 9999) 
                end
                for _, pc in ipairs(pending_cands) do process_and_record(pc) end
                pending_cands = nil
            end
            process_and_record(cand)
        end
    end

    -- 3. [收尾阶段]
    if pending_cands then
        if not abbrev_triggered then
            local max_q = 0
            local has_high_q = false
            for _, pc in ipairs(pending_cands) do 
                local pq = pc.quality or 0
                if pq > max_q then max_q = pq end
                if pq > HIGH_THRESHOLD then has_high_q = true end
            end

            if has_high_q then
                for _, pc in ipairs(pending_cands) do process_and_record(pc) end
                if not has_phrase then
                    try_trigger_abbrev_logic(true, max_q - 0.001)
                end
            else
                if not has_phrase then
                    try_trigger_abbrev_logic(true, 9999)
                end
                for _, pc in ipairs(pending_cands) do process_and_record(pc) end
            end
            pending_cands = nil
        end

        if pending_cands then
            for _, pc in ipairs(pending_cands) do process_and_record(pc) end
        end
    end
end
return M