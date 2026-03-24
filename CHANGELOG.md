# Changelog

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
