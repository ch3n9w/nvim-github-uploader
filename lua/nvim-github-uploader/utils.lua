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

M.get_curl_data_command_1 = function(message, committer_name, committer_email, from_where)
    local header = string.format([[{"message":"%s","committer":{"name":"%s","email":"%s"},"content":"]], message, committer_name, committer_email)
local ender = [["}]]
    local insert_command = string.format([[sed -i '1s/^/%q/' %q]], header, from_where)
    local append_command = string.format([[echo %q >> %q]], ender, from_where)
    return insert_command, append_command
end

M.get_curl_data_command = function()
    local insert_command = [[sed -i '1s/^/{"message":"%s","committer":{"name":"%s","email":"%s"},"content":"/' %q]]
    local append_command = [[echo '"}' >> %q]]
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
    local curpos = vim.fn.getcurpos()
    local line_num, line_col = curpos[2], curpos[3]
    local indent = string.rep(" ", line_col)
    local txt_topaste = url_txt

    ---Convert txt_topaste to lines table so it can handle multiline string
    local lines = {}
    for line in txt_topaste:gmatch "[^\r\n]+" do
        table.insert(lines, line)
    end

    for line_index, line in pairs(lines) do
        local current_line_num = line_num + line_index - 1
        local current_line = vim.fn.getline(current_line_num)
        ---Since there's no collumn 0, remove extra space when current line is blank
        if current_line == "" then
            indent = indent:sub(1, -2)
        end

        local pre_txt = current_line:sub(1, line_col)
        local post_txt = current_line:sub(line_col + 1, -1)
        local inserted_txt = pre_txt .. line .. post_txt

        vim.fn.setline(current_line_num, inserted_txt)
        ---Create new line so inserted_txt doesn't replace next lines
        if line_index ~= #lines then
            vim.fn.append(current_line_num, indent)
        end
    end
end


return M
