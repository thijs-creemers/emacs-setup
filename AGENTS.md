# AGENTS.md — notes for working on this Emacs config

Personal Emacs 31 setup (emacs-plus, macOS, Apple Silicon): Evil (vim keys), Clojure/CIDER,
Python, YAML, Markdown, AsciiDoc, CSS, Git, terminal, Claude Code, Linear, Jira.
User-facing key reference: `KEYS.md`. This file is for whoever changes the config.

## Layout

| Path | What |
|------|------|
| `early-init.el` | Startup speed, hide toolbar/menu |
| `init.el` | Only `require`s, one line per topic, in load order |
| `lisp/init-<topic>.el` | One file per topic; ends with `(provide 'init-<topic>)` |
| `KEYS.md` | Cheatsheet for the user (`SPC h k` opens it) |
| `custom.el` | Customize output; don't hand-edit |
| `rass/slow-start.py` | Parked rass preset (see Tailwind below) |
| `eat-terminfo/` | Generated: eat terminfo compiled for macOS (git-ignored) |
| `parinfer-rust/` | Downloaded parinfer library (git-ignored, see Clojure gotchas) |
| `tree-sitter/` | Bash + Python grammars, compiled on first start (git-ignored) |
| `.cache/` | Treemacs state (git-ignored) |
| `tickets-backends.eld` | Linear/Jira choice per project (git-ignored) |

Git tracks only the config and docs; packages, caches and personal state are in `.gitignore`.
New machine: clone, start Emacs once (installs packages), then build the vterm module and
fetch the parinfer library as described below.

New topic: add `lisp/init-foo.el`, add `(require 'init-foo)` to `init.el`, document in `KEYS.md`.

## Conventions

- Keep it simple and readable. Comments max 3 lines. Match surrounding style.
- **Every key change goes into `KEYS.md`** in the same change.
- Keys follow the user's nvim (Telescope/Conjure/paredit) muscle memory:
  - `SPC` = global leader (all bindings in `init-evil.el`).
  - `,` = local leader for language commands, bound per mode in each language file.
  - which-key labels for `,` groups are per major mode (`init-ui.el`), never global,
    otherwise Markdown showed Clojure labels.
- Bind menu keys with a label for which-key: `(kbd "<leader>gg") '("Git status" . magit-status)`.
  Emacs runs the command; which-key shows the label instead of the function name.
- Own functions are prefixed `my/`.
- `use-package` with `:ensure t` by default (`init-packages.el`). Built-ins use `:ensure nil`.
- Language servers start via `(my/eglot-if "binary")`: only when installed.

## Daemon workflow

- Emacs runs as a **brew service**: `emacs-plus@31` (launchd, `--fg-daemon`, auto-respawns).
- Windows come from `/Applications/Emacs Client.app` (emacsclient). See "Emacs Client.app".
- **Reload** config in the running server: `SPC h r` or
  `emacsclient -e '(my/reload-config)'`. It re-loads all `lisp/init-*.el`.
  Removed settings/bindings stay active until restart.
- **Restart**: `brew services restart emacs-plus@31`. Never `emacs --daemon` (fails: already
  running) or `kill-emacs` (launchd respawns it, possibly before your edit lands).
- Before a restart, check for unsaved buffers; a restart also kills CIDER REPLs.
- **Prompts block the server.** A `y-or-n-p` during reload (e.g. first install of a `:vc`
  package) freezes every `emacsclient -e`. Install new packages in a batch Emacs first,
  and wrap server calls in `timeout`.
- The daemon starts without a window system: GUI-only guards (`window-system`) skip there.
  Per-frame settings (font) use `after-make-frame-functions`.

## Testing changes

Don't claim a change works without running it. Patterns that worked:

- **Load check**: `emacs --batch -l early-init.el -l init.el --eval '(message "RES %s" ...)'`
  and grep `RES`. First run also installs packages.
- **Keys / UI**: GUI Emacs with a test file: `emacs -l /tmp/test.el`, using
  `run-at-time` + `(setq unread-command-events (listify-key-sequence (kbd "SPC f f")))`,
  write results to a file, then `kill-emacs`.
  - Test files need `;;; -*- lexical-binding: t; -*-` or timer closures lose variables.
  - Don't define global helpers with common names (`step` hung Emacs). Prefix them.
  - `vertico-multiform` picks layouts by `this-command`; set it when calling directly.
  - Keyboard macros act on the *displayed* buffer: `switch-to-buffer` first.
  - Read state *before* `with-temp-file` (it switches the current buffer).
