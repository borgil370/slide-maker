# 「零到全栈」HTML Slides 设计规范

> 依据 `reference/slides-模块1.1.html` 与 `reference/slides-模块2.2.html` 提炼。
> 目标：不看原文件也能 1:1 复刻同风格的 slide 页面。
> 两文件共享同一套设计系统与 JS 框架，2.2 比 1.1 多若干命令行相关组件（cmd-grid / vim-grid / flow-row / check-grid / code-block / token）。

---

## 1. 整体架构

### 1.1 文件组织

单个自包含 HTML 文件，结构为：

```
<!DOCTYPE html>
<html lang="zh-CN">
<head>
  <meta charset / viewport>
  <title>模块 X.X · 标题 · 零到全栈</title>
  <link JetBrains Mono (Google Fonts)>
  <style> 全部 CSS </style>
</head>
<body>
  固定 UI：进度条 / 导航点 / 主题切换 / 内联编辑控件
  <section class="slide" id="slide-1"> … </section>
  <section class="slide" id="slide-2"> … </section>
  … 每页一个 section，顺序堆叠
  <script> 4 个 class + boot </script>
</body>
</html>
```

外部依赖只有两类，均相对于 HTML 文件：

- `assets/fonts/LXGWWenKai-{Light,Regular,Medium}.ttf` —— 本地霞鹜文楷（@font-face 引入）
- `assets/logo/icon-light.svg` / `icon-dark.svg` —— 结尾页 logo，深浅两套
- JetBrains Mono 走 Google Fonts CDN

### 1.2 Slide DOM 标记模式

每页 slide 的骨架固定为：

```html
<section class="slide [title-slide|quote-slide]" id="slide-N">
  <div class="slide-content">
    <!-- 内容元素，逐个带 class="reveal" 或 "reveal-blur"，
         内联 style="--delay: 0.XXs;" 控制入场顺序 -->
  </div>
</section>
```

规则：

- `<section class="slide">` 是页面容器；`id="slide-N"` 从 1 开始顺序编号（JS 不依赖 id，但保留）。
- 特殊页加修饰类：`title-slide`（封面，加双径向光晕背景）、`quote-slide`（金句/结尾页，加中心光晕）。
- 内容容器固定为 `.slide-content`（flex 纵向居中）。可通过内联 style 改对齐，如封面用 `justify-content: flex-end; padding-bottom: clamp(4rem, 10vh, 8rem);`。
- **class 命名**：全小写、连字符（`split-panel`、`cmd-row`）；容器与卡片成对（`.two-col` > `.split-panel`、`.three-col` > `.col-card` 等）；状态类为 `.active` / `.visible` / `.card-highlighted` / `.has-selection` / `.done`。
- **data 属性**：
  - `data-edit` —— 标记可被内联编辑系统接管的文字元素（标题、正文、列表项等）。
  - `data-edit-id="e{i}"` —— 由 JS 在进入编辑模式时按顺序自动写入，作为 localStorage 存储键。HTML 源码里不写。

### 1.3 导航机制

- **滚轮**：监听 `wheel`，700ms 节流，`deltaY > 0` 下一页，否则上一页。
- **键盘**：`ArrowDown / ArrowRight / PageDown / Space` 下一页；`ArrowUp / ArrowLeft / PageUp` 上一页。目标元素处于 contenteditable 时忽略。
- **触摸**：`touchstart` 记录起始 Y，`touchend` 位移绝对值 > 48px 时翻页。
- **导航点**：右侧垂直一排小圆点，由 JS 按 slide 数量动态生成，点击 `goTo(i)`。当前页的点放大 1.7 倍并变为 accent 色。
- **进度条**：顶部 2px 高 accent 色横条。宽度有两条更新路径：scroll 事件按滚动百分比、以及 slide 切换时按 `idx / (total-1)`。
- **翻页实现**：`goTo(idx)` 调用 `slides[idx].scrollIntoView({ behavior: 'smooth' })`——本质是整页滚动 + CSS scroll-snap，不是 transform 位移。
- **URL hash**：不使用 URL hash；刷新后总是回到第一页。

### 1.4 JS 如何工作

`<script>` 在 body 末尾，无框架，4 个 class，最后 boot：

