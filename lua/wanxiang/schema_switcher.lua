---Provides a utility to dynamically switch the active Pinyin schema by rewriting the configuration file with the
---selected schema rules.
---@author amzxyz
---@author Fidel Yin <fidel.yin@hotmail.com>

local utils = require("utils.utils")

local PINYIN_SCHEMAS = {
    ["/pinyin"] = "全拼",
    ["/zrm"] = "自然码",
    ["/znabc"] = "智能ABC",
    ["/flypy"] = "小鹤双拼",
    ["/mspy"] = "微软双拼",
    ["/sogou"] = "搜狗双拼",
    ["/ziguang"] = "紫光双拼",
    ["/gbpy"] = "国标双拼",
    ["/pyjj"] = "拼音加加",
    ["/lxsq"] = "乱序17",
    ["/ltsp"] = "蓝天双拼",
    ["/dnsp"] = "大牛双拼",
    ["/sdpy"] = "首道双拼",
    ["/zrlong"] = "自然龙",
    ["/hxlong"] = "汉心龙",
}

local AUX_SCHEMAS = {
    ["/zjf"] = "直接辅助",
    ["/jjf"] = "间接辅助",
}

---Copies a file from `src` to `dest`, returning whether the copy succeeded.
---@param src string
---@param dest string
---@return boolean
local function copy_file(src, dest)
    local fi = io.open(src, "rb")
    if not fi then
        return false
    end
    local content = fi:read("*a")
    fi:close()

    local fo = io.open(dest, "wb")
    if not fo then
        return false
    end
    fo:write(content)
    fo:close()
    return true
end

---Ensures a custom file exists in the user data directory, copying its template
---from the user `custom` directory when missing.
---@param user_dir string
---@param custom_file_name string
---@return boolean ok true if the destination file exists after this call
local function ensure_custom_file(user_dir, custom_file_name)
    local dest = user_dir .. "/" .. custom_file_name
    if utils.file_exists(dest) then
        return true
    end

    local src = user_dir .. "/custom/" .. custom_file_name
    if not utils.file_exists(src) then
        log.warning("Template custom file not found: " .. src)
        return false
    end

    return copy_file(src, dest)
end

---Reads `custom_file`, applies `transform` to its content, and writes the result
---back. The write is skipped when `transform` returns `nil`.
---@param custom_file string
---@param transform fun(content: string): string?
---@return boolean ok true if the file was successfully updated
local function update_custom_file(custom_file, transform)
    local f = io.open(custom_file, "r")
    if not f then
        return false
    end
    local content = f:read("*a")
    f:close()

    local new_content = transform(content)
    if not new_content then
        return false
    end

    f = io.open(custom_file, "w")
    if not f then
        return false
    end
    f:write(new_content)
    f:close()
    return true
end

---Rewrites the pinyin algebra reference in a custom file to the given schema.
---@param user_dir string
---@param custom_file_name string
---@param schema_name string
---@return boolean ok true if a substitution was made and written
local function set_pinyin_schema(user_dir, custom_file_name, schema_name)
    return update_custom_file(user_dir .. "/" .. custom_file_name, function(content)
        local matched = false
        content = content:gsub("(%s*%-%s*wanxiang_algebra:/%a+/)(%S+)", function(parent, name)
            -- Replace only known pinyin schema references, preserving other entries.
            for _, pinyin_name in pairs(PINYIN_SCHEMAS) do
                if name == pinyin_name then
                    matched = true
                    return parent .. schema_name
                end
            end
            return parent .. name
        end)

        if not matched then
            return nil
        end
        return content
    end)
end

---Rewrites the auxiliary code algebra reference in a custom file to the given
---schema, replacing both direct and indirect aux entries.
---@param custom_file string
---@param schema_name string
---@return boolean ok true if a substitution was made and written
local function set_aux_schema(custom_file, schema_name)
    return update_custom_file(custom_file, function(content)
        local n1, n2
        content, n1 = content:gsub("(%-+%s*wanxiang_algebra:/pro/)直接辅助(%s*#?.*)", "%1" .. schema_name .. "%2")
        content, n2 = content:gsub("(%-+%s*wanxiang_algebra:/pro/)间接辅助(%s*#?.*)", "%1" .. schema_name .. "%2")

        if n1 + n2 == 0 then
            return nil
        end
        return content
    end)
end

---Rime translator that handles `/`-prefixed schema-switch commands by
---rewriting the relevant `*.custom.yaml` files and yielding a status candidate.
---@param input string
---@param seg Segment
---@param env Env
local function translator(input, seg, env)
    if input:sub(1, 1) ~= "/" then
        return
    end

    local target_aux_schema = AUX_SCHEMAS[input]
    local target_pinyin_schema = PINYIN_SCHEMAS[input]
    if not target_aux_schema and not target_pinyin_schema then
        return
    end

    local user_dir = rime_api.get_user_data_dir()

    -- Check existing main custom file
    local main_custom_file = env.engine.schema.schema_id .. ".custom.yaml"
    local main_custom_file_path = user_dir .. "/" .. main_custom_file
    local main_custom_file_exists = utils.file_exists(main_custom_file_path)

    if target_aux_schema then
        if not ensure_custom_file(user_dir, main_custom_file) then
            yield(Candidate("message", seg.start, seg._end, "〔警告〕未找到模板配置文件。", ""))
            return
        end

        local success = set_aux_schema(main_custom_file_path, target_aux_schema)

        ---@type string
        local msg
        if success then
            msg = main_custom_file_exists
                    and ("已切换至〔" .. target_aux_schema .. "〕方案，请重新部署。")
                or ("已创建新配置并切换至〔" .. target_aux_schema .. "〕方案，请重新部署。")
        else
            msg = "〔警告〕未找到可切换的条目。"
        end
        yield(Candidate("message", seg.start, seg._end, msg, ""))
        return
    end

    if target_pinyin_schema then
        local custom_files = {
            main_custom_file,
            "wanxiang_reverse.custom.yaml",
        }

        ---@type string[]
        local missing = {}
        local missing_len = 0
        ---@type string[]
        local unmatched = {}
        local unmatched_len = 0
        for _, custom_file_name in ipairs(custom_files) do
            if not ensure_custom_file(user_dir, custom_file_name) then
                missing_len = missing_len + 1
                missing[missing_len] = custom_file_name
            elseif not set_pinyin_schema(user_dir, custom_file_name, target_pinyin_schema) then
                unmatched_len = unmatched_len + 1
                unmatched[unmatched_len] = custom_file_name
            end
        end

        ---@type string[]
        local messages = {}
        local messages_len = 0
        if #missing > 0 then
            messages_len = messages_len + 1
            messages[messages_len] = "〔警告〕未找到以下模板配置文件：\n" .. table.concat(missing, "\n")
        end
        if #unmatched > 0 then
            messages_len = messages_len + 1
            messages[messages_len] = "〔警告〕在以下配置文件中未找到可切换的条目：\n"
                .. table.concat(unmatched, "\n")
        end

        if main_custom_file_exists then
            messages_len = messages_len + 1
            messages[messages_len] = (
                "检测到已有配置，已切换至〔"
                .. target_pinyin_schema
                .. "〕方案，请手动重新部署。"
            )
        else
            messages_len = messages_len + 1
            messages[messages_len] = (
                "已创建新配置并切换至〔"
                .. target_pinyin_schema
                .. "〕方案，请手动重新部署。"
            )
        end

        local msg = table.concat(messages, "\n")
        yield(Candidate("message", seg.start, seg._end, msg, ""))
    end
end

return translator
