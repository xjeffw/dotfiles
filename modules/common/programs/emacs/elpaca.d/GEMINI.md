# Emacs Elpaca Configuration

This project is a personal Emacs configuration built around the **Elpaca** package manager, emphasizing performance, modularity, and a Vim-like editing experience.

## Project Overview

- **Core Framework**: Built on Emacs 28+ with `lexical-binding` enabled.
- **Package Management**: Uses [Elpaca](https://github.com/progfolio/elpaca), a declarative, asynchronous package manager.
- **Editing Paradigm**: Full Vim emulation via `evil-mode` and `evil-collection`.
- **Keybindings**: Managed with `general.el`, featuring a structured leader-key system (`SPC`).
- **UI/UX**: Minimalist interface with `doom-modeline`, `catppuccin-theme`, and optimized font settings (JetBrains Mono Nerd Font).

## Project Structure

- `early-init.el`: Handles early-stage optimizations, including garbage collection tweaks, UI element suppression (menu-bar, tool-bar), and font initialization.
- `init.el`: The primary configuration file. It bootstraps Elpaca, configures `use-package` integration, defines global keybindings, and sets up individual packages.
- `emacs.sh`: A helper script to launch Emacs using this directory as the `--init-directory`.
- `elpaca/`:
    - `repos/`: Cloned source code for installed packages.
    - `builds/`: Compiled `.elc` and autoload files for packages.
- `auto-save-list/`: Directory for Emacs auto-save records.

## Key Technologies & Packages

- **Completion**: `corfu` (overlay completion), `cape` (completion at point extensions), and `consult` (enhanced search/selection).
- **Keybindings**: `general.el` for defining complex, state-aware keybindings and menus.
- **Vim Emulation**: `evil`, `evil-collection`, and `evil-anzu`.
- **Org Mode Support**: Includes `doct` for declarative Org capture templates and `auto-tangle-mode`.
- **Theming**: `catppuccin-theme` (Frappe flavor) and `doom-modeline`.

## Usage & Commands

### Launching Emacs
To start Emacs with this configuration, use the provided wrapper script:
```bash
./emacs.sh
```

### Key Leader Bindings (Internal)
Most functionality is accessible via the `SPC` (leader) and `SPC m` (major-mode leader) prefixes:
- `SPC SPC`: Execute extended command (`M-x`).
- `SPC f f`: Find file.
- `SPC b b`: Switch buffer (via `consult-buffer`).
- `SPC /`: Search line (via `consult-line`).
- `SPC a p m`: Open Elpaca Manager.
- `SPC q r`: Restart Emacs.

### Package Management
- **Install/Update**: Packages are automatically handled by `elpaca` on startup based on `use-package` declarations in `init.el`.
- **Manual Management**: Use `M-x elpaca-manager` to view and manage package states.

## Development Conventions

- **Package Declaration**: Use `(use-package <name> :ensure t ...)` for external packages.
- **Built-in Features**: Use the custom `(use-feature <name> ...)` macro for configuring built-in Emacs functionality without Elpaca trying to install it.
- **Keybinding Menus**: Use the `+general-global-menu!` macro to add new categories to the leader-key system.
- **Performance**: Garbage collection is tuned in `early-init.el` and reset after Elpaca finishes initializing.

## References

- For an example of a full, complex Emacs configuration using Elpaca, see:
    - `~/repos/progfolio-emacs.d/init.org`
    - `~/repos/progfolio-emacs.d/README.org`
- To see the previous Emacs configuration before this rewrite, refer to:
    - `~/.config/doom/config.el`
- The source code for Doom Emacs itself is available for reference in:
    - `~/.config/emacs`