- **LSP**: wait for `(eglot--capabilities (eglot-current-server))`; for request debugging set
  `eglot-events-buffer-config '(:size 4000000 :format full)` and read `jsonrpc-events-buffer`.
  `jsonrpc-request` with `:timeout` avoids hangs.
- Test in real projects (e.g. `~/work/worktrees/boundary/main`) only in **unsaved** buffers;
  `set-buffer-modified-p nil` before killing; check `git status` afterwards.
- Secrets: when checking `.env`, print names or lengths, never values.

## Gotchas we hit (and the fix in place)

**Loading / packages**
- `:bind` in use-package makes loading lazy: vertico never turned on. Use `:demand t`.
- When a package may already be loaded (server reload), its `:config` runs immediately:
  define helper functions *above* the `use-package` that calls them.
- elpa.gnu.org / elpa.nongnu.org can be unreachable (timeouts) while MELPA works: cider
  (dep `queue`), rainbow-mode and eat then fail to install. `init-packages.el` uses the
  d12frosted GitHub mirror (unsigned, so `package-check-signature nil`) until then.
- Native-compile warnings (`*Warnings*` after installing cider etc.) are package bugs;
  `early-init.el` silences them (`native-comp-async-report-warnings-errors`).
- `exec-path-from-shell` must run on every macOS start, including the daemon, or Homebrew
  tools (pandoc, clojure-lsp, ...) are not found.

**Evil**
- evil-collection REPLs: RET submits only in normal state by default. Overridden with
  `evil-collection-binding-overrides`. CIDER uses `my/cider-repl-return`: evaluate only when
  the form is complete *and* the cursor is at the end (electric-pair closes parens early).
- Terminals: insert state sends keys to the shell; `Esc` → normal state for `SPC`, `C-w`.

**Clojure**
- parinfer-rust: needs the arm64 `.so` in `parinfer-rust/` (from justinbarclay's fork,
  v0.4.7). Auto-download didn't work in batch; fetch it with
  `curl -L -o parinfer-rust/parinfer-rust-darwin.so https://github.com/justinbarclay/parinfer-rust-emacs/releases/download/v0.4.7/parinfer-rust-darwin.so`.
  Disable `electric-pair` *locally* only; the package's own fix disables it globally.
- Structural edits (paredit commands, drag, raise) are listed in
  `parinfer-rust-treat-command-as` as "paren", or parinfer undoes them.
- clojure-lsp takes ~9 s to start on boundary (5 s re-analysis of all sources). Hence
  `eglot-sync-connect nil` (no freeze) and `eglot-autoshutdown nil` (start once per session,
  ~1.6 GB per project; free with `M-x eglot-shutdown-all`).
- boundary's `.dir-locals.el` sets CIDER refresh fns; those values are marked safe in
  `init-clojure.el`. Jack in from boundary's own `src/`, not `examples/shop` (own deps.edn).

**.env (`init-env.el`)**
- Loaded per buffer into `process-environment` via `after-change-major-mode-hook`
  (+ `cider-connected-hook`, CIDER sets the REPL dir late).
- Cache checks file mtime: an edited `.env` used to be served stale (wrong JWT_SECRET).
- `my/dotenv-skip-vars` skips Docker-only vars (`JAVA_OPTS` with `-XX:+UseContainerSupport`
  crashed the macOS JVM).
- vterm starts its shell before that hook runs: `my/vterm-in` passes `.env` explicitly.

**Python (`init-python.el`, venv in `init-env.el`)**
- LSP = `rass -- pyright-langserver --stdio -- ruff server` (both start fast, so rass' 3 s
  timeout is fine here). Formatting goes to Ruff; output equals `ruff format`.
- `.venv` in the project root is part of the project env (`my/project-env-vars`): sets
  `VIRTUAL_ENV`, `PATH`, buffer-local `exec-path` and `python-shell-virtualenv-root`.
- Helpers like `process-lines` run in a temp buffer without the buffer-local `exec-path`:
  Django commands resolve the venv Python first (`my/django-python`) and use its full path.
- `python-mode` is remapped to `python-ts-mode`; keys go on `python-base-mode-map`.
- `treesit-language-source-alist` needs `(require 'treesit)` before `add-to-list`.

