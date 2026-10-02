# emacs-setup

My personal Emacs 30 configuration for macOS (Apple Silicon): Vim keys everywhere,
built for Clojure work, with a fast fuzzy finder, LSP, Git, a terminal and Claude Code
inside the editor.

- **Keys and tips:** [KEYS.md](KEYS.md), the cheatsheet (inside Emacs: `SPC h k`).
- **How it works, gotchas, how to test changes:** [AGENTS.md](AGENTS.md).

## What you get

- **Vim everywhere** with Evil. `SPC` is the leader for global commands, `,` for language
  commands (same keys as my Neovim setup: Telescope, Conjure, paredit).
- **Find things fast:** fuzzy file finder with live preview (list left, preview right),
  project grep, recent files, symbols.
- **Clojure:** CIDER REPL, clojure-lsp, parinfer (indent mode) and paredit-style structural
  editing, Integrant `user/reset`/`go`/`halt`, namespace refresh.
- **Other languages:** Python (pyright), YAML, Markdown and AsciiDoc with live preview and
  PDF export, CSS/SCSS with formatting, Emmet and Tailwind/daisyUI completion.
- **Git:** Magit, changed lines in the margin, stage/revert hunks, worktrees.
- **Terminal:** vterm (native speed), babashka task picker.
- **Claude Code** in a side window, aware of your file and selection; diffs open in ediff.
- **Linear** issues in an Org file.
- **Per-project `.env`:** loaded automatically for the REPL, LSP, terminal and tasks.
- Catppuccin Mocha theme, JetBrains Mono Nerd Font, doom-modeline status bar.

## Install on a new Mac

```sh
# Emacs, run as a background service
brew tap d12frosted/emacs-plus
brew install emacs-plus@30
git clone git@github.com:thijs-creemers/emacs-setup.git ~/.emacs.d

# Tools the config uses (skip what you don't need)
brew install clojure-lsp/brew/clojure-lsp-native pyright marksman pandoc asciidoctor \
             cmake libvterm node uv
brew install --cask font-jetbrains-mono-nerd-font
npm install -g vscode-langservers-extracted @tailwindcss/language-server
uv tool install rassumfrassum

# First start installs all packages
brew services start emacs-plus@30
```

Then two one-time steps, both described in [AGENTS.md](AGENTS.md): build the vterm module,
and download the parinfer library. Optional: put your Linear API key in the macOS Keychain.

## Daily use

- Open a window with **Emacs Client** (Applications), or `emacsclient -c`.
- After editing the config: `SPC h r` reloads it. Bigger changes:
  `brew services restart emacs-plus@30`.
- Lost? Press `SPC` and wait: a panel on the right shows what each next key does.

## Layout

```
init.el            loads one file per topic, in order
early-init.el      startup speed
lisp/init-*.el     the config, one topic per file (evil, clojure, git, ...)
KEYS.md            cheatsheet
AGENTS.md          notes for changing the config (humans and AI agents)
```
