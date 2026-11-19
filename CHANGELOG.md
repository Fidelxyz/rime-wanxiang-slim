# 更新日志

## [1.3.0-beta.1](https://github.com/Fidelxyz/rime-wanxiang-slim/compare/v1.2.0...v1.3.0-beta.1) (2026-11-19)


### 新增功能

* 基于 ESDB 和 wordfreq 生成英文词库 ([f9a66fb](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/f9a66fbdb799c5dd2584c07927fa906ac73459d4))


### 问题修复

* 为主翻译器关闭词语补全 ([086adf3](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/086adf3221d930f4d97ade3cab39d8f3e214cd0f))


### 重构

* 移除名人和艺人词库 ([1708efc](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/1708efc57659cbd1173368b5f3674cc202c7480f))

## [1.2.0](https://github.com/Fidelxyz/rime-wanxiang-slim/compare/v1.1.1...v1.2.0) (2026-11-17)


### 新增功能

* 新增开关 `disable_english`，用于关闭英文输入 ([c5a5a6d](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/c5a5a6d68c9eb0c70f1e8a4d1c4b5ee60d537194))
* **lookup_filter:** 辅助码查询支持声调数字 ([b396917](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/b39691761ec7f92a58392ec2e315a3be55e8604c))


### 问题修复

* 移除过时的生成词库和数据表 ([40ec12a](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/40ec12ab85c77c6b2ca3eea27835d9d240142ac6))
* 使用主词库查询用户词组和置顶候选 ([#38](https://github.com/Fidelxyz/rime-wanxiang-slim/issues/38)) ([4155e76](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/4155e76614c0d8048399769aa380204ffe19c5a9))


### 杂项

* **dicts:** 同步上游词库元数据 ([a30e1aa](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/a30e1aa4055f6a4ae8f8de78f812715442f0a179))
* **dicts:** 从上游更新词库至 v18.1.8 ([e819672](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/e8196728724b3dcd714cfafb9c71d7bafd0cd80b))
* 在 Issue 模板中使用 Issue 类型 ([daf31c3](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/daf31c3c6b5608e9f57f167b41b1062872285c70))


### 重构

* 明确词库源文件与目标文件的命名 ([b2a0abe](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/b2a0abe5c673638233af0ad740337994ee2b97fa))
* 移除冗余的方案元数据和引擎配置块 ([a357e31](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/a357e317a99dfea493e1b78f9c0a577d46481b02))
* 移除未使用的简拼开关 ([14fc861](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/14fc861e827f66b69232ce3d5961a9ecd6b5f244))

## [1.2.0-beta.2](https://github.com/Fidelxyz/rime-wanxiang-slim/compare/v1.2.0-beta.1...v1.2.0-beta.2) (2026-11-11)


### 问题修复

* 使用主词库查询用户词组和置顶候选 ([#38](https://github.com/Fidelxyz/rime-wanxiang-slim/issues/38)) ([4155e76](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/4155e76614c0d8048399769aa380204ffe19c5a9))

## [1.2.0-beta.1](https://github.com/Fidelxyz/rime-wanxiang-slim/compare/v1.1.1...v1.2.0-beta.1) (2026-11-07)


### 新增功能

* 新增开关 `disable_english`，用于关闭英文输入 ([c5a5a6d](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/c5a5a6d68c9eb0c70f1e8a4d1c4b5ee60d537194))
* **lookup_filter:** 辅助码查询支持声调数字 ([b396917](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/b39691761ec7f92a58392ec2e315a3be55e8604c))


### 问题修复

* 移除过时的生成词库和数据表 ([40ec12a](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/40ec12ab85c77c6b2ca3eea27835d9d240142ac6))


### 杂项

* **dicts:** 同步上游词库元数据 ([a30e1aa](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/a30e1aa4055f6a4ae8f8de78f812715442f0a179))
* **dicts:** 从上游更新词库至 v18.1.8 ([e819672](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/e8196728724b3dcd714cfafb9c71d7bafd0cd80b))


### 重构

* 明确词库源文件与目标文件的命名 ([b2a0abe](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/b2a0abe5c673638233af0ad740337994ee2b97fa))
* 移除冗余的方案元数据和引擎配置块 ([a357e31](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/a357e317a99dfea493e1b78f9c0a577d46481b02))
* 移除未使用的简拼开关 ([14fc861](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/14fc861e827f66b69232ce3d5961a9ecd6b5f244))

## [1.1.1](https://github.com/Fidelxyz/rime-wanxiang-slim/compare/v1.1.0...v1.1.1) (2026-10-30)


### 问题修复

* 在默认用户词库设置下启用自动造词 ([9ea20ab](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/9ea20abe2fa3741a8f57f5d515cb01b95e14bd93))

## [1.1.1-beta.1](https://github.com/Fidelxyz/rime-wanxiang-slim/compare/v1.1.0...v1.1.1-beta.1) (2026-10-28)


### 问题修复

* 在默认用户词库设置下启用自动造词 ([9ea20ab](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/9ea20abe2fa3741a8f57f5d515cb01b95e14bd93))

## [1.1.0](https://github.com/Fidelxyz/rime-wanxiang-slim/compare/v1.0.1...v1.1.0) (2026-10-22)


### 新增功能

* 新增开关斜杠命令的配置项 ([09b59f4](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/09b59f4e1934ba3546d6300c883573582b3a6119))


### 问题修复

* 为基础方案关闭自动造词 ([3c6422d](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/3c6422d18c24b7f4534e0c55b974eed86169d351))
* 在显示过滤器中保留候选包装 ([ba62a34](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/ba62a341bfbfce99131bcef3ea5b3e4bc51229f9))


### 性能优化

* 通过 tags_match 跳过未激活的 Lua 过滤器 ([07a0ff8](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/07a0ff8cd1f91557ccdf9f45cbea4cb2fc496ea7))
* 在用户词库为空时跳过用户词组和置顶候选查询 ([48eb984](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/48eb98452012e9aef2522a8873c97b1003372a7d))
* 使用稀疏词库查询用户词组和置顶候选 ([a2432ec](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/a2432ecaecde715bee698c309bc486928235ece4))


### 杂项

* 整理自定义文件模板 ([be53b35](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/be53b353a891020d2b1b0c8225abfca080082168))


### 重构

* 将用户词库翻译器和造词器拆分为独立模块 ([738e5e0](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/738e5e015893cec77c49132922f7425af0460db2))

## [1.1.0-beta.1](https://github.com/Fidelxyz/rime-wanxiang-slim/compare/v1.0.1...v1.1.0-beta.1) (2026-10-14)


### 新增功能

* 新增开关斜杠命令的配置项 ([09b59f4](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/09b59f4e1934ba3546d6300c883573582b3a6119))


### 问题修复

* 为基础方案关闭自动造词 ([24f6f8a](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/24f6f8a078097deaf9964ae78e4d574548a485d2))
* 在显示过滤器中保留候选包装 ([ba62a34](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/ba62a341bfbfce99131bcef3ea5b3e4bc51229f9))


### 性能优化

* 通过 tags_match 跳过未激活的 Lua 过滤器 ([b650988](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/b650988829462347c691f56a15430d55e06777a5))
* 在用户词库为空时跳过用户词组和置顶候选查询 ([14cdd36](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/14cdd362a3ff1c37a786962eafa4c25a587a3849))


### 杂项

* 整理自定义文件模板 ([be53b35](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/be53b353a891020d2b1b0c8225abfca080082168))

## [1.0.1](https://github.com/Fidelxyz/rime-wanxiang-slim/compare/v1.0.0...v1.0.1) (2026-10-10)


### 问题修复

* 改进 Lua 错误日志和故障报告 ([5c417d9](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/5c417d993ce2fb37c20533f79a6b3fa793132c06))


### 性能优化

* 用脚本翻译器替代候选置顶过滤器 ([14ba937](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/14ba937793861f6565088642e89ee7149e2c70d5))


### 杂项

* **algebra:** 合并上游的 ng 规范化修复 (3b93aac) ([0251c32](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/0251c32637300ac107dcd153d4e835cdfa432124))
* **algebra:** 从上游更新拼写运算规则 (5da7227) ([beff04f](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/beff04f7b89705081090ccdcfb531394fdf042ca))
* **dicts:** 从上游更新词库至 v18.0.15 ([704d5c9](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/704d5c9e6838d243481135fcb11085fbba19fb73))
* 改进发布说明中下载部分的格式 ([60eac13](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/60eac133295cfc6f40c7cd8ee63d06db06a73f14))
* **punctuation:** 改进默认标点 ([d5a0a58](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/d5a0a584a184ab39517fc875e86fe9a89b3eab3c))
* 统一各翻译器的 `spelling_hints` ([3fc5ec8](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/3fc5ec877ed744b3a28406e18131004b3d33dcd2))


### 重构

* **algebra:** 通用化辅助码推导 ([a6436d9](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/a6436d9e081c9d74f62ae0c98a0a9e1c1126b863))
* **algebra:** 统一拼写运算中的特殊字符范围 ([840de47](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/840de4710fb90224429a84b9ae5c111b446ca515))
* 提取共享的文件工具函数 ([4619fc7](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/4619fc79f49c873dbc3d64ec7311b3ad0c3729d9))

## [1.0.1-beta.1](https://github.com/Fidelxyz/rime-wanxiang-slim/compare/v1.0.0...v1.0.1-beta.1) (2026-10-06)


### 问题修复

* 改进 Lua 错误日志和故障报告 ([5c417d9](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/5c417d993ce2fb37c20533f79a6b3fa793132c06))


### 性能优化

* 用脚本翻译器替代候选置顶过滤器 ([14ba937](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/14ba937793861f6565088642e89ee7149e2c70d5))


### 杂项

* **algebra:** 合并上游的 ng 规范化修复 (3b93aac) ([0251c32](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/0251c32637300ac107dcd153d4e835cdfa432124))
* **algebra:** 从上游更新拼写运算规则 (5da7227) ([beff04f](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/beff04f7b89705081090ccdcfb531394fdf042ca))
* **dicts:** 从上游更新词库至 v18.0.15 ([704d5c9](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/704d5c9e6838d243481135fcb11085fbba19fb73))
* 改进发布说明中下载部分的格式 ([60eac13](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/60eac133295cfc6f40c7cd8ee63d06db06a73f14))
* **punctuation:** 改进默认标点 ([d5a0a58](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/d5a0a584a184ab39517fc875e86fe9a89b3eab3c))
* 统一各翻译器的 `spelling_hints` ([3fc5ec8](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/3fc5ec877ed744b3a28406e18131004b3d33dcd2))


### 重构

* **algebra:** 通用化辅助码推导 ([a6436d9](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/a6436d9e081c9d74f62ae0c98a0a9e1c1126b863))
* **algebra:** 统一拼写运算中的特殊字符范围 ([840de47](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/840de4710fb90224429a84b9ae5c111b446ca515))
* 提取共享的文件工具函数 ([4619fc7](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/4619fc79f49c873dbc3d64ec7311b3ad0c3729d9))

## [1.0.0](https://github.com/Fidelxyz/rime-wanxiang-slim/compare/v0.6.0...v1.0.0) (2026-09-20)


### ⚠ 破坏性变更

* **algebra:** 升级到该版本时，需手动更新自定义文件 `custom.yaml` 中 `speller/algebra` 补丁至 `custom` 目录下模板文件中新的格式。
* 移除中英混合词库

### 新增功能

* 新增安装脚本 ([ec4e93c](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/ec4e93c359cd493fcc4a1073caac0a7491356c7d))
* Pro 方案支持乱序17 ([ee15391](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/ee15391f28e8727d5a519521f561cf619c00db5c))
* 支持蓝天双拼和大牛双拼反查 ([ba8f45b](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/ba8f45b682d9a459fba7c9269fa0d2b9038d8b43))
* **version_displayer:** `/version` 命令显示辅助码方案 ([55cd442](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/55cd442d17938dadb69da9acf6f1ca8a1ebeacac))


### 问题修复

* 为 `env.engine.schema.config` 添加 nil 检查 ([2bd1acc](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/2bd1acc72fe6ff04453bd5268f814467fd363ea0))
* 修复重复的辅助模式检测字符 ([7c85502](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/7c85502c1f163eb6033fa55ca8dac7d5faf83ee0))
* 修复 librime-lua contrib 的类型注解 ([531a7a9](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/531a7a92c02701d90655c6a11b6f3dcb1c1c4f28))
* 使 install.sh 兼容 PowerShell 5.1 ([5747e11](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/5747e1135b36a6bb1e6cfdf4b72b4d8abac70fea))
* 仅置顶匹配整个输入段的候选 ([58c3508](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/58c35086bd2d947bb738dd19fe0c34d034eb9f76))


### 杂项

* **algebra:** 从上游更新拼写运算规则 (469262e) ([fd07528](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/fd07528861b19fe143e31e42b111adbd5dee20df))
* **algebra:** 从上游更新拼写运算规则 (d738f2a) ([22430ed](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/22430edfba961095611698563dff2e2553a85d7c))
* 整理拼写运算规则 ([f90df11](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/f90df11ea30c5a8c9524bbc254ffaab8af11f7b7))
* 整理代码 ([3ab57ea](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/3ab57eabb967da819fb2cf7c7ff9fa0bea609f58))
* **dicts:** 从上游更新词库至 v17.9.2 ([ebba37f](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/ebba37f0ef9c22bcd50f4b7e6702f0b245f29dbc))
* **dicts:** 更新 OpenCC 数据至 ver.1.4.2 ([fa3c002](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/fa3c002b658c2302d417167d4248f4add9904b82))
* **schema_switcher:** 简化方案切换器逻辑 ([32583ab](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/32583ab53f0cc0f9fd4e7aa837d954c1bf5248c6))
* 更新 LSP 和 linter 配置 ([259c601](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/259c6017a52713114be5bc222f47e3d2376a8e51))
* 发布 v1 ([1546f41](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/1546f4170d55a2091be702e27b459e84d3b0bb0b))
* 发布 v1 ([7badbd9](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/7badbd90f55aff18eef1d42eff89c7c41cde2ac8))


### 重构

* **algebra:** 统一拼写运算补丁配置 ([3fa26fc](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/3fa26fcb236144c30f01f4305c6ba18ab2056ee4))
* 移除中英混合词库 ([f328d83](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/f328d83cd171fb45b9a41b6b95b8d33dc3b56e25))
* 重命名 Lua 模块以明确职责 ([1f01dd5](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/1f01dd5e8acd73f041a68ca5165e86a1ed485277))

## [1.0.0-beta.2](https://github.com/Fidelxyz/rime-wanxiang-slim/compare/v1.0.0-beta.1...v1.0.0-beta.2) (2026-09-18)


### 新增功能

* 新增安装脚本 ([ec4e93c](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/ec4e93c359cd493fcc4a1073caac0a7491356c7d))
* Pro 方案支持乱序17 ([ee15391](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/ee15391f28e8727d5a519521f561cf619c00db5c))
* 支持蓝天双拼和大牛双拼反查 ([ba8f45b](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/ba8f45b682d9a459fba7c9269fa0d2b9038d8b43))
* **version_displayer:** `/version` 命令显示辅助码方案 ([55cd442](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/55cd442d17938dadb69da9acf6f1ca8a1ebeacac))


### 问题修复

* 修复重复的辅助模式检测字符 ([7c85502](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/7c85502c1f163eb6033fa55ca8dac7d5faf83ee0))
* 仅置顶匹配整个输入段的候选 ([58c3508](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/58c35086bd2d947bb738dd19fe0c34d034eb9f76))


### 杂项

* **algebra:** 从上游更新拼写运算规则 (d738f2a) ([22430ed](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/22430edfba961095611698563dff2e2553a85d7c))


### 重构

* 重命名 Lua 模块以明确职责 ([1f01dd5](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/1f01dd5e8acd73f041a68ca5165e86a1ed485277))

## [1.0.0-beta.1](https://github.com/Fidelxyz/rime-wanxiang-slim/compare/v0.6.0...v1.0.0-beta.1) (2026-09-05)


### ⚠ 破坏性变更

* 移除中英混合词库

### 问题修复

* 为 `env.engine.schema.config` 添加 nil 检查 ([2bd1acc](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/2bd1acc72fe6ff04453bd5268f814467fd363ea0))
* 修复 librime-lua contrib 的类型注解 ([531a7a9](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/531a7a92c02701d90655c6a11b6f3dcb1c1c4f28))


### 杂项

* 整理拼写运算规则 ([f90df11](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/f90df11ea30c5a8c9524bbc254ffaab8af11f7b7))
* 整理代码 ([3ab57ea](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/3ab57eabb967da819fb2cf7c7ff9fa0bea609f58))
* **dicts:** 从上游更新词库至 v17.9.2 ([ebba37f](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/ebba37f0ef9c22bcd50f4b7e6702f0b245f29dbc))
* **dicts:** 更新 OpenCC 数据至 ver.1.4.2 ([fa3c002](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/fa3c002b658c2302d417167d4248f4add9904b82))
* 更新 LSP 和 linter 配置 ([259c601](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/259c6017a52713114be5bc222f47e3d2376a8e51))
* 发布 v1 ([7badbd9](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/7badbd90f55aff18eef1d42eff89c7c41cde2ac8))


### 重构

* 移除中英混合词库 ([f328d83](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/f328d83cd171fb45b9a41b6b95b8d33dc3b56e25))

## [0.6.0](https://github.com/Fidelxyz/rime-wanxiang-slim/compare/v0.5.0...v0.6.0) (2026-08-22)


### ⚠ 破坏性变更

* **lookup_filter:** 重命名 lookup_filter 配置项
* **algebra:** 重命名模糊音拼写运算规则
* **charset_filter:** 重新组织字符集过滤器配置
* **lookup_filter:** 使用单一反查词库
* 移除英文自动空格
* **english_user_dict_appender:** 统一中文和英文用户词库造词器的触发方式
* **comment_hint_displayer:** 重构 super_comment

### 新增功能

* **candidate_pinner:** 新增候选置顶器 ([bd4efaa](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/bd4efaa59be965d553be5fc5571c6f65020a4b54))
* **user_dict_appender:** 造词模式下去除整句候选并始终显示提示 ([e8d3fbc](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/e8d3fbc6c1e86dacdb9ac2b6365f547ce99e26b0))
* **version_displayer:** 新增版本显示器 ([055333c](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/055333cf96214ee29c2326756a82e2cf35daa1dd))


### 问题修复

* **build:** 跳过对排除词库的处理 ([eee70d4](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/eee70d44248c5594c95474dee92f1c8a125426f8))
* **charset_filter:** 跳过对用户词库候选的字符集过滤 ([ecb8736](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/ecb8736e5cddb38c009426c7e6b02dda93390a2e))
* 修正 Projection.load 规则的类型 ([0048c36](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/0048c36ae03efa3936466bab84597e665675d1bf))
* 修复 librime contrib 中错误的类型注解 ([2bd92ca](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/2bd92ca757158a8238d4f05dd854d800155acbff))
* 修复 librime-lua 类型存根 ([8b073da](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/8b073da7f95dcdb2e8612db84e4cc1ac78201173))
* 在 mira_report 中刷新子进程输出以实时显示 ([fe8d0e1](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/fe8d0e1f9cbd13b71d63161a55ce66f70b6cca80))
* **utils:** 修正 escape_for_pattern 中魔法字符的转义 ([7fc6aac](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/7fc6aacb6524047db8751b6a480526251d880e29))


### 性能优化

* **lookup_filter:** 短路查询数据源 ([282d5e6](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/282d5e66c103a497b18df2721e20861935b0b7cf))
* **lookup_filter:** 通过分段冷热缓存实现更智能的查询缓存淘汰 ([67788dd](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/67788dd60524a0f9902a54f4ac5786c4f6df572c))
* 优化列表追加操作 ([81e1e32](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/81e1e32f61c2b2af0314d1a9bcdf530c0a11e484))


### 杂项

* 新增问题报告和功能请求的 Issue 模板 ([b308502](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/b308502589642676a7b7c423d15a84aa367dc577))
* **algebra:** 从上游更新拼写运算规则 (f219fbf) ([9b94f44](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/9b94f44cf34c087737b16aab3481d67fe4ebd52e))
* 整理代码 ([0dbeb18](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/0dbeb1852f113775c115e9374be31205f1649bbc))
* 整理方案文件中的词库配置 ([f746f60](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/f746f602cb18cf93e19bdd59ca8e4a4c29ada13c))
* 整理 generate_pro_dicts.py ([c0a7cef](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/c0a7cefe0a00141a4b3c74cd30e0ba91877e1732))
* 整理方案文件 ([d630db7](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/d630db7c200adea6d96419b508ee4d98e50e4bb2))
* 整理代码 ([85eac46](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/85eac462d37eb4782b2561530119dba91fa6ac3e))
* **dicts:** 从上游更新词库至 v16.0.1 ([06c9de5](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/06c9de549c82057a48eaf74d5d7f2e6c2594b503))
* **dicts:** 从上游更新词库至 v17.0.3 ([e8f42d5](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/e8f42d59be66bd40efd08a14f051056c8ba526ac))
* **dicts:** 更新 OpenCC 数据至 ver.1.4.0 ([6999090](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/6999090eaaf3f6384c14fc128a43aa500b9ef23c))
* **dicts:** 更新 OpenCC 数据至 ver.1.4.1 ([e5b0be5](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/e5b0be5b898ed6ccd08f1921326816c745ad19be))
* **docs:** 更新依赖 ([649ef39](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/649ef393cec723775abcdde67dffe74f94688082))
* 改进候选类型处理及文档 ([06dccfc](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/06dccfcbb8925c2689670207db84c9d0c813a61a))
* **lookup_filter:** 整理代码 ([4577f7f](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/4577f7fc950f514f74f2a2b70abaa922348a3c38))
* 合并上游 v15.16.0 ([ceaeeed](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/ceaeeed74e499d15eecb526bfc347d78aaf4e343))
* **opencc:** 更新 OpenCC 数据至 ver.1.3.1 ([b751556](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/b751556b504f8900186dae11bd3238c553c2830d))
* **opencc:** 更新 OpenCC 数据至 ver.1.3.2 ([2abd33b](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/2abd33bab893850a361fbd7fb784cfea63fac5ad))
* 移除 Lua 脚本中的默认按键映射 ([cb25c71](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/cb25c712b09e567a52603cc0bc410c88fe1c8519))
* 更新问题报告 Issue 模板 ([b949f2b](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/b949f2b5b83ef352413379534600d36e2aa66ed3))
* 升级 StyLua 使用的 Lua 语法版本 ([76e9d5e](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/76e9d5e7aa49c3b159587c52492ff6893c5fb3cc))


### 重构

* **algebra:** 重命名模糊音拼写运算规则 ([58c9701](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/58c9701a7f88777e0991eb11f724498241633c9f))
* **candidate_code_recorder:** 从 auto_phrase 中提取 candidate_code_recorder ([3b80b9f](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/3b80b9fd0d4f2d29a3974967cadcc07127ad427d))
* **charset_filter:** 重新组织字符集过滤器配置 ([1b808b9](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/1b808b987d0e520f302edb2079750a2a51f010bf))
* **comment_hint_displayer:** 重构 super_comment ([9c0f440](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/9c0f44077e447b633701541fde8699c7c37b7ce2))
* **english_user_dict_appender:** 从 auto_phrase 中提取 english_user_dict_appender ([bca7369](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/bca7369fb53bfa46af452600f24ca8f27f872d8b))
* **english_user_dict_appender:** 统一中文和英文用户词库造词器的触发方式 ([a628cc0](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/a628cc090951f3c9f23b00df93f394e69b8774d3))
* 从 wanxiang.lua 中提取冗余的辅助函数 ([abdeda5](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/abdeda52a12fcfa7c66314baf7a622ccdfa8907c))
* 从上游源数据生成 Pro 辅助码数据 ([5f98bc0](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/5f98bc0bfba3f2db96037c413335e089f9079033))
* **lookup_filter:** 重命名 lookup_filter 配置项 ([79b5038](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/79b5038d757a510a9e89c320451aa295055fb17a))
* **lookup_filter:** 简化触发器和提示器的处理 ([248d1cd](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/248d1cde81c0973d5a13ca8d146a2fff33eed16f))
* **lookup_filter:** 使用单一反查词库 ([1507442](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/150744249f48443b95b29c717dc259a6fdc9ee18))
* 整理 Lua 模块 ([c61aec1](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/c61aec12bd6e640cfd64944c5432f0b6194763c3))
* **partial_committer:** 将 partial_commit 重命名为 partial_committer ([d88e40a](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/d88e40a20ba62dcac6828af27cc90d1afe490ee2))
* **phrase_escaper:** 将 escape_filter 重命名为 phrase_escaper ([91bc61e](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/91bc61e6d448d5bc4c7bf088c3de304491f38f9c))
* **preedit_tone_displayer:** 将 preedit_tone_display 重命名为 preedit_tone_displayer ([f9da5a1](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/f9da5a1c8ff294e214f5be7ea207c88c9b65bb25))
* 移除英文自动空格 ([34358ab](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/34358ab77a30226236a8b30049916505d2e4481a))
* 移除兜底过滤器 ([b485d41](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/b485d4120adb2f5afde6b18e9b456f1d5bd8f34f))
* 移除重排过滤器 ([4dfb211](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/4dfb2116da3f3837e222613d0a7fff2afa6ae52c))
* 重新组织方案源数据 ([570f222](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/570f222c13480367fa89b9ec054fdaa83d9e3eb6))
* 拆分英文模块并整理代码 ([3e526f7](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/3e526f79ab91f2c1bca6ae075ed87b4fc84d65b8))

## [0.6.0-beta.4](https://github.com/Fidelxyz/rime-wanxiang-slim/compare/v0.6.0-beta.3...v0.6.0-beta.4) (2026-08-02)


### ⚠ 破坏性变更

* **lookup_filter:** 使用单一反查词库

### 问题修复

* 修正 Projection.load 规则的类型 ([0048c36](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/0048c36ae03efa3936466bab84597e665675d1bf))
* **utils:** 修正 escape_for_pattern 中魔法字符的转义 ([7fc6aac](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/7fc6aacb6524047db8751b6a480526251d880e29))


### 性能优化

* **lookup_filter:** 短路查询数据源 ([282d5e6](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/282d5e66c103a497b18df2721e20861935b0b7cf))
* **lookup_filter:** 通过分段冷热缓存实现更智能的查询缓存淘汰 ([67788dd](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/67788dd60524a0f9902a54f4ac5786c4f6df572c))


### 杂项

* **dicts:** 从上游更新词库至 v17.0.3 ([e8f42d5](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/e8f42d59be66bd40efd08a14f051056c8ba526ac))
* **dicts:** 更新 OpenCC 数据至 ver.1.4.1 ([e5b0be5](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/e5b0be5b898ed6ccd08f1921326816c745ad19be))
* **lookup_filter:** 整理代码 ([4577f7f](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/4577f7fc950f514f74f2a2b70abaa922348a3c38))


### 重构

* 从上游源数据生成 Pro 辅助码数据 ([5f98bc0](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/5f98bc0bfba3f2db96037c413335e089f9079033))
* **lookup_filter:** 简化触发器和提示器的处理 ([248d1cd](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/248d1cde81c0973d5a13ca8d146a2fff33eed16f))
* **lookup_filter:** 使用单一反查词库 ([1507442](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/150744249f48443b95b29c717dc259a6fdc9ee18))
* 重新组织方案源数据 ([570f222](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/570f222c13480367fa89b9ec054fdaa83d9e3eb6))

## [0.6.0-beta.3](https://github.com/Fidelxyz/rime-wanxiang-slim/compare/v0.6.0-beta.2...v0.6.0-beta.3) (2026-07-07)


### ⚠ 破坏性变更

* 移除英文自动空格
* **english_user_dict_appender:** 统一中文和英文用户词库造词器的触发方式

### 新增功能

* **user_dict_appender:** 造词模式下去除整句候选并始终显示提示 ([e8d3fbc](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/e8d3fbc6c1e86dacdb9ac2b6365f547ce99e26b0))


### 问题修复

* **build:** 跳过对排除词库的处理 ([eee70d4](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/eee70d44248c5594c95474dee92f1c8a125426f8))
* 修复 librime-lua 类型存根 ([8b073da](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/8b073da7f95dcdb2e8612db84e4cc1ac78201173))


### 杂项

* 整理代码 ([0dbeb18](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/0dbeb1852f113775c115e9374be31205f1649bbc))
* 整理 generate_pro_dicts.py ([c0a7cef](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/c0a7cefe0a00141a4b3c74cd30e0ba91877e1732))
* 整理代码 ([85eac46](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/85eac462d37eb4782b2561530119dba91fa6ac3e))
* **dicts:** 从上游更新词库至 v16.0.1 ([06c9de5](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/06c9de549c82057a48eaf74d5d7f2e6c2594b503))
* **dicts:** 更新 OpenCC 数据至 ver.1.4.0 ([6999090](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/6999090eaaf3f6384c14fc128a43aa500b9ef23c))
* 合并上游 v15.16.0 ([ceaeeed](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/ceaeeed74e499d15eecb526bfc347d78aaf4e343))
* **opencc:** 更新 OpenCC 数据至 ver.1.3.2 ([2abd33b](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/2abd33bab893850a361fbd7fb784cfea63fac5ad))


### 重构

* **english_user_dict_appender:** 从 auto_phrase 中提取 english_user_dict_appender ([bca7369](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/bca7369fb53bfa46af452600f24ca8f27f872d8b))
* **english_user_dict_appender:** 统一中文和英文用户词库造词器的触发方式 ([a628cc0](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/a628cc090951f3c9f23b00df93f394e69b8774d3))
* 整理 Lua 模块 ([c61aec1](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/c61aec12bd6e640cfd64944c5432f0b6194763c3))
* 移除英文自动空格 ([34358ab](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/34358ab77a30226236a8b30049916505d2e4481a))
* 移除重排过滤器 ([4dfb211](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/4dfb2116da3f3837e222613d0a7fff2afa6ae52c))
* 拆分英文模块并整理代码 ([3e526f7](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/3e526f79ab91f2c1bca6ae075ed87b4fc84d65b8))

## [0.6.0-beta.2](https://github.com/Fidelxyz/rime-wanxiang-slim/compare/v0.6.0-beta.1...v0.6.0-beta.2) (2026-06-08)


### ⚠ 破坏性变更

* **comment_hint_displayer:** 重构 super_comment

### 新增功能

* **version_displayer:** 新增版本显示器 ([055333c](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/055333cf96214ee29c2326756a82e2cf35daa1dd))


### 问题修复

* 修复 librime contrib 中错误的类型注解 ([2bd92ca](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/2bd92ca757158a8238d4f05dd854d800155acbff))


### 杂项

* 新增问题报告和功能请求的 Issue 模板 ([b308502](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/b308502589642676a7b7c423d15a84aa367dc577))
* 整理方案文件 ([d630db7](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/d630db7c200adea6d96419b508ee4d98e50e4bb2))
* **docs:** 更新依赖 ([649ef39](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/649ef393cec723775abcdde67dffe74f94688082))
* **opencc:** 更新 OpenCC 数据至 ver.1.3.1 ([b751556](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/b751556b504f8900186dae11bd3238c553c2830d))
* 更新问题报告 Issue 模板 ([b949f2b](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/b949f2b5b83ef352413379534600d36e2aa66ed3))
* 升级 StyLua 使用的 Lua 语法版本 ([76e9d5e](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/76e9d5e7aa49c3b159587c52492ff6893c5fb3cc))


### 重构

* **comment_hint_displayer:** 重构 super_comment ([9c0f440](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/9c0f44077e447b633701541fde8699c7c37b7ce2))
* 从 wanxiang.lua 中提取冗余的辅助函数 ([abdeda5](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/abdeda52a12fcfa7c66314baf7a622ccdfa8907c))
* **partial_committer:** 将 partial_commit 重命名为 partial_committer ([d88e40a](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/d88e40a20ba62dcac6828af27cc90d1afe490ee2))
* **phrase_escaper:** 将 escape_filter 重命名为 phrase_escaper ([91bc61e](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/91bc61e6d448d5bc4c7bf088c3de304491f38f9c))
* **preedit_tone_displayer:** 将 preedit_tone_display 重命名为 preedit_tone_displayer ([f9da5a1](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/f9da5a1c8ff294e214f5be7ea207c88c9b65bb25))
* 移除兜底过滤器 ([b485d41](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/b485d4120adb2f5afde6b18e9b456f1d5bd8f34f))

## [0.6.0-beta.1](https://github.com/Fidelxyz/rime-wanxiang-slim/compare/v0.5.0...v0.6.0-beta.1) (2026-05-30)


### 新增功能

* **candidate_pinner:** 新增候选置顶器 ([bd4efaa](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/bd4efaa59be965d553be5fc5571c6f65020a4b54))


### 性能优化

* 优化列表追加操作 ([81e1e32](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/81e1e32f61c2b2af0314d1a9bcdf530c0a11e484))


### 杂项

* 整理方案文件中的词库配置 ([f746f60](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/f746f602cb18cf93e19bdd59ca8e4a4c29ada13c))
* 改进候选类型处理及文档 ([06dccfc](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/06dccfcbb8925c2689670207db84c9d0c813a61a))
* 移除 Lua 脚本中的默认按键映射 ([cb25c71](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/cb25c712b09e567a52603cc0bc410c88fe1c8519))


### 重构

* **candidate_code_recorder:** 从 auto_phrase 中提取 candidate_code_recorder ([3b80b9f](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/3b80b9fd0d4f2d29a3974967cadcc07127ad427d))

## [0.5.0](https://github.com/Fidelxyz/rime-wanxiang-slim/compare/v0.4.0...v0.5.0) (2026-05-27)


### ⚠ 破坏性变更

* **charset_filter:** 将 `base` 选项重命名为 `charset`
* 合并上游 v15.11.0
* **user_predict:** 移除候选预测
* 更改用户词库名称
* 重命名用户词库组件

### 新增功能

* **preedit_tone:** 重新引入编码区全拼转换 ([2c902b0](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/2c902b080e36d44cbb929763018db7f00fab5bc1))
* **preedit_tone:** 重新引入编码区声调显示 ([61e1c88](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/61e1c88380716a49161a8327ca67772f2ea2a11e))
* 从上游重新引入声调输入 ([530e3a7](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/530e3a7dd1b1168e21ad0692f37375e732ce00ba))


### 问题修复

* **charset:** 修复字符集过滤器中白名单与黑名单颠倒的问题 ([d339a81](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/d339a81d667c2364d4d82b3a3788d70e8a066037))
* **english:** 修复英文候选的大小写 ([2e17717](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/2e177170852e6b5e702384dc14fdc1fc87cdd6e1))
* **english:** 在 chain-breaker 处理器中忽略按键释放事件 ([123dfba](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/123dfba858f0e1d77e8a158983939a77e084b6c1))
* 修正 librime.lua 中的版权信息 ([36a2c00](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/36a2c005722186d79f45a4c6472b1c2535a9bfef))
* 修正错误的 `config_version` ([4bb52a7](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/4bb52a791ef702bb3e56bbd3d2679707d8f7fc49))
* 防止在开头添加反引号时光标移到末尾 ([7a3cc68](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/7a3cc68cde83512e6d7749ca0eebecf0abe88203))
* 为 `rime_api.get_time_ms` 提供后备实现以兼容小狼毫 ([5c73ac2](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/5c73ac28cb896117587cd52ca96c2952fffea1eb))


### 性能优化

* 优化读取页面大小 ([a5e516a](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/a5e516aba38f4807b061707ca11bbf088674b6ba))


### 杂项

* 为 librime.lua 添加版权头 ([bb91ac2](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/bb91ac24991acc464dd1f501e00adb681fcabbc9))
* 更改方案名称 ([41e9b02](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/41e9b02b0f11b4528ecd33bd5677b07369ba2639))
* 更改用户词库名称 ([0503e5c](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/0503e5c07150b29c10b1efbf4a885363f405a14b))
* **charset_filter:** 整理字符集过滤器代码 ([1294f9d](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/1294f9da827af96c67b29e3562a07c5f28ca77ef))
* 整理 Lua 代码 ([fe6ec1d](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/fe6ec1dc48ebcb434d9fde815b6e45f07e02965c))
* 清理 candidate_type_marker 中的冗余检查 ([840915d](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/840915d6d172ad3f5d64aa95a89ce5eb1798a616))
* 整理方案注释 ([2308327](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/23083271c2750e0306488a865f1af99d90c18fa8))
* 关闭英文整句 ([ff666cc](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/ff666ccb30377d12a58932eb079e063532808beb))
* 改进切换器选项的显示 ([2126f38](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/2126f38aa5a2dccf093cc2cc5618dfe22fe62c82))
* 合并上游 v15.11.0 ([73d188f](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/73d188f76a773e9eaf032a0466bb577a0af717aa))
* 移除针对英文整句候选的 hack ([eccfcae](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/eccfcae3ff930c01df28a469753d7905c7a2aa22))


### 重构

* **charset_filter:** 将 `base` 选项重命名为 `charset` ([5c55b2d](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/5c55b2d5f18805d58c9b422cd5bb900bf951e0c3))
* **english:** 移除英文候选数量限制 ([1c43b78](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/1c43b78f14f9879421e126119fa0b48fac790cbd))
* **english:** 移除后备的英文单词推导 ([4436b28](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/4436b28915e1ea8c01a67e9a3688c883bc419414))
* 移除 sentence_filter ([0434a7b](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/0434a7bb4a1ea2faf468c84ddb89e5ee6dbac3ed))
* 重命名用户词库组件 ([8883806](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/8883806657f110cff64660c4f911c879bb621793))
* 拆分 preedit_tone_display 和 preedit_pinyin_expander ([3cbfa00](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/3cbfa00aed391891d176d6f786ace3437e35fa9f))
* **tone_corrector:** 将 tone_fallback 重命名为 tone_corrector ([d1081b9](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/d1081b93390656afb84a795a67cff0f1a352ae4f))
* **user_predict:** 移除候选预测 ([22dcac8](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/22dcac88da02228ea9a7f58417a2af6fad81f9cd))


### 持续集成

* 新增预发布工作流 ([9c67425](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/9c67425dc6d9b50a0da1c4ee683d4d119889c250))
* 将预发布版本后缀改为 beta ([ec6a0e8](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/ec6a0e8ca3dd020b13eb2f7330293c491b00f712))
* 修复多分支发布工作流 ([162771f](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/162771fe5f9b343196655b4fa935255539ccd70d))

## [0.5.0-beta.3](https://github.com/Fidelxyz/rime-wanxiang-slim/compare/v0.5.0-beta.2...v0.5.0-beta.3) (2026-05-22)


### 问题修复

* 修正错误的 `config_version` ([4bb52a7](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/4bb52a791ef702bb3e56bbd3d2679707d8f7fc49))

## [0.5.0-beta.2](https://github.com/Fidelxyz/rime-wanxiang-slim/compare/v0.5.0-beta.1...v0.5.0-beta.2) (2026-05-22)


### ⚠ 破坏性变更

* 合并上游 v15.11.0

### 杂项

* 为 librime.lua 添加版权头 ([bb91ac2](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/bb91ac24991acc464dd1f501e00adb681fcabbc9))
* 整理 Lua 代码 ([fe6ec1d](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/fe6ec1dc48ebcb434d9fde815b6e45f07e02965c))
* 合并上游 v15.11.0 ([73d188f](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/73d188f76a773e9eaf032a0466bb577a0af717aa))
* 移除针对英文整句候选的 hack ([eccfcae](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/eccfcae3ff930c01df28a469753d7905c7a2aa22))


### 重构

* 拆分 preedit_tone_display 和 preedit_pinyin_expander ([3cbfa00](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/3cbfa00aed391891d176d6f786ace3437e35fa9f))

## [0.5.0-beta.1](https://github.com/Fidelxyz/rime-wanxiang-slim/compare/v0.4.0...v0.5.0-beta.1) (2026-05-21)


### ⚠ 破坏性变更

* **user_predict:** 移除候选预测
* 更改用户词库名称
* 重命名用户词库组件

### 新增功能

* **preedit_tone:** 重新引入编码区全拼转换 ([2c902b0](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/2c902b080e36d44cbb929763018db7f00fab5bc1))
* **preedit_tone:** 重新引入编码区声调显示 ([61e1c88](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/61e1c88380716a49161a8327ca67772f2ea2a11e))
* 从上游重新引入声调输入 ([530e3a7](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/530e3a7dd1b1168e21ad0692f37375e732ce00ba))


### 问题修复

* 防止在开头添加反引号时光标移到末尾 ([7a3cc68](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/7a3cc68cde83512e6d7749ca0eebecf0abe88203))


### 性能优化

* 优化读取页面大小 ([a5e516a](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/a5e516aba38f4807b061707ca11bbf088674b6ba))


### 杂项

* 更改用户词库名称 ([0503e5c](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/0503e5c07150b29c10b1efbf4a885363f405a14b))
* 整理方案注释 ([2308327](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/23083271c2750e0306488a865f1af99d90c18fa8))
* 关闭英文整句 ([ff666cc](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/ff666ccb30377d12a58932eb079e063532808beb))
* 改进切换器选项的显示 ([2126f38](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/2126f38aa5a2dccf093cc2cc5618dfe22fe62c82))


### 重构

* 重命名用户词库组件 ([8883806](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/8883806657f110cff64660c4f911c879bb621793))
* **user_predict:** 移除候选预测 ([22dcac8](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/22dcac88da02228ea9a7f58417a2af6fad81f9cd))


### 持续集成

* 新增预发布工作流 ([9c67425](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/9c67425dc6d9b50a0da1c4ee683d4d119889c250))
* 将预发布版本后缀改为 beta ([ec6a0e8](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/ec6a0e8ca3dd020b13eb2f7330293c491b00f712))

## [0.4.0](https://github.com/Fidelxyz/rime-wanxiang-slim/compare/v0.3.0...v0.4.0) (2026-05-03)


### ⚠ 破坏性变更

* 将 super_processor 拆分为专门的模块
* 将 super_filter 拆分为专门的过滤器模块
* 移除 manual_segmentor
* **sequencer:** 移除 sequencer
* **super_filter:** 改进 custom_phrase 转义
* **english:** 移除英文路径输入处理
* **user_predict:** 默认关闭上屏后预测
* **super_Replacer:** 移除 super_replacer
* 合并上游 v15.9.4
* 移除 wanxiang_english 的派生拼写运算
* **user_predict:** 启用 user_predict

### 新增功能

* 借助 OpenCC 重新引入拆分提示 ([ef363f0](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/ef363f0ff696b6a5383e44b0a9058237683e5d91))
* 借助 OpenCC 支持 emoji ([0bbb41a](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/0bbb41a98201467166291efe208e3716ab29534e))
* 借助 OpenCC 支持简繁转换 ([f932258](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/f932258d2d9b24309557dc311dca40c574b850b0))


### 问题修复

* **decomposition_hint:** 修复 zrm_chaifen.txt 拆分提示格式不一致的问题 ([bc9168d](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/bc9168d24d73d81f4f0ff21f898c02a2d1a3f7a0))
* 修复 Lua 代码中的错误 ([d427b36](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/d427b36a1ca5c5cd286356d98573f9ce36fddaff))
* 修复代码检查问题 ([b2b6e20](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/b2b6e20560c58b4427cc4b332ff1df5467f15550))
* **key_binder:** 添加缺失的 nil 检查 ([0a92d88](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/0a92d88652540296e433163d02bf81e4d1d54796))
* **keypad_composer:** 修复释放小键盘按键时多上屏一个数字的问题 ([b1ec360](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/b1ec3604cfa72ee3d94bb467c6b96352ffcca9b5))
* 移除方案中多余的 import_preset ([0ccf0af](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/0ccf0af0c39a543128bc16be3afcf5835e2c9961))
* **user_predict:** 启用 user_predict ([81ed501](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/81ed5012e449e68b68855feddf64d7d6a466956f))


### 性能优化

* **set_schema:** 输入不是有效命令时提前返回 ([d1830b6](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/d1830b6a71e468f02ce6234a21abf2662ad7fb61))
* **unicode:** 简化 Unicode 输入模式的识别 ([f92732b](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/f92732bd5a0c275ced6df099723c355e2348369c))


### 杂项

* 将 wanxiang_pro 的默认拼写运算方案改为全拼 ([90535a7](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/90535a705ef3e8cfdef154b759919c20de8576a9))
* 更改文件权限 ([db0b55a](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/db0b55a1fd239475722cf539f667a363dc4b31df))
* 整理子方案 ([ff5086e](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/ff5086ed3bec8c54955da9ed7c29713d4ee65ef9))
* 整理代码 ([ab4ddab](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/ab4ddab9e17ea7b10aa31d75e63a2374b8e05e32))
* 合并上游 v15.9.4 ([648e582](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/648e582058d8f6a3a02a8e488f4efbe6228a83be))
* **opencc:** 更新 OpenCC 数据至 ver.1.3.0 ([113a2a9](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/113a2a91b1f4f1ba93456ca25dd7e97eed9bd334))
* 移除 wanxiang_english 的派生拼写运算 ([09e1b78](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/09e1b788e94faa73e582385ab561eaca6e99269e))
* 移除旧的替换器数据 ([803afbc](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/803afbcc9186a9ac768c975f36a47ec0f5ad6ff9))
* 移除冗余的识别器模式 ([1e0bca6](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/1e0bca6131f37c6ed9b703f3555ec4a4768a335e))
* 移除 wanxiang_mixedcode 的冗余方案配置 ([c992e09](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/c992e09e98c8523937c1cc593b11db3ef0bd5006))
* **super_filter:** 改进 custom_phrase 转义 ([ee666d2](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/ee666d2ce99609f7f5454c7fc1b6ff7c5826245c))
* **user_predict:** 默认关闭上屏后预测 ([c21d178](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/c21d178bd3e7e0aa080919b6a22e8c9a224e45f4))


### 重构

* **english:** 移除英文路径输入处理 ([c8693d5](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/c8693d59cc568fae62d457485c1c098896562a10))
* 移除 manual_segmentor ([bf12eb8](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/bf12eb8f2fa78c79a805c4c9337ae1f81020fda1))
* 重新组织方案配置 ([3731667](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/3731667020eb702b6da482970166dd5673b97a72))
* **sequencer:** 移除 sequencer ([0213bad](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/0213bad0431fc5936ae17f82cee1a913a71db44a))
* 将 super_filter 拆分为专门的过滤器模块 ([85207c5](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/85207c5ef7a7101cd1213a341abfacbb0c8570d0))
* 将 super_processor 拆分为专门的模块 ([1bd00b5](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/1bd00b541bd90b3e7714148151510d9d9c513713))
* **super_Replacer:** 移除 super_replacer ([070cfdd](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/070cfdd0e78a3284f849237322d3a95509d8a3be))

## [0.3.0](https://github.com/Fidelxyz/rime-wanxiang-slim/compare/v0.2.0...v0.3.0) (2026-04-19)


### ⚠ 破坏性变更

* 调整开关顺序
* 合并上游 v15.8.1
* 更新小狼毫默认配置
* 默认关闭联想词库
* 恢复默认标点行为
* **super_processor:** 默认关闭退格限制
* **charset_filter:** 重命名配置字段
* **manual_segmentor:** 从 super_processor 中提取 manual_segmentor

### 问题修复

* **super_comment:** 修正标准版错误的默认配置 ([835a7e9](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/835a7e92e1c736a4a264bd3e1602422600241122))
* **super_replacer:** 修复因方案中选项名称错误导致 super_replacer 不生效的问题 ([1adefa4](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/1adefa4604dd85e38fddd2f6a00af42cd8c041b7))


### 杂项

* 调整 character_selector 的顺序 ([42cfd35](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/42cfd357e4b0f6980285c77939484e6b58416597))
* 整理代码 ([aca9172](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/aca91721654311f849ce3c625781005ff0f2e63e))
* 默认关闭联想词库 ([ed75ed0](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/ed75ed090d23f0f9de51ea29eb340b3b068b9b24))
* 合并上游 v15.8.1 ([de32257](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/de3225760f78b95914c6299538f6644af9e5b470))
* 移除未使用的缩写数据 ([7d94b86](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/7d94b8641c0d94ff38e23c9eb88370609fbf3cdd))
* 调整开关顺序 ([5d408dc](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/5d408dc8f6d44c108f7fc2bc0d9d6ac7225d6e18))
* 恢复默认标点行为 ([00124b6](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/00124b6cf88f61c312d48eb922ce077fe82bc17e))
* 撤销上游对 `switcher/caption` 的修改 ([f1c445c](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/f1c445ca55250138d2b1e6ca53408aeb4f2fd74a))
* **super_processor:** 默认关闭退格限制 ([278fe8e](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/278fe8e1e6035ea8f00e1a26156f3ede6630632e))
* 更新小狼毫默认配置 ([e673f9c](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/e673f9cff82514571cd293881abc05577c352260))


### 重构

* **charset_filter:** 重命名配置字段 ([4acba0c](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/4acba0c11925cb98f43159be4a5f0fecde305a64))
* **english:** 从 super_processor 中提取英文处理器和过滤器 ([248ca19](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/248ca1915a3df01ac944fc14e725d40d2b677844))
* **lookup_filter:** 整理代码 ([fa2548a](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/fa2548a757f42dbe7520560acc21cc70714d8dec))
* **manual_segmentor:** 从 super_processor 中提取 manual_segmentor ([580bae3](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/580bae304c529cf3f4c91d7d3fb77ed205663b33))
* 重新组织文件结构 ([473003d](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/473003dae09a86dc7992d226568667afadc13581))
* **super_comment:** 将 super_comment_preedit 重命名为 super_comment ([e700fcf](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/e700fcfba5ac39626dff93b045d26bd4b09877db))
* **super_replacer:** 整理代码 ([a71cd5d](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/a71cd5d7c0875f38072143307780867505b65199))

## [0.2.0](https://github.com/Fidelxyz/rime-wanxiang-slim/compare/v0.1.1...v0.2.0) (2026-04-06)


### ⚠ 破坏性变更

* **keypad_composer:** 从 super_processor 中提取 keypad_composer
* 禁用 Shift+Space 切换方案
* **super_comment:** 整理 super_comment 配置
* **lookup_filter:** 将 super_lookup 重命名为 lookup_filter
* **english_filter:** 将 super_english 重命名为 english_filter
* **sequencer:** 将 super_sequence 重命名为 sequencer
* **character_selector:** 从 super_processor 中提取 character_selector

### 问题修复

* **auto_phrase:** 修复因未关闭 memory 导致的同步错误 ([13b17a9](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/13b17a99abf7c58e72898c8d9541e912510fdc83))
* **set_schema:** 整理并修复切换方案的代码 ([8be4168](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/8be416824c16924c6a083ccd85172664335585d0))
* **super_sequence:** 不再手动关闭数据库 ([5b466a6](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/5b466a6d98097d3888183deaa993c9cc29cb3823))


### 杂项

* 整理代码 ([2903a9a](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/2903a9af5fc0d049666e6f61bf5c2f7d3e603cb8))
* 整理自定义 YAML 文件 ([5276834](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/52768349cf73dfa39d33811d8b5a29cefc5770f4))
* 禁用 Shift+Space 切换方案 ([1623cd7](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/1623cd73bf637329a41a9197a2641e640cfcc7d2))
* 合并上游 v15.5.0 ([2345771](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/2345771be95866c085cb727da47faaeceacbe480))
* 合并上游 v15.5.2 ([e0e1e02](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/e0e1e025c52c56315c98f4be6a0dd1e228982294))
* **partial_commit:** 整理代码 ([c124ccf](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/c124ccfb2ffbe1094ca28620304b19f52069f328))
* 移除未使用的配置 ([9bba22c](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/9bba22cc0dada1e73ac05fe0613b4df6534512c4))


### 重构

* **character_selector:** 从 super_processor 中提取 character_selector ([8cf5611](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/8cf5611970d3a2e4e34b0157fa634b279640ed65))
* 整理 Lua 代码 ([349a7b3](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/349a7b36a6029e1c53ef3f1a3d03b69e903dcf24))
* **english_filter:** 将 super_english 重命名为 english_filter ([cca68ce](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/cca68ce16ffcd0f9ba03440ed049acf255bafbe8))
* **keypad_composer:** 从 super_processor 中提取 keypad_composer ([f72f703](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/f72f703b6ff5481b3912096549eb104dd08c80ed))
* **lookup_filter:** 将 super_lookup 重命名为 lookup_filter ([bc63e72](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/bc63e72e84c71f512b2a95be8d4d715784c27c71))
* 将 custom_phrase.txt 移至 custom 目录 ([834db60](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/834db60e71396fcc4607aa091a311c921c893d92))
* **partial_commit:** 整理 partial_commit ([ecc0998](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/ecc099826ec7943c1dbe09461b439cb1bae482ab))
* **sequencer:** 将 super_sequence 重命名为 sequencer ([3b117f9](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/3b117f9dc2ca8ff6d007b0293607f56699cf7036))
* **super_comment:** 整理 super_comment 配置 ([3de20ca](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/3de20ca7a80c0ca53aaa106adab13f4c39f8609a))
* **super_sequence:** 重构 super_sequence ([cdec247](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/cdec247e6bdb7f8750b6ae3635f513e81d8c931d))

## [0.1.1](https://github.com/Fidelxyz/rime_wanxiang/compare/v0.1.0...v0.1.1) (2026-03-24)


### 问题修复

* 修复 super_sequence 错误 ([d22106d](https://github.com/Fidelxyz/rime_wanxiang/commit/d22106db08f204032ec09dcb0c55ce13cfddafb2))


### 杂项

* 合并上游 v15.3.6 ([4dea759](https://github.com/Fidelxyz/rime_wanxiang/commit/4dea759d7f7b8612d489e70a903ccaf8c06900d7))


### 重构

* 添加类型注解并整理代码 ([873e285](https://github.com/Fidelxyz/rime_wanxiang/commit/873e285ccfb2d3bf816cf792c2ba778459ffaaa3))

## 0.1.0 (2026-03-19)


### 问题修复

* 恢复 punctuator ([930101f](https://github.com/Fidelxyz/rime_wanxiang/commit/930101f1891b4122e5427bb20173c8217bf3820d))


### 性能优化

* 优化 aux_go.py 的词库生成速度 ([1d130a9](https://github.com/Fidelxyz/rime_wanxiang/commit/1d130a9c20dc33ea7ff9ca928ca16e749315a80f))


### 杂项

* 整理 Lua 代码 ([01bbe58](https://github.com/Fidelxyz/rime_wanxiang/commit/01bbe58654c6d1f37a77f47d42abf1b0fdb7d061))
* 将所有 CRLF 和混合换行符转换为 LF ([7d96a95](https://github.com/Fidelxyz/rime_wanxiang/commit/7d96a9588ec79beed97265f5cf6e2e9eb8319902))
* 合并上游 v15.2.0 ([0c18da4](https://github.com/Fidelxyz/rime_wanxiang/commit/0c18da46475ed111c155d1fd95bca5ca50f24f29))
* 重新格式化 *.custom.yaml ([0db3f82](https://github.com/Fidelxyz/rime_wanxiang/commit/0db3f82e2be3b94987d452cc69c1c4cabf27d32d))
* 重新格式化 Lua 和 YAML 文件 ([6c1c7bf](https://github.com/Fidelxyz/rime_wanxiang/commit/6c1c7bf3507d2ff0943257853a5d7a7bd21679a5))


### 重构

* 移除自定义短语中的字符重复和变量格式化 ([df0faaf](https://github.com/Fidelxyz/rime_wanxiang/commit/df0faaf57d1de89ac5c94148f5dcc03b79065bfd))
* 移除固定词功能（force_upper_aux） ([2bf5908](https://github.com/Fidelxyz/rime_wanxiang/commit/2bf5908ff171323ba802697a2e243161ffd4172e))
* 移除成对符号功能 ([d47a66a](https://github.com/Fidelxyz/rime_wanxiang/commit/d47a66a5d2a4d3933a16ef5271404724b158cb6a))
* 移除快捷符号输入功能 ([1a21e44](https://github.com/Fidelxyz/rime_wanxiang/commit/1a21e44a143416f8c0694f88581e6bf854a5b3b7))
* 移除时间日期、数字翻译器、符号输入、计算器、统计和翻译模式 ([b4e07e1](https://github.com/Fidelxyz/rime_wanxiang/commit/b4e07e13a1cebdd9c93c66842e2b235f1e662017))
* 移除 super_tips 功能（提示数据库、处理器、快捷键、配置） ([6c4e8d4](https://github.com/Fidelxyz/rime_wanxiang/commit/6c4e8d4a007677adbf5c945200f281cef5b1e927))
* 移除 T9 方案以及 14/18 键布局支持 ([1e7dd99](https://github.com/Fidelxyz/rime_wanxiang/commit/1e7dd99bdc889ce964c0a2ead0e985e05aca42bd))
* 移除声调输入支持（7890 键、声调过滤、编码区声调显示） ([d80a3ba](https://github.com/Fidelxyz/rime_wanxiang/commit/d80a3bad27a8d8c010a47e76a3a21a470c1cf181))
