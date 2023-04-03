local M = {}
local conf_module = require("nvim-github-uploader.config")
local utils = require("nvim-github-uploader.utils")
local check_dependency = require("nvim-github-uploader.health").check_current_dep
local cmd_check, cmd_paste = utils.get_clip_command()
local insert_command, append_command = utils.get_curl_data_command()

local store_img = function(path)
    os.execute(string.format(cmd_paste, path))
end

local generate_curl_data = function(message, committer_name, committer_email, from_where)
    os.execute(string.format(insert_command, message, committer_name, committer_email, from_where))
    os.execute(string.format(append_command, from_where))
end

M.upload_clip = function()
    local is_dep_exist, deps_msg = check_dependency()
    if not is_dep_exist then
        vim.notify(deps_msg, vim.log.levels.ERROR)
        return false
    end

    local type = utils.get_clip_content(cmd_check)
    if utils.is_clipboard_img(type) ~= true then
        vim.notify("There is no image data in clipboard", vim.log.levels.ERROR)
    else
        local conf = conf_module.get_config()
        -- store clipboard image into usable_conf.tmp_file
        store_img(conf.tmp_file)
        generate_curl_data(
            conf.message,
            conf.committer_name,
            conf.committer_email,
            conf.tmp_file
        )
        local image_name = conf.img_name()
        upload_img(
            conf.token,
            conf.repo,
            conf.path,
            image_name,
            conf.tmp_file
        )
    end
end

local function callbackfn(job_id, data, _)
    -- if request status code is not 20x, exit
    -- after success upload, there will be another callbackfn where the data is {""}
    if data[1]:match("20") == nil then
        print(vim.inspect(data))
        if data[1] ~= "" then
            utils.notice_success(false)
        end
        vim.fn.jobstop(job_id)
        return
    end
    utils.notice_success(true)

    -- upload success, extract url from response body
    local regex = vim.regex("https://raw.githubusercontent.com.*\"")
    local img_link
    for _, content in ipairs(data) do
        if regex ~= nil then
            local img_url_start, img_url_end = regex:match_str(content)
            if img_url_start ~= nil then
                local img_url = string.sub(content, img_url_start + 1, img_url_end - 1)
                local filetype = vim.bo.filetype
                if filetype == "markdown" then
                    local conf = conf_module.get_config()
                    if conf.show_name then
                        img_link = string.format("![%s](%s)", vim.fn.fnamemodify(img_url, ":t:r"), img_url)
                    else
                        img_link = string.format("![](%s)", img_url)
                    end
                else
                    img_link = string.format("%s", img_url)
                end

                -- put img_url into clipboard
                vim.fn.setreg(vim.v.register, img_link)
            end
        end
    end
    -- insert image link into content
    utils.insert_txt(img_link)
end

-- upload image to github
function upload_img(token, repo, path, filename, from_where)
    -- local exec_command_with_result = vim.api.nvim_exec(string.format("!cat %s | base64 -w 0", from_where), true)
    -- local base64content = io.popen(string.format("cat %s | base64 -w 0", from_where)):read("*a")

    -- local data = string.format("{\"message\":\"%s\",\"committer\":{\"name\":\"%s\",\"email\":\"%s\"},\"content\":\"%s\"}", message
    --\"}
    -- local data = string.format("{\"message\":\"%s\",\"committer\":{\"name\":\"%s\",\"email\":\"%s\"},\"content\":\"",
    --     message, committer_name, committer_email)
    -- local maxChunkSize = 10000
    -- for i = 1, #base64content, maxChunkSize do
    --     local chunk = base64content:sub(i, i + maxChunkSize - 1)
    --     data = data .. string.format("%s", chunk)
    -- end
    -- data = data .. "\"}"
    local job = {
        "curl",
        "-s",
        "-i",
        "-X", "PUT",
        "-H", "Accept: application/vnd.github+json",
        "-H", "Authorization: Bearer " .. token,
        string.format("https://api.github.com/repos/%s/contents/%s/%s", repo, path, filename),
        "-d",
        string.format([[@%s]], from_where),
        -- string.format("{\"message\":\"%s\",\"committer\":{\"name\":\"%s\",\"email\":\"%s\"},\"content\":\"$(cat %s)\"}", message,
        -- committer_name, committer_email, from_where)
    }
    -- vim.pretty_print(job)
    vim.fn.jobstart(job, {
        on_stdout = callbackfn,
    })
end

return M
