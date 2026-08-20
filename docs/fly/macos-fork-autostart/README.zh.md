# 在 macOS 上自动从 `master` 启动 fork

[English](README.md) | 中文

本教程安装一个当前用户专用的 macOS LaunchAgent。用户登录图形界面后，它会同步 DeepSeek Harness fork，将同步后的 `master` 合并到工作分支，构建仓库并启动 Web UI。

## 前置条件

- 使用 macOS，并登录图形用户会话。
- clone 一个 fork，且其 `origin` 远程仓库指向该 fork。
- 保留本地 `master` 和工作分支，并在 `origin` 上保留同名分支。
- 安装 `git`、Node.js 和 `pnpm`，并确保当前 shell 可以找到这些命令。
- 下次登录前提交或 stash 所有 worktree 改动。

遇到脏 worktree、分叉的 `master`、推送失败、缺失远程分支或构建失败时，自动任务会停止。将 `origin/master` 合并到工作分支发生冲突时，脚本会自动中止合并。

## 安装

在本目录运行安装器，依次传入仓库绝对路径和工作分支名：

```sh
cd docs/fly/macos-fork-autostart
./install.sh /absolute/path/to/deepseek-harness fly0819
```

安装器会将可执行文件复制到 `~/.local/bin`，创建 `~/Library/LaunchAgents/com.fly.deepseek-harness.web.plist`，并在 plist 中记录仓库路径、分支和命令搜索路径。安装过程不会启动任务；macOS 会在下次登录图形界面时加载它。

如需立即加载，请运行：

```sh
launchctl bootstrap "gui/$(id -u)" "$HOME/Library/LaunchAgents/com.fly.deepseek-harness.web.plist"
```

立即加载任务也会立即执行同步、构建和 Web UI 启动流程。

## 启动顺序

每次登录时，脚本按顺序执行以下操作：

1. worktree 包含已跟踪或未跟踪改动时拒绝运行。
2. 缺少 `upstream` 时添加 `https://github.com/deepseek-ai/deepseek-harness.git`；现有 `upstream` 指向其他 URL 时拒绝运行。
3. 从 `origin` 获取 `master` 和工作分支，再获取 `upstream/master`。
4. 依次通过 `origin/master` 和 `upstream/master` 快进本地 `master`，然后推送到 `origin/master`。
5. 从同名远程分支快进本地工作分支，并将 `origin/master` 合并到其中，但不推送工作分支。
6. 运行 `pnpm run clean`、`pnpm install` 和 `pnpm run build`；清理操作会删除陈旧产物和上游已删除包留下的目录。
7. 运行 `pnpm dsh web`，将其作为 LaunchAgent 的常驻进程。

`master` 只接受快进更新。脚本切换分支后发生失败时，如果 worktree 仍然干净，它会尝试返回配置的工作分支。

## 文件与日志

| 用途 | 路径 |
|---|---|
| 已安装的可执行文件 | `~/.local/bin/deepseek-harness-start` |
| LaunchAgent 配置 | `~/Library/LaunchAgents/com.fly.deepseek-harness.web.plist` |
| 合并输出与错误日志 | `~/Library/Logs/deepseek-harness-web.log` |

使用以下命令跟踪日志：

```sh
tail -f "$HOME/Library/Logs/deepseek-harness-web.log"
```

LaunchAgent 会在登录图形界面后运行；电脑仅从睡眠状态唤醒时不会运行。

## 手动运行

提供两项必需设置后，可以在 launchd 之外运行已安装的可执行文件：

```sh
DSH_REPO_DIR=/absolute/path/to/deepseek-harness \
DSH_WORK_BRANCH=fly0819 \
"$HOME/.local/bin/deepseek-harness-start"
```

## 停止或卸载

停止已加载任务但保留文件：

```sh
launchctl bootout "gui/$(id -u)/com.fly.deepseek-harness.web"
```

在本目录运行以下命令，删除已安装的可执行文件和 LaunchAgent 配置：

```sh
./uninstall.sh
```

卸载器会停止已加载任务，并且只删除上述两个安装文件。它会保留日志，也不会修改仓库。
