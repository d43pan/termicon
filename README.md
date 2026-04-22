# termicon

Set emoji on your terminal tabs automatically — per SSH host, per directory, or as a local default.

```
🗄️ myserver.example.com          🚨 prod.example.com       💼 ~/work
```

## How it works

`termicon.sh` is a shell plugin that hooks into your shell. It wraps the `ssh` command and registers a directory-change hook (`PROMPT_COMMAND` in bash, `chpwd`/`precmd` in zsh). Whenever you change directory or open an SSH connection, it sets the terminal tab title via standard OSC escape sequences — or tmux window names if you're inside tmux.

The `termicon` CLI manages a plain-text config file at `~/.config/termicon/config`.

## Install

```bash
git clone https://github.com/d43pan/termicon.git
bash termicon/install.sh
```

Then add to your `~/.bashrc` or `~/.zshrc`:

```bash
source /path/to/termicon/termicon.sh
```

### Dependencies

- **bash** or **zsh** (no other requirements)
- **[fzf](https://github.com/junegunn/fzf)** *(optional)* — enables fuzzy emoji search in `setup` and `pick`

## Quick start

```bash
termicon setup
```

Reads your shell history, shows your most-used SSH hosts and directories, and walks you through assigning an emoji to each one. Includes an emoji search (fuzzy with fzf, keyword without).

## Commands

### `termicon setup`

Interactive wizard. Pulls your top SSH hosts and `cd` destinations from shell history and lets you assign emojis to each. Also prompts for a local default and checks for config conflicts that would cause the title to flicker.

### `termicon local [emoji]`

Set the default emoji shown on local tabs when no directory rule matches.

```bash
termicon local        # opens picker
termicon local 🏠     # set directly
```

### `termicon add <ssh|dir> <host|path> <emoji>`

Add or update a mapping.

```bash
termicon add ssh prod.example.com 🚨
termicon add ssh dev.example.com 🧪
termicon add dir ~/work 💼
termicon add dir ~/work/urgent 🔥   # more specific paths take priority
```

### `termicon pick <ssh|dir> <host|path>`

Open the emoji search for a specific host or directory. Type a keyword to filter (`cloud`, `prod`, `linux`, …), pick a number, or paste any emoji directly.

```bash
termicon pick ssh staging.example.com
termicon pick dir ~/projects/myapp
```

### `termicon list`

Show all configured mappings.

```
Local default:
  🏠  (all local tabs, no directory rule)

SSH hosts:
  🚨  prod.example.com
  🧪  dev.example.com

Directories:
  💼  ~/work
  🔥  ~/work/urgent
```

### `termicon remove <ssh|dir> <host|path>`

Remove a mapping.

```bash
termicon remove ssh dev.example.com
termicon remove dir ~/work
```

### `termicon edit`

Open the config file directly in `$EDITOR`.

## Config file

`~/.config/termicon/config` is a plain text file — one rule per line.

```
local 🏠
ssh:prod.example.com 🚨
ssh:dev.example.com 🧪
dir:/home/user/work 💼
dir:/home/user/work/urgent 🔥
```

**Directory matching** uses longest-prefix: if both `~/work` and `~/work/urgent` are configured and you're in `~/work/urgent/src`, the more specific rule (`~/work/urgent`) wins.

**SSH host matching** strips `user@` prefixes and `:port` suffixes, so `ssh user@host -p 2222` matches the rule for `host`.

## Title priority

1. **SSH host emoji** — set when an SSH connection opens, restored when it exits
2. **Directory emoji** — most specific matching prefix
3. **Local default** — fallback for all other local tabs
4. **Directory name** — bare `basename $PWD` if nothing is configured

## Remote servers

When you SSH into a server, the remote shell's own `.bashrc` can overwrite the emoji title on the first prompt — the same PS1 conflict as the local fix above, but on the remote side.

Use `termicon remote` to check and fix it:

```bash
termicon remote myserver.example.com
```

```
Checking myserver.example.com for terminal title conflicts...

⚠️  Conflict on myserver.example.com — the remote shell will overwrite '🗄️ myserver.example.com' on every prompt.

   /home/user/.bashrc  line 71:  PS1="\[\e]0;...\u@\h: \w\a\]$PS1"

Fix — run this on myserver.example.com:
   sed -i '71s/^/# /' /home/user/.bashrc

Apply automatically via SSH? Creates .termicon.bak backups. [y/N]
```

Choosing `y` SSHes in, backs up the file, and comments out the offending line. Choosing `n` leaves the server untouched and just prints the sed command to run manually.

## Conflict: emoji flickers and disappears

If you see the emoji appear and then immediately vanish, another tool is overwriting the terminal title after termicon sets it. The most common cause is the default Ubuntu/Debian `.bashrc`, which embeds a title in `PS1`:

```bash
# This line in ~/.bashrc will overwrite termicon on every prompt:
PS1="\[\e]0;\u@\h: \w\a\]$PS1"
```

`termicon setup` detects this automatically and tells you which file and line to fix. The fix is to comment out that line — termicon handles title setting via `PROMPT_COMMAND` instead.
