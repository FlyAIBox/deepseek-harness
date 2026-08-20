# 将 master 的最新代码合并到当前分支

[English](merge-master.md) | 中文

本文以当前分支 `fly0819`、远程仓库 `origin` 和主分支 `master` 为例。

## 合并前检查

确认当前分支和工作区状态：

```sh
git branch --show-current
git status
```

如果存在尚未提交的修改，可以先提交，或者临时暂存：

```sh
git stash push -u -m "before merging master"
```

## 合并最新代码

获取远程仓库的最新状态，并将远程 `master` 合并到当前分支：

```sh
git fetch origin
git merge origin/master
```

使用 `origin/master` 可以避免误用尚未更新的本地 `master`。

## 解决冲突

如果 Git 报告冲突，先查看冲突文件：

```sh
git status
```

手动修改每个冲突文件，确认内容正确后将其标记为已解决，并完成合并提交：

```sh
git add <已解决的文件>
git commit
```

## 恢复暂存修改

如果合并前执行过 `git stash`，在合并完成后恢复修改：

```sh
git stash pop
```

如果恢复时出现冲突，按上一节的方法解决。

## 验证并推送

根据合并涉及的代码运行相关检查，然后将当前分支推送到远程仓库：

```sh
pnpm run typecheck
pnpm run test
git push origin fly0819
```
