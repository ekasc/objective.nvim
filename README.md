# objective.nvim 🎯
Floating HUD for your current dev objective per repo, zero noise.

## Install
```lua
-- with lazy.nvim
{
  "ekasc/objective.nvim",
  dependencies = { "MunifTanjim/nui.nvim" },
  event = { "BufReadPost", "BufNewFile" },
  config = function()
    require("objective").setup()
  end,
}
