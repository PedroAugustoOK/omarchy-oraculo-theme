#!/bin/bash
# Generate the Oráculo wallpapers in the soft-wash language of Veredas:
# broad, asymmetric Gaussian blooms; no shapes or imagery, only a fine grain.
# The render is 3840x2160, truecolor PNG with grain to break up banding.
#
#   ./scripts/make-wallpapers.sh [theme-dir]
#
# Driven entirely by colors.toml. The three compositions are a bloom, a
# vertical recess and a diagonal wash.
set -euo pipefail

theme_dir=${1:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}
out_dir="$theme_dir/backgrounds"
slug=$(basename "$(cd "$theme_dir" && pwd)" | sed 's/^omarchy-//; s/-theme$//')

if command -v magick >/dev/null 2>&1; then
  MAGICK=magick
elif command -v convert >/dev/null 2>&1; then
  MAGICK=convert
else
  echo "ImageMagick is required (magick or convert)" >&2
  exit 1
fi

if [[ ! -f $theme_dir/colors.toml ]]; then
  echo "missing $theme_dir/colors.toml" >&2
  exit 1
fi

W=3840
H=2160
seed=20261022

color() {
  if command -v omarchy-theme-color >/dev/null 2>&1; then
    omarchy-theme-color "$1" --file "$theme_dir/colors.toml"
  else
    sed -nE "s/^[[:space:]]*$1[[:space:]]*=[[:space:]]*\"([^\"]+)\".*/\\1/p" \
      "$theme_dir/colors.toml" | head -n 1
  fi
}

rgba() {
  local hex=${1#\#} alpha=$2
  printf 'rgba(%d,%d,%d,%s)' "0x${hex:0:2}" "0x${hex:2:2}" "0x${hex:4:2}" "$alpha"
}

background=$(color background)
dark_bg=$(color dark_background)
darker_bg=$(color darker_background)
lighter_bg=$(color lighter_background)
accent=$(color accent)
selection=$(color selection)
mode=$(color mode)

if [[ $mode == light ]]; then
  names=(mist linen haze)
  a_bloom=0.24
  a_wash=0.70
  a_alt=0.50
  a_low=0.16
  grain=0.0045
  recess_color="$selection"
  recess_alpha=0.55
else
  names=(veil tide dusk)
  a_bloom=0.35
  a_wash=0.70
  a_alt=0.48
  a_low=0.20
  grain=0.006
  recess_color="$dark_bg"
  recess_alpha="$a_wash"
fi

mkdir -p "$out_dir"
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

# Coordinates below are written for a 2560x1440 canvas and scaled to 4K.
scaled() { printf '%d' $(( $1 * 3 / 2 )); }

blob() { # color alpha cx cy rx ry blur out
  "$MAGICK" -size ${W}x${H} xc:none \
    -fill "$(rgba "$1" "$2")" \
    -draw "ellipse $(scaled "$3"),$(scaled "$4") $(scaled "$5"),$(scaled "$6") 0,360" \
    -blur 0x"$(scaled "$7")" "$8"
}

# --- 001: a single broad bloom dissolving into the field -------------------
blob "$accent"    "$a_bloom" 1980 300 1050 900 240 "$tmp/bloom.png"
blob "$selection" "$a_wash"  1620 1040 900 760 250 "$tmp/wash.png"
blob "$darker_bg" "$a_alt"   360 1180 820 640 260 "$tmp/low.png"
blob "$accent"    0.08       900 250 700 500 280 "$tmp/high.png"
"$MAGICK" -size ${W}x${H} "xc:$background" \
  "$tmp/high.png" -compose over -composite \
  "$tmp/bloom.png" -compose over -composite \
  "$tmp/wash.png" -compose over -composite \
  "$tmp/low.png" -compose over -composite \
  -colorspace sRGB -seed "$seed" -attenuate "$grain" +noise Gaussian \
  -type TrueColor -define png:color-type=2 -depth 8 -strip \
  -define png:compression-level=9 \
  "PNG24:$out_dir/001-$slug-${names[0]}.png"

# --- 002: a quiet vertical recess in an otherwise flat field ---------------
blob "$selection"  0.45      1340 760 700 760 320 "$tmp/ambient.png"
blob "$recess_color" "$recess_alpha" 1340 760 620 700 320 "$tmp/recess.png"
blob "$lighter_bg" "$a_alt"  420 220 700 520 300 "$tmp/high.png"
blob "$accent"     "$a_low"  2260 560 620 700 300 "$tmp/edge.png"
blob "$selection"  0.24      900 1350 800 450 280 "$tmp/basewash.png"
"$MAGICK" -size ${W}x${H} "xc:$background" \
  "$tmp/ambient.png" -compose over -composite \
  "$tmp/basewash.png" -compose over -composite \
  "$tmp/recess.png" -compose over -composite \
  "$tmp/high.png" -compose over -composite \
  "$tmp/edge.png" -compose over -composite \
  -colorspace sRGB -seed "$seed" -attenuate "$grain" +noise Gaussian \
  -type TrueColor -define png:color-type=2 -depth 8 -strip \
  -define png:compression-level=9 \
  "PNG24:$out_dir/002-$slug-${names[1]}.png"

# --- 003: one slow diagonal wash, low and off-centre -----------------------
blob "$selection"  "$a_wash"  640 1180 1150 800 280 "$tmp/diag.png"
blob "$accent"     "$a_low"  1980 340 900 700 290 "$tmp/far.png"
blob "$darker_bg"  "$a_alt"  2100 1180 760 560 270 "$tmp/corner.png"
blob "$lighter_bg" 0.14      1300 400 700 450 300 "$tmp/top.png"
"$MAGICK" -size ${W}x${H} "xc:$background" \
  "$tmp/diag.png" -compose over -composite \
  "$tmp/far.png" -compose over -composite \
  "$tmp/top.png" -compose over -composite \
  "$tmp/corner.png" -compose over -composite \
  -colorspace sRGB -seed "$seed" -attenuate "$grain" +noise Gaussian \
  -type TrueColor -define png:color-type=2 -depth 8 -strip \
  -define png:compression-level=9 \
  "PNG24:$out_dir/003-$slug-${names[2]}.png"

ls -la "$out_dir"
