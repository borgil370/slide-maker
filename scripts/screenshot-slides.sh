#!/usr/bin/env bash
# screenshot-slides.sh — 对 zero-to-tech 风格 slides 逐页截图验证
# 用法: screenshot-slides.sh <slides.html> [outdir] [width] [height]
# 原理: 该 slides 无 hash 路由, 逐页注入 scrollIntoView 后 headless Chrome 截图。
# 临时注入文件放在目标同目录, 保证 fonts 等相对路径资源可加载。
set -euo pipefail

HTML="${1:?usage: screenshot-slides.sh <slides.html> [outdir] [width] [height]}"
OUTDIR="${2:-/tmp/slides-shots}"
W="${3:-1600}"
H="${4:-900}"

CHROME="${CHROME_BIN:-}"
if [ -z "$CHROME" ]; then
  for c in "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" \
           "/Applications/Chromium.app/Contents/MacOS/Chromium" \
           "$(command -v chromium || true)" "$(command -v google-chrome || true)"; do
    [ -n "$c" ] && [ -x "$c" ] && CHROME="$c" && break
  done
fi
[ -n "$CHROME" ] || { echo "ERROR: no Chrome/Chromium found; set CHROME_BIN" >&2; exit 1; }

HTML="$(cd "$(dirname "$HTML")" && pwd)/$(basename "$HTML")"
N=$(grep -c '<section class="slide' "$HTML")
[ "$N" -gt 0 ] || { echo "ERROR: no <section class=\"slide\"> found in $HTML" >&2; exit 1; }
mkdir -p "$OUTDIR"

TMP="${HTML%.html}.shot-tmp.html"
trap 'rm -f "$TMP"' EXIT

echo "slides: $N  chrome: $CHROME  out: $OUTDIR"
for ((i=0; i<N; i++)); do
  IDX=$i python3 - "$HTML" "$TMP" <<'PY'
import os, sys
src = open(sys.argv[1], encoding="utf-8").read()
i = os.environ["IDX"]
# headless 下 scroll-snap + IntersectionObserver + virtual-time-budget 组合不可靠
# (滚动后 reveal 元素可能保持 opacity:0 截出空白页)。
# 改用「隐藏其余 slide、只显示目标页并手动加 .visible」的方式, 与滚动解耦。
inject = ("<style>*{transition:none !important;animation:none !important}"
          "section.slide{display:none !important}"
          "section.slide.shot{display:flex !important;position:relative !important}"
          "html,body{scroll-snap-type:none !important}</style>"
          f"<script>window.addEventListener('load',()=>{{setTimeout(()=>{{"
          f"var s=document.querySelectorAll('section.slide')[{i}];"
          f"s.classList.add('visible','shot');window.scrollTo(0,0);"
          f"}},300);}});</script></body>")
open(sys.argv[2], "w", encoding="utf-8").write(src.replace("</body>", inject))
PY
  printf -v PAD "%02d" $((i+1))
  "$CHROME" --headless --disable-gpu --window-size="$W,$H" \
    --virtual-time-budget=6000 --screenshot="$OUTDIR/slide-$PAD.png" \
    "file://$TMP" 2>/dev/null
done
echo "done: $N screenshots in $OUTDIR"
