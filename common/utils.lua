local utils_common = require "tf_api.utils"
local protoc = require "tf_api.protoc"
local const = require "common.const"
local M = {}

function M.get_proto_path()
    return utils_common.get_plugin_pwd(const.plugin_name) .. '/proto'
end

function M.load_all_proto()
    local files = dart_os_ext.listdir(M.get_proto_path())
    if files ~= nil then
        for _, file in ipairs(files) do
            protoc:loadfile(file)
        end
    end
end

return M
