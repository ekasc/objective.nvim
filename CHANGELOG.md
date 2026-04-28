# Changelog

All notable changes to this project will be documented in this file.

## [1.1.0] - 2026-04-28

### Added

- **Auto-hide HUD** — the objective popup now automatically disappears after a configurable timeout (default: 5 seconds). It reappears on buffer switches and window resizes.
- **Toggle mapping** — press `<leader>ot` (configurable) or run `:ObjectiveToggle` to manually show or hide the HUD.
- **Discard changes** — press `<C-q>` in the objective editor to close without saving.
- **Config validation** — invalid config values now produce clear error messages on startup.
- **Vim help docs** — run `:help objective` for full reference.

### Changed

- **Improved `<Esc>` behavior** — the editor now saves and closes on a single `<Esc>` press (no need to press twice).
- **Hide when empty** — the HUD no longer renders a blank popup when no objective is set.
- **Deprecated API fix** — replaced `vim.api.nvim_buf_set_option` with `vim.bo`.

## [1.0.0] - 2026-04-28

- Initial release.
