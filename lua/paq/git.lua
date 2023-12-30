---@param dir Path
---@return string
local function get_git_hash(dir)
    local first_line = function(path)
        local file = io.open(path)
        if file then
            local line = file:read()
            file:close()
            return line
        end
    end
    local head_ref = first_line(dir .. "/.git/HEAD")
    return head_ref and first_line(dir .. "/.git/" .. head_ref:gsub("ref: ", ""))
end

return { get_git_hash = get_git_hash }
