# Changelog

## [15.9.4](https://github.com/Fidelxyz/rime-wanxiang-slim/compare/v15.8.1...v15.9.4) (2026-04-29)


### ⚠ BREAKING CHANGES

* merge v15.9.4 from upstream
* remove derivative algebra for wanxiang_english
* **user_predict:** enable user_predict

### Bug Fixes

* fix linting issues ([b2b6e20](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/b2b6e20560c58b4427cc4b332ff1df5467f15550))
* **key_binder:** add missing nil check ([0a92d88](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/0a92d88652540296e433163d02bf81e4d1d54796))
* **keypad_composer:** fix extra digit committed when release keypad key ([b1ec360](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/b1ec3604cfa72ee3d94bb467c6b96352ffcca9b5))
* remove extra import_preset in schemas ([0ccf0af](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/0ccf0af0c39a543128bc16be3afcf5835e2c9961))
* **user_predict:** enable user_predict ([81ed501](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/81ed5012e449e68b68855feddf64d7d6a466956f))


### Performance Improvements

* **set_schema:** early return if input is not a valid command ([d1830b6](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/d1830b6a71e468f02ce6234a21abf2662ad7fb61))


### Miscellaneous Chores

* merge v15.9.4 from upstream ([648e582](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/648e582058d8f6a3a02a8e488f4efbe6228a83be))
* remove derivative algebra for wanxiang_english ([09e1b78](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/09e1b788e94faa73e582385ab561eaca6e99269e))

## [15.8.1](https://github.com/Fidelxyz/rime-wanxiang-slim/compare/v15.5.2...v15.8.1) (2026-04-19)


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

* disable lianxiang dictionary by default ([ed75ed0](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/ed75ed090d23f0f9de51ea29eb340b3b068b9b24))
* merge v15.8.1 from upstream ([de32257](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/de3225760f78b95914c6299538f6644af9e5b470))
* reorder switches ([5d408dc](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/5d408dc8f6d44c108f7fc2bc0d9d6ac7225d6e18))
* restore default punctuation behavior ([00124b6](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/00124b6cf88f61c312d48eb922ce077fe82bc17e))
* **super_processor:** disable backspace limit by default ([278fe8e](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/278fe8e1e6035ea8f00e1a26156f3ede6630632e))
* update default Weasel config ([e673f9c](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/e673f9cff82514571cd293881abc05577c352260))


### Code Refactoring

* **charset_filter:** rename config fields ([4acba0c](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/4acba0c11925cb98f43159be4a5f0fecde305a64))
* **manual_segmentor:** extract manual_segmentor from super_processor ([580bae3](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/580bae304c529cf3f4c91d7d3fb77ed205663b33))

## [15.5.2](https://github.com/Fidelxyz/rime-wanxiang-slim/compare/v15.3.6...v15.5.2) (2026-04-06)


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

* disable Shift+Space for switching schema ([1623cd7](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/1623cd73bf637329a41a9197a2641e640cfcc7d2))
* merge v15.5.0 from upstream ([2345771](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/2345771be95866c085cb727da47faaeceacbe480))
* merge v15.5.2 from upstream ([e0e1e02](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/e0e1e025c52c56315c98f4be6a0dd1e228982294))


### Code Refactoring

