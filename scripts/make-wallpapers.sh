#!/bin/bash
# Generate the Oráculo wallpapers in the soft-wash language of Veredas:
# broad, asymmetric Gaussian blooms; no shapes, no texture, no noise.
#
#   ./scripts/make-wallpapers.sh [theme-dir]
#
# 2560x1440 PNG, three images per theme, driven entirely by colors.toml.
set -euo pipefail

theme_dir=${1:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}
out_dir="$theme_dir/backgrounds"
slug=$(basename "$theme_dir" | sed 's/^omarchy-//; s/-theme$//')

W=2560
H=1440

color() { omarchy-theme-color "$1" --file "$theme_dir/colors.toml"; }
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
  a_bloom=0.11
  a_wash=0.55
  a_alt=0.35
  a_low=0.10
else
  names=(veil tide dusk)
  a_bloom=0.20
  a_wash=0.55
  a_alt=0.45
  a_low=0.12
fi

mkdir -p "$out_dir"
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

blob() { # color alpha cx cy rx ry blur out
  magick -size ${W}x${H} xc:none \
    -fill "$(rgba "$1" "$2")" \
    -draw "ellipse $3,$4 $5,$6 0,360" \
    -blur 0x"$7" "$8"
}

# --- 001: a single broad bloom dissolving into the field -------------------
blob "$accent"    "$a_bloom" 1980 300 1050 900 240 "$tmp/bloom.png"
blob "$selection" "$a_wash"  1620 1040 900 760 250 "$tmp/wash.png"
blob "$darker_bg" "$a_alt"   360 1180 820 640 260 "$tmp/low.png"
magick -size ${W}x${H} "xc:$background" \
  "$tmp/bloom.png" -compose over -composite \
  "$tmp/wash.png"  -compose over -composite \
  "$tmp/low.png"   -compose over -composite \
  -colorspace sRGB -depth 8 -strip "$out_dir/001-$slug-${names[0]}.png"

# --- 002: a quiet vertical recess in an otherwise flat field ---------------
blob "$dark_bg"    "$a_wash" 1340 760 620 700 320 "$tmp/recess.png"
blob "$lighter_bg" "$a_alt"  420 220 620 460 300 "$tmp/high.png"
blob "$accent"     "$a_low"  2260 560 620 700 300 "$tmp/edge.png"
magick -size ${W}x${H} "xc:$background" \
  "$tmp/recess.png" -compose over -composite \
  "$tmp/high.png"   -compose over -composite \
  "$tmp/edge.png"   -compose over -composite \
  -colorspace sRGB -depth 8 -strip "$out_dir/002-$slug-${names[1]}.png"

# --- 003: one slow diagonal wash, low and off-centre -----------------------
blob "$selection"  "$a_wash"  640 1180 1150 800 280 "$tmp/diag.png"
blob "$accent"     "$a_low"  1980 340 900 700 290 "$tmp/far.png"
blob "$darker_bg"  "$a_alt"  2100 1180 760 560 270 "$tmp/corner.png"
magick -size ${W}x${H} "xc:$background" \
  "$tmp/diag.png"   -compose over -composite \
  "$tmp/far.png"    -compose over -composite \
  "$tmp/corner.png" -compose over -composite \
  -colorspace sRGB -depth 8 -strip "$out_dir/003-$slug-${names[2]}.png"

ls -la "$out_dir"
