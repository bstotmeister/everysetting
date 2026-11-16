#!/usr/bin/env bash
# Rebuilds the brand images from their sources in docs/brand/:
#
#   logo.svg   ->  logo-400.png                   the listing's avatar
#              ->  EverySetting/Media/logo.tga    the in-game icon, 64x64
#   card.html  ->  social.png                     GitHub's social preview, 1280x640
#              ->  banner.png                     the README's banner, 1280x360
#
# Needs Google Chrome and Python 3 with Pillow. card.html loads its fonts from Google
# Fonts, so it needs the network too. Set CHROME if Chrome is somewhere else.
set -euo pipefail
cd "$(dirname "$0")/.."

chrome="${CHROME:-/Applications/Google Chrome.app/Contents/MacOS/Google Chrome}"
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

# shot <page> <width> <height> <out.png>: a screenshot with a see-through background.
shot() {
	"$chrome" --headless --hide-scrollbars --default-background-color=00000000 \
		--virtual-time-budget=5000 --window-size="$2,$3" \
		--screenshot="$4" "file://$PWD/$1" >/dev/null 2>&1
}

shot docs/brand/card.html 1280 640 "$PWD/docs/brand/social.png"
shot "docs/brand/card.html?banner" 1280 360 "$PWD/docs/brand/banner.png"

# Chrome's window can't be narrower than about 500px, so the logo is drawn at 800 and
# scaled down. The game reads 32-bit TGA, with sides that are a power of two.
shot docs/brand/logo.svg 800 800 "$tmp/logo.png"
mkdir -p EverySetting/Media
python3 - "$tmp/logo.png" <<'PY'
import sys
from PIL import Image
logo = Image.open(sys.argv[1]).convert("RGBA")
logo.resize((400, 400), Image.LANCZOS).save("docs/brand/logo-400.png")
logo.resize((64, 64), Image.LANCZOS).save("EverySetting/Media/logo.tga")
PY
