local uv = vim.uv or vim.loop

local Config = require("paq.cfg").Config
local get_git_hash = require("paq.git").get_git_hash

---@enum Status
local Status = {
    INSTALLED = 0,
    CLONED = 1,
    UPDATED = 2,
    REMOVED = 3,
    TO_INSTALL = 4,
    TO_MOVE = 5,
    TO_RECLONE = 6,
}

-- [TODO] Is it useful to distinguish between user input and "resolved" fields?
-- e.g. `as` serves no purpose once `name` is computed.
---@class Package A parsed and validated package definition.
---@field name string Package name.
---@field url string URL (or URI) of the package.
---@field as string Directory name on the filesystem, if not nil. Otherwise, uses the name from Git.
---@field branch string Git branch to use, if not nil. Otherwise, uses the repo default.
---@field pin boolean If true, do not update when a new version is found.
---@field build string | function Callback to execute after installing or updating.
---@field private dir string Physical filesystem location where the package is installed.
---@field private status Status Package installation status.
---@field private hash string Currently checked-out Git hash.

-- [TODO] Move to a central "nvim-utils" module
local function _err(msg)
    vim.notify(msg, vim.log.levels.ERROR)
end

local function is_string(x)
    return type(x) == "string"
end

local function is_table(x)
    return type(x) == "table"
end

local function is_boolean(x)
    return type(x) == "boolean"
end

local function is_function(x)
    return type(x) == "function"
end

---@param data any
---@return string
local function parse_url(data)
    -- [TODO] Separate basic data shape checking from URL parsing

    if is_string(data) then
        if #data < 1 then
            return _err("Package specification must not be empty or nil.")
        end
        url_maybe = data
    elseif is_table(data) then
        if vim.tbl_islist(data) then
            if #data < 1 then
                return _err("Package specification must not be empty or nil.")
            elseif #data > 1 then
                return _err("Package specification may have at most one non-string key, the URL in position 1.")
            end
            url_maybe = data[1]
        else
            if #vim.tbl_keys(data) < 1 then
                return _err("Package specification must not be empty or nil.")
            end
            if 0 ~= #(
                vim.tbl_filter(
                    function(x) return x ~= 1 and type(x) ~= "string" end,
                    vim.tbl_keys(data)
                )
            ) then
                return _err("Package specification keys must be strings.")
            end
            url_maybe = data.url or data[1]
        end
    else
        return _err("Package specification must be string or table.")
    end

    if not is_string(url_maybe) or #url_maybe < 1 then
        return _err("Package url= must be a non-empty string.")
    end

    -- RFC 3986 ch.2 "Characters" <https://www.rfc-editor.org/rfc/rfc3986#page-11>
    if url_maybe:match("[^%w:%[%]./_%-@%-#?=%(%),;*!]") then
        return _err("Package url= contains invalid data! If this is intentional, use percent-encoding.")
    end

    local url
    if url_maybe:match("^[^:]+://.*") then
        url = url_maybe
    else
        url = string.format(Config.url_format, url_maybe)
    end
    return url
end

---@param data any
---@return Package
local function parse(data)
    ---@type Package
    local pkg = {}

    if data == nil then
        return _err("Package specification must not be empty or nil.")
    end

    pkg.url = parse_url(data)
    if not pkg.url then
        return _err("Failed to parse URL.")
    end

    -- Parse everything else

    if is_table(data) then

        if nil ~= data.as then
            if is_string(data.as) and data.as:match("^%w+$") then
                pkg.as = data.as
            else
                return _err("Package as= must be a non-empty string of ASCII alphanumeric characters.")
            end
        end

        if nil ~= data.branch then
            -- [TODO] Implement the actual rules from Git, which are more lenient.
            -- https://git-scm.com/docs/git-check-ref-format
            -- https://stackoverflow.com/a/3651867/2954547
            if is_string(data.branch) and data.branch:match("^%w+$") then
                pkg.branch = data.branch
            else
                return _err("Package branch= must be a non-empty string of ASCII alphanumeric characters.")
            end
        end

        if nil == data.pin then
            pkg.pin = false
        else
            if is_boolean(data.pin) then
                pkg.pin = data.pin
            else
                return _err("Package pin= must be Boolean (true or false).")
            end
        end

        if nil ~= data.run then
            vim.deprecate("run=", "build=", "3.0", "Paq", false)
            if nil == data.build then
                data.build = data.run
            end
        end

        if nil ~= data.build then
            if is_function(data.build) or (is_string(data.build) and #data.build > 0) then
                pkg.build = data.build
            else
                return _err("Package build= must be a non-empty string, or a Lua function.")
            end
        end

        if nil ~= data.opt then
            if is_boolean(data.opt) then
                pkg.opt = data.opt
            else
                return _err("Package opt= must be Boolean (true or false).")
            end
        end

    end

    pkg.name = pkg.as or pkg.url:gsub("%.git$", ""):match("/([%w-_.]+)$")
    if not pkg.name then
        return _err("Failed to extract name from URL!")
    end

    if nil == pkg.opt then
        pkg.opt = Config.opt
    end

    pkg.dir = vim.fs.joinpath(Config.path, pkg.opt and "opt" or "start", pkg.name)

    pkg.status = uv.fs_stat(pkg.dir) and Status.INSTALLED or Status.TO_INSTALL

    pkg.hash = get_git_hash(pkg.dir)

    return pkg
end

return { parse = parse }
