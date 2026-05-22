---Drops sentence-type derivation candidates when the first candidate is a
---long English word from the table/user_table/fixed source. This keeps the
---candidate list clean during mixed Chinese-English input.
---@author amzxyz
---@author Fidel Yin <fidel.yin@hotmail.com>

local wanxiang = require("wanxiang.wanxiang")

local M = {}

---When the first candidate is a table-type entry with 4+ characters containing
---English letters, drop all subsequent sentence-type candidates. This prevents
---irrelevant sentence derivations from cluttering the candidate list when the
---user is clearly typing an English word.
---@param translation Translation
function M.func(translation, _)
    local drop_sentence = false

    for cand in translation:iter() do
        if not drop_sentence then
            -- First candidate: decide whether to activate sentence dropping.
            local text = cand.text
            if wanxiang.is_table_type_candidate(cand) and #text >= 4 and wanxiang.has_ascii_letter(text) then
                drop_sentence = true
            end
            yield(cand)
        elseif cand.type ~= "sentence" then
            yield(cand)
        end
        -- else: drop sentence-type candidates suppressed by an English first candidate.
    end
end

return M
