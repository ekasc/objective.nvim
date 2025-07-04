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

	local lines = vim.split(text, "\n", { plain = true })
	local width = 0
	for _, l in ipairs(lines) do
		width = math.max(width, vim.fn.strdisplaywidth(l))
	end
	width = math.max(config.min_width, math.min(width + 2, vim.o.columns - config.col_offset - 2))

	local height = math.max(config.min_height, math.min(#lines, math.floor(vim.o.lines / 2)))

	popup = Popup({
		position = { row = config.row, col = vim.o.columns - width - config.col_offset },
		size = { width = width, height = height },
		enter = false,
		focusable = false,
		border = {
			style = config.border,
			text = { top = " " .. config.icon .. " Objective ", top_align = "center" },
		},
		buf_options = { modifiable = true, readonly = false },
	})

	popup:mount()
	vim.api.nvim_buf_set_lines(popup.bufnr, 0, -1, false, lines)
	vim.api.nvim_buf_add_highlight(popup.bufnr, -1, config.highlight, 0, 0, -1)
end

return M
