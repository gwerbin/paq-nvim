---@class setup_opts
---@field path Path The Vim `pack` directory to be managed by Paq.
---@field opt boolean If true, use `opt/` by default, otherwise use `start/`.
---@field verbose boolean If true, enable verbose output during operations.
---@field log Path Log file locadtion.
---@field lock Path Lock file location.
---@field url_format string Default URL format for package names that are not valid URIs or URLs.
---@field clone_args string[] Default arguments for the `git clone` command.
local Config = {
    path = vim.fn.stdpath("data") .. "/site/pack/paqs/",
    opt = false,
    verbose = false,
    url_format = "https://github.com/%s.git",
    log = vim.fn.stdpath(vim.fn.has("nvim-0.8") == 1 and "log" or "cache") .. "/paq.log",
    lock = vim.fn.stdpath("data") .. "/paq-lock.json",
    clone_args = { "--depth=1", "--recurse-submodules", "--shallow-submodules", "--no-single-branch" }
}

return { Config = Config }
