#!/bin/bash

set -Eeuo pipefail

readonly LABEL="com.fly.deepseek-harness.web"
readonly PLIST_PATH="$HOME/Library/LaunchAgents/$LABEL.plist"
readonly INSTALLED_SCRIPT="$HOME/.local/bin/deepseek-harness-start"

launchctl bootout "gui/$(id -u)/$LABEL" 2>/dev/null || true
rm -f "$PLIST_PATH" "$INSTALLED_SCRIPT"

printf 'Removed %s\n' "$PLIST_PATH"
printf 'Removed %s\n' "$INSTALLED_SCRIPT"
printf 'The log remains at %s/Library/Logs/deepseek-harness-web.log\n' "$HOME"
