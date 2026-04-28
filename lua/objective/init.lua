local M = {}

---@class ObjectiveConfig
---@field icon? string icon shown in popup title
---@field border? string border style: "single", "rounded", "double"
---@field col_offset? number horizontal offset from right edge
---@field row? number vertical offset from top
---@field min_width? number minimum popup width (columns)
---@field min_height? number minimum popup height (rows)
---@field mapping? string keybinding to open the editor
---@field toggle_mapping? string keybinding to toggle the HUD
---@field highlight? string highlight group for objective text
---@field timeout? number auto-hide timeout in seconds (0 to disable)
---@field resolvers? fun(root: string): string[] list of path resolvers

local default_config = {
	icon = "🎯",
	border = "rounded",
	col_offset = 10,
	row = 1,
	min_width = 20,
	min_height = 1,
	mapping = "<leader>oo",
	toggle_mapping = "<leader>ot",
	highlight = "Background",
	timeout = 5,
	resolvers = {
		function(root)
			return root .. "/.git/OBJECTIVE"
		end,
		function(root)
			return root .. "/.objective"
		end,
	},
}

local auto_hide_timer
local hud_enabled = true
local editor_win

---@param timeout number seconds until auto-hide
local function start_auto_hide(timeout)
	if timeout <= 0 then
		return
	end
	if auto_hide_timer then
		auto_hide_timer:stop()
		auto_hide_timer:close()
	end
	auto_hide_timer = vim.defer_fn(function()
		require("objective.ui").hide()
		auto_hide_timer = nil
	end, timeout * 1000)
end

local function clear_auto_hide()
	if auto_hide_timer then
		auto_hide_timer:stop()
		auto_hide_timer:close()
		auto_hide_timer = nil
	end
end

---@param config table
local function validate_config(config)
	local ok, err = pcall(vim.validate, {
		icon = { config.icon, "string", true },
		border = { config.border, "string", true },
		col_offset = { config.col_offset, "number", true },
		row = { config.row, "number", true },
		min_width = { config.min_width, "number", true },
		min_height = { config.min_height, "number", true },
		mapping = { config.mapping, "string", true },
		toggle_mapping = { config.toggle_mapping, "string", true },
		highlight = { config.highlight, "string", true },
		timeout = { config.timeout, "number", true },
		resolvers = { config.resolvers, "table", true },
	})
	if not ok then
		error("objective.nvim: invalid config - " .. tostring(err))
	end
end

---@param user_config? ObjectiveConfig
function M.setup(user_config)
	local config = vim.tbl_deep_extend("force", default_config, user_config or {})
	validate_config(config)

	local core = require("objective.core")
	core._set_config(config)
	local ui = require("objective.ui")

	-- auto-refresh HUD on startup / buffer switches / resize / dir change
	local scheduled = false
	vim.api.nvim_create_autocmd({ "VimEnter", "BufEnter", "DirChanged", "WinResized" }, {
		callback = function()
			if not hud_enabled then
				return
			end
			if scheduled then
				return
			end
			scheduled = true
			vim.schedule(function()
				scheduled = false

				local bufnr = vim.api.nvim_get_current_buf()
				if ui.is_popup_buf(bufnr) then
					return
				end

				-- Skip special buffers like :LspInfo / help / prompts.
				if vim.bo[bufnr].buftype ~= "" then
					return
				end

				-- Also skip scheme buffers like health://, lspinfo://, etc.
				local name = vim.api.nvim_buf_get_name(bufnr)
				if name:match("^%w+://") then
					return
				end

				local current = core._get_current()
				if current == "" then
					ui.hide()
					return
				end

				clear_auto_hide()
				ui.show(current, config)
				start_auto_hide(config.timeout)
			end)
		end,
	})

	-- Toggle command and mapping
	vim.api.nvim_create_user_command("ObjectiveToggle", function()
		hud_enabled = not hud_enabled
		if hud_enabled then
			local current = core._get_current()
			if current ~= "" then
				clear_auto_hide()
				ui.show(current, config)
				start_auto_hide(config.timeout)
			end
		else
			clear_auto_hide()
			ui.hide()
		end
	end, { desc = "Toggle objective HUD" })

	vim.keymap.set("n", config.toggle_mapping, function()
		vim.cmd("ObjectiveToggle")
	end, { desc = "Toggle Objective HUD" })

	-- Open editor
	vim.keymap.set("n", config.mapping, function()
		clear_auto_hide()
		ui.hide()

		-- Close any existing editor popup to avoid nui state conflicts.
		if editor_win then
			pcall(function()
				editor_win:unmount()
			end)
			editor_win = nil
		end

		-- Capture git root from the buffer we were editing before opening the popup.
		local captured_root = core.find_git_root()
		local current = core._get_current()
		local buf = vim.api.nvim_create_buf(false, true)
		vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(current, "\n", { plain = true }))
		vim.bo[buf].filetype = "markdown"
		vim.bo[buf].buftype = ""
		vim.bo[buf].swapfile = false

		local Popup = require("nui.popup")
		editor_win = Popup({
			bufnr = buf,
			position = "50%",
			size = {
				width = math.floor(vim.o.columns * 0.6),
				height = math.floor(vim.o.lines * 0.4),
			},
			enter = true,
			focusable = true,
			border = {
				style = config.border,
				text = { top = " " .. config.icon .. " Edit Objective ", top_align = "center" },
			},
			buf_options = { buftype = "", swapfile = false, modifiable = true },
			win_options = { winhighlight = "Normal:Normal" },
		})

		editor_win:mount()
		vim.cmd("startinsert")

		-- :w saves the objective (BufWriteCmd)
		vim.api.nvim_create_autocmd("BufWriteCmd", {
			buffer = buf,
			callback = function()
				local new = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
				core.set(table.concat(new, "\n"), captured_root)
				vim.bo[buf].modified = false
			end,
		})

		-- Keep modified=false so :q never complains about unsaved changes.
		-- The user explicitly saves with :w (which triggers BufWriteCmd).
		local no_modified = vim.api.nvim_create_augroup("ObjectiveNoModified", { clear = true })
		vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
			group = no_modified,
			buffer = buf,
			callback = function()
				vim.bo[buf].modified = false
			end,
		})

		-- Clean up when buffer leaves its window (e.g. via :q)
		vim.api.nvim_create_autocmd("BufWinLeave", {
			buffer = buf,
			once = true,
			callback = function()
				vim.api.nvim_clear_autocmds({ group = no_modified, buffer = buf })
				vim.schedule(function()
					if vim.api.nvim_buf_is_valid(buf) then
						vim.api.nvim_buf_delete(buf, { force = true })
					end
				end)
				editor_win = nil
			end,
		})
	end, { desc = "Edit Objective" })
end

return M
