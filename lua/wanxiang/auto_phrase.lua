-- @amzxyz https://github.com/amzxyz/rime_wanxiang
-- 自动造词

---@class AutoPhraseConfig
---@field escaped_delimiter string

---@class AutoPhraseState
---@field zh_memory Memory?
---@field en_memory Memory?
---@field comment_cache table<string, string> -- 注释缓存：text -> comment (for chinese only)
---
---@field commit_conn Connection?
---@field delete_conn Connection?

---@class Env
---@field auto_phrase_config AutoPhraseConfig?
---@field auto_phrase_state AutoPhraseState?

---Test if the text is a non-empty ASCII word
---@param text string
---@return boolean
local function is_ascii_word(text)
    if text == "" then
        return false
    end

    local has_alpha = false
    for i = 1, #text do
        local b = text:byte(i)
        if b > 127 then
            return false
        end
        if (b >= 65 and b <= 90) or (b >= 97 and b <= 122) then
            has_alpha = true
        end
    end
    return has_alpha
end

local M = {}

---判断字符是否为汉字
---@param text string
---@return boolean
local function is_chinese_only(text)
    if text == "" then
        return false
    end

    -- Check for presence of any ASCII letters or punctuation
    if text:match("[%w%p]") then
        return false
    end

    for _, cp in utf8.codes(text) do
        -- 常用汉字区 + 扩展 A/B/C/D/E/F/G
        if
            not (
                (cp >= 0x4E00 and cp <= 0x9FFF) -- CJK Unified Ideographs
                or (cp >= 0x3400 and cp <= 0x4DBF) -- CJK Ext-A
                or (cp >= 0x20000 and cp <= 0x2EBEF) -- CJK Ext-B~G
            )
        then
            return false
        end
    end

    return true
end

---@param cand Candidate
---@param genuine Candidate
---@param state AutoPhraseState
local function save_comment_cache(cand, genuine, state)
    local text = cand.text
    local comment = genuine.comment

    if text ~= "" and comment ~= "" then
        state.comment_cache[text] = comment
    end
end

---@param env Env
function M.init(env)
    local config = env.engine.schema.config
    local ctx = env.engine.context

    local delimiter = config:get_string("speller/delimiter") or " '"
    local escaped_delimiter = utf8.char(utf8.codepoint(delimiter)):gsub("(%W)", "%%%1")

    -- 中文自动造词的开关（只控制 add_user_dict）
    local enable_auto_phrase = config:get_bool("add_user_dict/enable_auto_phrase") or false
    local enable_user_dict = config:get_bool("add_user_dict/enable_user_dict") or false

    -- 中文：add_user_dict（受 add_* 开关影响）
    local zh_memory = (enable_auto_phrase and enable_user_dict)
            and Memory(env.engine, env.engine.schema, "add_user_dict")
        or nil

    -- 英文：enuser（不受 add_* 开关影响，始终尝试启用）
    local en_memory = Memory(env.engine, env.engine.schema, "wanxiang_english")

    ---@type Connection?
    local commit_conn = nil
    ---@type Connection?
    local delete_conn = nil
    if zh_memory or en_memory then
        -- 只要有一边需要，就挂上 commit/delete 通知
        commit_conn = ctx.commit_notifier:connect(function(c)
            M.commit_handler(c, env)
        end)
        delete_conn = ctx.delete_notifier:connect(function(_)
            local state = env.auto_phrase_state
            assert(state)

            state.comment_cache = {}
        end)
    end

    env.auto_phrase_config = {
        escaped_delimiter = escaped_delimiter,
    }

    env.auto_phrase_state = {
        zh_memory = zh_memory,
        en_memory = en_memory,
        comment_cache = {},
        commit_conn = commit_conn,
        delete_conn = delete_conn,
    }
end

---@param env Env
function M.fini(env)
    if env.auto_phrase_state.commit_conn then
        env.auto_phrase_state.commit_conn:disconnect()
    end
    if env.auto_phrase_state.delete_conn then
        env.auto_phrase_state.delete_conn:disconnect()
    end
    env.auto_phrase_state = nil
end

---@param input Translation
---@param env Env
function M.func(input, env)
    local state = env.auto_phrase_state
    assert(state)

    local use_comment_cache = state.zh_memory ~= nil -- 只有中文造词才需要缓存注释

    for cand in input:iter() do
        local genuine_cand = cand:get_genuine()

        if use_comment_cache then
            save_comment_cache(cand, genuine_cand, state)
        end

        yield(cand)
    end
end

-- 造词
---@param ctx Context
---@param env Env
function M.commit_handler(ctx, env)
    local config = env.auto_phrase_config
    assert(config)
    local state = env.auto_phrase_state
    assert(state)

    local segments = ctx.composition:toSegmentation():get_segments()
    local segments_count = #segments
    local commit_text = ctx:get_commit_text() or ""
    local raw_input = ctx.input or ""

    ---------------------------------------------------
    -- ① 英文造词（保持原样，仍用硬编码 "\"）
    ---------------------------------------------------
    if raw_input ~= "" and raw_input:sub(-1) == "\\" and is_ascii_word(commit_text) then
        local code_body = raw_input:gsub("\\+$", "")
        code_body = code_body:gsub("%s+$", "")

        if code_body ~= "" and state.en_memory then
            local function save_entry(code)
                local entry = DictEntry()
                entry.text = commit_text
                entry.weight = 1
                entry.custom_code = code .. " "
                state.en_memory:update_userdict(entry, 1, "")
            end

            save_entry(code_body)
            local lower_code = code_body:lower()
            if lower_code ~= code_body then
                save_entry(lower_code)
            end
        end

        state.comment_cache = {}
        return
    end

    ---------------------------------------------------
    -- ② 中文自动造词
    ---------------------------------------------------
    if not state.zh_memory then
        state.comment_cache = {}
        return
    end

    -- 基础检查
    if segments_count <= 1 or utf8.len(commit_text) <= 1 then
        state.comment_cache = {}
        return
    end
    if not is_chinese_only(commit_text) or state.comment_cache[commit_text] then
        state.comment_cache = {}
        return
    end

    ---@type string[]
    local codes = {}

    for i = 1, segments_count do
        local seg = segments[i]
        local cand = seg:get_selected_candidate()

        -- 无候选：可能是符号段
        if not cand then
            if i == segments_count then
                -- 最后一个 segment 无候选，允许跳过
                goto continue
            else
                state.comment_cache = {}
                return
            end
        end

        -- 从缓存中取出该候选的注释（编码）
        local comment = state.comment_cache[cand.text]

        -- 有候选但无编码
        if not comment or comment == "" then
            if i == segments_count then
                -- 最后一个 segment 无编码，允许跳过
                goto continue
            else
                state.comment_cache = {}
                return
            end
        end

        -- 有编码，分割加入
        for part in comment:gmatch("[^" .. config.escaped_delimiter .. "]+") do
            table.insert(codes, part)
        end

        ::continue::
    end

    -- 最终至少需要一个编码片段
    if #codes == 0 then
        state.comment_cache = {}
        return
    end

    -- 检查编码片段数量是否与 commit_text 的字数一致
    local total_chars = utf8.len(commit_text)
    if #codes ~= total_chars then
        state.comment_cache = {}
        return
    end

    local dictEntry = DictEntry()
    dictEntry.text = commit_text
    dictEntry.weight = 1
    dictEntry.custom_code = table.concat(codes, " ") .. " "
    state.zh_memory:update_userdict(dictEntry, 1, "")

    if raw_input == "" then
        state.comment_cache = {}
    end
end

return M