```js
const presentation = new SlidePresentation();
const editor       = new InlineEditor();
const highlighter  = new CardHighlighter(presentation);
const themeToggle  = new ThemeToggle();
```

**SlidePresentation**：

- `this.slides = document.querySelectorAll('.slide')`。
- `IntersectionObserver`（threshold 0.5）观察每个 slide：进入视口时给该 section 加 `.visible`（触发内部 `.reveal` 动画），更新 `currentSlide`、进度条、导航点。
- 构造时给第一页手动加 `.visible`。
- 方法：`setupIntersectionObserver / buildNavDots / updateDots / setupKeyboardNav / setupWheelNav / setupTouchNav / setupScrollProgress / syncProgress / goTo`。

**CardHighlighter**（卡片聚焦，演讲时用）：

- 容器选择器：`.two-col, .three-col, .doubt-list, .cmd-grid, .vim-grid, .check-grid, .flow-row`（1.1 只有前三者）。
- 卡片选择器：`.split-panel, .col-card, .doubt-card, .cmd-row, .vim-card, .check-card, .flow-step`。
- 点击卡片：容器加 `.has-selection`、该卡片加 `.card-highlighted`（其余卡片淡出至 opacity 0.25 + scale 0.97）；再点一次或点容器空白处取消。
- 键盘：数字键 1–9 高亮当前页对应序号卡片，`Escape` 清除。编辑模式下全部忽略。

**InlineEditor**（见 §7.4）与 **ThemeToggle**（见 §6）。

---

## 2. 设计 token

### 2.1 `:root`（Light 默认）

```css
:root {
  --bg:              #F6F4F1;
  --surface:         #FFFFFF;
  --surface-2:       #EFEBE6;
  --text:            #1C1E1D;
  --text-secondary:  #586460;
  --text-dim:        #9AA8A4;
  --border:          #DDD8D2;
  --border-subtle:   #EAE6E1;
  --accent:          #2A9182;
  --accent-light:    #4DB8A8;
  --accent-muted:    #E6F4F2;

  --glow-primary:       rgba(42, 145, 130, 0.08);
  --glow-secondary:     rgba(42, 145, 130, 0.05);
  --glow-quote:         rgba(42, 145, 130, 0.06);
  --highlight-glow:     rgba(42, 145, 130, 0.15);
  --edit-outline-color: rgba(42, 145, 130, 0.35);

  --font-zh:   'LXGW WenKai', 'Songti SC', Georgia, serif;
  --font-mono: 'JetBrains Mono', 'Fira Code', monospace;

  --ease-expo: cubic-bezier(0.16, 1, 0.3, 1);
  --duration:  0.65s;

  --title-size:    clamp(2.2rem, 5.5vw, 4.2rem);
  --h2-size:       clamp(1.75rem, 3.4vw, 2.5rem);
  --h3-size:       clamp(1.2rem, 2.3vw, 1.7rem);
  --body-size:     clamp(1.05rem, 1.6vw, 1.25rem);
  --small-size:    clamp(0.9rem, 1.15vw, 1.05rem);
  --slide-padding: clamp(1.5rem, 5vw, 5rem);
  --content-gap:   clamp(0.75rem, 2.5vw, 2.5rem);
  --element-gap:   clamp(0.3rem, 1vw, 0.9rem);
}
```

> 注：1.1 中 light 模式的 glow 变量误写成自引用（`--glow-primary: var(--glow-primary);`），导致 light 模式光晕回落为透明/继承值；2.2 已修正为上表的具体 rgba 值。复刻时用 2.2 的正确写法。

注意：变量名是 `--font-mono`（不是 `--font-code`）；卡片高亮阴影在 1.1 里用 `var(--highlight-glow)`，2.2 里硬编码 `rgba(77,184,168,0.2)`。

### 2.2 `html.dark`（Dark 覆盖）

```css
html.dark {
  --bg:              #131614;
  --surface:         #1E2320;
  --surface-2:       #252B27;
  --text:            #EDECEA;
  --text-secondary:  #9DA89F;
  --text-dim:        #6B756D;
  --border:          #2A302C;
  --border-subtle:   #1E2420;
  --accent:          #4DB8A8;
  --accent-light:    #68CABB;
  --accent-muted:    #1A2E2C;

  --glow-primary:       rgba(77, 184, 168, 0.13);
  --glow-secondary:     rgba(77, 184, 168, 0.07);
  --glow-quote:         rgba(77, 184, 168, 0.08);
  --highlight-glow:     rgba(77, 184, 168, 0.2);
  --edit-outline-color: rgba(77, 184, 168, 0.35);
}
```

