---Provides a utility to dynamically switch the active Pinyin schema by rewriting the configuration file with the selected schema rules.
---@module "wanxiang.set_schema"
---@author amzxyz
---@author Fidel Yin <fidel.yin@hotmail.com>

local wanxiang = require("wanxiang.wanxiang")

local SCHEMA_MAP = {
    ["/flypy"] = "小鹤双拼",
    ["/mspy"] = "微软双拼",
    ["/zrm"] = "自然码",
    ["/sogou"] = "搜狗双拼",
    ["/znabc"] = "智能ABC",
    ["/ziguang"] = "紫光双拼",
    ["/pyjj"] = "拼音加加",
    ["/gbpy"] = "国标双拼",
    ["/lxsq"] = "乱序17",
    ["/zrlong"] = "自然龙",
    ["/hxlong"] = "汉心龙",
    ["/pinyin"] = "全拼",
}

---@param src string
---@param dest string
---@return boolean
local function copy_file(src, dest)
    local fi = io.open(src, "r")
    if not fi then
        return false
    end
    local content = fi:read("*a")
    fi:close()

    local fo = io.open(dest, "w")
    if not fo then
        return false
    end
    fo:write(content)
    fo:close()
    return true
end

---@param custom_file string
---@param schema_name string
---@return boolean
local function set_pinyin_schema(custom_file, schema_name)
    local f = io.open(custom_file, "r")
    if not f then
        return false
    end
    ---@type string
    local content = f:read("*a")
    f:close()

    local function new_schema_name(name)
        if name == "直接辅助" or name == "间接辅助" then
            return name
        end
        return schema_name
    end

    -- 根据文件名决定替换模式
    if custom_file:find("wanxiang_reverse") then
        content = content:gsub("(%s*__include:%s*wanxiang_algebra:/reverse/)%S+", "%1" .. schema_name)
    elseif custom_file:find("wanxiang_mixedcode") then
        content = content:gsub("(%s*__patch:%s*wanxiang_algebra:/mixed/)%S+", "%1" .. schema_name)
    elseif custom_file:find("wanxiang_english") then
        content = content:gsub("(%s*__patch:%s*wanxiang_algebra:/english/)%S+", "%1" .. schema_name)
    elseif custom_file:find("wanxiang%.custom") then
        content = content:gsub("(%s*%-%s*wanxiang_algebra:/base/)(%S+)", function(prefix, suffix)
            return prefix .. new_schema_name(suffix)
        end)
    elseif custom_file:find("wanxiang_pro%.custom") then
        content = content:gsub("(%s*%-%s*wanxiang_algebra:/pro/)(%S+)", function(prefix, suffix)
            return prefix .. new_schema_name(suffix)
        end)
    end

    f = io.open(custom_file, "w")
    if not f then
        return false
    end
    f:write(content)
    f:close()
    return true
end

---@param custom_file string
---@param schema_name string
---@return boolean
local function set_aux_schema(custom_file, schema_name)
    local f = io.open(custom_file, "r")
    if not f then
        return false
    end

    ---@type string
    local content = f:read("*a")
    f:close()

    local n1 = 0
    local n2 = 0
    content, n1 = content:gsub("(%-+%s*wanxiang_algebra:/pro/)直接辅助(%s*#?.*)", "%1" .. schema_name .. "%2")
    content, n2 = content:gsub("(%-+%s*wanxiang_algebra:/pro/)间接辅助(%s*#?.*)", "%1" .. schema_name .. "%2")
    local n = n1 + n2

    if n == 0 then
        return false
    end

    local w = io.open(custom_file, "w")
    if not w then
        return false
    end

    w:write(content)
    w:close()
    return true
end

---translator 主函数
---@param input string
---@param seg Segment
---@param env Env
local function translator(input, seg, env)
    local user_dir = rime_api.get_user_data_dir()
    local shared_dir = rime_api.get_shared_data_dir()

    -- Check existing main custom file
    local main_custom_file = wanxiang.is_pro_schema(env) and "wanxiang_pro.custom.yaml" or "wanxiang.custom.yaml"
    local main_custom_file_path = user_dir .. "/" .. main_custom_file
    local main_custom_file_exists = wanxiang.file_exists(main_custom_file_path)

    -- 处理直接辅助/间接辅助切换
    if input == "/zjf" or input == "/jjf" then
        local target_aux = (input == "/zjf") and "直接辅助" or "间接辅助"

        local success = set_aux_schema(main_custom_file_path, target_aux)

        local msg = success and ("已切换到〔" .. target_aux .. "〕，请重新部署。")
            or "未找到可切换的条目。"
        yield(Candidate("switch", seg.start, seg._end, msg, ""))
        return
    end

    local target_schema = SCHEMA_MAP[input]
    if target_schema then
        local files = {
            main_custom_file,
            "wanxiang_mixedcode.custom.yaml",
            "wanxiang_reverse.custom.yaml",
            "wanxiang_english.custom.yaml",
        }

        for _, filename in ipairs(files) do
            local src = shared_dir .. "/custom/" .. filename
            if not wanxiang.file_exists(src) then
                src = user_dir .. "/custom/" .. filename
            end

            local dest = user_dir .. "/" .. filename

            -- Copy custom files from src if they does not exist in the destination
            if not wanxiang.file_exists(dest) then
                if not wanxiang.file_exists(src) then
                    log.warning("Template custom file not found: " .. src)
                    goto continue
                end

                if not copy_file(src, dest) then
                    goto continue
                end
            end

            set_pinyin_schema(dest, target_schema)

            ::continue::
        end

        local msg = main_custom_file_exists
                and ("检测到已有配置，已切换到〔" .. target_schema .. "〕，请手动重新部署。")
            or ("已创建新配置并切换到〔" .. target_schema .. "〕，请手动重新部署。")
        yield(Candidate("switch", seg.start, seg._end, msg, ""))
    end
end

return translator
