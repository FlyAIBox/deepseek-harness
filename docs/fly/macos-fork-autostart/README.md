# Start a Fork from `master` Automatically on macOS

English | [中文](README.zh.md)

This tutorial installs a per-user macOS LaunchAgent that synchronizes a DeepSeek Harness fork, merges the synchronized `master` into a work branch, builds the repository, and starts the Web UI after graphical login.

## Prerequisites

- Use macOS with a graphical user login.
- Clone a fork whose `origin` remote points to the fork.
- Keep local `master` and work branches, with matching branches on `origin`.
- Install `git`, Node.js, and `pnpm`, and ensure they are available in the current shell.
- Commit or stash all worktree changes before the next login.

The automation stops on a dirty worktree, divergent `master`, push failure, missing remote branch, or build failure. A conflict while merging `origin/master` into the work branch is aborted automatically.

## Install

Run the installer from this directory. Pass the repository's absolute path and the work branch name:

```sh
cd docs/fly/macos-fork-autostart
./install.sh /absolute/path/to/deepseek-harness fly0819
```

The installer copies the executable to `~/.local/bin`, creates `~/Library/LaunchAgents/com.fly.deepseek-harness.web.plist`, and records the repository path, branch, and command search path in the plist. It does not start the job during installation; macOS loads it at the next graphical login.

To load it immediately, run:

```sh
launchctl bootstrap "gui/$(id -u)" "$HOME/Library/LaunchAgents/com.fly.deepseek-harness.web.plist"
```

Loading the job immediately also runs the synchronization, build, and Web UI startup immediately.

## Startup Sequence

At login, the script performs these operations in order:

1. Refuse to run if the worktree contains tracked or untracked changes.
2. Add `upstream` for `https://github.com/deepseek-ai/deepseek-harness.git` when it is absent, or reject an existing `upstream` with another URL.
3. Fetch `master` and the work branch from `origin`, then fetch `upstream/master`.
4. Fast-forward local `master` through `origin/master` and `upstream/master`, then push it to `origin/master`.
5. Fast-forward the local work branch from its matching remote branch and merge `origin/master` into it without pushing the work branch.
6. Run `pnpm run clean`, `pnpm install`, and `pnpm run build`; cleaning removes stale output and directories left by packages deleted upstream.
7. Run `pnpm dsh web` as the long-lived LaunchAgent process.

Only fast-forward updates are accepted for `master`. If the script fails after switching branches, it attempts to return to the configured work branch when the worktree remains clean.

## Files and Logs

| Purpose | Path |
|---|---|
| Installed executable | `~/.local/bin/deepseek-harness-start` |
| LaunchAgent configuration | `~/Library/LaunchAgents/com.fly.deepseek-harness.web.plist` |
| Combined output and error log | `~/Library/Logs/deepseek-harness-web.log` |

Follow the log with:

```sh
tail -f "$HOME/Library/Logs/deepseek-harness-web.log"
```

The LaunchAgent runs after graphical login. It does not run when the computer only wakes from sleep.

## Troubleshooting

### `@deepseek-ai/dsh-root` Has No Build Entry

The build log may end with this error:

```text
ERROR Error: [@deepseek-ai/dsh-root] Cannot find entry: ["lib/types/{index,invariant,startup}.js"]
```

This message does not normally mean that the root package needs a build entry. The tsdown workspace patterns match package directories under `packages/*/*`. If upstream deletes a package while local build output or `node_modules` leaves its directory behind without a `package.json`, tsdown walks upward to the root `package.json`, labels the stale directory as `@deepseek-ai/dsh-root`, and resolves the shared entry relative to a directory that has no emitted `lib/types`.

List matching directories that have no package manifest:

```sh
for dir in vendor/* packages/*/* apps/cli; do
  if [ -d "$dir" ] && [ ! -f "$dir/package.json" ]; then
    printf '%s\n' "$dir"
  fi
done
```

Remove safe repository residue, reinstall dependencies, and rebuild:

```sh
pnpm run clean
pnpm install
pnpm run build
```

The installed startup script runs `pnpm run clean` before every install and build. If an older installed copy does not contain that step, rerun the installer and restart the job:

```sh
./install.sh /absolute/path/to/deepseek-harness fly0819
launchctl kickstart -k "gui/$(id -u)/com.fly.deepseek-harness.web"
```

## Run Manually

The installed executable can run outside launchd when both required settings are provided:

```sh
DSH_REPO_DIR=/absolute/path/to/deepseek-harness \
DSH_WORK_BRANCH=fly0819 \
"$HOME/.local/bin/deepseek-harness-start"
```

## Stop or Uninstall

Stop the loaded job without deleting its files:

```sh
launchctl bootout "gui/$(id -u)/com.fly.deepseek-harness.web"
```

Remove the installed executable and LaunchAgent configuration from this directory:

```sh
./uninstall.sh
```

The uninstaller stops the loaded job and removes only those two installed files. It retains the log and does not modify the repository.
