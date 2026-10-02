# Emacs Cheatsheet

Open this file anytime with `SPC h k`.

Notation: `SPC` = space (leader key, global commands), `,` = local leader (language commands), `C-x` = Ctrl+x, `M-x` = Cmd+x (or Esc then x).

---

## Survival

| Keys          | Action                                    |
|---------------|-------------------------------------------|
| `Esc` / `C-g` | Cancel anything (C-g works everywhere)    |
| `M-x`         | Run any command by name                   |
| `SPC q q`     | Quit Emacs                                |
| `SPC` + wait  | which-key popup shows next possible keys  |

---

## Leader keys (SPC)

### Find (same keys as Telescope in nvim)

| Keys      | Action                                           |
|-----------|--------------------------------------------------|
| `SPC f f` | Fuzzy find file in project, with live preview    |
| `SPC f F` | Browse / create file by path                     |
| `SPC f g` | Live grep in project (ripgrep)                   |
| `SPC f b` | Buffers                                          |
| `SPC f r` | Recent files                                     |
| `SPC f h` | Help for function / variable                     |
| `SPC f d` | Diagnostics (errors / warnings)                  |
| `SPC f s` | Symbols in file (functions, defs)                |
| `SPC /`   | Search in current buffer                         |

Fuzzy: `icl` finds `init-clojure.el`. Words in any order: `clj core`.
Start a word with `!` to exclude: `core !test`.

### Buffers and project

| Keys      | Action                      |
|-----------|-----------------------------|
| `SPC b b` | Switch buffer               |
| `H` / `L` | Previous / next file buffer (as in nvim) |
| `SPC b p` / `SPC b n`, `[b` / `]b` | Same: previous / next |
| `SPC b d` | Delete (close) buffer, closes previews too |
| `SPC b s` | Save buffer (`:w` works too)|
| `SPC p f` | Find file in project        |
| `SPC p p` | Switch project, then find file |
| `SPC p e` | Reload `.env` after editing it  |

A project = the git repo of the current file. Get in by opening any file in it,
via `SPC p p`, or `emacsclient -c ~/path/to/repo`. Add all repos under a folder at once:
`M-x project-remember-projects-under`.

`.env` in the project root is loaded automatically, per project: the REPL (`, c j`),
LSP, `run-python` and `compile` all see those variables. Other projects don't.

### Windows

| Keys      | Action              |
|-----------|---------------------|
| `SPC w v` | Split right         |
| `SPC w s` | Split below         |
| `SPC w d` | Close window        |
| `SPC w w` | Next window         |
| `C-w h/j/k/l` | Move to window left/down/up/right (vim style) |

### Code (LSP, all languages)

| Keys      | Action                              |
|-----------|-------------------------------------|
| `gd`      | Go to definition                    |
| `C-o`     | Jump back (after `gd`)              |
| `K`       | Docs for symbol at point            |
| `SPC c u` | Find usages / references            |
| `SPC c a` | Code actions (quick fixes)          |
| `SPC c r` | Rename symbol everywhere            |
| `SPC c f` | Format buffer                       |
| `SPC c d` | List errors / warnings              |
| `]d` / `[d` | Next / previous error (flymake)  |

### Help

| Keys      | Action                         |
|-----------|--------------------------------|
| `SPC h k` | This cheatsheet                |
| `SPC h r` | Reload config                  |
| `SPC h b` | What does this key do?         |
| `SPC h f` | Describe function              |
| `SPC h v` | Describe variable              |

---

## Clojure (CIDER)

Language keys live under `,` (local leader), same as Conjure in nvim.
Start: open a `.clj` file in a project with `deps.edn` / `project.clj`, then `, c j`.

### Connect

| Keys    | Action                                 |
|---------|----------------------------------------|
| `, c j` | Jack in: start Clojure REPL            |
| `, c J` | Jack in: start ClojureScript REPL      |
| `, c s` | Connect to already running nREPL       |
| `, c d` | Disconnect / quit REPL                 |