### 2.3 字体

```css
@font-face {
  font-family: 'LXGW WenKai';
  src: url('assets/fonts/LXGWWenKai-Light.ttf') format('truetype');
  font-weight: 300; font-style: normal; font-display: swap;
}
/* Regular → 400，Medium → 500，同上结构 */
```

外加 `<link href="https://fonts.googleapis.com/css2?family=JetBrains+Mono:wght@400;500&display=swap" rel="stylesheet">`。

字体栈：

- `--font-zh: 'LXGW WenKai', 'Songti SC', Georgia, serif;` —— 全局正文/标题（body 默认）。
- `--font-mono: 'JetBrains Mono', 'Fira Code', monospace;` —— slide-label、module-tag、代码块、命令名、编号、品牌行等"技术感"点缀。

---

## 3. 布局体系

**不是 16:9 固定画布，而是"每页 = 一个视口"的流式全屏滚动布局**：

```css
html, body { height: 100%; overflow-x: hidden; }
html { scroll-snap-type: y mandatory; scroll-behavior: smooth; }

.slide {
  width: 100vw; height: 100vh; height: 100dvh;
  overflow: hidden; scroll-snap-align: start;
  display: flex; flex-direction: column; position: relative;
}
.slide-content {
  flex: 1; display: flex; flex-direction: column;
  justify-content: center; max-height: 100%;
  overflow: hidden; padding: var(--slide-padding);
}
img, .image-container { max-width: 100%; max-height: min(50vh, 400px); object-fit: contain; }
```

要点：

- 每页 `100vw × 100dvh`，CSS scroll-snap 保证一次滚一页；内容超出即裁剪（`overflow: hidden`），不做缩放适配。
- 内容通过 flex 垂直居中，padding 为 `--slide-padding`（clamp(1.5rem, 5vw, 5rem)）。**没有全局 max-width 限制**，内容宽度 = 视口宽 − 2×padding；依靠 clamp() 字号保证大屏可读。
- 响应式：全部尺寸走 `clamp(min, vw/vh, max)`，另有三档高度媒体查询（`max-height: 700/600/500px`）逐级压缩 padding、字号；≤600px 高度时隐藏 `.nav-dots`（1.1 还隐藏 `.keyboard-hint`、`.decorative`）；`max-width: 600px` 时所有多列网格塌缩为单列（`grid-template-columns: 1fr !important`）；`prefers-reduced-motion` 关闭动画与平滑滚动。

---

## 4. 页面类型 / 组件清单

### 4.1 封面页（`.slide.title-slide`）

```html
<section class="slide title-slide" id="slide-1">
  <div class="slide-content">  <!-- 1.1 用 justify-content:flex-end 靠下排版；2.2 默认居中 -->
    <div class="module-tag reveal" style="--delay: 0.05s;">模块 2.2</div>
    <h1 class="reveal" style="--delay: 0.25s;" data-edit>认识终端</h1>
    <p class="reveal" style="--delay: 0.35s; font-size: var(--h3-size);
       color: var(--text-secondary); font-weight: 300; margin-top: 0.5rem;" data-edit>
      副标题（可选）</p>
    <div class="brand-line reveal" style="--delay: 0.48s;" data-edit>零到全栈 · 李勃老师 · 2026</div>
  </div>
</section>
```

```css
.module-tag {
  display: inline-flex; align-items: center;
  background: var(--accent-muted); border: 1px solid var(--accent);
  color: var(--accent); padding: 3px 10px; border-radius: 4px;
  font-family: var(--font-mono); font-size: var(--small-size);
  letter-spacing: 0.08em; margin-bottom: clamp(1rem, 2.5vh, 1.75rem);
  flex-shrink: 0; width: fit-content;
}
.brand-line {
  display: flex; align-items: center; gap: 14px;
  font-family: var(--font-mono); font-size: var(--small-size);
  color: var(--text-dim); margin-top: clamp(1.5rem, 3.5vh, 2.5rem);
}
.brand-line::before {
  content: ''; display: block; width: 28px; height: 1px;
  background: var(--text-dim); flex-shrink: 0;
}
.title-slide::before {
  content: ''; position: absolute; inset: 0; pointer-events: none;
  background:
    radial-gradient(ellipse at 75% 15%, var(--glow-primary) 0%, transparent 55%),
    radial-gradient(ellipse at 15% 85%, var(--glow-secondary) 0%, transparent 45%);
}
```

