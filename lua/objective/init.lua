local M = {}

local default_config = {
	icon = "🎯",
	border = "rounded",
	col_offset = 10,
	row = 1,
	min_width = 20,
	min_height = 1,
	mapping = "<leader>oo",
	highlight = "Background",
	resolvers = {
		function(root)
			return root .. "/.git/OBJECTIVE"
		end,
		function(root)
			return root .. "/.objective"
		end,
	},
}

function M.setup(user_config)
	local config = vim.tbl_deep_extend("force", default_config, user_config or {})
	local core = require("objective.core")
	core._set_config(config)
	local ui = require("objective.ui")

	-- auto-refresh HUD on startup / buffer switches / resize / dir change
	vim.api.nvim_create_autocmd({ "VimEnter", "BufEnter", "DirChanged", "WinResized" }, {
		callback = function()
			ui.show(core._get_current(), config)
		end,
	})

	vim.keymap.set("n", config.mapping, function()
		ui.hide()

		local current = core._get_current()
		local buf = vim.api.nvim_create_buf(false, true)
		vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(current, "\n", { plain = true }))
		vim.api.nvim_buf_set_option(buf, "filetype", "markdown")

		local Popup = require("nui.popup")
		local win = Popup({
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

		win:mount()
		vim.schedule(function()
			vim.api.nvim_set_current_buf(buf)
			vim.cmd("startinsert")
		end)

		vim.keymap.set("n", "<Esc>", function()
			local new = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
			core.set(table.concat(new, "\n"))
			win:unmount()
		end, { buffer = buf, silent = true })
	end, { desc = "Edit Objective" })
end

return M
