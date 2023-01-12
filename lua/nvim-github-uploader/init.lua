local M = {}

local conf_module = require("nvim-github-uploader.config")
local uploader = require("nvim-github-uploader.upload")

M.setup = function(opts)
    conf_module.config = conf_module.merge_config(conf_module.config, opts)

    -- conf_module.init(opts)

    -- vim.api.nvim_create_user_command(
    --     "UploadClipboard",
    --     uploader.upload_clip,
    --     { desc = "Upload image from clipboard to github"}
    -- )
end
M.upload_img = uploader.upload_clip

return M
