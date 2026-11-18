---
name: translate-changelog
description: Translate the latest English changelog section that release-please generated in CHANGELOG.md into Chinese, and fold the prerelease sections into a stable release section. Use when the user asks to translate the changelog, a release note, or a release-please pull request.
---

# Translate the Changelog

## Workflow

1. Read the top of `CHANGELOG.md`. The newest `## [version]` sections with English entries are the sections to translate.
2. Decide the release type from the version of each new section: a version with a suffix such as `x.x.x-beta.x` is a prerelease, and a version without a suffix such as `x.x.x` is a stable release.
3. For a stable release, delete the prerelease sections of the same version (`## [x.x.x-beta.N]`). Before deleting them, copy the Chinese text of each prerelease entry word for word to the stable entry that links to the same commit hash, so that the same change reads the same in every release note.
4. Translate the remaining English entries of the new section following the rules below.
5. Verify the result by reviewing the diff, and report which entries reuse a previous translation and which entries are new translations.

## Translation Rules

- Translate the entry descriptions and the breaking change bullets into concise Chinese.
- Keep the Markdown structure, the blank lines, the version headings, the section headings, and every link exactly as they are.
- Keep the scope prefix such as `**lookup_filter:**`, inline code, module names, option names, file names, command names, version numbers, and commit hashes in their original form.
- Follow the wording of the earlier translated sections.