* **character_selector:** extract character_selector from super_processor ([8cf5611](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/8cf5611970d3a2e4e34b0157fa634b279640ed65))
* **english_filter:** rename super_english to english_filter ([cca68ce](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/cca68ce16ffcd0f9ba03440ed049acf255bafbe8))
* **keypad_composer:** extract keypad_composer from super_processor ([f72f703](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/f72f703b6ff5481b3912096549eb104dd08c80ed))
* **lookup_filter:** rename super_lookup to lookup_filter ([bc63e72](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/bc63e72e84c71f512b2a95be8d4d715784c27c71))
* **sequencer:** rename super_sequence to sequencer ([3b117f9](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/3b117f9dc2ca8ff6d007b0293607f56699cf7036))
* **super_comment:** organize super_comment configs ([3de20ca](https://github.com/Fidelxyz/rime-wanxiang-slim/commit/3de20ca7a80c0ca53aaa106adab13f4c39f8609a))

## [15.3.6](https://github.com/Fidelxyz/rime_wanxiang/compare/v15.2.0...v15.3.6) (2026-03-24)


### 🐛 Bug 修复

* fix super_sequence error ([d22106d](https://github.com/Fidelxyz/rime_wanxiang/commit/d22106db08f204032ec09dcb0c55ce13cfddafb2))


### 💅 重构

* add type annotations and cleanup codes ([873e285](https://github.com/Fidelxyz/rime_wanxiang/commit/873e285ccfb2d3bf816cf792c2ba778459ffaaa3))


### 📖 文档

* update README and release note ([6de5544](https://github.com/Fidelxyz/rime_wanxiang/commit/6de5544ae5186349df131829a044697446086fe9))


### 🏡 杂项

* merge v15.3.6 from upstream ([4dea759](https://github.com/Fidelxyz/rime_wanxiang/commit/4dea759d7f7b8612d489e70a903ccaf8c06900d7))


### 🤖 持续集成

* update exclude files list and cleanup scripts ([e2c2711](https://github.com/Fidelxyz/rime_wanxiang/commit/e2c271190399aae99cdbc6c5a8f39341d06571b7))
* update release note ([e65afaf](https://github.com/Fidelxyz/rime_wanxiang/commit/e65afaf9406d095034ebf5233de05e0ec08ce764))

## 15.2.0 (2026-03-19)


### 🔥 性能优化

* optimize aux_go.py for dictionary generation speed ([1d130a9](https://github.com/Fidelxyz/rime_wanxiang/commit/1d130a9c20dc33ea7ff9ca928ca16e749315a80f))


### 🐛 Bug 修复

* recover punctuator ([930101f](https://github.com/Fidelxyz/rime_wanxiang/commit/930101f1891b4122e5427bb20173c8217bf3820d))


### 💅 重构

* remove character repeating and variable formatting in custom phrases ([df0faaf](https://github.com/Fidelxyz/rime_wanxiang/commit/df0faaf57d1de89ac5c94148f5dcc03b79065bfd))
* remove fixing words feature (force_upper_aux) ([2bf5908](https://github.com/Fidelxyz/rime_wanxiang/commit/2bf5908ff171323ba802697a2e243161ffd4172e))
* remove paired symbols feature ([d47a66a](https://github.com/Fidelxyz/rime_wanxiang/commit/d47a66a5d2a4d3933a16ef5271404724b158cb6a))
* remove quick symbol input feature ([1a21e44](https://github.com/Fidelxyz/rime_wanxiang/commit/1a21e44a143416f8c0694f88581e6bf854a5b3b7))
* remove shijian, number translator, symbol input, calculator, statistics, and translation mode ([b4e07e1](https://github.com/Fidelxyz/rime_wanxiang/commit/b4e07e13a1cebdd9c93c66842e2b235f1e662017))
* remove super_tips feature (tips database, processor, keybinding, config) ([6c4e8d4](https://github.com/Fidelxyz/rime_wanxiang/commit/6c4e8d4a007677adbf5c945200f281cef5b1e927))
* remove T9 schema and 14/18 key layout support ([1e7dd99](https://github.com/Fidelxyz/rime_wanxiang/commit/1e7dd99bdc889ce964c0a2ead0e985e05aca42bd))
* remove tone input support (7890 keys, tone filtering, preedit tone display) ([d80a3ba](https://github.com/Fidelxyz/rime_wanxiang/commit/d80a3bad27a8d8c010a47e76a3a21a470c1cf181))


### 📖 文档

* add instructions for merging from upstream ([72e0c28](https://github.com/Fidelxyz/rime_wanxiang/commit/72e0c288638fdedee95c48c986bb5713d1021ae9))
* clear changelog from upstream ([8f51507](https://github.com/Fidelxyz/rime_wanxiang/commit/8f5150733dc15d156c1cecb8fe03dd97a691dcab))
* init for agents ([183bdf6](https://github.com/Fidelxyz/rime_wanxiang/commit/183bdf6e081a3846832ad4f4d5d7c57a5eece432))
* rewrite PATCH_GUIDE and update README ([5f54fce](https://github.com/Fidelxyz/rime_wanxiang/commit/5f54fceed6c400b0416fdaf0f6e6ff37ad95cd4b))
* rewrite README to remove deleted features and simplify ([c4ae635](https://github.com/Fidelxyz/rime_wanxiang/commit/c4ae6353078fb9e761261af30a703db64887b2f1))
* simplify AGENTS.md ([b1528a1](https://github.com/Fidelxyz/rime_wanxiang/commit/b1528a124189bc8cf5872d2de257958c3e70c3bc))
* update README ([ecbbfa9](https://github.com/Fidelxyz/rime_wanxiang/commit/ecbbfa9164bde3d18aae8db3fc8968221cef4253))
* update README and FEATURES ([d055169](https://github.com/Fidelxyz/rime_wanxiang/commit/d0551697cb930fbf00ec44436c2a19207b53a402))


### 🏡 杂项

* cleanup lua codes ([01bbe58](https://github.com/Fidelxyz/rime_wanxiang/commit/01bbe58654c6d1f37a77f47d42abf1b0fdb7d061))
* convert all CRLF and mixed line endings to LF ([7d96a95](https://github.com/Fidelxyz/rime_wanxiang/commit/7d96a9588ec79beed97265f5cf6e2e9eb8319902))
* merge v15.2.0 from upstream ([0c18da4](https://github.com/Fidelxyz/rime_wanxiang/commit/0c18da46475ed111c155d1fd95bca5ca50f24f29))
* reformat *.custom.yaml ([0db3f82](https://github.com/Fidelxyz/rime_wanxiang/commit/0db3f82e2be3b94987d452cc69c1c4cabf27d32d))
* reformat lua and yaml files ([6c1c7bf](https://github.com/Fidelxyz/rime_wanxiang/commit/6c1c7bf3507d2ff0943257853a5d7a7bd21679a5))
* **wanxiang:** release 14.9.0 ([19fa156](https://github.com/Fidelxyz/rime_wanxiang/commit/19fa156f5cce1a80f0392dda72437dce8af5222e))


### 🤖 持续集成

* cleanup build scripts ([62d3c0d](https://github.com/Fidelxyz/rime_wanxiang/commit/62d3c0d6c6dec633427c6b94267f3a1eb8ce194d))
* cleanup build scripts and modify zip arguments to improve performance ([76e0536](https://github.com/Fidelxyz/rime_wanxiang/commit/76e05365e67c95bfcb1898aab897c7fec66314e2))
* exclude markdown and image files from release packages ([2ce6f67](https://github.com/Fidelxyz/rime_wanxiang/commit/2ce6f67aec8539690d14d7bd72e4072c0c3e5fb5))
* fix release workflow ([6987143](https://github.com/Fidelxyz/rime_wanxiang/commit/6987143e294c47267ca608c19bf97af7a8baf00f))
* remove workflow for building Android app and fix typo ([9d3fa2c](https://github.com/Fidelxyz/rime_wanxiang/commit/9d3fa2c41bf012fcbb1e71b1b3fea2ad12a6c727))
* rename default branch from wanxiang to main ([1381c7c](https://github.com/Fidelxyz/rime_wanxiang/commit/1381c7c8078acf96d2e1098eec92295a4ccd882c))
