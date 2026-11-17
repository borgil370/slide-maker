# 配色主题

slides 通过 CSS 变量 + 主题类名切换主题（模板 `cli-dark-example.html` 用的是 `<html class="dark">` + `html:not(.dark)` 选择器；更早的原版用 `data-theme` 属性——以你基于的模板为准，不要混用）。结构、变量名保持不变，只换值。

## dark-wenku（默认，「漆黑/苍色/蓝」深色主题）

源自配色参考图：漆黑 `#161823`、苍色 `#75878A`、蓝 `#44CEF6`。新 deck 默认使用此主题（`<html class="dark">`，localStorage 无记录时回退 dark）。

| 变量 | 值 | 说明 |
|---|---|---|
| `--bg` | `#161823` | 页面背景（漆黑） |
| `--surface` | `#1C1F2E` | 卡片/代码块底 |
| `--surface-strong` | `#222634` | 强调卡片底 |
| `--text` | `#E9EBF0` | 主文字（近白） |
| `--text-secondary` | `#9AA0AE` | 次要文字（苍色系调亮） |
| `--text-tertiary` | `#75878A` | 三级文字（苍色） |
| `--border` | `#2A2E3E` | 分隔线 |
| `--border-strong` | `#343949` | 强边框 |
| `--accent` | `#44CEF6` | 强调蓝：标签、编号、强调词、边框、进度点 |
| `--accent-light` | `#6FDAF8` | hover/亮色变体 |
| `--accent-muted` | `rgba(68,206,246,0.12)` | accent 淡底色（标签背景等） |
| `--shadow` | `rgba(0,0,0,0.35) 0 4px 24px` | 阴影 |

body 背景装饰径向渐变改用蓝色系：`rgba(68,206,246,0.10)` / `rgba(68,206,246,0.06)`。

## light-wenku（原版浅色主题）

完整变量值见 `references/design-spec.md` 第 2 节（米白底 `#F6F4F1`、青绿 accent `#2A9182`）。保留在 `[data-theme="light"]` 下供切换。

## 使用规则

- accent 单色原则：全片只有一个强调色，不用第二种彩色。
- 主题切换 JS 与 localStorage key 保留，key 按项目改名（如 `ev-<topic>-theme`）。
- accent 单色原则：全片只有一个强调色，不用第二种彩色。
