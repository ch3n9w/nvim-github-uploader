# neovim github image uploader

A simple plugin to upload clipboard image

## dependency

curl, xclip(for x11), wl-clipboard (for wayland)

Only support Linux now.

## install

use your favorate plugin manager, like `packer.nvim`. then add your configurations in `setup`
```lua
--- default configurations
require'nvim-github-uploader'.setup({
    token = "<your github api token>",
    repo = "<username>/<repo>",
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
    })
```

## usage

```lua
<cmd>lua require'nvim-github-uploader'.upload_img()<cr>
```
or using command 
```lua
:UploadClipboard
```

## Thanks
[nvim-picgo](https://github.com/askfiy/nvim-picgo)
[clipboard-image.nvim](https://github.com/ekickx/clipboard-image.nvim)
