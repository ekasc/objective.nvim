local Popup = require("nui.popup")

local M = {}
local popup

function M.hide()
	if popup then
		popup:unmount()
		popup = nil
	end
end

function M.show(text, config)
	M.hide()
	local msg = (config.icon ~= "" and (config.icon .. "") or "") .. text
	popup = Popup({
		position = { row = config.row, col = vim.o.columns - #msg - config.col_offset },
		size = { width = #msg + 2, height = 1 },
		enter = false,
		focusable = false,
		border = { style = config.border },
		buf_options = { modifiable = false, readonly = true },
	})

	popup:mount()
	vim.api.nvim_buf_set_lines(popup.bufnr, 0, 1, false, { msg })
	vim.api.nvim_buf_add_highlight(popup.bufnr, -1, config.highlight, 0, 0, -1)
end

return M