### 4.2 金句页（`.slide.quote-slide`）

正文页和结尾页都用它：`.accent-line` 短横 + `.quote-text` 大字（`<em>` 标 accent 色关键词）+ `.caption` 补充说明。

```html
<section class="slide quote-slide">
  <div class="slide-content" style="justify-content: center;">
    <div class="accent-line reveal" style="--delay: 0.05s;"></div>
    <p class="quote-text reveal-blur" style="--delay: 0.18s;" data-edit>
      AI 确实能写代码。<br>
      但<em>代码本身不产生价值</em>，<br>
      价值来自产品。
    </p>
    <p class="caption reveal" style="--delay: 0.45s; margin-top: var(--content-gap);" data-edit>…</p>
  </div>
</section>
```

```css
.accent-line {
  width: clamp(36px, 5vw, 64px); height: 3px;
  background: var(--accent); border-radius: 2px;
  margin-bottom: var(--content-gap); flex-shrink: 0;
}
.quote-text {
  font-size: clamp(1.3rem, 3.8vw, 3rem);
  font-weight: 300; line-height: 1.5; color: var(--text);
}
.quote-text em { font-style: normal; color: var(--accent); font-weight: 400; }
.quote-slide::before {
  content: ''; position: absolute; inset: 0; pointer-events: none;
  background: radial-gradient(ellipse at 50% 45%, var(--glow-quote) 0%, transparent 60%);
}
```

### 4.3 结尾页（quote-slide 变体）

与金句页同结构，差异：开头放 logo `<img class="brand-icon-closing">`，引文字号加大（内联 `font-size: clamp(1.4rem, 4.2vw, 3.4rem)`），结尾一行 mono 字体的 `caption.dim`（如"零到全栈 · 模块 2.2 完"）。logo 带 `onerror="this.style.display='none'"` 兜底（1.1 有，2.2 没有——建议保留）。

```css
.brand-icon-closing {
  height: clamp(4rem, 9vh, 7rem); width: auto;
  display: block; margin-bottom: var(--content-gap);
  opacity: 0.9; flex-shrink: 0;   /* 1.1 为 0.85 */
}
```

### 4.4 标准内容页：label + h2 + 组件 + caption

所有正文页共用同一模式：

```html
<section class="slide">
  <div class="slide-content">
    <div class="slide-label reveal" style="--delay: 0.05s;">ENGLISH LABEL</div>
    <h2 class="reveal" style="--delay: 0.15s;" data-edit>中文标题</h2>
    <div class="[组件容器]" style="margin-top: var(--content-gap);">…</div>
    <p class="caption reveal" style="--delay: 0.52s; margin-top: var(--content-gap);" data-edit>…</p>
  </div>
</section>
```

```css
.slide-label {
  font-family: var(--font-mono); font-size: var(--small-size);
  color: var(--accent); letter-spacing: 0.12em; text-transform: uppercase;
  margin-bottom: var(--element-gap); flex-shrink: 0;
}
.caption { font-size: var(--small-size); color: var(--text-secondary); line-height: 1.6; }
.caption.dim { color: var(--text-dim); }
```

reveal 延时惯例：label 0.05s → h2 0.15s → 内容卡片 0.22s 起逐张 +0.04~0.08s → caption 收尾。

### 4.5 双栏对比（`.two-col` > `.split-panel`）

```html
<div class="two-col" style="margin-top: var(--content-gap);">
  <div class="split-panel reveal" style="--delay: 0.28s;">
    <div class="split-label">图形界面（你熟悉的）</div>
    <div class="split-title" data-edit>鼠标点来点去</div>
    <ul class="split-items" style="margin-top: 8px;">
      <li data-edit>…</li>
    </ul>
  </div>
  <div class="split-panel accent-panel reveal" style="--delay: 0.38s;">
    <div class="split-label teal">终端（命令行 / CLI）</div>
    …
  </div>
</div>
```

