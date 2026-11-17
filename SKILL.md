---
name: slide-maker
description: 把任意内容（教程、文章、文档、大纲）制作成「零到全栈」风格的自包含 HTML slides——全屏 scroll-snap 翻页、霞鹜文楷 + JetBrains Mono 字体、单色 accent 极简编辑风，支持深色（漆黑#161823/苍色#75878A/蓝#44CEF6）与浅色（米白/青绿）双主题，内置键盘/圆点导航、reveal 动画、E 键编辑与 Ctrl+S 导出。当用户说"把这个内容做成 slides/幻灯片"、"用零到全栈风格做 slides"、"扒那个 slides 的样式做一套"、或需要修改/续做该风格的现有 deck 时使用。
---

# Zero-to-Tech 风格 Slides 制作

## 概述

复刻 slides.xn--ygr25xpohxwz.com/zero-to-tech 的 slides 设计：单文件 HTML、每页 100vw×100dvh 全屏流式画布 + scroll-snap（非 16:9 固定尺寸），右侧圆点导航，reveal 渐显动画，dark/light 主题切换，演讲者工具（E 键编辑、Ctrl+S 导出 HTML）。

## 工作流程

### 1. 准备内容大纲

把源内容（文章/教程/文档）按内容量拆成若干页（通常 6–20 页，内容少就少拆）：封面（title-slide）→ 各内容页 → 结尾（quote-slide）。每页 3–6 条要点，演示友好，不堆大段文字；代码块原文照录。

### 2. 读设计规范

读 `references/design-spec.md`（完整架构、CSS 变量、13 种页面类型的 HTML 骨架与 CSS、JS 交互机制）。需要换配色时读 `references/color-themes.md`（dark-wenku 深色主题为默认；light-wenku 为原版浅色）。

### 3. 准备字体与素材

霞鹜文楷字体不随 skill 分发（约 78MB），首次使用时下载到输出项目的 `assets/fonts/`：

```bash
mkdir -p assets/fonts assets/logo
BASE="https://slides.xn--ygr25xpohxwz.com/slides-zero-to-tech/assets"
for f in LXGWWenKai-Light LXGWWenKai-Regular LXGWWenKai-Medium; do
  curl -sL -o "assets/fonts/$f.ttf" "$BASE/fonts/$f.ttf"
done
```

本机缓存（若存在可直接复制）：`/Users/lina/Vibe Coding/Tools/现代CLI编程工具-Slides/assets/fonts/`。
logo 从 skill 的 `assets/logo/icon-light.svg` 复制；dark 主题下主题切换逻辑会找 `icon-dark.svg`，复制一份改名即可（两主题共用同一图形、不变色，是有意的妥协）。JetBrains Mono 用 Google Fonts CDN 链接。HTML 中用相对路径 `assets/fonts/...` 引用。

### 4. 构建 HTML

以 `assets/templates/cli-dark-example.html`（深色完整示例）或 `assets/templates/zero-to-tech-light.html`（浅色原版）为结构参照：

- 保留全部 CSS 变量名、class 命名、4 个 JS class（翻页/键盘/圆点/进度/reveal/主题切换/编辑导出），只改变量值与内容。
- 默认深色：`<html class="dark">`（对应 `html:not(.dark)` 选择器），localStorage 无记录时回退 dark。
- 每页结构：`<section class="slide">` + 内部 `.slide-content`；子元素用 `class="reveal" style="--delay: 0.1s;"` 做 stagger 渐显。
- accent 单色原则：全片只用一种强调色（标签、编号、强调词、进度点）。
- 图片热链原文 URL + `loading="lazy"`，每页最多 1–2 张。
- localStorage key 按项目改名（如 `ev-<topic>-theme`、`ev-slides-<topic>`），避免不同 deck 互相污染。
- 品牌/课程文案换成当前主题的，不留"零到全栈"字样（除非是复刻该课程本身）。

### 5. 截图验证（必须）

```bash
scripts/screenshot-slides.sh <slides.html> [outdir] [宽] [高]
# 默认 outdir=/tmp/slides-shots, 1600x900
```

输出为 `slide-01.png`…`slide-N.png`（两位数字编号）。逐页截图后用 Read 工具查看每张：配色正确、字体渲染正常（文楷中文 + JetBrains Mono 标签）、无文字溢出/重叠/空白页。发现异常（尤其文件明显偏小的空白页）就修复后重截。

注意：该 slides 的 reveal 动画依赖 IntersectionObserver，headless Chrome 普通截图会截出空白页——必须用本脚本（已内置绕过逻辑），不要自己写 scrollIntoView 截图。

## 资源

- `references/design-spec.md` — 完整设计规范（构建前必读）
- `references/color-themes.md` — 双主题变量值对照
- `assets/templates/cli-dark-example.html` — 深色主题完整示例（19 页真实 deck）
- `assets/templates/zero-to-tech-light.html` — 浅色原版参考
- `assets/logo/icon-light.svg` — logo
- `scripts/screenshot-slides.sh` — 逐页截图验证脚本
