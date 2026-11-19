---
name: check-upstream-algebra
description: Check the upstream changes to wanxiang_algebra.yaml since the last sync, and decide which changes are worth syncing into this fork. Use when the user asks to check, review, or sync upstream algebra updates.
---

# Check Upstream Algebra Updates

## Workflow

1. Fetch the upstream default branch `wanxiang`:

   ```sh
   git fetch upstream wanxiang
   ```

2. Find the last synced upstream commit. Sync commits record the upstream commit hash in their message, such as `chore(algebra): merge upstream ... (3b93aac)`. Read the newest such hash from:

   ```sh
   git log --format='%h %s' -- wanxiang_algebra.yaml
   ```

3. List the upstream commits since that hash, and read the diff of each commit restricted to the algebra file:

   ```sh
   git log --format='%h %ci %s' <base>..upstream/wanxiang -- wanxiang_algebra.yaml
   git show <commit> -- wanxiang_algebra.yaml
   ```

4. Classify each hunk by the top-level section and the input scheme it changes following the rules below.
5. Report the result to the user as a table with one row per upstream commit: the commit, the change, the changed sections, and the decision with its reason.
6. Apply changes only when the user asks to sync them. Commit each sync as `chore(algebra): <change summary> (<upstream short hash>)`.

## Decision Rules

- Skip changes to sections or schemes that are absent from the local `wanxiang_algebra.yaml`, such as an upstream-only variant section.
- Skip changes to features listed in the `## 已移除功能` section of `FEATURES.md`. That section names the algebra blocks each removed feature used.
- Sync fixes and improvements to sections that exist locally. Adapt them to local refactors: the local file may express the same rule differently, so compare the behavior of a rule and do not rely on textual equality.
- When an upstream change also touches other files, such as Lua modules or dictionaries, note those files in the report, because a rule may depend on them.
