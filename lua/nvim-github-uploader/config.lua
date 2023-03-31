local M = {}

M.config = {
    token = "",
    repo = "",
    path = "",
    img_name = function()
        return os.date "%Y-%m-%d-%H-%M-%S.png"
    end,
    affix = "![](%s)",
    message = "upload image",
    committer_name = "uploader",
    committer_email = "xxx@xxx.com",
    notice = "notify",
    tmp_file = "/tmp/nvim-github-uploader",
    show_name = true,
}

M.merge_config = function(old_opts, new_opts)
  return vim.tbl_deep_extend("force", old_opts, new_opts or {})
end

M.get_config = function() 
    return M.config
end

return M
