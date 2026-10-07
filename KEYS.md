# Emacs Cheatsheet

Open this file anytime with `SPC h k`.

Notation: `SPC` = space (leader key, global commands), `,` = local leader (language commands), `C-x` = Ctrl+x, `M-x` = Cmd+x (or Esc then x).

---

## Survival

| Keys          | Action                                    |
|---------------|-------------------------------------------|
| `Esc` / `C-g` | Cancel anything (C-g works everywhere)    |
| `Cmd-V` / `Cmd-C` | Paste / copy selection, like other Mac apps (also in terminals and prompts) |
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
| `SPC f s` | Functions / headings in this file (jump, with preview) |
| `SPC /`   | Search in current buffer                         |

Fuzzy: `icl` finds `init-clojure.el`. Words in any order: `clj core`.
Start a word with `!` to exclude: `core !test`.

**Change many files at once:** `SPC f g`, search, then `C-c C-e` = results as a list.
`i` makes it editable: change the lines like normal text (`:s/old/new/`, macros, ...),
then `Esc` and `, ,` writes every change to its file (`, k` cancels).

### Buffers and project

| Keys      | Action                      |
|-----------|-----------------------------|
| `SPC b b` | Switch buffer; in that list `C-d` closes the highlighted buffer (list stays open) |
| `SPC b i` | Buffer list for bulk cleanup: `d` flag, `x` close flagged (or `m` mark, `D` close marked), `u` unmark, `q` quit |
| `SPC b B` | Switch buffer from *all* tabs (`SPC b b` shows this tab's buffers) |
| `SPC b u` | Undo history as a tree: `h`/`l` back/forward in time, `j`/`k` other branch, `RET` keep, `q` cancel |
| `H` / `L` | Previous / next file buffer (as in nvim) |
| `SPC b p` / `SPC b n`, `[b` / `]b` | Same: previous / next |
| `SPC b d` | Delete (close) buffer, closes previews too |
| `SPC b s` | Save buffer (`:w` works too)|
| `SPC p f` | Find file in project        |
| `SPC p p` | Switch project, then find file |
| `SPC p e` | Reload `.env` after editing it  |
| `SPC p d` | Remove a project from the list (choose it) |
| `SPC p c` | Clean up: projects whose folder is gone, temp folders, package sources |
| `SPC p t` | Switch to another project tab |
| `SPC p k` | Close this project tab and its buffers |
| `gt` / `gT` | Next / previous tab |

**One tab per project:** `SPC p p` opens a project in its own tab (shown at the top once
there are 2+ tabs), with its own windows and buffer list. Switching tabs restores each
project's layout (code, Claude, REPL).

A project = the git repo of the current file. Get in by opening any file in it,
via `SPC p p`, or `emacsclient -c ~/path/to/repo`. Add all repos under a folder at once:
`M-x project-remember-projects-under`. Temp folders and package sources are never added,
and projects whose folder was deleted (e.g. a removed worktree) drop out at startup.

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
| `SPC c s` | Functions / headings in this file (same as `SPC f s`) |
| `SPC c a` | Code actions (quick fixes)          |
| `SPC c r` | Rename symbol everywhere            |
| `SPC c f` | Format buffer                       |
| `SPC c d` | List errors / warnings              |
| `]d` / `[d` | Next / previous error (flymake)  |

### Look (UI)

| Keys      | Action                         |
|-----------|--------------------------------|
| `SPC u t` | Theme: `auto` (follow macOS light/dark), `light` or `dark`; remembered |
| `SPC u p` | Presentation mode on/off: big font (22pt) everywhere, absolute line numbers |

Auto switches by itself when macOS changes (also macOS "Auto" appearance by daylight).
Light = Catppuccin Latte, dark = Catppuccin Mocha. Fine-tune the size in presentation
mode with `C-x C-M-+` / `C-x C-M--` (all windows), or `C-x C-+` / `C-x C--` (this buffer).

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

### Format (cljfmt, via clojure-lsp)

Only on demand, never on save. Rules: cljfmt defaults (or the project's `.cljfmt.edn`).

| Keys             | Action                                              |
|------------------|-----------------------------------------------------|
| `, =`            | Format the top-level form under the cursor          |
| `, =` (visual)   | Format the selection                                |
| `SPC c f`        | Format the whole file                               |

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

LSP: pyright (types, completion) + Ruff (lint, quick fixes, imports, formatting).
A project's `.venv` (as `uv` creates it) is used automatically: LSP, REPL, tests,
`manage.py` and the terminal all run its Python. No activating needed.
Same `,` layout as Clojure.

| Keys      | Action                                          |
|-----------|-------------------------------------------------|
| `, c j`   | Start Python REPL                               |
| `, e e`   | Send statement (visual: selection)              |
| `, e r`   | Send function / class                           |
| `, e b`   | Send buffer                                     |
| `, l g`   | Go to REPL                                      |
| `, t c`   | Run the test under the cursor (pytest)          |
| `, t n`   | Run this test file                              |
| `, t a`   | pytest menu: all tests, options                 |
| `, t f`   | Rerun failed tests                              |
| `, t r`   | Repeat last test run                            |
| `SPC c f` | Format with Ruff                                |
| `SPC c a` | Quick fix (remove unused import, sort imports, ...) |

### Django

| Keys    | Action                                                       |
|---------|--------------------------------------------------------------|
| `, d m` | Pick a `manage.py` command (migrate, makemigrations, ...)    |
| `, d r` | `runserver` in a terminal at the bottom (`SPC b d` stops it) |
| `, d s` | Django shell as the REPL (`, e e` etc. send code into it)    |

Templates (`templates/**/*.html`): `{% %}` / `{{ }}` highlighting, Emmet with `C-j`.

---

## YAML

LSP needs `npm i -g yaml-language-server`. Then validation and completion work, also for
schemas like GitHub Actions, docker-compose and k8s.

---

## Shell scripts (Bash / sh / Zsh)

`.sh`, `.bash` and scripts with a bash/sh shebang: tree-sitter colors (also variables
inside strings), ShellCheck warnings as you type, completion.
`.zshrc` / `.zsh`: colors only (no checker exists for zsh).

| Keys      | Action                                            |
|-----------|---------------------------------------------------|
| `K`       | Docs for command under cursor (man page / help)   |
| `]d` / `[d` | Next / previous ShellCheck warning              |
| `SPC c a` | Quick fix (e.g. add the missing quotes)           |
| `SPC c f` | Format with shfmt                                 |
| `gd`      | Go to function / variable definition              |

---

## Markdown

`.md` files open in GitHub flavor: tables, task lists, colored code blocks.

| Keys  | Action                                   |
|-------|------------------------------------------|
| `, p` | Live preview side by side (toggle)       |
| `, o` | Preview in browser, looks like GitHub (refreshes on every save) |
| `, h` | Hide / show markup (`**`, `#`, links)    |
| `, l` | Insert link                              |
| `, t` | Align table under cursor                 |
| `, x` | Toggle checkbox `- [ ]`                  |
| `, i` | Jump to heading                          |
| `TAB` | Fold / unfold heading                    |

Tip: in a table, `TAB` in insert mode jumps to the next cell and aligns.

Previews: `, o` uses GitHub's own stylesheet (light/dark follows macOS) and reloads by
itself after each save, keeping the scroll position. `, p` stays inside Emacs, but Emacs'
browser can't do CSS, so it only resembles GitHub (font, heading sizes).

---

## AsciiDoc

`.adoc` / `.asciidoc` files. Rendering uses asciidoctor.

| Keys  | Action                                         |
|-------|------------------------------------------------|
| `, p` | Preview side by side (refreshes on every save) |
| `, o` | Preview in browser, looks like GitHub (refreshes on every save) |
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

### GitHub: pull requests, issues, CI (Forge + gh)

| Keys      | Action                                                   |
|-----------|----------------------------------------------------------|
| `SPC g P` | Pull requests of this repo (`RET` opens one)             |
| `SPC g I` | Issues of this repo                                      |
| `SPC g n` | New PR from the current branch (`, ,` submits)           |
| `SPC g o` | Open repo / PR / issue in the browser                    |
| `SPC g c` | Live CI status of this branch's PR (bottom window)       |
| `@` (Magit) | Forge menu: pull new data, check out a PR as worktree, ... |

Review someone's PR: `SPC g P`, put the cursor on it, `@`, then the worktree checkout
option; it opens as its own project. Pull fresh data: `@ f f` in Magit.
Setup once per repo: `M-x forge-add-repository` in that repo. Token: see AGENTS.md.

---

## Project tree (Treemacs)

`SPC o p` shows / hides a tree of the current project on the left. It follows the file
you are editing and switches along with the project. Git colors show changed / new files.

| Keys          | Action                                             |
|---------------|----------------------------------------------------|
| `j` / `k`     | Down / up                                          |
| `TAB`         | Open / close folder                                |
| `RET`         | Open file (or open / close folder)                 |
| `o v` / `o h` | Open file in a split side by side / below          |
| `c f` / `c d` | New file / new folder                              |
| `R`           | Rename                                             |
| `m`           | Move                                               |
| `y f`         | Copy file                                          |
| `y r` / `y a` | Copy relative / absolute path                      |
| `d`           | Delete                                             |
| `t h`         | Show / hide dotfiles                               |
| `g r`         | Refresh                                            |
| `?`           | All keys                                           |
| `SPC ...`     | All leader keys work in the tree too (`SPC o p` closes it) |
| `q`           | Close the tree                                     |

`C-w l` goes from the tree to your code, `C-w h` back to the tree.

---

## Files and folders (Dired)

Open: `SPC o d` = folder of the current file (cursor on it), `SPC o D` = project root.
Folders are listed first; `(` shows / hides details (size, date, permissions).

### Move around

| Keys        | Action                                    |
|-------------|-------------------------------------------|
| `j` / `k`   | Down / up                                 |
| `RET`       | Open file or folder                       |
| `-`         | Up to the parent folder                   |
| `E`         | Open with the macOS app (like double-click) |
| `g r`       | Refresh                                   |
| `q`         | Close                                     |

### Change files

Commands work on the **marked** files, or on the file under the cursor if none are marked.

| Keys      | Action                                                      |
|-----------|-------------------------------------------------------------|
| `R`       | Rename or move (type a new name, or a folder to move into)  |
| `C`       | Copy                                                        |
| `D`       | Delete (goes to the macOS Trash; Finder "Put Back" restores)|
| `+`       | New folder                                                  |
| `Y`       | Copy file name                                              |

New file: `SPC f F`, type the name, `M-RET`.

### Mark several files

| Keys      | Action                                         |
|-----------|------------------------------------------------|
| `m`       | Mark (cursor moves to the next file)           |
| `u` / `U` | Unmark this / unmark all                       |
| `t`       | Invert marks                                   |
| `% m`     | Mark by regex, e.g. `\.log$`                   |
| `d` then `x` | Flag for deletion, then delete all flagged  |

### Rename many files at once: edit the list as text

`i` makes the file names editable. Change them with normal vim editing (`cw`, `:s/old/new/`,
visual block), then `Esc` and `, ,` to apply, or `, k` to cancel.

### Move or copy between two folders

Open two Dired windows side by side (`SPC w v`, then `SPC o d` / `-` in the other one).
`R` or `C` now suggest the *other* window's folder as the destination.

---

## Terminal and tasks

| Keys      | Action                                              |
|-----------|-----------------------------------------------------|
| `SPC o t` | Terminal in project root (reused when open)         |
| `SPC o T` | Terminal in current directory                       |
| `SPC o u` | Open a URL in the browser (pre-filled from cursor)  |
| `gx`      | Open URL / Markdown link under cursor in browser    |
| `SPC t b` | Pick and run a bb task (nearest `bb.edn`)           |
| `SPC t n` | Pick and run an npm script (nearest `package.json`) |

Terminal = vterm (fast, native). Gets the project's `.env`. `SPC o t` reuses the
project terminal if it is open. Fallback: `M-x eat` (pure Lisp, slower).
Terminal starts in insert mode: all keys go to the shell (`C-w` deletes a word there).
`Esc` = normal mode: now `SPC`, `C-w h/l`, scrolling, `y` all work; `i` to type again.
Close: `Esc SPC b d` (no questions), or type `exit`.
Programs that need Esc themselves (vim in the terminal): `C-c C-z` toggles where Esc goes.
bb tasks run in a compile buffer: errors are clickable, `q` closes.

---

## JavaScript / TypeScript / JSON

`.js` `.jsx` `.mjs` `.cjs`, `.ts`, `.tsx`, `.json`: tree-sitter colors. LSP is TypeScript 7's
own server (`tsc --lsp`): completion, type errors as you type, hover (`K`), `gd`, find usages.

| Keys      | Action                                             |
|-----------|----------------------------------------------------|
| `SPC c f` | Format (2 spaces)                                  |
| `SPC c a` | Quick fix / organize imports                       |
| `SPC c r` | Rename everywhere                                  |
| `]d` / `[d` | Next / previous error                            |
| `C-j` (insert) | Emmet in JSX/TSX: `div.card` → `<div className="card">` |
| `SPC t n` | Run an npm script                                  |

Language menu under `,` (same layout as Clojure / Python):

| Keys      | Action                                                        |
|-----------|---------------------------------------------------------------|
| `, c j`   | Start Node REPL (`, l g` = go to it)                          |
| `, e e`   | Send expression before the cursor to the REPL (visual: selection) |
| `, e b`   | JS: send buffer to the REPL. TS: run the file                 |
| `, r r`   | Run this file with node (TypeScript too; Node strips types)   |
| `, t n`   | Tests in this file (Vitest / Jest / `node --test`, auto-detected) |
| `, t a`   | All tests                                                     |
| `, o`     | Organize imports                                              |
| `, n`     | Run an npm script                                             |

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
| `SPC a R`          | Redraw the Claude window (when blank / garbled) |
| `SPC a x`          | Drop the file/selection Claude currently sees   |
| `SPC a m`          | Menu with all commands                          |

In the Claude window all of Claude's own shortcuts work: `Esc` (interrupt), `Esc Esc`,
`Shift-Tab` (modes), `Ctrl-C`, `Ctrl-R`, `Ctrl-O`, `Ctrl-T`, ... `S-RET` = new line.
**`Cmd-V` pastes text** into the prompt; `Ctrl-V` is Claude's own image paste.
**Read earlier output:** `Ctrl-Z`, then scroll with `C-u` / `k` / `gg` (or the mouse wheel),
search with `/`; `i` jumps back to the prompt. After a window resize, part of the
conversation may appear twice in the history (as in other terminals).
**`Ctrl-Z`** (or `Ctrl-\`) is the way out: it switches to vim normal mode, so `SPC a c`
(hide), `C-w h` (other window), `SPC b d` (hide; Claude keeps running, stop with `SPC a q`) work. `i` = back to typing to Claude.
`Esc` does *not* leave: it goes to Claude (interrupt). The window's top line shows this.

---

## Tickets (Linear / Jira)

`SPC l` works for Linear and for Jira. Each project remembers its system: the first
`SPC l` in a project asks "Jira or Linear", `SPC l b` changes it. In a ticket buffer
(linear.org, jira.org, a ticket view or board) the keys use that buffer's system.

| Keys      | Action                                  |
|-----------|-----------------------------------------|
| `SPC l l` | My open tickets (Org file `~/org/linear.org` or `~/org/jira.org`) |
| `SPC l p` | Project board: pick project and assignee (All / Me / Unassigned / a person) |
| `SPC l n` | New ticket                              |
| `SPC l s` | Find one ticket and show it (Markdown: details, description, comments) |
| `SPC l c` | Comment on a ticket (the one you view / stand on, else asks) |
| `SPC l b` | Choose Linear or Jira for this project  |
| `, t`     | In the Org file: set a ticket's state (synced) |
| `, v`     | In the Org file: show the ticket under the cursor |
| `TAB`     | Open / fold a project or status group   |

### Linear

The file is grouped per project, then per status (In Progress, In Review, Todo,
Backlog, ...), with the ticket number in front: `*** TODO [#B] BOU-590 Title`.
Done / Canceled groups start folded. `SPC l l` again refreshes and regroups.

Finding a ticket (`SPC l s`): type to filter your own tickets (number or title words),
or type a number like `BOU-123` for any ticket, or words + `M-RET` to search all of Linear.
In a ticket view: `, c` comment, `, r` refresh, `, o` open in browser, `q` close.
Project board: grouped In Progress / In Review, Todo, Backlog (urgent first); each line shows
the assignee (`me`, a name, or `unassigned`). The assignee list shows counts, e.g. `Me (15)`.
`RET` or `, v` shows the ticket on that line, `, a` switches assignee (no reload), `, c`
comments, `, r` refreshes (keeps the assignee), `, o` opens the project in the browser, `q` closes.
Your own list (`SPC l l`, linear.org) is not touched by the board.
Writing a comment (Markdown): `Esc`, then `, ,` send or `, k` cancel.
Setup once, API key from Linear settings > Security & access:
`security add-internet-password -a apikey -s api.linear.app -w <KEY>`

### Jira (Cloud)

Same keys. Differences:
- `~/org/jira.org` is regenerated by `SPC l l` (edits there are overwritten). Headings:
  `*** DOING [#A] ABC-123 Title` (TODO = to do, DOING = in progress, DONE = done last 14 days).
- `, t` (in jira.org, a ticket view or the board) shows the transitions your Jira workflow
  allows, e.g. `Start progress → In Progress`.
- New ticket: pick project and type, title in the minibuffer, then the description as
  Markdown (`, ,` create, `, k` cancel). Comments and descriptions are Markdown; pandoc
  converts them to Jira's format and back.
- Finding a ticket: type a key like `ABC-123`, or words + `M-RET` to search all of Jira.

Setup once: API token from id.atlassian.com > Security > API tokens, then
`security add-internet-password -a <your e-mail> -s <company>.atlassian.net -w <TOKEN>`.
The first Jira command asks for the site (`<company>.atlassian.net`) and remembers it.

---

## Vim extras (evil plugins)

| Keys             | Action                                      |
|------------------|---------------------------------------------|
| `Cmd-/`          | Toggle comment on line / selected lines (any mode, cursor stays) |
| `gcc`            | Toggle comment on line                      |
| `gc` + motion    | Comment motion, e.g. `gcap` = paragraph     |
| `ys` + motion + char | Surround, e.g. `ysiw"` = quote word     |
| `cs` + old + new | Change surround, e.g. `cs"'`                |
| `ds` + char      | Delete surround, e.g. `ds(`                 |
| `S` + char (visual) | Surround selection                       |
| `C-r`            | Redo                                        |
| `u` after reopening | Undo still works: history survives closing files and restarts |
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
| `C-.`             | Actions on the highlighted item (open in split, copy path, delete, ...) |
| `C-d`             | Buffer lists: close the highlighted buffer |
| `Backspace` after `/` | File prompt: up to the parent folder |
| `M-Backspace`     | File prompt: remove one folder / word |
| `~/` or `/`       | File prompt: start over from home / root |
| `Esc`             | Cancel                                |

### Code popup (appears while typing)

| Keys              | Action               |
|-------------------|----------------------|
| `C-j` / `C-k`     | Next / previous      |
| `RET` / `TAB`     | Insert               |
| `Esc`             | Close popup          |

---

## Spelling (Markdown, AsciiDoc, Org, commit messages)

English and Dutch, in text only (not in code). Mistakes are underlined.

| Keys        | Action                                            |
|-------------|---------------------------------------------------|
| `z=`        | Suggestions for the word under the cursor (also "save word") |
| `]s` / `[s` | Next / previous mistake                           |

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
