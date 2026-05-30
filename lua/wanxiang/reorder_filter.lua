---Reorders candidates to prioritize non-English table/user_table/fixed entries
---within a page-aware sort window. Active only when the input code length is
---between 2 and 6 inclusive. The first candidate always passes through
---unchanged; if the second candidate is already a table-type entry, no
---reordering occurs (passthrough mode).
---@author amzxyz
---@author Fidel Yin <fidel.yin@hotmail.com>

local wanxiang = require("wanxiang.wanxiang")

-- Maximum number of candidates to buffer for grouping before flushing.
local SORT_WINDOW = 30

local M = {}

---Reorder candidates by grouping non-English table/user_table/fixed entries
---before others, using a page-aware flush strategy. When code length is
---outside 2-6 or the second candidate is already table-type, all candidates
---pass through in their original order.
---@param translation Translation
---@param env Env
function M.func(translation, env)
    local context = env.engine.context

    local code = context.input
    local comp = context.composition

    -- Empty context: pass through all candidates unchanged.
    if code == "" or comp:empty() then
        for cand in translation:iter() do
            yield(cand)
        end
        return
    end

    local code_len = #code

    -- Outside the active range (2-6): pass through without reordering.
    if code_len < 2 or code_len > 6 then
        for cand in translation:iter() do
            yield(cand)
        end
        return
    end

    -- Grouping mode: buffer candidates and yield in grouped order.
    local page_size = env.engine.schema.page_size
    local visual_idx = 0

    ---@type Candidate[] -- non-English table/user_table/fixed entries
    local special_buf = {}
    local special_buf_len = 0
    ---@type Candidate[] -- all other entries
    local normal_buf = {}
    local normal_buf_len = 0

    ---Yield a single candidate and increment the visual index.
    ---@param cand Candidate
    local function emit(cand)
        yield(cand)
        visual_idx = visual_idx + 1
    end

    ---Page-aware flush: emit buffered candidates respecting page boundaries.
    ---On the first page, normal (non-table) entries fill positions first so
    ---that table entries land near the page boundary; from the second page
    ---onward (or at the last slot of the first page), special entries are
    ---preferred. When force_all is true, drain both buffers completely.
    ---@param force_all boolean
    local function try_flush_page_sort(force_all)
        while true do
            local next_pos = visual_idx + 1
            local current_idx_in_page = ((next_pos - 1) % page_size) + 1
            local is_second_page = (visual_idx >= page_size)

            -- Allow special (table-type) entries at the last slot of the
            -- first page or anywhere on subsequent pages.
            local allow_special = is_second_page or (current_idx_in_page >= page_size)

            local cand_to_emit = nil
            if force_all then
                if allow_special then
                    if special_buf_len > 0 then
                        cand_to_emit = table.remove(special_buf, 1)
                        special_buf_len = special_buf_len - 1
                    elseif normal_buf_len > 0 then
                        cand_to_emit = table.remove(normal_buf, 1)
                        normal_buf_len = normal_buf_len - 1
                    end
                else
                    if normal_buf_len > 0 then
                        cand_to_emit = table.remove(normal_buf, 1)
                        normal_buf_len = normal_buf_len - 1
                    elseif special_buf_len > 0 then
                        cand_to_emit = table.remove(special_buf, 1)
                        special_buf_len = special_buf_len - 1
                    end
                end
                if not cand_to_emit then
                    break
                end
            else
                if allow_special then
                    if special_buf_len > 0 then
                        cand_to_emit = table.remove(special_buf, 1)
                        special_buf_len = special_buf_len - 1
                    else
                        -- Only flush normal entries when the buffer exceeds
                        -- the sort window, to leave room for late-arriving
                        -- special entries.
                        if normal_buf_len > SORT_WINDOW then
                            cand_to_emit = table.remove(normal_buf, 1)
                            normal_buf_len = normal_buf_len - 1
                        else
                            break
                        end
                    end
                else
                    if normal_buf_len > 0 then
                        cand_to_emit = table.remove(normal_buf, 1)
                        normal_buf_len = normal_buf_len - 1
                    else
                        break
                    end
                end
            end

            emit(cand_to_emit)
        end
    end

    local idx = 0
    ---@type "unknown"|"passthrough"|"grouping"
    local mode = "unknown"

    for cand in translation:iter() do
        idx = idx + 1

        if idx == 1 then
            -- First candidate always passes through unchanged.
            emit(cand)
        elseif idx == 2 and mode == "unknown" then
            -- Decide mode based on the second candidate's type.
            if wanxiang.is_table_type_candidate(cand) then
                -- Second candidate is table-type: no reordering needed.
                mode = "passthrough"
                emit(cand)
            else
                -- Second candidate is not table-type: enter grouping mode.
                mode = "grouping"
                normal_buf_len = normal_buf_len + 1
                normal_buf[normal_buf_len] = cand
                try_flush_page_sort(false)
            end
        elseif mode == "passthrough" then
            emit(cand)
        else
            -- Grouping mode: classify and buffer the candidate.
            if wanxiang.is_table_type_candidate(cand) and not wanxiang.has_ascii_letter(cand.text) then
                special_buf_len = special_buf_len + 1
                special_buf[special_buf_len] = cand
            else
                normal_buf_len = normal_buf_len + 1
                normal_buf[normal_buf_len] = cand
            end
            try_flush_page_sort(false)
        end
    end

    -- Drain remaining buffered candidates.
    if mode == "grouping" then
        try_flush_page_sort(true)
    end
end

return M
