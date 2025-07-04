# objective.nvim 🎯  
Floating HUD for your current dev objective per repo — clean, no clutter.

## Why?

I kept forgetting what I was doing after taking breaks.  
This lets me drop a quick objective and keep it visible — no todo list, no distractions.

---

## Install

```lua
{
  "ekasc/objective.nvim",
  dependencies = { "MunifTanjim/nui.nvim" },
  event = { "BufReadPost", "BufNewFile" },
  config = function()
    require("objective").setup()
  end,
}
```

## Usage

- `<leader>oo` → open a floating editor  
- Type your objective (multi-line supported)  
- Press `Esc` twice to save and close  

Your objective is saved to `.git/OBJECTIVE` or `.objective` in your repo.  
A floating HUD displays it on buffer switches and window resizes.

## Configuration

You can tweak how the popup looks and which key opens it:

```lua
require("objective").setup({
    icon = "🚀", -- icon shown in the popup title (empty = no icon)
	border = "rounded", -- border style: "single", "round", "double".
	col_offset = 5, -- horizontal offset from right edge
	row = 2, -- vertical offset from top
    min_width = 30, -- minimum popup height (in rows)
    min_height = 2, -- minimum popup width (in columns)
	highlight = "Background", -- highlight group for the objective window
	mapping = "<leader>oo", -- which keybinding opens the editor
	-- where to look for your objective file (in order)
	resolvers = {
		function(root) return root .. "/.git/OBJECTIVE" end,
		function(root) return root .. "/.objective" end
	},
})

```