### Evaluate

| Keys    | Action                                 |
|---------|----------------------------------------|
| `, e e` | Eval current form (around cursor)      |
| `, e r` | Eval root form (top-level `defn`)      |
| `, e w` | Eval word under cursor                 |
| `, e b` | Eval whole buffer                      |
| `, e n` | Eval ns form                           |

### REPL window, refresh, system

| Keys    | Action                                           |
|---------|--------------------------------------------------|
| `, l g` | Go to REPL                                       |
| `, l q` | Close REPL window (REPL keeps running)           |
| `, r r` | Refresh changed namespaces (halt before, go after) |
| `, r a` | Refresh all namespaces                           |
| `, r c` | Clear refresh cache and refresh                  |
| `, r s` | `(user/reset)`                                   |
| `, r g` | `(user/go)`                                      |
| `, r h` | `(user/halt)`                                    |

### Parinfer (indent mode, as in nvim)

Indentation drives the parens: indent a line and parens move with it.
Starts on first edit; asks before fixing badly indented files.

| Keys    | Action                                   |
|---------|------------------------------------------|
| `, p t` | Toggle parinfer on/off in this buffer    |
| `, p m` | Switch mode: indent / smart / paren      |

### Structural editing (same keys as nvim-paredit)

Form = list around the cursor. Element = thing under the cursor.

| Keys          | Action                                        |
|---------------|-----------------------------------------------|
| `>)` / `<)`   | Slurp / barf forward: `(a b) c` <-> `(a b c)` |
| `<(` / `>(`   | Slurp / barf backward                         |
| `>e` / `<e`   | Drag element right / left                     |
| `>f` / `<f`   | Drag form right / left                        |
| `, o`         | Raise form (replace parent with it)           |
| `, O`         | Raise element                                 |
| `, @`         | Splice: remove parens around cursor           |
| `af` / `if`   | Text object: a form / inside form (`daf`, `cif`, `yaf`) |
| `ae` / `ie`   | Text object: element (`die`, `cie`)           |

### Test and docs

| Keys    | Action                   |
|---------|--------------------------|
| `, t c` | Run test at cursor       |
| `, t n` | Run namespace tests      |
| `, t a` | Run all project tests    |
| `, t f` | Rerun failed tests       |
| `K`     | CIDER docs for symbol    |
| `gd`    | Go to definition         |

### In the REPL buffer

| Keys          | Action                      |
|---------------|-----------------------------|
| `RET` (insert)| Evaluate if form complete and cursor at end, else new line |
| `M-p` / `M-n` | Previous / next history     |
| `C-c C-c`     | Interrupt running eval      |
| `C-c C-o`     | Clear last output           |

Tip: in error (stacktrace) buffers press `q` to close.

---

## Python

LSP: pyright. REPL: python3. Same `,` layout as Clojure.

| Keys    | Action                                  |
|---------|-----------------------------------------|
| `, c j` | Start Python REPL                       |
| `, e e` | Send statement (visual: selection)      |
| `, e r` | Send function / class                   |
| `, e b` | Send buffer                             |
| `, l g` | Go to REPL                              |

Tip: activate your virtualenv before starting Emacs, or pyright won't find packages.

---

## YAML

LSP needs `npm i -g yaml-language-server`. Then validation and completion work, also for
schemas like GitHub Actions, docker-compose and k8s.

---

## Markdown

`.md` files open in GitHub flavor: tables, task lists, colored code blocks.

| Keys  | Action                                   |
|-------|------------------------------------------|
| `, p` | Live preview side by side (toggle)       |
| `, o` | Open rendered page in browser            |
| `, h` | Hide / show markup (`**`, `#`, links)    |
| `, l` | Insert link                              |
| `, t` | Align table under cursor                 |
| `, x` | Toggle checkbox `- [ ]`                  |
| `, i` | Jump to heading                          |
| `TAB` | Fold / unfold heading                    |

Tip: in a table, `TAB` in insert mode jumps to the next cell and aligns.

---

