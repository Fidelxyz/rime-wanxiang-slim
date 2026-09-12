---
outline: deep
---

# 模糊音

模糊音规则允许输入的声母或韵母匹配另一种读音。

## 可选规则

| 模糊音 | 配置引用 |
| --- | --- |
| n ↔ l | `wanxiang_algebra:/模糊音_n_l` |
| r ↔ y | `wanxiang_algebra:/模糊音_r_y` |
| h ↔ f | `wanxiang_algebra:/模糊音_h_f` |
| r ↔ l | `wanxiang_algebra:/模糊音_r_l` |
| k ↔ g | `wanxiang_algebra:/模糊音_k_g` |
| en ↔ eng | `wanxiang_algebra:/模糊音_en_eng` |
| in ↔ ing | `wanxiang_algebra:/模糊音_in_ing` |
| c ↔ ch | `wanxiang_algebra:/模糊音_c_ch` |
| z ↔ zh | `wanxiang_algebra:/模糊音_z_zh` |
| s ↔ sh | `wanxiang_algebra:/模糊音_s_sh` |

## 配置

可在自定义文件 `custom.yaml` 中，启用特定的模糊音规则。

```yaml
patch:
  speller/algebra:
    __patch:
      # 取消注释以开启模糊音。具体规则见 wanxiang_algebra.yaml。
      #- wanxiang_algebra:/模糊音_n_l
      #- wanxiang_algebra:/模糊音_r_y
      #- wanxiang_algebra:/模糊音_h_f
      #- wanxiang_algebra:/模糊音_r_l
      #- wanxiang_algebra:/模糊音_k_g
      #- wanxiang_algebra:/模糊音_en_eng
      #- wanxiang_algebra:/模糊音_in_ing
      #- wanxiang_algebra:/模糊音_c_ch
      #- wanxiang_algebra:/模糊音_z_zh
      #- wanxiang_algebra:/模糊音_s_sh
```
