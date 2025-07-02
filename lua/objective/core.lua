local ui = require("objective.ui")

local json = vim.json
local M = {}

local config, curr_repo, curr_msg
local GLOBAL_FILE = vim.fn.stdpath("state") .. "/objective.nvim..json"

-- find git root
local function find_git_root()
	local path = vim.fn.expand("%:p:h")
	while path and path ~= "/" do
		if vim.fn.isdirectory(path .. "/.git") == 1 then
			return path
		end
		path = vim.fn.fnamemodify(path, ":h")
	end
end

local function global_db()
	local f = io.open(GLOBAL_FILE, "r")

	if not f then
		return {}
	end
	local ok, tbl = pcall(json.decode, f:read("*a") or "{}")

	f:close()
	return ok and tbl or {}
end

local function write_global(db)
	vim.fn.mkdir(vim.fn.fnamemodify(GLOBAL_FILE, ":h"), "p")
	local f = io.open(GLOBAL_FILE, "w")
	if f then
		f:write(json.encode(db))
		f:close()
	end
end

-- pick objective path
local function objective_path(root)
	for _, fn in pairs(config.resolvers) do
		local path = fn(root)
		if vim.fn.filereadable(path) == 1 or vim.fn.filereadable(path) == 0 then
			return path
		end
	end
end

-- public
function M._set_config(cfg)
	config = cfg
end

function M._get_current()
	return curr_msg
end

function M.refresh()
	local root = find_git_root()
	local msg

	if root then
		local path = objective_path(root)
		if path then
			local f = io.open(path, "r")
			if f then
				msg = vim.trim(f:read("*a") or "")
				f:close()
			end
		end
	else
		local db = global_db()
		msg = db[vim.fn.getcwd()]
	end

	curr_repo = root
	curr_msg = (msg and msg ~= "") and msg or nil

	if curr_msg then
		ui.show(curr_msg, config)
	else
		ui.hide()
	end
end

function M.set(msg)
	local root = find_git_root()
	if root then
		local path = objective_path(root)
		if not path then
			vim.notify("No writable path for objective", vim.log.levels.WARN)
			return
		end
		local f = io.open(path, "w")
		if not f then
			vim.notify("Failed to write objective", vim.log.levels.ERROR)
			return
		end
		f:write(msg)
		f:close()
	else
		local db = global_db()
		db[vim.fn.getcwd()] = msg
		write_global(db)
	end

	curr_msg = msg
	ui.show(msg, config)
end

return M