## AsciiDoc

`.adoc` / `.asciidoc` files. Rendering uses asciidoctor.

| Keys  | Action                                         |
|-------|------------------------------------------------|
| `, p` | Preview side by side (refreshes on every save) |
| `, o` | Open rendered page in browser (full styling)   |
| `, P` | Export PDF next to the file and open it        |
| `, i` | Jump to heading                                |

Tip: close the preview with `SPC b d` on it, or on the source file.

---

## Git (Magit)

| Keys        | Action                                            |
|-------------|---------------------------------------------------|
| `SPC g g`   | Git status (Magit). Press `?` there for all keys  |
| `SPC g b`   | Blame                                             |
| `SPC g f`   | History of this file                              |
| `SPC g V`   | Diff: this branch vs main                         |
| `SPC g w`   | Worktrees (create, switch, delete)                |
| `]h` / `[h` | Next / previous changed hunk                      |
| `SPC g p`   | Preview hunk                                      |
| `SPC g s`   | Stage hunk                                        |
| `SPC g r`   | Revert hunk                                       |

In Magit status: `s` stage, `u` unstage, `c c` commit, `P p` push, `F p` pull,
`b b` switch branch, `TAB` expand, `q` close (restores your window layout).
Key popups (after `c`, `P`, `b`, ...): `Esc` closes them.
Commit message window: type message, `Esc`, then `, ,` commit or `, k` cancel.
Colored bars in the margin show added / changed / deleted lines.

---

## Terminal and tasks

| Keys      | Action                                              |
|-----------|-----------------------------------------------------|
| `SPC o t` | Terminal in project root (reused when open)         |
| `SPC o T` | Terminal in current directory                       |
| `SPC o u` | Open a URL in the browser (pre-filled from cursor)  |
| `gx`      | Open URL / Markdown link under cursor in browser    |
| `SPC t b` | Pick and run a bb task (nearest `bb.edn`)           |

Terminal = vterm (fast, native). Gets the project's `.env`. `SPC o t` reuses the
project terminal if it is open. Fallback: `M-x eat` (pure Lisp, slower).
Terminal starts in insert mode: all keys go to the shell (`C-w` deletes a word there).
`Esc` = normal mode: now `SPC`, `C-w h/l`, scrolling, `y` all work; `i` to type again.
Close: `Esc SPC b d` (no questions), or type `exit`.
Programs that need Esc themselves (vim in the terminal): `C-c C-z` toggles where Esc goes.
bb tasks run in a compile buffer: errors are clickable, `q` closes.

---

## CSS / SCSS

Errors as you type (Tailwind v4 `@theme`, `@apply`, ... are allowed), completion,
colors shown in their own color. In Tailwind projects, `@apply bt` also completes
Tailwind + daisyUI classes (`btn`, `btn-primary`, ...). Not yet in `.clj` hiccup.

| Keys          | Action                                        |
|---------------|-----------------------------------------------|
| `K`           | Docs for property under cursor                |
| `SPC c f`     | Format file (2 spaces)                        |
| `SPC c d`, `]d` / `[d` | List errors / next / previous error  |
| `SPC f s`     | Jump to selector                              |
| `C-j` (insert)| Expand Emmet abbreviation                     |

Emmet: `d:f` display: flex, `jc:c` justify-content: center, `ai:c` align-items: center,
`m10` margin: 10px, `p10-20` padding: 10px 20px, `fz14` font-size: 14px,
`w100p` width: 100%, `bgc#f80` background-color, `pos:a` position: absolute.
In HTML: `div.card>p*3` + `C-j`.

---

## Claude Code

Claude runs in a side window (right) and is connected to Emacs: it sees the file and
selection you are on, can use xref / imenu / LSP, and shows its edits as diffs.

