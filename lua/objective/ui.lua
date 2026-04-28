local Popup = require("nui.popup")
local M = {}
local popup
local rendering = false

function M.hide()
	if popup then
		popup:unmount()
		popup = nil
	end
end

function M.is_popup_buf(bufnr)
	return popup ~= nil and popup.bufnr == bufnr
end

---@param text string objective text to display
---@param config table current plugin config
function M.show(text, config)
	if rendering then
		return
	end
	rendering = true

	local ok, err = pcall(function()
		-- Don't show empty or whitespace-only objectives
		if not text or text:match("^%s*$") then
			M.hide()
			return
		end

		local lines = vim.split(text, "\n", { plain = true })
		local width = 0
		for _, l in ipairs(lines) do
			width = math.max(width, vim.fn.strdisplaywidth(l))
		end
		width = math.max(config.min_width, math.min(width + 2, vim.o.columns - config.col_offset - 2))

		local height = math.max(config.min_height, math.min(#lines, math.floor(vim.o.lines / 2)))
		local row = config.row
		local col = vim.o.columns - width - config.col_offset

		if popup and popup.winid and vim.api.nvim_win_is_valid(popup.winid) then
			vim.api.nvim_win_set_config(popup.winid, {
				relative = "editor",
				row = row,
				col = col,
				width = width,
				height = height,
				zindex = 50,
			})
		else
			popup = Popup({
				position = { row = row, col = col },
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
		end

		if popup and popup.bufnr and vim.api.nvim_buf_is_valid(popup.bufnr) then
			vim.api.nvim_buf_set_lines(popup.bufnr, 0, -1, false, lines)
			vim.bo[popup.bufnr].filetype = "markdown"
			vim.api.nvim_buf_add_highlight(popup.bufnr, -1, config.highlight, 0, 0, -1)
		end
	end)

	rendering = false
	if not ok then
		rendering = false
		vim.schedule(function()
			vim.notify("objective.nvim: failed to render HUD: " .. tostring(err), vim.log.levels.WARN)
		end)
	end
end

return M
