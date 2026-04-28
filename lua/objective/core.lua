local M = {}

---@type table|nil
local config

---@param cfg table
function M._set_config(cfg)
	config = cfg
end

---Find the git root of the current buffer.
---@return string|nil
function M.find_git_root()
	-- Special buffers (like `health://`, `lspinfo://`, help, prompts) can make
	-- `%:p:h` or `fnamemodify(..., ':h')` return a non-changing value, which can
	-- otherwise lead to an infinite loop.
	local bt = vim.bo.buftype
	if bt ~= "" then
		return nil
	end

	local name = vim.api.nvim_buf_get_name(0)
	if name:match("^%w+://") then
		return nil
	end

	local path = vim.fn.expand("%:p:h")
	if not path or path == "" or path == "." then
		return nil
	end

	local prev
	while path and path ~= "/" and path ~= prev do
		if vim.fn.isdirectory(path .. "/.git") == 1 then
			return path
		end
		prev = path
		path = vim.fn.fnamemodify(path, ":h")
	end

	return nil
end

---@param root string
---@return string|nil
local function objective_path(root)
	for _, fn in ipairs(config.resolvers) do
		local p = fn(root)
		if vim.fn.filereadable(p) == 1 then
			return p
		end
	end
end

---Read the current objective text.
---@return string
function M._get_current()
	local root = M.find_git_root()
	if not root then
		return ""
	end
	local p = objective_path(root)
	if not p then
		return ""
	end
	local f = io.open(p, "r")
	if not f then
		return ""
	end
	local txt = f:read("*a")
	f:close()
	return txt or ""
end

---Write objective text and refresh the HUD.
---@param text string
function M.set(text)
	local root = M.find_git_root()
	if not root then
		return vim.notify("Not in a Git repo", vim.log.levels.WARN)
	end
	local p = objective_path(root) or config.resolvers[1](root)
	vim.fn.mkdir(vim.fn.fnamemodify(p, ":h"), "p")
	local f = io.open(p, "w")
	if not f then
		return vim.notify("Failed to write objective", vim.log.levels.ERROR)
	end
	f:write(text)
	f:close()
	require("objective.ui").show(text, config)
end

return M
