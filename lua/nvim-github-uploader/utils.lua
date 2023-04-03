local M = {}


M.get_os = function()
    if vim.fn.has "win32" == 1 then
        return "Windows"
    end

    local this_os = tostring(io.popen("uname"):read())
    if this_os == "Linux" and
        vim.fn.readfile("/proc/version")[1]:lower():match "microsoft" then
        this_os = "Wsl"
    end
    return this_os
end

M.get_clip_command = function()
    local cmd_check = ""
    local cmd_paste
    local this_os = M.get_os()
    if this_os == "Linux" then
        local display_server = os.getenv "XDG_SESSION_TYPE"
        if display_server == "x11" or display_server == "tty" then
            cmd_check = "xclip -selection clipboard -o -t TARGETS"
            cmd_paste = "xclip -selection clipboard -t image/png -o | base64 -w 0 > '%s'"
        elseif display_server == "wayland" then
            cmd_check = "wl-paste --list-types"
            cmd_paste = "wl-paste --no-newline --type image/png | base64 -w 0 > '%s'"
        end
    end
    return cmd_check, cmd_paste
end

M.get_curl_data_command = function()
    local insert_command = [[sed -i '1s/^/{"message":"%s","committer":{"name":"%s","email":"%s"},"content":"/' %s]]
    local append_command = [[echo '"}' >> %s]]
    return insert_command, append_command
end

M.get_clip_content = function(command)
    command = io.popen(command)
    local outputs = {}

    ---Store output in outputs table
    if command ~= nil then
        for output in command:lines() do
            table.insert(outputs, output)
        end
    end
    return outputs
end

M.is_clipboard_img = function(type)
    local this_os = M.get_os()
    if this_os == "Linux" and vim.tbl_contains(type, "image/png") then
        return true
    elseif this_os == "Darwin" and string.sub(type[1], 1, 9) == "iVBORw0KG" then -- Magic png number in base64
        return true
    elseif this_os == "Windows" or this_os == "Wsl" and type ~= nil then
        return true
    end
    return false
end

M.notice_success = function(state)
    local notice = require("nvim-github-uploader.config").get_config().notice
    if state then
        local msg = "Upload image success"

        vim.pretty_print(notice)
        if notice == "notify" and vim.notify ~= nil then
            vim.notify(msg, "info", { title = "Uploader" })
        else
            vim.api.nvim_echo({ { msg, "MoreMsg" } }, true, {})
        end
    else
        local msg = "Upload image failed"
        if notice == "notify" and vim.notify ~= nil then
            vim.notify(msg, "error", { title = "Uploader" })
        else
            vim.api.nvim_echo({ { msg, "ErrorMsg" } }, true, {})
        end
    end
end

M.insert_txt = function(url_txt)
    local current_buf = vim.api.nvim_get_current_buf()
    local current_line = vim.api.nvim_win_get_cursor(0)[1] - 1
    vim.api.nvim_buf_set_lines(current_buf, current_line, current_line, false, { url_txt })
end

return M