**JavaScript / TypeScript (`init-js.el`)**
- TypeScript 7 (native) no longer ships `tsserver`, so `typescript-language-server` can't work
  with it. LSP = `tsc --lsp --stdio` (TS 7's own server, also handles JS).
- That server reports errors via *pull* diagnostics, which Eglot only supports since 1.20.
  Emacs 30 bundles 1.17, so `init-lsp.el` installs Eglot from ELPA (1.24). Retested all
  languages on it; CSS now also gets Tailwind's suggestions.
- Grammars pinned to v0.21.x (javascript, typescript, tsx, jsdoc, json) for Emacs 30's modes.

**Dired (`init-dired.el`)**
- In the user's shell `ls` is eza; Dired must use GNU ls, so `insert-directory-program` is
  set to `gls` (coreutils) for `--group-directories-first`.
- `delete-by-moving-to-trash` uses macOS' own trash (`system-move-file-to-trash`); tests
  can't list `~/.Trash` (macOS privacy), so check the file left its folder instead.

**Treemacs (`init-tree.el`)**
- Plain `treemacs` asks "Project root:" on an empty workspace; `my/project-tree` (`SPC o p`)
  uses `treemacs-add-and-display-current-project-exclusively` instead (no prompt).
- Follow mode runs on an *idle* timer: tests must open files via keystrokes
  (`unread-command-events`), not from a timer, or the tree never follows.
- State file `.cache/treemacs-persist` is git-ignored.
- treemacs-evil has its own evil state (`treemacs`) without the leader: `SPC` there is bound
  to normal state's `<leader>` keymap (same object, so new SPC keys show up there too).

**Completion / UI**
- Search commands use a side-by-side vertico layout (`vertico-multiform`); list is 40% of
  the frame, capped at `my/vertico-list-max-width` (90) for full screen. The file finder
  uses its own category `project-finder`: Emacs 30's project *picker* also uses
  `project-file`, so that category would split the picker too.
- Preview buffers (eww) and terminals close with `SPC b d` via `my/kill-buffer`.
  Claude buffers are only hidden: killing one sends SIGHUP ("exited with error code 129").

**Terminal**
- vterm is the main terminal (30× faster than eat). Its module is built against Homebrew's
  libvterm: `brew install cmake libvterm`, then in `elpa/vterm-*/build`:
  `cmake -DUSE_SYSTEM_LIBVTERM=yes .. && make`. (Bundled libvterm needs GNU `glibtool`.)
- eat (fallback): macOS ncurses (2015) can't read eat's terminfo format, so the shell ran in
  dumb mode (Backspace didn't redraw). `my/eat-use-macos-terminfo` compiles it with `tic`.

**LSP / Tailwind**
- CSS server only formats when started with `:initializationOptions (:provideFormatter t)`.
- Eglot's glob parser rejects patterns like `{a,b.*.c}`; Tailwind sends two and then gave up.
  An advice on `eglot-register-capability` drops unreadable patterns.
- Tailwind + daisyUI completion works in CSS via `rass` (rassumfrassum, `uv tool install`).
  **Parked for Clojure hiccup**: rass waits only 3 s for `initialize`; clojure-lsp needs ~9 s,
  so rass drops it and Clojure completion breaks. `rass/slow-start.py` raises that timeout
  but its last test hung. Resume when the boundary admin rework (daisyUI) starts.

**Keychain secrets**
- Store as *internet* passwords (`add-internet-password -a <account> -s <server>`). Emacs'
  `macos-keychain-generic` backend matches generic entries by `-c`, not `-s`, so
  `add-generic-password -s` entries were never found (Linear "key not set").

**Linear (`init-linear.el`)**
- linear.org layout comes from an `:around` advice on `linear-emacs--build-org-content`:
  `* Project / ** Status / *** TODO BOU-123 Title`. Sync only reads level-3 TODO state +
  properties, so the grouping and ticket number in the title are safe.
- Don't call `linear-emacs-enable-org-sync`: it hooks the buffer current at load time
  (never linear.org), and its after-save hook re-sends *every* ticket's state.
  `my/linear-org-sync-setup` adds only the state-change hook, in linear.org.
- Its sync handles one ticket only when `this-command` is `org-todo`; otherwise it walks
  the whole file. `my/org-todo-choose` (`, t`) binds it accordingly.
- `org-todo` with `C-u` means "log note" in Org 9.7, not "choose state".
- Don't bind `linear-emacs-list-issues-by-project`: it shows nothing, fetches only *my*
  tickets and overwrites linear.org. `SPC l p` is `my/linear-project-board` (own buffer,
  all open tickets via `project.issues` filtered on state type started/unstarted/backlog).

**Jira + ticket backends (`init-jira.el`, `init-tickets.el`)**
- `SPC l` commands are `my/tickets-*` dispatchers: buffer's own system first (jira/linear
  minor modes, linear.org), else the project's choice in `tickets-backends.eld`, else ask.
- Jira Cloud via REST API **v2** (wiki markup, not v3's ADF); pandoc `-f jira`/`-t jira`
  converts to/from Markdown, one pandoc call per ticket view (split marker).
- Search uses `POST search/jql` with `nextPageToken` (old `/search` is retired).
- Auth: Keychain *internet* password, server = the site, account = e-mail; auth-source
  returns the account as `:user`. Site is `my/jira-site` (asked once, custom.el).
- jira.org is generated; `, t` / `, v` there come from `my/jira-org-mode` (minor-mode keys
  beat org-mode-map's `, t` = `my/org-todo-choose`, which is Linear-only).
- Tested with mocked responses only, plus a real request to a bogus site (error path).

**Forge (GitHub PRs/issues)**
- Forge does not use `gh`; it reads a token from the Keychain (`auth-sources` is set in
  `init-core.el`): *internet* password, server `api.github.com`, account `<github-user>^forge`
  (`security add-internet-password -U -a '<user>^forge' -s api.github.com -w "$(gh auth token)"`). It needs the
  scopes `repo`, `user` and `read:org`; the token from `gh auth token` works once `user`
  is added (`gh auth refresh -h github.com -s user`).
- Forge finds the GitHub user via git config: `git config --global github.user <user>` and
  `git config --global github.api.github.com.user <user>` (set for thijs-creemers).
- Each repo is added once with `M-x forge-add-repository` (fills `forge-database.sqlite`,
  a local cache of PRs/issues; git-ignored because it holds private repo data).
- `SPC g c` (`my/gh-pr-checks`) runs `gh pr checks --watch` in vterm, in a bottom side window.

**Magit / Claude**
- Esc closes transient popups; commit window `, ,` / `, k`; `q` restores the window layout.
- claude-code-ide: diffs open in ediff; `SPC a a` / `SPC a d` answer its quit + "Accept the
  changes?" prompts. Backend is vterm.
- Claude window: `my/claude-term-mode` (switched on via advice on
  `claude-code-ide--setup-terminal-keybindings`) sends Claude's shortcuts (Esc, C-c, S-Tab,
  C-r, C-o, ...) to the terminal via evil *insert* aux keymaps, which beat evil's own
  insert map and vterm's C-c prefix. Only `C-z` / `C-\` stay for Emacs (normal state); a
  header line in the Claude window shows this (users kept pressing Esc, which goes to Claude).
- Claude redraws with ESC[2J; libvterm erases the screen instead of pushing it into the
  scrollback, so only one screenful was kept. `my/claude-keep-scrollback` (advice on
  `vterm--filter`, depth -90 = before the anti-flicker queue) turns ESC[2J into "scroll the
  screen up" and drops ESC[3J, in Claude windows only.

**Emacs Client.app**
- emacs-plus' AppleScript ran `open -a Emacs`, which launched the separate
  `/Applications/Emacs.app` → a second standalone Emacs next to the server window.
  Patched to `open -a /opt/homebrew/opt/emacs-plus@31/Emacs.app` and re-signed
  (`codesign --force --deep -s -`). Backup: `backup-Emacs-Client.app`. A brew reinstall can
  undo this (the upgrade to @31 did); symptom is "two clients". Re-patch: `osadecompile`
  `Contents/Resources/Scripts/main.scpt`, fix the path, `osacompile`, re-sign.

## External tools this config uses

Homebrew: `clojure-lsp` (native), `pyright`, `marksman`, `pandoc`, `asciidoctor`, `cmake`,
`libvterm`, `JetBrains Mono Nerd Font` (cask). npm: `vscode-langservers-extracted`,
`@tailwindcss/language-server`, `bash-language-server`, `typescript` (7.x, for `tsc --lsp`). Homebrew also: `shellcheck`, `shfmt`, `ruff`. uv: `rassumfrassum`. Optional: `yaml-language-server`.
Linear API key and the Forge GitHub token live in the macOS Keychain (`security add-internet-password -a apikey
-s api.linear.app -w <KEY>`), never in this repo.
