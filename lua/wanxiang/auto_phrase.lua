-- @amzxyz https://github.com/amzxyz/rime_wanxiang
-- 自动造词

---@class AutoPhraseConfig
---@field escaped_delimiter string

---@class AutoPhraseState
---@field zh_memory Memory?
---@field en_memory Memory?
---注释缓存：text -> comment (for chinese only)
---Invariant: no empty string.
---@field comment_cache table<string, string>
---
---@field commit_conn Connection?
---@field delete_conn Connection?

---@class Env
---@field auto_phrase_config AutoPhraseConfig?
---@field auto_phrase_state AutoPhraseState?

local wanxiang = require("wanxiang.wanxiang")

---Return if the text is a non-empty ASCII word.
---@param text string
---@return boolean
local function is_english_phrase(text)
    -- consists of ASCII characters & contains at least one letter
    return text:match("^[%z\1-\127]+$") and text:match("[A-Za-z]") ~= nil
end

---@param text string
---@return boolean
local function is_chinese_phrase(text)
    if text == "" then
        return false
    end

    for _, cp in utf8.codes(text) do
        -- Reject ASCII (covers letters, digits, punctuation)
        if cp <= 127 then
            return false
        end
        if not wanxiang.is_chinese_codepoint(cp) then
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

-- 造词
---@param ctx Context
---@param env Env
local function commit_handler(ctx, env)
    local config = env.auto_phrase_config
    assert(config)
    local state = env.auto_phrase_state
    assert(state)

    local segments = ctx.composition:toSegmentation():get_segments()
    local segments_count = #segments
    local commit_text = ctx:get_commit_text()
    local raw_input = ctx.input

    ---------------------------------------------------
    -- ① 英文造词（保持原样，仍用硬编码 "\"）
    ---------------------------------------------------
    if raw_input ~= "" and raw_input:sub(-1) == "\\" and is_english_phrase(commit_text) then
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
    if not is_chinese_phrase(commit_text) or state.comment_cache[commit_text] then
        state.comment_cache = {}
        return
    end

    ---@type string[]
    local codes = {}

    -- 遍历所有词段收集编码
    for i = 1, segments_count do
        local seg = segments[i]
        local cand = seg:get_selected_candidate()

        if not cand then
            state.comment_cache = {}
            return
        end

        local comment = state.comment_cache[cand.text]
        if not comment or comment == "" then
            state.comment_cache = {}
            return
        end

        -- 有编码，分割加入
        for part in comment:gmatch("[^" .. config.escaped_delimiter .. "]+") do
            table.insert(codes, part)
        end
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

    -- 写入用户词典
    local dictEntry = DictEntry()
    dictEntry.text = commit_text
    dictEntry.weight = 1
    dictEntry.custom_code = table.concat(codes, " ") .. " "
    state.zh_memory:update_userdict(dictEntry, 1, "")

    if raw_input == "" then
        state.comment_cache = {}
    end
end

local F = {}

---@param env Env
function F.init(env)
    local rime_config = env.engine.schema.config
    local context = env.engine.context

    local delimiter = rime_config:get_string("speller/delimiter") or " '"
    local escaped_delimiter = delimiter:gsub("(%W)", "%%%1")

    -- 中文自动造词的开关（只控制 add_user_dict）
    local auto_phrase_enabled = rime_config:get_bool("add_user_dict/enable_auto_phrase") or false
    local user_dict_enabled = rime_config:get_bool("add_user_dict/enable_user_dict") or false

    -- 中文：add_user_dict（受 add_* 开关影响）
    local zh_memory = (auto_phrase_enabled and user_dict_enabled)
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
        commit_conn = context.commit_notifier:connect(function(ctx)
            commit_handler(ctx, env)
        end)
        delete_conn = context.delete_notifier:connect(function(_)
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
function F.fini(env)
    if env.auto_phrase_state.zh_memory then
        env.auto_phrase_state.zh_memory:disconnect()
    end
    if env.auto_phrase_state.en_memory then
        env.auto_phrase_state.en_memory:disconnect()
    end

    if env.auto_phrase_state.commit_conn then
        env.auto_phrase_state.commit_conn:disconnect()
    end
    if env.auto_phrase_state.delete_conn then
        env.auto_phrase_state.delete_conn:disconnect()
    end
    env.auto_phrase_config = nil
    env.auto_phrase_state = nil
end

---@param input Translation
---@param env Env
function F.func(input, env)
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

return F