```css
.two-col { display: grid; grid-template-columns: 1fr 1fr;
  gap: clamp(0.75rem, 2.5vw, 2.5rem); align-items: stretch; }
.split-panel {
  background: var(--surface); border: 1px solid var(--border);
  border-radius: 8px; padding: clamp(0.9rem, 2vw, 1.6rem);
  display: flex; flex-direction: column; gap: 6px;
}
.split-panel.accent-panel { border-color: var(--accent); background: var(--accent-muted); }
.split-label { font-family: var(--font-mono); font-size: var(--small-size); color: var(--text-dim); }
.split-label.teal { color: var(--accent); }
.split-title { font-size: var(--h3-size); color: var(--text); line-height: 1.3; }
.split-body  { font-size: var(--small-size); color: var(--text-secondary); line-height: 1.6; }
.split-items li {
  font-size: var(--small-size); color: var(--text-secondary); line-height: 1.5;
  padding: 5px 0; border-bottom: 1px solid var(--border-subtle);
}
.split-items li:last-child { border-bottom: none; }
```

惯例：强调/推荐的一侧加 `.accent-panel`，其 label 加 `.teal`。panel 内也可嵌 `.code-block` 或 `.split-body`。

### 4.6 三栏卡片（`.three-col` > `.col-card`）

```html
<div class="three-col" style="margin-top: var(--content-gap);">
  <div class="col-card reveal" style="--delay: 0.25s;">
    <div class="col-card-num">01</div>
    <div class="col-card-title" data-edit>前端</div>
    <div class="col-card-desc" data-edit>…</div>
  </div>
  …
</div>
```

```css
.three-col { display: grid; grid-template-columns: repeat(3, 1fr);
  gap: clamp(0.6rem, 1.8vw, 1.4rem); }
.col-card {
  background: var(--surface); border: 1px solid var(--border);
  border-radius: 8px; padding: clamp(0.9rem, 2vw, 1.5rem);
  display: flex; flex-direction: column; gap: 8px;  /* 1.1 为 gap:6px */
}
.col-card-num   { font-family: var(--font-mono); font-size: var(--small-size); color: var(--accent); }
.col-card-title { font-size: var(--h3-size); color: var(--text); }
.col-card-desc  { font-size: var(--small-size); color: var(--text-secondary); line-height: 1.6; }
```

### 4.7 破折号列表（`.dash-list`）

```html
<ul class="dash-list" style="margin-top: var(--content-gap);">
  <li class="reveal" style="--delay: 0.26s;" data-edit>…</li>
</ul>
```

```css
.dash-list { display: flex; flex-direction: column; gap: var(--element-gap); }
.dash-list li { display: flex; align-items: flex-start; gap: 12px;
  font-size: var(--body-size); color: var(--text-secondary); line-height: 1.65; }
.dash-list li::before { content: '—'; color: var(--accent); flex-shrink: 0;
  margin-top: 1px; font-family: var(--font-mono); }
```

### 4.8 疑虑卡列表（`.doubt-list` > `.doubt-card`，样式库中有定义）

```css
.doubt-list { display: flex; flex-direction: column; gap: clamp(0.4rem, 1.2vh, 0.9rem); }
.doubt-card {
  background: var(--surface); border-left: 2px solid var(--border);
  border-radius: 0 6px 6px 0; padding: clamp(0.7rem, 1.8vw, 1.1rem);
  font-size: var(--body-size); color: var(--text-secondary); line-height: 1.5;
}
```

### 4.9 命令速查网格（`.cmd-grid` > `.cmd-row`，仅 2.2）

```html
<div class="cmd-grid" style="margin-top: var(--content-gap);">
  <div class="cmd-row reveal" style="--delay: 0.22s;">
    <span class="cmd-name">pwd</span>
    <span class="cmd-desc" data-edit>查看当前所在路径</span>
  </div>
  …
</div>
```

```css
.cmd-grid { display: grid; grid-template-columns: repeat(2, 1fr);
  gap: clamp(0.3rem, 0.8vw, 0.6rem); }
.cmd-row {
  display: flex; align-items: baseline; gap: 10px;
  background: var(--surface); border: 1px solid var(--border);
  border-radius: 6px; padding: clamp(0.5rem, 1.2vw, 0.85rem) clamp(0.7rem, 1.4vw, 1.1rem);
}
.cmd-name {
  font-family: var(--font-mono); font-size: var(--small-size);
  color: var(--accent-light); white-space: nowrap; flex-shrink: 0;
  min-width: clamp(3rem, 5vw, 5rem);
}
.cmd-desc { font-size: var(--small-size); color: var(--text-secondary); line-height: 1.4; }
```

