package.path = package.path .. ";./lua/?.lua" .. ";./lua/?/init.lua"

local paq_cfg = require("paq.cfg")
local Config = paq_cfg.Config
local parse = require("paq.pkg").parse

-- local function id(x)
--   return x
-- end

-- local function tbl_copy(t)
--   return vim.tbl_map(id, t)
-- end

vim.cmd([[messages clear]])
-- vim.cmd([[redir @t]])
assert(parse({}) == nil)
-- vim.cmd([[redir END]])
-- msg = vim.fn.getreg("t")
-- vim.fn.setreg("t", "")
msg = vim.api.nvim_cmd({cmd = "messages"}, {output = true})
assert(msg ~= "")

vim.cmd([[messages clear]])
assert(parse("") == nil)
msg = vim.api.nvim_cmd({cmd = "messages"}, {output = true})
assert(msg ~= "")

vim.cmd([[messages clear]])
assert(parse({"a", "b"}) == nil)
msg = vim.api.nvim_cmd({cmd = "messages"}, {output = true})
assert(msg ~= "")

vim.cmd([[messages clear]])
assert(parse({1, 2}) == nil)
msg = vim.api.nvim_cmd({cmd = "messages"}, {output = true})
assert(msg ~= "")

vim.cmd([[messages clear]])
assert(parse(2) == nil)
msg = vim.api.nvim_cmd({cmd = "messages"}, {output = true})
assert(msg ~= "")

vim.cmd([[messages clear]])
assert(parse("α⇒β") == nil)
msg = vim.api.nvim_cmd({cmd = "messages"}, {output = true})
assert(msg ~= "")

vim.cmd([[messages clear]])
assert(parse({[3] = "z", [false] = "a", [9] = "b"}) == nil)
msg = vim.api.nvim_cmd({cmd = "messages"}, {output = true})
assert(msg ~= "")

vim.cmd([[messages clear]])
result = parse("a/b")
msg = vim.api.nvim_cmd({cmd = "messages"}, {output = true})
assert(msg == "")
assert(result.url == "https://github.com/a/b.git")
assert(result.name == "b")

vim.cmd([[messages clear]])
result = parse({"a/b"})
msg = vim.api.nvim_cmd({cmd = "messages"}, {output = true})
assert(msg == "")
assert(result.url == "https://github.com/a/b.git")
assert(result.name == "b")

vim.cmd([[messages clear]])
result = parse({url = "a/b"})
msg = vim.api.nvim_cmd({cmd = "messages"}, {output = true})
assert(msg == "")
assert(result.url == "https://github.com/a/b.git")
assert(result.name == "b")

vim.cmd([[messages clear]])
result = parse("https://git.example.net/a/b")
msg = vim.api.nvim_cmd({cmd = "messages"}, {output = true})
assert(msg == "")
assert(result.url == "https://git.example.net/a/b")
assert(result.name == "b")

local url_format_orig = Config.url_format
Config.url_format = "zzz___%s___zzz"
vim.cmd([[messages clear]])
ok, result = pcall(parse, "a/b")
Config.url_format = url_format_orig
msg = vim.api.nvim_cmd({cmd = "messages"}, {output = true})
assert(msg == "")
assert(ok)
assert(result.url == "zzz___a/b___zzz")
assert(result.name == "b___zzz")

local url_format_orig = Config.url_format
Config.url_format = "zzz___%s___zzz"
vim.cmd([[messages clear]])
ok, result = pcall(parse, "https://git.example.net/a/b")
Config.url_format = url_format_orig
msg = vim.api.nvim_cmd({cmd = "messages"}, {output = true})
assert(msg == "")
assert(ok)
assert(result.url == "https://git.example.net/a/b")
assert(result.name == "b")
assert(result.dir == vim.fs.joinpath(Config.path, "start", "b"))

vim.cmd([[messages clear]])
assert(parse({ "a/b", as = "a/b" }) == nil)
msg = vim.api.nvim_cmd({cmd = "messages"}, {output = true})
assert(msg ~= "")

vim.cmd([[messages clear]])
result = parse({ "a/b", as = "ab" })
msg = vim.api.nvim_cmd({cmd = "messages"}, {output = true})
print(msg)
assert(msg == "")
assert(result.url == "https://github.com/a/b.git")
assert(result.as == "ab")
assert(result.name == "ab")
assert(result.dir == vim.fs.joinpath(Config.path, "start", "ab"))

vim.cmd([[messages clear]])
result = parse({ "a/b", as = "ab", opt = true})
msg = vim.api.nvim_cmd({cmd = "messages"}, {output = true})
print(msg)
assert(msg == "")
assert(result.url == "https://github.com/a/b.git")
assert(result.as == "ab")
assert(result.name == "ab")
assert(result.dir == vim.fs.joinpath(Config.path, "opt", "ab"))
