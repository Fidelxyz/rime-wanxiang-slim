---Provides a utility to dynamically switch the active Pinyin schema by rewriting the configuration file with the
---selected schema rules.
---@author amzxyz
---@author Fidel Yin <fidel.yin@hotmail.com>

---@class SchemaSwitcherConfig
---@field enabled boolean

---@diagnostic disable-next-line: duplicate-type
---@class Env
---@field schema_switcher_config SchemaSwitcherConfig?

local file = require("utils.file")

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

---Ensures a custom file exists in the user data directory, copying its template
---from the user `custom` directory when missing.
---@param user_dir string
---@param custom_file_name string
---@return boolean ok true if the destination file exists after this call
local function ensure_custom_file(user_dir, custom_file_name)
    local dest = user_dir .. "/" .. custom_file_name
    if file.file_exists(dest) then
        return true
    end

    local src = user_dir .. "/custom/" .. custom_file_name
    if not file.file_exists(src) then
        log.warning(("schema_switcher: template custom file not found or unreadable: %s"):format(src))
        return false
    end

    local copied, err = file.copy_file(src, dest)
    if not copied then
        log.error(("schema_switcher: %s"):format(err))
    end
    return copied
end

---Reads `custom_file`, applies `transform` to its content, and writes the result
---back. The write is skipped when `transform` returns `nil`.
---@param custom_file string
---@param transform fun(content: string): string?
---@return boolean ok true if the file was successfully updated
local function update_custom_file(custom_file, transform)
    local content, read_err = file.read_file(custom_file)
    if not content then
        log.error(("schema_switcher: %s"):format(read_err))
        return false
    end

    local new_content = transform(content)
    if not new_content then
        log.warning(("schema_switcher: no matching algebra entry in %s"):format(custom_file))
        return false
    end

    local written, write_err = file.write_file(custom_file, new_content)
    if not written then
        log.error(("schema_switcher: %s"):format(write_err))
    end
    return written
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

local T = {}

---@param env Env
function T.init(env)
    local rime_config = env.engine.schema.config
    assert(rime_config)

    env.schema_switcher_config = {
        enabled = rime_config:get_bool("command/enabled") == true,
    }
end

---@param env Env
function T.fini(env)
    env.schema_switcher_config = nil
end

---Rime translator that handles `/`-prefixed schema-switch commands by
---rewriting the relevant `*.custom.yaml` files and yielding a status candidate.
---@param input string
---@param seg Segment
---@param env Env
function T.func(input, seg, env)
    local config = env.schema_switcher_config
    assert(config)
    if not config.enabled then
        return
    end

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

    if target_aux_schema then
        if not ensure_custom_file(user_dir, main_custom_file) then
            local message = "〔警告〕无法准备配置文件，请检查模板及文件读写权限。"
            yield(Candidate("message", seg.start, seg._end, message, ""))
            return
        end

        local success = set_aux_schema(main_custom_file_path, target_aux_schema)

        ---@type string
        local message
        if success then
            message = ("已切换至〔%s〕方案，请重新部署。"):format(target_aux_schema)
        else
            message = "〔警告〕未能切换，请检查配置条目及文件读写权限。"
        end
        yield(Candidate("message", seg.start, seg._end, message, ""))
        return
    end

    if target_pinyin_schema then
        local custom_files = {
            main_custom_file,
            "wanxiang_reverse.custom.yaml",
        }

        ---@type string[]
        local failed = {}
        for _, custom_file_name in ipairs(custom_files) do
            local success = ensure_custom_file(user_dir, custom_file_name)
                and set_pinyin_schema(user_dir, custom_file_name, target_pinyin_schema)
            if not success then
                failed[#failed + 1] = custom_file_name
            end
        end

        ---@type string[]
        local messages = {}
        if #failed > 0 then
            messages[#messages + 1] = "〔警告〕以下文件未能切换，请检查模板、配置条目及文件读写权限：\n"
                .. table.concat(failed, "\n")
        end
        messages[#messages + 1] = ("已切换至〔%s〕方案，请重新部署。"):format(target_pinyin_schema)

        local message = table.concat(messages, "\n")
        yield(Candidate("message", seg.start, seg._end, message, ""))
    end
end

return T