### 4.10 按键卡（`.vim-grid` > `.vim-card`，仅 2.2）

4 列网格，卡片居中：`.vim-key`（mono 大字、accent 描边徽章）+ `.vim-action` + `.vim-desc`。

```css
.vim-grid { display: grid; grid-template-columns: repeat(4, 1fr);
  gap: clamp(0.6rem, 1.5vw, 1.2rem); }
.vim-card {
  background: var(--surface); border: 1px solid var(--border);
  border-radius: 8px; padding: clamp(0.8rem, 2vw, 1.4rem);
  display: flex; flex-direction: column; gap: 8px; align-items: center; text-align: center;
}
.vim-key {
  font-family: var(--font-mono); font-size: clamp(1.1rem, 2.2vw, 1.6rem);
  color: var(--accent); background: var(--accent-muted);
  border: 1px solid var(--accent); border-radius: 5px;
  padding: 4px 12px; display: inline-block;
}
.vim-action { font-size: var(--small-size); color: var(--text); font-weight: 500; }
.vim-desc   { font-size: var(--small-size); color: var(--text-secondary); line-height: 1.5; }
```

### 4.11 流程条（`.flow-row` > `.flow-step` + `.flow-arrow`，仅 2.2）

```html
<div class="flow-row reveal" style="--delay: 0.28s; margin-top: var(--content-gap);">
  <div class="flow-step">
    <div class="flow-step-num">01</div>
    <div class="flow-step-desc" data-edit>确认当前位置</div>
  </div>
  <div class="flow-arrow">→</div>
  …
</div>
```

```css
.flow-row { display: flex; align-items: stretch;
  gap: clamp(0.4rem, 1vw, 0.8rem); flex-wrap: nowrap; overflow-x: auto; }
.flow-step {
  background: var(--surface); border: 1px solid var(--border);
  border-radius: 8px; padding: clamp(0.6rem, 1.4vw, 1rem) clamp(0.8rem, 1.8vw, 1.3rem);
  display: flex; flex-direction: column; gap: 4px; flex: 1; min-width: 0; text-align: center;
}
.flow-step-num  { font-family: var(--font-mono); font-size: var(--small-size); color: var(--accent); }
.flow-step-cmd  { font-family: var(--font-mono); font-size: var(--small-size); color: var(--accent-light); }
.flow-step-desc { font-size: var(--small-size); color: var(--text-secondary); line-height: 1.4; }
.flow-arrow { color: var(--text-dim); font-size: clamp(1rem, 1.5vw, 1.3rem);
  flex-shrink: 0; font-family: var(--font-mono); display: flex; align-items: center; }
```

### 4.12 勾选清单（`.check-grid` > `.check-card`，仅 2.2）

```html
<div class="check-grid" style="margin-top: var(--content-gap);">
  <div class="check-card done reveal" style="--delay: 0.26s;">
    <div class="check-icon"></div>
    <div class="check-text" data-edit>一进终端先确认路径…</div>
  </div>
</div>
```

```css
.check-grid { display: grid; grid-template-columns: repeat(2, 1fr);
  gap: clamp(0.5rem, 1.4vw, 1rem); }
.check-card {
  background: var(--surface); border: 1px solid var(--border);
  border-radius: 8px; padding: clamp(0.75rem, 1.6vw, 1.2rem);
  display: flex; gap: clamp(0.5rem, 1vw, 0.8rem); align-items: flex-start;
}
.check-icon {
  width: clamp(16px, 1.8vw, 22px); height: clamp(16px, 1.8vw, 22px);
  flex-shrink: 0; margin-top: 2px;
  border: 1.5px solid var(--border); border-radius: 4px;
  display: flex; align-items: center; justify-content: center;
}
.check-card.done .check-icon { background: var(--accent-muted); border-color: var(--accent); }
.check-card.done .check-icon::after {
  content: '✓'; font-size: 0.72em; color: var(--accent); font-family: var(--font-mono);
}
.check-text { font-size: var(--small-size); color: var(--text-secondary); line-height: 1.6; }
```

