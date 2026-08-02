---
outline: deep
---

# 候选排序

## 候选置顶

在输入法窗口中，按下 `Ctrl` + `P` 置顶所选候选，按下 `Ctrl` + `L` 取消置顶。

置顶记录储存于用户数据库 `pinned.userdb`，可通过 Rime 的「同步用户数据」功能在设备间同步。

```yaml
candidate_pinner:
  # 启用候选置顶功能。
  enabled: true

  # 置顶当前候选的按键。
  pin_key: "Control+p"

  # 取消置顶当前候选的按键。
  unpin_key: "Control+l"
```

## 单字 / 词组优先

在[方案选单](https://github.com/rime/home/wiki/UserGuide#%E4%BD%BF%E7%94%A8%E6%96%B9%E6%A1%88%E9%81%B8%E5%96%AE)中切换「词组先」/「单字先」选项，控制单字与词组编码重合时优先显示单字或词组。
