# Changelog

## [1.2.0](https://github.com/Fidelxyz/rime-wanxiang-slim/compare/v1.1.1...v1.2.0) (2026-11-17)


### Features

* add a switch `disable_english` to disable English input ([c5a5a6d](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/c5a5a6d68c9eb0c70f1e8a4d1c4b5ee60d537194))
* **lookup_filter:** support tone digits in auxiliary code lookup ([b396917](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/b39691761ec7f92a58392ec2e315a3be55e8604c))


### Bug Fixes

* remove stale generated dictionaries and tables ([40ec12a](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/40ec12ab85c77c6b2ca3eea27835d9d240142ac6))
* use main dictionary for user phrase and pinned candidate lookup ([#38](https://github.com/Fidelxyz/rime-wanxiang-slim/issues/38)) ([4155e76](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/4155e76614c0d8048399769aa380204ffe19c5a9))


### Miscellaneous Chores

* **dicts:** sync upstream dictionaries metadata ([a30e1aa](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/a30e1aa4055f6a4ae8f8de78f812715442f0a179))
* **dicts:** Update dictionaries to v18.1.8 from upstream ([e819672](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/e8196728724b3dcd714cfafb9c71d7bafd0cd80b))
* use issue types in issue templates ([daf31c3](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/daf31c3c6b5608e9f57f167b41b1062872285c70))


### Code Refactoring

* clarify dictionary source and destination naming ([b2a0abe](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/b2a0abe5c673638233af0ad740337994ee2b97fa))
* remove redundant schema metadata and engine blocks ([a357e31](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/a357e317a99dfea493e1b78f9c0a577d46481b02))
* remove unused abbrev switches ([14fc861](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/14fc861e827f66b69232ce3d5961a9ecd6b5f244))

## [1.2.0-beta.2](https://github.com/Fidelxyz/rime-wanxiang-slim/compare/v1.2.0-beta.1...v1.2.0-beta.2) (2026-11-11)


### Bug Fixes

* use main dictionary for user phrase and pinned candidate lookup ([#38](https://github.com/Fidelxyz/rime-wanxiang-slim/issues/38)) ([4155e76](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/4155e76614c0d8048399769aa380204ffe19c5a9))

## [1.2.0-beta.1](https://github.com/Fidelxyz/rime-wanxiang-slim/compare/v1.1.1...v1.2.0-beta.1) (2026-11-07)


### Features

* add a switch `disable_english` to disable English input ([c5a5a6d](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/c5a5a6d68c9eb0c70f1e8a4d1c4b5ee60d537194))
* **lookup_filter:** support tone digits in auxiliary code lookup ([b396917](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/b39691761ec7f92a58392ec2e315a3be55e8604c))


### Bug Fixes

* remove stale generated dictionaries and tables ([40ec12a](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/40ec12ab85c77c6b2ca3eea27835d9d240142ac6))


### Miscellaneous Chores

* **dicts:** sync upstream dictionaries metadata ([a30e1aa](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/a30e1aa4055f6a4ae8f8de78f812715442f0a179))
* **dicts:** Update dictionaries to v18.1.8 from upstream ([e819672](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/e8196728724b3dcd714cfafb9c71d7bafd0cd80b))


### Code Refactoring

* clarify dictionary source and destination naming ([b2a0abe](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/b2a0abe5c673638233af0ad740337994ee2b97fa))
* remove redundant schema metadata and engine blocks ([a357e31](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/a357e317a99dfea493e1b78f9c0a577d46481b02))
* remove unused abbrev switches ([14fc861](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/14fc861e827f66b69232ce3d5961a9ecd6b5f244))

## [1.1.1](https://github.com/Fidelxyz/rime-wanxiang-slim/compare/v1.1.0...v1.1.1) (2026-10-30)


### Bug Fixes

* enable automatic phrase creation with default user dictionary settings ([9ea20ab](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/9ea20abe2fa3741a8f57f5d515cb01b95e14bd93))

## [1.1.1-beta.1](https://github.com/Fidelxyz/rime-wanxiang-slim/compare/v1.1.0...v1.1.1-beta.1) (2026-10-28)


### Bug Fixes

* enable automatic phrase creation with default user dictionary settings ([9ea20ab](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/9ea20abe2fa3741a8f57f5d515cb01b95e14bd93))

## [1.1.0](https://github.com/Fidelxyz/rime-wanxiang-slim/compare/v1.0.1...v1.1.0) (2026-10-22)


### Features

* add configuration to toggle slash commands ([09b59f4](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/09b59f4e1934ba3546d6300c883573582b3a6119))


### Bug Fixes

* disable auto phrase for base schema ([3c6422d](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/3c6422d18c24b7f4534e0c55b974eed86169d351))
* preserve candidate wrappers in display filters ([ba62a34](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/ba62a341bfbfce99131bcef3ea5b3e4bc51229f9))


### Performance Improvements

* skip inactive Lua filters through tags_match ([07a0ff8](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/07a0ff8cd1f91557ccdf9f45cbea4cb2fc496ea7))
* skip user phrase and pinned lookup when the user dictionary is empty ([48eb984](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/48eb98452012e9aef2522a8873c97b1003372a7d))
* use sparse dictionary for user phrase and pinned candidate lookup ([a2432ec](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/a2432ecaecde715bee698c309bc486928235ece4))


### Miscellaneous Chores

* clean up custom file templates ([be53b35](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/be53b353a891020d2b1b0c8225abfca080082168))


### Code Refactoring

* split user dictionary translator and appender into separate modules ([738e5e0](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/738e5e015893cec77c49132922f7425af0460db2))

## [1.1.0-beta.1](https://github.com/Fidelxyz/rime-wanxiang-slim/compare/v1.0.1...v1.1.0-beta.1) (2026-10-14)


### Features

* add configuration to toggle slash commands ([09b59f4](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/09b59f4e1934ba3546d6300c883573582b3a6119))


### Bug Fixes

* disable auto phrase for base schema ([24f6f8a](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/24f6f8a078097deaf9964ae78e4d574548a485d2))
* preserve candidate wrappers in display filters ([ba62a34](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/ba62a341bfbfce99131bcef3ea5b3e4bc51229f9))


### Performance Improvements

* skip inactive Lua filters through tags_match ([b650988](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/b650988829462347c691f56a15430d55e06777a5))
* skip user phrase and pinned lookup when the user dictionary is empty ([14cdd36](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/14cdd362a3ff1c37a786962eafa4c25a587a3849))


### Miscellaneous Chores

* clean up custom file templates ([be53b35](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/be53b353a891020d2b1b0c8225abfca080082168))

## [1.0.1](https://github.com/Fidelxyz/rime-wanxiang-slim/compare/v1.0.0...v1.0.1) (2026-10-10)


### Bug Fixes

* improve Lua error logging and failure reporting ([5c417d9](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/5c417d993ce2fb37c20533f79a6b3fa793132c06))


### Performance Improvements

* replace candidate pinning filter with script translator ([14ba937](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/14ba937793861f6565088642e89ee7149e2c70d5))


### Miscellaneous Chores

* **algebra:** merge upstream ng normalization fix (3b93aac) ([0251c32](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/0251c32637300ac107dcd153d4e835cdfa432124))
* **algebra:** update algebra from upstream (5da722703c2562ec7cf2a4f7851f73cedf0997c2) ([beff04f](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/beff04f7b89705081090ccdcfb531394fdf042ca))
* **dicts:** Update dictionaries to v18.0.15 from upstream ([704d5c9](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/704d5c9e6838d243481135fcb11085fbba19fb73))
* improve release note download formatting ([60eac13](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/60eac133295cfc6f40c7cd8ee63d06db06a73f14))
* **punctuation:** better default punctuation ([d5a0a58](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/d5a0a584a184ab39517fc875e86fe9a89b3eab3c))
* unify `spelling_hints` for translators ([3fc5ec8](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/3fc5ec877ed744b3a28406e18131004b3d33dcd2))


### Code Refactoring

* **algebra:** generalize auxiliary code derivation ([a6436d9](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/a6436d9e081c9d74f62ae0c98a0a9e1c1126b863))
* **algebra:** unify special character range in algebra ([840de47](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/840de4710fb90224429a84b9ae5c111b446ca515))
* extract shared file utilities ([4619fc7](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/4619fc79f49c873dbc3d64ec7311b3ad0c3729d9))

## [1.0.1-beta.1](https://github.com/Fidelxyz/rime-wanxiang-slim/compare/v1.0.0...v1.0.1-beta.1) (2026-10-06)


### Bug Fixes

* improve Lua error logging and failure reporting ([5c417d9](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/5c417d993ce2fb37c20533f79a6b3fa793132c06))


### Performance Improvements

* replace candidate pinning filter with script translator ([14ba937](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/14ba937793861f6565088642e89ee7149e2c70d5))


### Miscellaneous Chores

* **algebra:** merge upstream ng normalization fix (3b93aac) ([0251c32](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/0251c32637300ac107dcd153d4e835cdfa432124))
* **algebra:** update algebra from upstream (5da722703c2562ec7cf2a4f7851f73cedf0997c2) ([beff04f](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/beff04f7b89705081090ccdcfb531394fdf042ca))
* **dicts:** Update dictionaries to v18.0.15 from upstream ([704d5c9](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/704d5c9e6838d243481135fcb11085fbba19fb73))
* improve release note download formatting ([60eac13](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/60eac133295cfc6f40c7cd8ee63d06db06a73f14))
* **punctuation:** better default punctuation ([d5a0a58](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/d5a0a584a184ab39517fc875e86fe9a89b3eab3c))
* unify `spelling_hints` for translators ([3fc5ec8](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/3fc5ec877ed744b3a28406e18131004b3d33dcd2))


### Code Refactoring

* **algebra:** generalize auxiliary code derivation ([a6436d9](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/a6436d9e081c9d74f62ae0c98a0a9e1c1126b863))
* **algebra:** unify special character range in algebra ([840de47](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/840de4710fb90224429a84b9ae5c111b446ca515))
* extract shared file utilities ([4619fc7](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/4619fc79f49c873dbc3d64ec7311b3ad0c3729d9))

## [1.0.0](https://github.com/Fidelxyz/rime-wanxiang-slim/compare/v0.6.0...v1.0.0) (2026-09-20)


### ⚠ BREAKING CHANGES

* **algebra:** 升级到该版本时，需手动更新自定义文件 `custom.yaml` 中 `speller/algebra` 补丁至 `custom` 目录下模板文件中新的格式。
* remove Chinese-English mixed dictionary

### Features

* add install scripts ([ec4e93c](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/ec4e93c359cd493fcc4a1073caac0a7491356c7d))
* add 乱序17 support for pro schema ([ee15391](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/ee15391f28e8727d5a519521f561cf619c00db5c))
* support 蓝天双拼 and 大牛双拼 reverse lookup ([ba8f45b](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/ba8f45b682d9a459fba7c9269fa0d2b9038d8b43))
* **version_displayer:** show aux code schema on `/version` command ([55cd442](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/55cd442d17938dadb69da9acf6f1ca8a1ebeacac))


### Bug Fixes

* add nil check for `env.engine.schema.config` ([2bd1acc](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/2bd1acc72fe6ff04453bd5268f814467fd363ea0))
* fix duplicated auxiliary mode detection character ([7c85502](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/7c85502c1f163eb6033fa55ca8dac7d5faf83ee0))
* fix librime-lua contrib type annotations ([531a7a9](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/531a7a92c02701d90655c6a11b6f3dcb1c1c4f28))
* make install.sh compatible with PowerShell 5.1 ([5747e11](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/5747e1135b36a6bb1e6cfdf4b72b4d8abac70fea))
* only pin candidates matching the entire input segment ([58c3508](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/58c35086bd2d947bb738dd19fe0c34d034eb9f76))


### Miscellaneous Chores

* **algebra:** update algebra from upstream (469262edc6fec1ef1a1c768e805b762035c78668) ([fd07528](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/fd07528861b19fe143e31e42b111adbd5dee20df))
* **algebra:** update algebra from upstream (d738f2a4db48a5962e434a7cc9acf4fed539d977) ([22430ed](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/22430edfba961095611698563dff2e2553a85d7c))
* cleanup algebra ([f90df11](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/f90df11ea30c5a8c9524bbc254ffaab8af11f7b7))
* cleanup code ([3ab57ea](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/3ab57eabb967da819fb2cf7c7ff9fa0bea609f58))
* **dicts:** Update dictionaries to v17.9.2 from upstream ([ebba37f](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/ebba37f0ef9c22bcd50f4b7e6702f0b245f29dbc))
* **dicts:** Update OpenCC data to ver.1.4.2 ([fa3c002](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/fa3c002b658c2302d417167d4248f4add9904b82))
* **schema_switcher:** simplify schema switcher logic ([32583ab](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/32583ab53f0cc0f9fd4e7aa837d954c1bf5248c6))
* update LSP and linter configurations ([259c601](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/259c6017a52713114be5bc222f47e3d2376a8e51))
* v1 release ([1546f41](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/1546f4170d55a2091be702e27b459e84d3b0bb0b))
* v1 release ([7badbd9](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/7badbd90f55aff18eef1d42eff89c7c41cde2ac8))


### Code Refactoring

* **algebra:** unify algebra patch configuration ([3fa26fc](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/3fa26fcb236144c30f01f4305c6ba18ab2056ee4))
* remove Chinese-English mixed dictionary ([f328d83](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/f328d83cd171fb45b9a41b6b95b8d33dc3b56e25))
* rename Lua modules for clearer responsibilities ([1f01dd5](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/1f01dd5e8acd73f041a68ca5165e86a1ed485277))

## [1.0.0-beta.2](https://github.com/Fidelxyz/rime-wanxiang-slim/compare/v1.0.0-beta.1...v1.0.0-beta.2) (2026-09-18)


### Features

* add install scripts ([ec4e93c](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/ec4e93c359cd493fcc4a1073caac0a7491356c7d))
* add 乱序17 support for pro schema ([ee15391](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/ee15391f28e8727d5a519521f561cf619c00db5c))
* support 蓝天双拼 and 大牛双拼 reverse lookup ([ba8f45b](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/ba8f45b682d9a459fba7c9269fa0d2b9038d8b43))
* **version_displayer:** show aux code schema on `/version` command ([55cd442](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/55cd442d17938dadb69da9acf6f1ca8a1ebeacac))


### Bug Fixes

* fix duplicated auxiliary mode detection character ([7c85502](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/7c85502c1f163eb6033fa55ca8dac7d5faf83ee0))
* only pin candidates matching the entire input segment ([58c3508](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/58c35086bd2d947bb738dd19fe0c34d034eb9f76))


### Miscellaneous Chores

* **algebra:** update algebra from upstream (d738f2a4db48a5962e434a7cc9acf4fed539d977) ([22430ed](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/22430edfba961095611698563dff2e2553a85d7c))


### Code Refactoring

* rename Lua modules for clearer responsibilities ([1f01dd5](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/1f01dd5e8acd73f041a68ca5165e86a1ed485277))

## [1.0.0-beta.1](https://github.com/Fidelxyz/rime-wanxiang-slim/compare/v0.6.0...v1.0.0-beta.1) (2026-09-05)


### ⚠ BREAKING CHANGES

* remove Chinese-English mixed dictionary

### Bug Fixes

* add nil check for `env.engine.schema.config` ([2bd1acc](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/2bd1acc72fe6ff04453bd5268f814467fd363ea0))
* fix librime-lua contrib type annotations ([531a7a9](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/531a7a92c02701d90655c6a11b6f3dcb1c1c4f28))


### Miscellaneous Chores

* cleanup algebra ([f90df11](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/f90df11ea30c5a8c9524bbc254ffaab8af11f7b7))
* cleanup code ([3ab57ea](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/3ab57eabb967da819fb2cf7c7ff9fa0bea609f58))
* **dicts:** Update dictionaries to v17.9.2 from upstream ([ebba37f](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/ebba37f0ef9c22bcd50f4b7e6702f0b245f29dbc))
* **dicts:** Update OpenCC data to ver.1.4.2 ([fa3c002](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/fa3c002b658c2302d417167d4248f4add9904b82))
* update LSP and linter configurations ([259c601](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/259c6017a52713114be5bc222f47e3d2376a8e51))
* v1 release ([7badbd9](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/7badbd90f55aff18eef1d42eff89c7c41cde2ac8))


### Code Refactoring

* remove Chinese-English mixed dictionary ([f328d83](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/f328d83cd171fb45b9a41b6b95b8d33dc3b56e25))

## [0.6.0](https://github.com/Fidelxyz/rime-wanxiang-slim/compare/v0.5.0...v0.6.0) (2026-08-22)


### ⚠ BREAKING CHANGES

* **lookup_filter:** rename lookup_filter config options
* **algebra:** rename fuzzy input algebras
* **charset_filter:** reorganize charset filter config
* **lookup_filter:** use a single reverse lookup dictionary
* remove automatic english spacing
* **english_user_dict_appender:** unify trigger for chinese and english user dict appender
* **comment_hint_displayer:** refactor super_comment

### Features

* **candidate_pinner:** add candidate pinner ([bd4efaa](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/bd4efaa59be965d553be5fc5571c6f65020a4b54))
* **user_dict_appender:** drop sentence candidate and always show tips in word creation mode ([e8d3fbc](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/e8d3fbc6c1e86dacdb9ac2b6365f547ce99e26b0))
* **version_displayer:** add version displayer ([055333c](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/055333cf96214ee29c2326756a82e2cf35daa1dd))


### Bug Fixes

* **build:** skip processing for excluded dicts ([eee70d4](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/eee70d44248c5594c95474dee92f1c8a125426f8))
* **charset_filter:** skip charset filtering for user dictionary candidates ([ecb8736](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/ecb8736e5cddb38c009426c7e6b02dda93390a2e))
* correct Projection.load rule types ([0048c36](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/0048c36ae03efa3936466bab84597e665675d1bf))
* fix incorrect type annotation in librime contrib ([2bd92ca](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/2bd92ca757158a8238d4f05dd854d800155acbff))
* fix librime-lua stub ([8b073da](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/8b073da7f95dcdb2e8612db84e4cc1ac78201173))
* flush subprocess output in mira_report for real-time display ([fe8d0e1](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/fe8d0e1f9cbd13b71d63161a55ce66f70b6cca80))
* **utils:** correct magic character escaping in escape_for_pattern ([7fc6aac](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/7fc6aacb6524047db8751b6a480526251d880e29))


### Performance Improvements

* **lookup_filter:** short-circuit lookup data sources ([282d5e6](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/282d5e66c103a497b18df2721e20861935b0b7cf))
* **lookup_filter:** smarter lookup cache eviction via segmented hot/cold cache ([67788dd](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/67788dd60524a0f9902a54f4ac5786c4f6df572c))
* optimize list appending operations ([81e1e32](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/81e1e32f61c2b2af0314d1a9bcdf530c0a11e484))


### Miscellaneous Chores

* add issue templates for bug reports and feature requests ([b308502](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/b308502589642676a7b7c423d15a84aa367dc577))
* **algebra:** update algebra from upstream (f219fbfb2286eec956373f9316fc4641f5052135) ([9b94f44](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/9b94f44cf34c087737b16aab3481d67fe4ebd52e))
* cleanup codes ([0dbeb18](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/0dbeb1852f113775c115e9374be31205f1649bbc))
* cleanup dictionary config in schema files ([f746f60](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/f746f602cb18cf93e19bdd59ca8e4a4c29ada13c))
* cleanup generate_pro_dicts.py ([c0a7cef](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/c0a7cefe0a00141a4b3c74cd30e0ba91877e1732))
* cleanup schema files ([d630db7](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/d630db7c200adea6d96419b508ee4d98e50e4bb2))
* code cleanup ([85eac46](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/85eac462d37eb4782b2561530119dba91fa6ac3e))
* **dicts:** Update dictionaries to v16.0.1 from upstream ([06c9de5](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/06c9de549c82057a48eaf74d5d7f2e6c2594b503))
* **dicts:** Update dictionaries to v17.0.3 from upstream ([e8f42d5](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/e8f42d59be66bd40efd08a14f051056c8ba526ac))
* **dicts:** Update OpenCC data to ver.1.4.0 ([6999090](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/6999090eaaf3f6384c14fc128a43aa500b9ef23c))
* **dicts:** Update OpenCC data to ver.1.4.1 ([e5b0be5](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/e5b0be5b898ed6ccd08f1921326816c745ad19be))
* **docs:** update dependencies ([649ef39](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/649ef393cec723775abcdde67dffe74f94688082))
* improve candidate types handling and documentation ([06dccfc](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/06dccfcbb8925c2689670207db84c9d0c813a61a))
* **lookup_filter:** cleanup code ([4577f7f](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/4577f7fc950f514f74f2a2b70abaa922348a3c38))
* merge v15.16.0 from upstream ([ceaeeed](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/ceaeeed74e499d15eecb526bfc347d78aaf4e343))
* **opencc:** Update OpenCC data to ver.1.3.1 ([b751556](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/b751556b504f8900186dae11bd3238c553c2830d))
* **opencc:** Update OpenCC data to ver.1.3.2 ([2abd33b](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/2abd33bab893850a361fbd7fb784cfea63fac5ad))
* remove default keymaps in Lua scripts ([cb25c71](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/cb25c712b09e567a52603cc0bc410c88fe1c8519))
* update bug report issue template ([b949f2b](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/b949f2b5b83ef352413379534600d36e2aa66ed3))
* upgrade Lua syntax version for StyLua ([76e9d5e](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/76e9d5e7aa49c3b159587c52492ff6893c5fb3cc))


### Code Refactoring

* **algebra:** rename fuzzy input algebras ([58c9701](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/58c9701a7f88777e0991eb11f724498241633c9f))
* **candidate_code_recorder:** extract candidate_code_recorder from auto_phrase ([3b80b9f](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/3b80b9fd0d4f2d29a3974967cadcc07127ad427d))
* **charset_filter:** reorganize charset filter config ([1b808b9](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/1b808b987d0e520f302edb2079750a2a51f010bf))
* **comment_hint_displayer:** refactor super_comment ([9c0f440](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/9c0f44077e447b633701541fde8699c7c37b7ce2))
* **english_user_dict_appender:** extract english_user_dict_appender from auto_phrase ([bca7369](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/bca7369fb53bfa46af452600f24ca8f27f872d8b))
* **english_user_dict_appender:** unify trigger for chinese and english user dict appender ([a628cc0](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/a628cc090951f3c9f23b00df93f394e69b8774d3))
* extract redundant helper function from wanxiang.lua ([abdeda5](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/abdeda52a12fcfa7c66314baf7a622ccdfa8907c))
* generate Pro auxiliary data from upstream sources ([5f98bc0](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/5f98bc0bfba3f2db96037c413335e089f9079033))
* **lookup_filter:** rename lookup_filter config options ([79b5038](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/79b5038d757a510a9e89c320451aa295055fb17a))
* **lookup_filter:** simplify trigger and notifier handling ([248d1cd](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/248d1cde81c0973d5a13ca8d146a2fff33eed16f))
* **lookup_filter:** use a single reverse lookup dictionary ([1507442](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/150744249f48443b95b29c717dc259a6fdc9ee18))
* organize lua modules ([c61aec1](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/c61aec12bd6e640cfd64944c5432f0b6194763c3))
* **partial_committer:** rename partial_commit to partial_committer ([d88e40a](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/d88e40a20ba62dcac6828af27cc90d1afe490ee2))
* **phrase_escaper:** rename escape_filter to phrase_escaper ([91bc61e](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/91bc61e6d448d5bc4c7bf088c3de304491f38f9c))
* **preedit_tone_displayer:** rename preedit_tone_display to preedit_tone_displayer ([f9da5a1](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/f9da5a1c8ff294e214f5be7ea207c88c9b65bb25))
* remove automatic english spacing ([34358ab](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/34358ab77a30226236a8b30049916505d2e4481a))
* remove fallback filter ([b485d41](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/b485d4120adb2f5afde6b18e9b456f1d5bd8f34f))
* remove reorder filter ([4dfb211](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/4dfb2116da3f3837e222613d0a7fff2afa6ae52c))
* reorganize schema source data ([570f222](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/570f222c13480367fa89b9ec054fdaa83d9e3eb6))
* split english module and cleanup codes ([3e526f7](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/3e526f79ab91f2c1bca6ae075ed87b4fc84d65b8))

## [0.6.0-beta.4](https://github.com/Fidelxyz/rime-wanxiang-slim/compare/v0.6.0-beta.3...v0.6.0-beta.4) (2026-08-02)


### ⚠ BREAKING CHANGES

* **lookup_filter:** use a single reverse lookup dictionary

### Bug Fixes

* correct Projection.load rule types ([0048c36](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/0048c36ae03efa3936466bab84597e665675d1bf))
* **utils:** correct magic character escaping in escape_for_pattern ([7fc6aac](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/7fc6aacb6524047db8751b6a480526251d880e29))


### Performance Improvements

* **lookup_filter:** short-circuit lookup data sources ([282d5e6](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/282d5e66c103a497b18df2721e20861935b0b7cf))
* **lookup_filter:** smarter lookup cache eviction via segmented hot/cold cache ([67788dd](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/67788dd60524a0f9902a54f4ac5786c4f6df572c))


### Miscellaneous Chores

* **dicts:** Update dictionaries to v17.0.3 from upstream ([e8f42d5](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/e8f42d59be66bd40efd08a14f051056c8ba526ac))
* **dicts:** Update OpenCC data to ver.1.4.1 ([e5b0be5](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/e5b0be5b898ed6ccd08f1921326816c745ad19be))
* **lookup_filter:** cleanup code ([4577f7f](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/4577f7fc950f514f74f2a2b70abaa922348a3c38))


### Code Refactoring

* generate Pro auxiliary data from upstream sources ([5f98bc0](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/5f98bc0bfba3f2db96037c413335e089f9079033))
* **lookup_filter:** simplify trigger and notifier handling ([248d1cd](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/248d1cde81c0973d5a13ca8d146a2fff33eed16f))
* **lookup_filter:** use a single reverse lookup dictionary ([1507442](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/150744249f48443b95b29c717dc259a6fdc9ee18))
* reorganize schema source data ([570f222](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/570f222c13480367fa89b9ec054fdaa83d9e3eb6))

## [0.6.0-beta.3](https://github.com/Fidelxyz/rime-wanxiang-slim/compare/v0.6.0-beta.2...v0.6.0-beta.3) (2026-07-07)


### ⚠ BREAKING CHANGES

* remove automatic english spacing
* **english_user_dict_appender:** unify trigger for chinese and english user dict appender

### Features

* **user_dict_appender:** drop sentence candidate and always show tips in word creation mode ([e8d3fbc](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/e8d3fbc6c1e86dacdb9ac2b6365f547ce99e26b0))


### Bug Fixes

* **build:** skip processing for excluded dicts ([eee70d4](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/eee70d44248c5594c95474dee92f1c8a125426f8))
* fix librime-lua stub ([8b073da](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/8b073da7f95dcdb2e8612db84e4cc1ac78201173))


### Miscellaneous Chores

* cleanup codes ([0dbeb18](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/0dbeb1852f113775c115e9374be31205f1649bbc))
* cleanup generate_pro_dicts.py ([c0a7cef](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/c0a7cefe0a00141a4b3c74cd30e0ba91877e1732))
* code cleanup ([85eac46](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/85eac462d37eb4782b2561530119dba91fa6ac3e))
* **dicts:** Update dictionaries to v16.0.1 from upstream ([06c9de5](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/06c9de549c82057a48eaf74d5d7f2e6c2594b503))
* **dicts:** Update OpenCC data to ver.1.4.0 ([6999090](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/6999090eaaf3f6384c14fc128a43aa500b9ef23c))
* merge v15.16.0 from upstream ([ceaeeed](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/ceaeeed74e499d15eecb526bfc347d78aaf4e343))
* **opencc:** Update OpenCC data to ver.1.3.2 ([2abd33b](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/2abd33bab893850a361fbd7fb784cfea63fac5ad))


### Code Refactoring

* **english_user_dict_appender:** extract english_user_dict_appender from auto_phrase ([bca7369](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/bca7369fb53bfa46af452600f24ca8f27f872d8b))
* **english_user_dict_appender:** unify trigger for chinese and english user dict appender ([a628cc0](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/a628cc090951f3c9f23b00df93f394e69b8774d3))
* organize lua modules ([c61aec1](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/c61aec12bd6e640cfd64944c5432f0b6194763c3))
* remove automatic english spacing ([34358ab](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/34358ab77a30226236a8b30049916505d2e4481a))
* remove reorder filter ([4dfb211](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/4dfb2116da3f3837e222613d0a7fff2afa6ae52c))
* split english module and cleanup codes ([3e526f7](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/3e526f79ab91f2c1bca6ae075ed87b4fc84d65b8))

## [0.6.0-beta.2](https://github.com/Fidelxyz/rime-wanxiang-slim/compare/v0.6.0-beta.1...v0.6.0-beta.2) (2026-06-08)


### ⚠ BREAKING CHANGES

* **comment_hint_displayer:** refactor super_comment

### Features

* **version_displayer:** add version displayer ([055333c](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/055333cf96214ee29c2326756a82e2cf35daa1dd))


### Bug Fixes

* fix incorrect type annotation in librime contrib ([2bd92ca](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/2bd92ca757158a8238d4f05dd854d800155acbff))


### Miscellaneous Chores

* add issue templates for bug reports and feature requests ([b308502](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/b308502589642676a7b7c423d15a84aa367dc577))
* cleanup schema files ([d630db7](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/d630db7c200adea6d96419b508ee4d98e50e4bb2))
* **docs:** update dependencies ([649ef39](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/649ef393cec723775abcdde67dffe74f94688082))
* **opencc:** Update OpenCC data to ver.1.3.1 ([b751556](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/b751556b504f8900186dae11bd3238c553c2830d))
* update bug report issue template ([b949f2b](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/b949f2b5b83ef352413379534600d36e2aa66ed3))
* upgrade Lua syntax version for StyLua ([76e9d5e](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/76e9d5e7aa49c3b159587c52492ff6893c5fb3cc))


### Code Refactoring

* **comment_hint_displayer:** refactor super_comment ([9c0f440](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/9c0f44077e447b633701541fde8699c7c37b7ce2))
* extract redundant helper function from wanxiang.lua ([abdeda5](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/abdeda52a12fcfa7c66314baf7a622ccdfa8907c))
* **partial_committer:** rename partial_commit to partial_committer ([d88e40a](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/d88e40a20ba62dcac6828af27cc90d1afe490ee2))
* **phrase_escaper:** rename escape_filter to phrase_escaper ([91bc61e](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/91bc61e6d448d5bc4c7bf088c3de304491f38f9c))
* **preedit_tone_displayer:** rename preedit_tone_display to preedit_tone_displayer ([f9da5a1](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/f9da5a1c8ff294e214f5be7ea207c88c9b65bb25))
* remove fallback filter ([b485d41](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/b485d4120adb2f5afde6b18e9b456f1d5bd8f34f))

## [0.6.0-beta.1](https://github.com/Fidelxyz/rime-wanxiang-slim/compare/v0.5.0...v0.6.0-beta.1) (2026-05-30)


### Features

* **candidate_pinner:** add candidate pinner ([bd4efaa](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/bd4efaa59be965d553be5fc5571c6f65020a4b54))


### Performance Improvements

* optimize list appending operations ([81e1e32](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/81e1e32f61c2b2af0314d1a9bcdf530c0a11e484))


### Miscellaneous Chores

* cleanup dictionary config in schema files ([f746f60](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/f746f602cb18cf93e19bdd59ca8e4a4c29ada13c))
* improve candidate types handling and documentation ([06dccfc](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/06dccfcbb8925c2689670207db84c9d0c813a61a))
* remove default keymaps in Lua scripts ([cb25c71](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/cb25c712b09e567a52603cc0bc410c88fe1c8519))


### Code Refactoring

* **candidate_code_recorder:** extract candidate_code_recorder from auto_phrase ([3b80b9f](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/3b80b9fd0d4f2d29a3974967cadcc07127ad427d))

## [0.5.0](https://github.com/Fidelxyz/rime-wanxiang-slim/compare/v0.4.0...v0.5.0) (2026-05-27)


### ⚠ BREAKING CHANGES

* **charset_filter:** rename `base` option to `charset`
* merge v15.11.0 from upstream
* **user_predict:** remove candidate prediction
* change user dictionaries name
* rename user dict components

### Features

* **preedit_tone:** reintroduce preedit full pinyin conversion ([2c902b0](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/2c902b080e36d44cbb929763018db7f00fab5bc1))
* **preedit_tone:** reintroduce preedit tone display ([61e1c88](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/61e1c88380716a49161a8327ca67772f2ea2a11e))
* reintroduce tone input from upstream ([530e3a7](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/530e3a7dd1b1168e21ad0692f37375e732ce00ba))


### Bug Fixes

* **charset:** fix flipped whitelist and blacklist in charset filter ([d339a81](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/d339a81d667c2364d4d82b3a3788d70e8a066037))
* **english:** fix English candidate casing ([2e17717](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/2e177170852e6b5e702384dc14fdc1fc87cdd6e1))
* **english:** ignore key release events in chain-breaker processor ([123dfba](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/123dfba858f0e1d77e8a158983939a77e084b6c1))
* fix copyright information in librime.lua ([36a2c00](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/36a2c005722186d79f45a4c6472b1c2535a9bfef))
* fix incorrect `config_version` ([4bb52a7](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/4bb52a791ef702bb3e56bbd3d2679707d8f7fc49))
* prevent caret moves to the end when backtick is added at the beginning ([7a3cc68](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/7a3cc68cde83512e6d7749ca0eebecf0abe88203))
* provide fallback for `rime_api.get_time_ms` for compatibility with Weasel ([5c73ac2](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/5c73ac28cb896117587cd52ca96c2952fffea1eb))


### Performance Improvements

* optimize reading page size ([a5e516a](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/a5e516aba38f4807b061707ca11bbf088674b6ba))


### Miscellaneous Chores

* add copyright header to librime.lua ([bb91ac2](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/bb91ac24991acc464dd1f501e00adb681fcabbc9))
* change schema names ([41e9b02](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/41e9b02b0f11b4528ecd33bd5677b07369ba2639))
* change user dictionaries name ([0503e5c](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/0503e5c07150b29c10b1efbf4a885363f405a14b))
* **charset_filter:** cleanup charset filter code ([1294f9d](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/1294f9da827af96c67b29e3562a07c5f28ca77ef))
* cleanup Lua code ([fe6ec1d](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/fe6ec1dc48ebcb434d9fde815b6e45f07e02965c))
* cleanup redundant check in candidate_type_marker ([840915d](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/840915d6d172ad3f5d64aa95a89ce5eb1798a616))
* cleanup schema comments ([2308327](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/23083271c2750e0306488a865f1af99d90c18fa8))
* disable english sentences ([ff666cc](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/ff666ccb30377d12a58932eb079e063532808beb))
* improve switcher options display ([2126f38](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/2126f38aa5a2dccf093cc2cc5618dfe22fe62c82))
* merge v15.11.0 from upstream ([73d188f](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/73d188f76a773e9eaf032a0466bb577a0af717aa))
* remove the hack for English sentence candidates ([eccfcae](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/eccfcae3ff930c01df28a469753d7905c7a2aa22))


### Code Refactoring

* **charset_filter:** rename `base` option to `charset` ([5c55b2d](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/5c55b2d5f18805d58c9b422cd5bb900bf951e0c3))
* **english:** remove English candidates number limit ([1c43b78](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/1c43b78f14f9879421e126119fa0b48fac790cbd))
* **english:** remove fallback English word derivation ([4436b28](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/4436b28915e1ea8c01a67e9a3688c883bc419414))
* remove sentence_filter ([0434a7b](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/0434a7bb4a1ea2faf468c84ddb89e5ee6dbac3ed))
* rename user dict components ([8883806](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/8883806657f110cff64660c4f911c879bb621793))
* split preedit_tone_display and preedit_pinyin_expander ([3cbfa00](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/3cbfa00aed391891d176d6f786ace3437e35fa9f))
* **tone_corrector:** rename tone_fallback to tone_corrector ([d1081b9](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/d1081b93390656afb84a795a67cff0f1a352ae4f))
* **user_predict:** remove candidate prediction ([22dcac8](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/22dcac88da02228ea9a7f58417a2af6fad81f9cd))


### Continuous Integration

* add prerelease workflow ([9c67425](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/9c67425dc6d9b50a0da1c4ee683d4d119889c250))
* change prerelease version suffix to beta ([ec6a0e8](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/ec6a0e8ca3dd020b13eb2f7330293c491b00f712))
* fix multi-branch release workflow ([162771f](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/162771fe5f9b343196655b4fa935255539ccd70d))

## [0.5.0-beta.3](https://github.com/Fidelxyz/rime-wanxiang-slim/compare/v0.5.0-beta.2...v0.5.0-beta.3) (2026-05-22)


### Bug Fixes

* fix incorrect `config_version` ([4bb52a7](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/4bb52a791ef702bb3e56bbd3d2679707d8f7fc49))

## [0.5.0-beta.2](https://github.com/Fidelxyz/rime-wanxiang-slim/compare/v0.5.0-beta.1...v0.5.0-beta.2) (2026-05-22)


### ⚠ BREAKING CHANGES

* merge v15.11.0 from upstream

### Miscellaneous Chores

* add copyright header to librime.lua ([bb91ac2](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/bb91ac24991acc464dd1f501e00adb681fcabbc9))
* cleanup Lua code ([fe6ec1d](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/fe6ec1dc48ebcb434d9fde815b6e45f07e02965c))
* merge v15.11.0 from upstream ([73d188f](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/73d188f76a773e9eaf032a0466bb577a0af717aa))
* remove the hack for English sentence candidates ([eccfcae](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/eccfcae3ff930c01df28a469753d7905c7a2aa22))


### Code Refactoring

* split preedit_tone_display and preedit_pinyin_expander ([3cbfa00](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/3cbfa00aed391891d176d6f786ace3437e35fa9f))

## [0.5.0-beta.1](https://github.com/Fidelxyz/rime-wanxiang-slim/compare/v0.4.0...v0.5.0-beta.1) (2026-05-21)


### ⚠ BREAKING CHANGES

* **user_predict:** remove candidate prediction
* change user dictionaries name
* rename user dict components

### Features

* **preedit_tone:** reintroduce preedit full pinyin conversion ([2c902b0](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/2c902b080e36d44cbb929763018db7f00fab5bc1))
* **preedit_tone:** reintroduce preedit tone display ([61e1c88](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/61e1c88380716a49161a8327ca67772f2ea2a11e))
* reintroduce tone input from upstream ([530e3a7](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/530e3a7dd1b1168e21ad0692f37375e732ce00ba))


### Bug Fixes

* prevent caret moves to the end when backtick is added at the beginning ([7a3cc68](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/7a3cc68cde83512e6d7749ca0eebecf0abe88203))


### Performance Improvements

* optimize reading page size ([a5e516a](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/a5e516aba38f4807b061707ca11bbf088674b6ba))


### Miscellaneous Chores

* change user dictionaries name ([0503e5c](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/0503e5c07150b29c10b1efbf4a885363f405a14b))
* cleanup schema comments ([2308327](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/23083271c2750e0306488a865f1af99d90c18fa8))
* disable english sentences ([ff666cc](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/ff666ccb30377d12a58932eb079e063532808beb))
* improve switcher options display ([2126f38](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/2126f38aa5a2dccf093cc2cc5618dfe22fe62c82))


### Code Refactoring

* rename user dict components ([8883806](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/8883806657f110cff64660c4f911c879bb621793))
* **user_predict:** remove candidate prediction ([22dcac8](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/22dcac88da02228ea9a7f58417a2af6fad81f9cd))


### Continuous Integration

* add prerelease workflow ([9c67425](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/9c67425dc6d9b50a0da1c4ee683d4d119889c250))
* change prerelease version suffix to beta ([ec6a0e8](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/ec6a0e8ca3dd020b13eb2f7330293c491b00f712))

## [0.4.0](https://github.com/Fidelxyz/rime-wanxiang-slim/compare/v0.3.0...v0.4.0) (2026-05-03)


### ⚠ BREAKING CHANGES

* split super_processor into specialized modules
* split super_filter into specialized filter modules
* remove manual_segmentor
* **sequencer:** remove sequencer
* **super_filter:** improve custom_phrase escape
* **english:** remove english path input handling
* **user_predict:** disable post prediction by default
* **super_Replacer:** remove super_replacer
* merge v15.9.4 from upstream
* remove derivative algebra for wanxiang_english
* **user_predict:** enable user_predict

### Features

* reintroduce decomposition hint with OpenCC ([ef363f0](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/ef363f0ff696b6a5383e44b0a9058237683e5d91))
* support emoji with OpenCC ([0bbb41a](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/0bbb41a98201467166291efe208e3716ab29534e))
* support simplified and traditional Chinese conversion with OpenCC ([f932258](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/f932258d2d9b24309557dc311dca40c574b850b0))


### Bug Fixes

* **decomposition_hint:** fix inconsistent decomposition hint format for zrm_chaifen.txt ([bc9168d](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/bc9168d24d73d81f4f0ff21f898c02a2d1a3f7a0))
* fix bugs in Lua code ([d427b36](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/d427b36a1ca5c5cd286356d98573f9ce36fddaff))
* fix linting issues ([b2b6e20](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/b2b6e20560c58b4427cc4b332ff1df5467f15550))
* **key_binder:** add missing nil check ([0a92d88](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/0a92d88652540296e433163d02bf81e4d1d54796))
* **keypad_composer:** fix extra digit committed when release keypad key ([b1ec360](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/b1ec3604cfa72ee3d94bb467c6b96352ffcca9b5))
* remove extra import_preset in schemas ([0ccf0af](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/0ccf0af0c39a543128bc16be3afcf5835e2c9961))
* **user_predict:** enable user_predict ([81ed501](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/81ed5012e449e68b68855feddf64d7d6a466956f))


### Performance Improvements

* **set_schema:** early return if input is not a valid command ([d1830b6](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/d1830b6a71e468f02ce6234a21abf2662ad7fb61))
* **unicode:** simplify unicode input pattern recognizing ([f92732b](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/f92732bd5a0c275ced6df099723c355e2348369c))


### Miscellaneous Chores

* change default algebra schema for wanxiang_pro to pinyin ([90535a7](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/90535a705ef3e8cfdef154b759919c20de8576a9))
* change file permissions ([db0b55a](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/db0b55a1fd239475722cf539f667a363dc4b31df))
* cleanup sub-schemas ([ff5086e](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/ff5086ed3bec8c54955da9ed7c29713d4ee65ef9))
* code cleanup ([ab4ddab](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/ab4ddab9e17ea7b10aa31d75e63a2374b8e05e32))
* merge v15.9.4 from upstream ([648e582](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/648e582058d8f6a3a02a8e488f4efbe6228a83be))
* **opencc:** Update OpenCC data to ver.1.3.0 ([113a2a9](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/113a2a91b1f4f1ba93456ca25dd7e97eed9bd334))
* remove derivative algebra for wanxiang_english ([09e1b78](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/09e1b788e94faa73e582385ab561eaca6e99269e))
* remove old replacer data ([803afbc](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/803afbcc9186a9ac768c975f36a47ec0f5ad6ff9))
* remove redundant recognizer patterns ([1e0bca6](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/1e0bca6131f37c6ed9b703f3555ec4a4768a335e))
* remove redundant schema config for wanxiang_mixedcode ([c992e09](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/c992e09e98c8523937c1cc593b11db3ef0bd5006))
* **super_filter:** improve custom_phrase escape ([ee666d2](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/ee666d2ce99609f7f5454c7fc1b6ff7c5826245c))
* **user_predict:** disable post prediction by default ([c21d178](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/c21d178bd3e7e0aa080919b6a22e8c9a224e45f4))


### Code Refactoring

* **english:** remove english path input handling ([c8693d5](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/c8693d59cc568fae62d457485c1c098896562a10))
* remove manual_segmentor ([bf12eb8](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/bf12eb8f2fa78c79a805c4c9337ae1f81020fda1))
* reorganize schema configs ([3731667](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/3731667020eb702b6da482970166dd5673b97a72))
* **sequencer:** remove sequencer ([0213bad](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/0213bad0431fc5936ae17f82cee1a913a71db44a))
* split super_filter into specialized filter modules ([85207c5](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/85207c5ef7a7101cd1213a341abfacbb0c8570d0))
* split super_processor into specialized modules ([1bd00b5](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/1bd00b541bd90b3e7714148151510d9d9c513713))
* **super_Replacer:** remove super_replacer ([070cfdd](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/070cfdd0e78a3284f849237322d3a95509d8a3be))

## [0.3.0](https://github.com/Fidelxyz/rime-wanxiang-slim/compare/v0.2.0...v0.3.0) (2026-04-19)


### ⚠ BREAKING CHANGES

* reorder switches
* merge v15.8.1 from upstream
* update default Weasel config
* disable lianxiang dictionary by default
* restore default punctuation behavior
* **super_processor:** disable backspace limit by default
* **charset_filter:** rename config fields
* **manual_segmentor:** extract manual_segmentor from super_processor

### Bug Fixes

* **super_comment:** fix incorrect default config for standard version ([835a7e9](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/835a7e92e1c736a4a264bd3e1602422600241122))
* **super_replacer:** fix super replacer not working due to incorrect option name in schema ([1adefa4](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/1adefa4604dd85e38fddd2f6a00af42cd8c041b7))


### Miscellaneous Chores

* change the ordering of character_selector ([42cfd35](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/42cfd357e4b0f6980285c77939484e6b58416597))
* code cleanup ([aca9172](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/aca91721654311f849ce3c625781005ff0f2e63e))
* disable lianxiang dictionary by default ([ed75ed0](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/ed75ed090d23f0f9de51ea29eb340b3b068b9b24))
* merge v15.8.1 from upstream ([de32257](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/de3225760f78b95914c6299538f6644af9e5b470))
* remove unused abbreviations data ([7d94b86](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/7d94b8641c0d94ff38e23c9eb88370609fbf3cdd))
* reorder switches ([5d408dc](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/5d408dc8f6d44c108f7fc2bc0d9d6ac7225d6e18))
* restore default punctuation behavior ([00124b6](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/00124b6cf88f61c312d48eb922ce077fe82bc17e))
* revert the change of `switcher/caption` from upstream ([f1c445c](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/f1c445ca55250138d2b1e6ca53408aeb4f2fd74a))
* **super_processor:** disable backspace limit by default ([278fe8e](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/278fe8e1e6035ea8f00e1a26156f3ede6630632e))
* update default Weasel config ([e673f9c](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/e673f9cff82514571cd293881abc05577c352260))


### Code Refactoring

* **charset_filter:** rename config fields ([4acba0c](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/4acba0c11925cb98f43159be4a5f0fecde305a64))
* **english:** extract english processor and filter from super_processor ([248ca19](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/248ca1915a3df01ac944fc14e725d40d2b677844))
* **lookup_filter:** cleanup code ([fa2548a](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/fa2548a757f42dbe7520560acc21cc70714d8dec))
* **manual_segmentor:** extract manual_segmentor from super_processor ([580bae3](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/580bae304c529cf3f4c91d7d3fb77ed205663b33))
* reorganize file structure ([473003d](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/473003dae09a86dc7992d226568667afadc13581))
* **super_comment:** rename super_comment_preedit to super_comment ([e700fcf](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/e700fcfba5ac39626dff93b045d26bd4b09877db))
* **super_replacer:** cleanup code ([a71cd5d](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/a71cd5d7c0875f38072143307780867505b65199))

## [0.2.0](https://github.com/Fidelxyz/rime-wanxiang-slim/compare/v0.1.1...v0.2.0) (2026-04-06)


### ⚠ BREAKING CHANGES

* **keypad_composer:** extract keypad_composer from super_processor
* disable Shift+Space for switching schema
* **super_comment:** organize super_comment configs
* **lookup_filter:** rename super_lookup to lookup_filter
* **english_filter:** rename super_english to english_filter
* **sequencer:** rename super_sequence to sequencer
* **character_selector:** extract character_selector from super_processor

### Bug Fixes

* **auto_phrase:** fix syncing error caused by memory not closed ([13b17a9](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/13b17a99abf7c58e72898c8d9541e912510fdc83))
* **set_schema:** cleanup and fix code for switching schema ([8be4168](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/8be416824c16924c6a083ccd85172664335585d0))
* **super_sequence:** not closing database manually ([5b466a6](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/5b466a6d98097d3888183deaa993c9cc29cb3823))


### Miscellaneous Chores

* cleanup code ([2903a9a](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/2903a9af5fc0d049666e6f61bf5c2f7d3e603cb8))
* cleanup custom yaml files ([5276834](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/52768349cf73dfa39d33811d8b5a29cefc5770f4))
* disable Shift+Space for switching schema ([1623cd7](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/1623cd73bf637329a41a9197a2641e640cfcc7d2))
* merge v15.5.0 from upstream ([2345771](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/2345771be95866c085cb727da47faaeceacbe480))
* merge v15.5.2 from upstream ([e0e1e02](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/e0e1e025c52c56315c98f4be6a0dd1e228982294))
* **partial_commit:** cleanup code ([c124ccf](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/c124ccfb2ffbe1094ca28620304b19f52069f328))
* remove unused config ([9bba22c](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/9bba22cc0dada1e73ac05fe0613b4df6534512c4))


### Code Refactoring

* **character_selector:** extract character_selector from super_processor ([8cf5611](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/8cf5611970d3a2e4e34b0157fa634b279640ed65))
* cleanup Lua code ([349a7b3](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/349a7b36a6029e1c53ef3f1a3d03b69e903dcf24))
* **english_filter:** rename super_english to english_filter ([cca68ce](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/cca68ce16ffcd0f9ba03440ed049acf255bafbe8))
* **keypad_composer:** extract keypad_composer from super_processor ([f72f703](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/f72f703b6ff5481b3912096549eb104dd08c80ed))
* **lookup_filter:** rename super_lookup to lookup_filter ([bc63e72](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/bc63e72e84c71f512b2a95be8d4d715784c27c71))
* move custom_phrase.txt to custom directory ([834db60](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/834db60e71396fcc4607aa091a311c921c893d92))
* **partial_commit:** cleanup partial_commit ([ecc0998](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/ecc099826ec7943c1dbe09461b439cb1bae482ab))
* **sequencer:** rename super_sequence to sequencer ([3b117f9](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/3b117f9dc2ca8ff6d007b0293607f56699cf7036))
* **super_comment:** organize super_comment configs ([3de20ca](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/3de20ca7a80c0ca53aaa106adab13f4c39f8609a))
* **super_sequence:** refactor super_sequence ([cdec247](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/cdec247e6bdb7f8750b6ae3635f513e81d8c931d))

## [0.1.1](https://github.com/Fidelxyz/rime_wanxiang/compare/v0.1.0...v0.1.1) (2026-03-24)


### Bug Fixes

* fix super_sequence error ([d22106d](https://github.com/Fidelxyz/rime_wanxiang/commit/d22106db08f204032ec09dcb0c55ce13cfddafb2))


### Miscellaneous Chores

* merge v15.3.6 from upstream ([4dea759](https://github.com/Fidelxyz/rime_wanxiang/commit/4dea759d7f7b8612d489e70a903ccaf8c06900d7))


### Code Refactoring

* add type annotations and cleanup codes ([873e285](https://github.com/Fidelxyz/rime_wanxiang/commit/873e285ccfb2d3bf816cf792c2ba778459ffaaa3))

## 0.1.0 (2026-03-19)


### Bug Fixes

* recover punctuator ([930101f](https://github.com/Fidelxyz/rime_wanxiang/commit/930101f1891b4122e5427bb20173c8217bf3820d))


### Performance Improvements

* optimize aux_go.py for dictionary generation speed ([1d130a9](https://github.com/Fidelxyz/rime_wanxiang/commit/1d130a9c20dc33ea7ff9ca928ca16e749315a80f))


### Miscellaneous Chores

* cleanup lua codes ([01bbe58](https://github.com/Fidelxyz/rime_wanxiang/commit/01bbe58654c6d1f37a77f47d42abf1b0fdb7d061))
* convert all CRLF and mixed line endings to LF ([7d96a95](https://github.com/Fidelxyz/rime_wanxiang/commit/7d96a9588ec79beed97265f5cf6e2e9eb8319902))
* merge v15.2.0 from upstream ([0c18da4](https://github.com/Fidelxyz/rime_wanxiang/commit/0c18da46475ed111c155d1fd95bca5ca50f24f29))
* reformat *.custom.yaml ([0db3f82](https://github.com/Fidelxyz/rime_wanxiang/commit/0db3f82e2be3b94987d452cc69c1c4cabf27d32d))
* reformat lua and yaml files ([6c1c7bf](https://github.com/Fidelxyz/rime_wanxiang/commit/6c1c7bf3507d2ff0943257853a5d7a7bd21679a5))


### Code Refactoring

* remove character repeating and variable formatting in custom phrases ([df0faaf](https://github.com/Fidelxyz/rime_wanxiang/commit/df0faaf57d1de89ac5c94148f5dcc03b79065bfd))
* remove fixing words feature (force_upper_aux) ([2bf5908](https://github.com/Fidelxyz/rime_wanxiang/commit/2bf5908ff171323ba802697a2e243161ffd4172e))
* remove paired symbols feature ([d47a66a](https://github.com/Fidelxyz/rime_wanxiang/commit/d47a66a5d2a4d3933a16ef5271404724b158cb6a))
* remove quick symbol input feature ([1a21e44](https://github.com/Fidelxyz/rime_wanxiang/commit/1a21e44a143416f8c0694f88581e6bf854a5b3b7))
* remove shijian, number translator, symbol input, calculator, statistics, and translation mode ([b4e07e1](https://github.com/Fidelxyz/rime_wanxiang/commit/b4e07e13a1cebdd9c93c66842e2b235f1e662017))
* remove super_tips feature (tips database, processor, keybinding, config) ([6c4e8d4](https://github.com/Fidelxyz/rime_wanxiang/commit/6c4e8d4a007677adbf5c945200f281cef5b1e927))
* remove T9 schema and 14/18 key layout support ([1e7dd99](https://github.com/Fidelxyz/rime_wanxiang/commit/1e7dd99bdc889ce964c0a2ead0e985e05aca42bd))
* remove tone input support (7890 keys, tone filtering, preedit tone display) ([d80a3ba](https://github.com/Fidelxyz/rime_wanxiang/commit/d80a3bad27a8d8c010a47e76a3a21a470c1cf181))