### 4.13 代码块与行内代码（仅 2.2）

```html
<div class="code-block" data-edit><span class="cmt"># 注释</span>
<span class="cmd">mkdir -p ~/Projects/zero2tech</span></div>

<!-- 行内： -->进入某个目录（<span class="token">cd</span>）
```

```css
.code-block {
  background: var(--surface); border: 1px solid var(--border);
  border-radius: 8px; padding: clamp(0.8rem, 1.8vw, 1.4rem);
  font-family: var(--font-mono); font-size: var(--small-size);
  color: var(--text-secondary); line-height: 1.9;
  white-space: pre; overflow-x: auto; flex-shrink: 0;
}
.code-block .cmd  { color: var(--accent-light); }
.code-block .cmt  { color: var(--text-dim); }
.code-block .path { color: var(--accent); }
.token {
  font-family: var(--font-mono); font-size: 0.9em;
  background: var(--surface-2); border: 1px solid var(--border);
  border-radius: 3px; padding: 1px 6px; color: var(--accent-light);
}
```

代码块 `white-space: pre`，HTML 里直接按行写源码，用 span 手工着色（无高亮库）。

---

## 5. 排版规则

| 元素 | 字号 | 字重 | 行高 | 颜色 |
|---|---|---|---|---|
| h1（封面标题） | `--title-size` clamp(2.2, 5.5vw, 4.2rem) | 300 | 1.25 | `--text` |
| h2（页面标题） | `--h2-size` clamp(1.75, 3.4vw, 2.5rem) | 400 | 1.3 | `--text` |
| h3 级（卡片标题 `.split-title`/`.col-card-title`） | `--h3-size` clamp(1.2, 2.3vw, 1.7rem) | 继承 400 | 1.3 | `--text` |
| 金句 `.quote-text` | clamp(1.3, 3.8vw, 3rem)（结尾页加大到 clamp(1.4, 4.2vw, 3.4rem)） | 300 | 1.5 | `--text`，`<em>` 用 `--accent` 400 |
| 正文（`.dash-list li`/`.doubt-card`） | `--body-size` clamp(1.05, 1.6vw, 1.25rem) | 400 | 1.5–1.65 | `--text-secondary` |
| 辅助文字（`.caption`/`.split-body`/卡片 desc） | `--small-size` clamp(0.9, 1.15vw, 1.05rem) | 400 | 1.4–1.6 | `--text-secondary`；`.dim` 用 `--text-dim` |
| 标签（`.slide-label`/`.module-tag`/编号） | `--small-size` | 400 | — | `--accent`（label/tag）或 `--text-dim` |

**accent 色（青绿 #2A9182 / 暗色 #4DB8A8）使用场景**：进度条、导航点 active、slide-label、module-tag、accent-line、金句 `<em>` 强调词、accent-panel 边框与底、卡片编号、命令名、vim 按键徽章、dash 列表的 `—` 前缀、卡片高亮描边、主题切换 hover。正文从不整段使用 accent，只作关键词点缀。

**正文强调**：caption 内可用 `<strong style="color: var(--text)">` 提亮个别句子（2.2 slide-4 实例）。

---

## 6. 主题切换机制

- 右下角固定圆形按钮 `.theme-toggle`（34×34，字符 `☾` / `☀`）。
- `ThemeToggle` class：点击时给 `<html>` 加/去 `.dark` class，持久化到 `localStorage['zt-theme']`（`'dark'` / `'light'`），加载时读取恢复。
- 切换时同步替换 `.brand-icon-closing` 的 src：`icon-light.svg` ↔ `icon-dark.svg`。
- 按钮样式：

```css
.theme-toggle {
  position: fixed; bottom: 18px; right: 22px; z-index: 10002;
  width: 34px; height: 34px; border-radius: 50%; border: 1px solid var(--border);
  background: var(--surface); color: var(--text-secondary);
  font-size: 16px; cursor: pointer; padding: 0;
  display: flex; align-items: center; justify-content: center;
  transition: border-color 0.25s, color 0.25s, background 0.25s;
}
.theme-toggle:hover { border-color: var(--accent); color: var(--accent); }
```

---

## 7. 其他细节

### 7.1 固定 UI 元素（body 开头，固定顺序）

