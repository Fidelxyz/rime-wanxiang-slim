---
name: release
description: Prepare the release-please pull request of a prerelease or a release by translating the latest English changelog section in CHANGELOG.md into Chinese, folding the prerelease sections into the release section, and pushing the result. Use when the user asks to prepare a release, translate the changelog, a release note, or a release-please pull request.
argument-hint: "[release|prerelease]"
---

# Prepare a Release

## Workflow

1. Ask the user whether to prepare a prerelease or a release if not specified.
2. Fetch the remote and check out the release-please pull request branch: `release-please--branches--main` for a prerelease, `release-please--branches--stable` for a release.
3. Read the top of `CHANGELOG.md`. The newest `## [version]` sections with English entries are the sections to translate.
4. For a release, delete the prerelease sections of the same version (`## [x.x.x-beta.N]`). Before deleting them, copy the Chinese text of each prerelease entry word for word to the release entry that links to the same commit hash, so that the same change reads the same in every release note.
5. Translate the remaining English entries of the new section following the rules below.
6. Verify the result by reviewing the diff, and report which entries reuse a previous translation and which entries are new translations.
7. After the user confirms the translation, commit the change with the message `chore: translate the changelog` and push it to the release-please pull request branch.

## Translation Rules

- Translate the entry descriptions and the breaking change bullets into concise Chinese.
- Keep the Markdown structure, the blank lines, the version headings, the section headings, and every link exactly as they are.
- Keep the scope prefix such as `**lookup_filter:**`, inline code, module names, option names, file names, command names, version numbers, and commit hashes in their original form.
- Follow the wording of the earlier translated sections.