| Keys               | Action                                          |
|--------------------|-------------------------------------------------|
| `SPC a c`          | Start Claude for this project, or show / hide it |
| `SPC a f`          | Jump into the Claude window                     |
| `SPC a s` (visual) | Send selection to Claude                        |
| `SPC a p`          | Type a prompt in the minibuffer                 |
| `SPC a a`          | Accept Claude's change (in the diff view)       |
| `SPC a d`          | Reject Claude's change                          |
| `SPC a e`          | Interrupt Claude (sends `Esc` to it)            |
| `SPC a r`          | Resume an older conversation                    |
| `SPC a C`          | Continue the last conversation                  |
| `SPC a q`          | Stop Claude                                     |
| `SPC a m`          | Menu with all commands                          |

In the Claude window: type in insert mode, `S-RET` = new line in the prompt,
`Esc` = vim normal mode (then `SPC ...`, `C-w h` work; `i` to type again).
`C-c C-x` drops the file/selection Claude currently sees.

---

## Linear

| Keys      | Action                                  |
|-----------|-----------------------------------------|
| `SPC l l` | My open issues (Org file `~/org/linear.org`) |
| `SPC l p` | Issues of one project                   |
| `SPC l n` | New issue                               |

Change an issue's TODO state in the Org file (`t` on the heading) and it syncs back
to Linear. Setup once, API key from Linear settings > Security & access:
`security add-generic-password -a apikey -s api.linear.app -w <KEY>`

---

## Vim extras (evil plugins)

| Keys             | Action                                      |
|------------------|---------------------------------------------|
| `gcc`            | Toggle comment on line                      |
| `gc` + motion    | Comment motion, e.g. `gcap` = paragraph     |
| `ys` + motion + char | Surround, e.g. `ysiw"` = quote word     |
| `cs` + old + new | Change surround, e.g. `cs"'`                |
| `ds` + char      | Delete surround, e.g. `ds(`                 |
| `S` + char (visual) | Surround selection                       |
| `C-r`            | Redo                                        |
| `C-u` / `C-d`    | Scroll half page up / down                  |

---

## Completion

### Minibuffer (M-x, find file, switch buffer)

| Keys              | Action                                |
|-------------------|---------------------------------------|
| type words        | Words match in any order: `ini ev`    |
| `C-j` / `C-k`     | Next / previous candidate             |
| `RET`             | Choose                                |
| `M-RET`           | Use exactly what you typed (new file) |
| `Esc`             | Cancel                                |

### Code popup (appears while typing)

| Keys              | Action               |
|-------------------|----------------------|
| `C-j` / `C-k`     | Next / previous      |
| `RET` / `TAB`     | Insert               |
| `Esc`             | Close popup          |

---

## Tips

- **Where is a setting?** Each topic has its own file in `lisp/`:
  `init-ui.el` (theme, font), `init-evil.el` (all leader keys), `init-clojure.el`, etc.
- **Change font / size:** `my/fonts` and `my/font-size` in `lisp/init-ui.el`. Temporary: `C-x C-+` / `C-x C--`.
- **Status bar:** vim mode, file (relative to project), git branch, LSP, errors.
  Narrow windows hide branch/path. Settings: `doom-modeline` in `lisp/init-ui.el`.
- **Other theme flavor:** `catppuccin-flavor` in `init-ui.el` (mocha, macchiato, frappe, latte).
- **Reload config:** `SPC h r` (also works in the daemon). Removed settings need a restart:
  `brew services restart emacs-plus@30`, then `emacsclient -c`. (Server runs as a brew
  service; `emacs --daemon` fails while it runs.)
- **Update packages:** `M-x package-upgrade-all`.
- **LSP not working?** `M-x eglot` starts it manually and shows an error if the server is
  missing. `M-x eglot-reconnect` restarts a stuck server.
- **LSP startup:** clojure-lsp needs ~9 s per project the first time (it analyzes all code);
  Emacs stays usable meanwhile. It keeps running after that (~1.6 GB per project).
  Free memory: `M-x eglot-shutdown` (one) or `M-x eglot-shutdown-all`.
- **Add a new language:** copy `lisp/init-yaml.el`, rename, add `(require 'init-xxx)` in `init.el`.
