local M = {}

local defaults = {
	icon = "🎯",
	border = "rounded",
	col_offset = 10,
	row = 1,
	highlight = "ObjectiveText",
	resolvers = {
		function(root)
			return root .. "/.git/OBJECTIVE"
		end,
		function(root)
			return root .. "/.objective"
		end,
	},
}

local config, core

function M.setup(user_config)
	config = vim.tbl_deep_extend("force", defaults, user_config or {})
	core = require("objective.core")
	core._set_config(config)

	vim.api.nvim_create_user_command("SetObjective", function(opts)
		local Input = require("nui.input").Input
		local inp = Input({
			position = "50%",
			size = { width = 20, height = 8 },
			border = { style = config.border },
			buf_options = { filetype = "markdown" },
			win_options = { winhighlight = "Normal:Normal" },
			prompt = config.icon .. " ",
			default_value = core._get_current() or "",
			multiline = true,
		}, {
			on_submit = function(value)
				core.set(value)
				inp:unmount()
			end,

			on_close = function()
				inp:unmount()
			end,
		})

		inp:mount()
		vim.keymap.set("i", "<Esc><Esc>", function()
			inp:unmount()
		end, {
			buffer = inp.bufnr,
			silent = true,
		})
	end, { desc = "Set objective (multiline floating)" })

	vim.keymap.set("n", "<leader>oo", "<cmd>SetObjective<CR>", { desc = "Set objective" })
	vim.cmd(("hi default %s gui=italic"):format(cfg.highlight))
end

return M
