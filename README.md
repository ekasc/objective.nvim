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

- `<leader>oo` → open the floating objective editor
- `<leader>ot` → toggle the HUD on/off
- Type your objective (multi-line supported)
- Use `:w` to save and `:q` to close the editor (standard Vim buffer behavior)
- Use `:wq` to save and close in one step

Your objective is saved to `.git/OBJECTIVE` or `.objective` in your repo.
A floating HUD displays it on buffer switches and window resizes, then
auto-hides after a few seconds so it never gets in the way.

If no objective is set, the HUD stays hidden.

## Configuration

You can tweak how the popup looks and which keys trigger it:

```lua
require("objective").setup({
    icon = "🚀",               -- icon shown in the popup title (empty = no icon)
    border = "rounded",        -- border style: "single", "rounded", "double"
    col_offset = 5,            -- horizontal offset from right edge
    row = 2,                   -- vertical offset from top
    min_width = 30,            -- minimum popup width (in columns)
    min_height = 2,            -- minimum popup height (in rows)
    highlight = "Background",  -- highlight group for the objective window
    mapping = "<leader>oo",    -- keybinding to open the editor
    toggle_mapping = "<leader>ot", -- keybinding to toggle the HUD
    timeout = 5,               -- auto-hide timeout in seconds (0 to disable)
    -- where to look for your objective file (in order)
    resolvers = {
        function(root) return root .. "/.git/OBJECTIVE" end,
        function(root) return root .. "/.objective" end
    },
})
```

## Commands

| Command | Description |
|---------|-------------|
| `:ObjectiveToggle` | Show or hide the objective HUD |

## Mappings

| Mapping | Mode | Description |
|---------|------|-------------|
| `<leader>oo` | Normal | Open the objective editor |
| `<leader>ot` | Normal | Toggle the HUD (closes editor if open) |
| `:w` | Editor | Save the objective (via WriteCmd) |
| `:q` | Editor | Close the editor |
| `:wq` | Editor | Save and close |

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for version history.