```html
<div class="progress-bar" id="progressBar"></div>
<nav class="nav-dots" id="navDots" aria-label="幻灯片导航"></nav>
<div class="edit-hotzone" id="editHotzone"></div>
<button class="edit-toggle" id="editToggle">✏ EDIT</button>
<div class="edit-banner" id="editBanner">…</div>
<button class="theme-toggle" id="themeToggle" title="切换深浅色模式">☾</button>
```

z-index 层级：进度条/导航点 1000；edit-banner 9999；edit-hotzone 10000；edit-toggle 10001；theme-toggle 10002。

**无页脚、无页码**。进度条 + 右侧导航点即全部位置指示。

### 7.2 入场动画

```css
.reveal {
  opacity: 0; transform: translateY(22px);
  transition: opacity var(--duration) var(--ease-expo), transform var(--duration) var(--ease-expo);
  transition-delay: var(--delay, 0s);
}
.slide.visible .reveal { opacity: 1; transform: translateY(0); }
.reveal-blur {
  opacity: 0; filter: blur(8px);
  transition: opacity 0.8s var(--ease-expo), filter 0.8s var(--ease-expo);
  transition-delay: var(--delay, 0s);
}
.slide.visible .reveal-blur { opacity: 1; filter: blur(0); }
```

- `.reveal`：上移 22px 淡入，0.65s；`.reveal-blur`：去模糊淡入，0.8s，用于金句与结尾页主文案。
- 延时通过内联 `style="--delay: 0.XXs;"` 逐级递增（见 §4.4 惯例）。
- 由 IntersectionObserver 给 `.slide` 加 `.visible` 一次性触发；离开视口不回收（动画只播一次）。

### 7.3 卡片高亮交互样式

```css
.split-panel, .col-card, .doubt-card, .cmd-row, .vim-card, .check-card, .flow-step {
  cursor: pointer;
  transition: opacity 0.3s ease, transform 0.25s ease, box-shadow 0.25s ease;
}
.<container>.has-selection .<card>:not(.card-highlighted) {
  opacity: 0.25; transform: scale(0.97);
}
.<card>.card-highlighted {
  box-shadow: 0 0 0 2px var(--accent), 0 4px 20px rgba(77,184,168,0.2);
  transform: translateY(-2px) scale(1.01);
}
.flow-step.card-highlighted { border-color: var(--accent); background: var(--accent-muted); }
```

### 7.4 内联编辑系统（演讲者工具，演示时不可见）

- 左上角 80×80 隐形热区 `.edit-hotzone`：鼠标悬停浮现 `✏ EDIT` 按钮（400ms 后自动隐藏），点击进入编辑模式；或直接按 `E` 键切换。
- 编辑模式：body 加 `.edit-active`，所有 `[data-edit]` 元素获得 `contenteditable` + 虚线 outline（`1px dashed var(--edit-outline-color)`，聚焦时实线 accent + 浅色底），底部浮现 mono 字体的 `.edit-banner` 提示条。
- 退出编辑模式时把所有编辑内容以 `{'e0': innerHTML, …}` 存入 localStorage（键：1.1 用 `zt-slides-1.1`，2.2 用 `zt-slides-2.2`——**复刻新模块时须改键名**），下次打开自动回填。
- `Ctrl/Cmd+S`：序列化整个 `document.documentElement.outerHTML`，去掉编辑态残留后导出为新 HTML 文件下载（文件名如 `slides-模块2.2.html`）。

### 7.5 装饰元素

- 仅两种光晕：`title-slide::before`（右上 75%/15% 主光 + 左下 15%/85% 次光，radial-gradient ellipse）、`quote-slide::before`（中心 50%/45% 单层光）。均 `pointer-events: none`，颜色走 glow 变量。
- 无其他装饰：无背景图、无网格纹理、无边框动效。
- logo：仅出现在结尾页（`.brand-icon-closing`，高约 clamp(4rem,9vh,7rem)，opacity 0.85–0.9），封面页不用 logo、用 `.module-tag` + `.brand-line` 文字行代替。

### 7.6 注释与组织风格

原文件 CSS 用 `/* ====== 分区标题 ====== */` 横幅注释分块，每个 slide 前用 HTML 注释 `<!-- ==== SLIDE N · 标题 ==== -->` 分隔。复刻时保持此组织习惯。
