# Merge the Latest master into the Current Branch

English | [中文](merge-master.zh.md)

This guide uses the current branch `fly0819`, remote repository `origin`, and primary branch `master` as examples.

## Check Before Merging

Confirm the current branch and working tree status:

```sh
git branch --show-current
git status
```

If the working tree contains uncommitted changes, commit or stash them first:

```sh
git stash push -u -m "before merging master"
```

## Merge the Latest Code

Fetch the latest remote state and merge the remote `master` into the current branch:

```sh
git fetch origin
git merge origin/master
```

Using `origin/master` avoids accidentally merging an outdated local `master`.

## Resolve Conflicts

If Git reports conflicts, list the affected files:

```sh
git status
```

Edit each conflicted file, verify the resolved content, mark it as resolved, and complete the merge commit:

```sh
git add <已解决的文件>
git commit
```

## Restore Stashed Changes

If you ran `git stash` before merging, restore the changes after the merge completes:

```sh
git stash pop
```

Resolve any conflicts from restoring the stash as described in the previous section.

## Verify and Push

Run the checks relevant to the merged code, then push the current branch to the remote repository:

```sh
pnpm run typecheck
pnpm run test
git push origin fly0819
```
