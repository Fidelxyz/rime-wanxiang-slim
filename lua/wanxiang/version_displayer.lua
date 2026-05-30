---Display version information about the input schema and Rime when the user types "/version".
---@author Fidel Yin <fidel.yin@hotmail.com>

local wanxiang = require("wanxiang.wanxiang")

---Pinyin schema markers to schema names mapping. The markers are defined in the algebra of each schema.
---@type table<string, string>
MARKERS_TO_PINYIN_SCHEMAS = {
    ["Ⅰ"] = "全拼",
    ["Ⅱ"] = "自然码",
    ["Ⅲ"] = "小鹤双拼",
    ["Ⅳ"] = "微软双拼",
    ["Ⅴ"] = "搜狗双拼",
    ["Ⅵ"] = "智能ABC",
    ["Ⅶ"] = "紫光双拼",
    ["Ⅷ"] = "拼音加加",
    ["Ⅸ"] = "国标双拼",
    ["Ⅺ"] = "自然龙",
    ["Ⅻ"] = "汉心龙",
    ["Ⅼ"] = "乱序17",
}

---Auxiliary code schema markers to schema names mapping. The markers are defined in the algebra of each schema.
---@type table<string, string>
MARKERS_TO_AUXCODE_SCHEMAS = {
    ["Ⅽ"] = "间接辅助",
    ["Ⅾ"] = "直接辅助",
}

---Get the schema name based on the algebra markers defined in the Rime configuration.
---@param env Env
---@param markers_to_schemas table<string, string>
---@return string?
function get_schema(env, markers_to_schemas)
    local rime_config = env.engine.schema.config

    local algebra_list = rime_config:get_list("speller/algebra")
    if not algebra_list then
        return nil
    end

    for i = 0, algebra_list.size - 1 do
        local algebra_val = algebra_list:get_value_at(i)
        local algebra = algebra_val and algebra_val:get_string()
        if algebra then
            local marker = algebra:match("xform/([^/]+)//")
            local schema = markers_to_schemas[marker]
            if schema then
                return schema
            end
        end
    end
end

---@param input string
---@param segment Segment
---@param env Env
local function translator(input, segment, env)
    if input == "/version" then
        local messages = {
            ("%s – %s"):format(env.engine.schema.schema_name, wanxiang.VERSION),
            ("Rime 前端：%s（%s）– %s"):format(
                rime_api.get_distribution_name(),
                rime_api.get_distribution_code_name(),
                rime_api.get_distribution_version()
            ),
            ("librime 版本：%s"):format(rime_api.get_rime_version()),
            ("Lua 版本：%s"):format(_VERSION),
            ("拼音方案：%s"):format(get_schema(env, MARKERS_TO_PINYIN_SCHEMAS) or ""),
            ("辅助码方案：%s"):format(get_schema(env, MARKERS_TO_AUXCODE_SCHEMAS) or ""),
        }

        yield(Candidate("message", segment.start, segment._end, table.concat(messages, "\n"), ""))
    end
end

return translator
