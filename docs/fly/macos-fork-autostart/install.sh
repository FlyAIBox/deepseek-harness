#!/bin/bash

set -Eeuo pipefail

readonly LABEL="com.fly.deepseek-harness.web"
readonly SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
readonly DEFAULT_REPO="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel 2>/dev/null || true)"

if [[ $# -gt 2 ]]; then
  printf 'Usage: %s [repository-path] [work-branch]\n' "$0" >&2
  exit 2
fi

readonly REPO_INPUT="${1:-$DEFAULT_REPO}"
readonly WORK_BRANCH="${2:-fly0819}"

[[ "$(uname -s)" == "Darwin" ]] || {
  printf 'This installer requires macOS.\n' >&2
  exit 1
}
[[ -n "$REPO_INPUT" ]] || {
  printf 'Pass the DeepSeek Harness repository path.\n' >&2
  exit 1
}
for required_command in git node pnpm plutil install; do
  command -v "$required_command" >/dev/null 2>&1 || {
    printf 'Required command not found: %s\n' "$required_command" >&2
    exit 1
  }
done

readonly REPO_DIR="$(cd -- "$REPO_INPUT" && pwd -P)"
readonly INSTALL_DIR="$HOME/.local/bin"
readonly INSTALLED_SCRIPT="$INSTALL_DIR/deepseek-harness-start"
readonly AGENT_DIR="$HOME/Library/LaunchAgents"
readonly PLIST_PATH="$AGENT_DIR/$LABEL.plist"
readonly LOG_PATH="$HOME/Library/Logs/deepseek-harness-web.log"
readonly COMMAND_PATH="$(dirname -- "$(command -v pnpm)"):$(dirname -- "$(command -v node)"):$(dirname -- "$(command -v git)"):/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"

git -C "$REPO_DIR" rev-parse --git-dir >/dev/null 2>&1 || {
  printf '%s is not a Git repository.\n' "$REPO_DIR" >&2
  exit 1
}
git -C "$REPO_DIR" remote get-url origin >/dev/null 2>&1 || {
  printf 'The repository has no origin remote.\n' >&2
  exit 1
}
git check-ref-format --branch "$WORK_BRANCH" >/dev/null 2>&1 || {
  printf 'Invalid work branch: %s\n' "$WORK_BRANCH" >&2
  exit 1
}
git -C "$REPO_DIR" show-ref --verify --quiet refs/heads/master || {
  printf 'The local master branch does not exist.\n' >&2
  exit 1
}
git -C "$REPO_DIR" show-ref --verify --quiet "refs/heads/$WORK_BRANCH" || {
  printf 'The local %s branch does not exist.\n' "$WORK_BRANCH" >&2
  exit 1
}

mkdir -p "$INSTALL_DIR" "$AGENT_DIR" "$(dirname -- "$LOG_PATH")"
install -m 755 "$SCRIPT_DIR/deepseek-harness-start" "$INSTALLED_SCRIPT"
cp "$SCRIPT_DIR/$LABEL.plist.template" "$PLIST_PATH"

plutil -remove ProgramArguments.0 "$PLIST_PATH"
plutil -insert ProgramArguments.0 -string "$INSTALLED_SCRIPT" "$PLIST_PATH"
plutil -replace WorkingDirectory -string "$REPO_DIR" "$PLIST_PATH"
plutil -replace EnvironmentVariables.DSH_REPO_DIR -string "$REPO_DIR" "$PLIST_PATH"
plutil -replace EnvironmentVariables.DSH_WORK_BRANCH -string "$WORK_BRANCH" "$PLIST_PATH"
plutil -replace EnvironmentVariables.HOME -string "$HOME" "$PLIST_PATH"
plutil -replace EnvironmentVariables.PATH -string "$COMMAND_PATH" "$PLIST_PATH"
plutil -replace StandardOutPath -string "$LOG_PATH" "$PLIST_PATH"
plutil -replace StandardErrorPath -string "$LOG_PATH" "$PLIST_PATH"
plutil -lint "$PLIST_PATH"

printf 'Installed %s\n' "$INSTALLED_SCRIPT"
printf 'Installed %s\n' "$PLIST_PATH"
printf 'The job will run at the next graphical login.\n'
