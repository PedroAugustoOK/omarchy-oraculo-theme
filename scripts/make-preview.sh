#!/bin/bash
# Generate an original neo-expressionist theme preview from colors.toml.
# The composition is inspired by the raw, graffiti-like language of Jean-Michel
# Basquiat, but it is an original arrangement: no specific artwork is copied.
# It is generated artwork, not a desktop screenshot.
#
# Usage: ./scripts/make-preview.sh <theme-dir> "<theme name>" <output>
# Example: ./scripts/make-preview.sh . "Oráculo" preview.png
set -euo pipefail

if (($# != 3)); then
  echo "usage: $0 <theme-dir> \"<theme name>\" <output>" >&2
  exit 2
fi

theme_dir=$1
name=$2
output=$3

if [[ ! -f $theme_dir/colors.toml ]]; then
  echo "missing $theme_dir/colors.toml" >&2
  exit 1
fi

if command -v magick >/dev/null 2>&1; then
  MAGICK=magick
elif command -v convert >/dev/null 2>&1; then
  MAGICK=convert
else
  echo "ImageMagick is required (magick or convert)" >&2
  exit 1
fi

if ! command -v fc-match >/dev/null 2>&1; then
  echo "fontconfig (fc-match) is required" >&2
  exit 1
fi

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

W=1800
H=1012
seed=20261022

background=$(color background)
foreground=$(color foreground)
dark_foreground=$(color dark_foreground)
accent=$(color accent)
selection=$(color selection)
darker_background=$(color darker_background)
red=$(color red)
yellow=$(color yellow)
orange=$(color orange)
green=$(color green)
cyan=$(color cyan)
blue=$(color blue)
magenta=$(color magenta)
mode=$(color mode)

if [[ $mode == light ]]; then
  descriptor="LIGHT"
  field_label="MIST / LINEN / HAZE"
  a_wash=0.10
  a_fill=0.20
  a_block=0.16
  a_scribble=0.60
  panel_color="$selection"
  panel_alpha=0.80
  panel_outline="$foreground"
  word_color="$foreground"
  word2_color="$accent"
else
  descriptor="NIGHT"
  field_label="VEIL / TIDE / DUSK"
  a_wash=0.18
  a_fill=0.32
  a_block=0.22
  a_scribble=0.80
  panel_color="$darker_background"
  panel_alpha=0.82
  panel_outline="$darker_background"
  word_color="$foreground"
  word2_color="$accent"
fi

paper="$background"
ink="$foreground"

font_bold=$(fc-match -f '%{file}' 'Liberation Sans:style=Bold' 2>/dev/null || true)
if [[ ! -f $font_bold ]]; then
  font_bold=$(fc-match -f '%{file}' 'DejaVu Sans:style=Bold' 2>/dev/null || true)
fi
if [[ ! -f $font_bold ]]; then
  font_bold=$(fc-match -f '%{file}' 'sans:style=Bold' 2>/dev/null || true)
fi
if [[ ! -f $font_bold ]]; then
  echo "no bold sans-serif font found; install Liberation Sans or DejaVu Sans" >&2
  exit 1
fi

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

printf 'Generating %s preview...\n' "$name"

# Canvas: a fine paper/paint tooth, not a flat digital gradient.
"$MAGICK" -size ${W}x${H} "xc:$paper" \
  -seed "$seed" -attenuate 0.018 +noise Gaussian \
  "$tmp/base.png"

# A broad painted blue field with a torn, uneven edge.
"$MAGICK" -size ${W}x${H} xc:none -fill "$(rgba "$accent" "$a_wash")" \
  -draw "polygon 0,0 1120,0 930,1012 0,1012" \
  -seed "$seed" -spread 3 "$tmp/field.png"

# Loose colour blocks, the way a canvas is blocked in before the figure.
"$MAGICK" -size ${W}x${H} xc:none \
  -fill "$(rgba "$red" "$a_block")"    -draw "polygon 1210,0 1800,0 1800,250 1290,205" \
  -fill "$(rgba "$yellow" "$a_block")" -draw "polygon 1460,285 1800,255 1800,610 1510,575" \
  -fill "$(rgba "$green" "$a_block")"  -draw "polygon 0,760 610,735 680,1012 0,1012" \
  -fill "$(rgba "$cyan" "$a_block")"   -draw "polygon 690,815 1010,790 1040,1012 710,1012" \
  -seed "$seed" -spread 3 "$tmp/blocks.png"

# A black/blue painted panel that anchors the wordmark.
"$MAGICK" -size ${W}x${H} xc:none -fill "$(rgba "$panel_color" "$panel_alpha")" \
  -stroke "$panel_outline" -strokewidth 4 \
  -draw "polygon 55,690 930,665 960,950 65,980" \
  -seed "$seed" -spread 4 "$tmp/panel.png"

# Figure: an abstract head under a crown, with a blocky torso.
"$MAGICK" -size ${W}x${H} xc:none \
  -fill "$(rgba "$accent" "$a_fill")" -draw "ellipse 1260,410 235,300 0,360" \
  -fill "$(rgba "$selection" 0.55)" -draw "ellipse 1260,700 260,230 0,360" \
  -fill "$(rgba "$yellow" 0.95)" -draw "polygon 1080,195 1080,95 1145,150 1200,55 1255,145 1315,60 1370,145 1435,95 1435,195" \
  -fill "$(rgba "$orange" 0.85)" -draw "rectangle 1115,610 1405,900" \
  -seed "$seed" -spread 3 "$tmp/figure-fill.png"

# Heavy ink outline around the figure and crown.
"$MAGICK" -size ${W}x${H} xc:none -stroke "$ink" -strokewidth 11 -fill none \
  -draw "ellipse 1260,410 235,300 0,360" \
  -draw "polygon 1080,195 1080,95 1145,150 1200,55 1255,145 1315,60 1370,145 1435,95 1435,195" \
  -draw "rectangle 1115,610 1405,900" \
  -seed "$seed" -spread 2 "$tmp/figure-line.png"

# Face: eyes, a triangular nose, a jagged mouth, one scar.
"$MAGICK" -size ${W}x${H} xc:none \
  -fill "$ink" -draw "circle 1185,360 1185,330" -draw "circle 1330,360 1330,330" \
  -fill "$paper" -draw "circle 1185,360 1185,345" -draw "circle 1330,360 1330,345" \
  -fill "$ink" -draw "circle 1185,360 1185,352" -draw "circle 1330,360 1330,352" \
  -stroke "$ink" -strokewidth 8 -fill none \
  -draw "polygon 1260,390 1225,470 1295,470" \
  -draw "path 'M 1150,520 L 1190,505 L 1220,525 L 1255,505 L 1290,525 L 1325,505 L 1360,520'" \
  -draw "line 1210,475 1250,500" \
  -seed "$seed" -spread 1 "$tmp/face.png"

# Crown points in red.
"$MAGICK" -size ${W}x${H} xc:none -fill "$red" -stroke "$ink" -strokewidth 5 \
  -draw "circle 1145,150 1145,128" -draw "circle 1200,55 1200,33" \
  -draw "circle 1255,145 1255,123" -draw "circle 1315,60 1315,38" \
  -draw "circle 1370,145 1370,123" "$tmp/crown-dots.png"

# Raised arms and hands.
"$MAGICK" -size ${W}x${H} xc:none -stroke "$ink" -strokewidth 26 -fill none \
  -draw "path 'M 1130,690 C 1030,640 940,560 900,480'" \
  -draw "path 'M 1390,690 C 1490,650 1580,590 1620,510'" \
  -fill "$(rgba "$yellow" 0.9)" -stroke "$ink" -strokewidth 8 \
  -draw "circle 890,470 890,430" -draw "circle 1630,500 1630,460" "$tmp/arms.png"

# Loose loops, arrows, and paint marks.
"$MAGICK" -size ${W}x${H} xc:none -stroke "$(rgba "$accent" "$a_scribble")" -strokewidth 5 -fill none \
  -draw "path 'M 980,245 C 930,205 890,220 900,270 C 910,320 970,330 1005,290'" \
  -draw "path 'M 1460,330 C 1520,300 1580,330 1560,380 C 1540,430 1480,420 1470,380'" \
  -draw "path 'M 1010,620 C 1070,590 1080,650 1130,620'" \
  -draw "path 'M 1420,820 C 1470,780 1540,800 1570,850'" \
  -stroke "$(rgba "$red" 0.8)" -strokewidth 4 \
  -draw "path 'M 1500,710 C 1530,680 1570,700 1550,735 C 1530,770 1490,750 1500,720'" \
  -stroke "$(rgba "$yellow" 0.9)" -strokewidth 6 \
  -draw "path 'M 840,180 L 900,150 L 870,210 L 930,185'" \
  -stroke "$(rgba "$green" 0.7)" -strokewidth 3 \
  -draw "path 'M 150,620 C 220,600 250,650 210,690 C 170,730 110,700 140,650'" \
  "$tmp/scribbles.png"

"$MAGICK" -size ${W}x${H} xc:none -stroke "$ink" -strokewidth 5 -fill "$ink" \
  -draw "line 950,900 1080,850" -draw "polygon 1080,850 1050,838 1055,865" \
  -draw "line 1480,650 1600,620" -draw "polygon 1600,620 1570,608 1575,635" \
  "$tmp/arrows.png"

# Wordmark: rough uppercase paint, not a UI label.
"$MAGICK" -size ${W}x${H} xc:none -font "$font_bold" -pointsize 160 -fill "$word_color" \
  -gravity northwest -annotate +85+690 "ORÁCULO" -seed "$seed" -spread 1 \
  -background none -rotate -2 "$tmp/word.png"
"$MAGICK" -size ${W}x${H} xc:none -font "$font_bold" -pointsize 64 -fill "$word2_color" \
  -gravity northwest -annotate +105+855 "$descriptor" \
  -background none -rotate -2 "$tmp/word2.png"

# Small hand-lettered marginalia.
"$MAGICK" -size ${W}x${H} xc:none -font "$font_bold" -pointsize 30 -fill "$dark_foreground" \
  -gravity northwest \
  -annotate +92+120 "ORÁCULO / STEEL BLUE" \
  -annotate +92+165 "$field_label" \
  "$tmp/labels.png"

# Six ANSI paint chips, labelled like a studio colour test.
chips=(red yellow green cyan blue magenta)
x=1430
for c in "${chips[@]}"; do
  chip=${!c}
  "$MAGICK" -size ${W}x${H} xc:none -fill "$chip" -stroke "$ink" -strokewidth 3 \
    -draw "rectangle $x,915 $((x + 46)),965" \
    -seed "$seed" -spread 2 "$tmp/chip-$c.png"
  x=$((x + 56))
done

"$MAGICK" -size ${W}x${H} xc:none -font "$font_bold" -pointsize 24 -fill "$dark_foreground" \
  -gravity northwest -annotate +1430+882 "ANSI" "$tmp/ansi-label.png"

# Anatomical marks and paint drips inside the torso.
"$MAGICK" -size ${W}x${H} xc:none -stroke "$ink" -strokewidth 5 -fill none \
  -draw "path 'M 1195,740 C 1195,700 1260,700 1260,740 C 1260,790 1225,820 1195,850'" \
  -draw "path 'M 1325,740 C 1325,700 1260,700 1260,740 C 1260,790 1295,820 1325,850'" \
  -draw "line 1195,780 1325,780" \
  -draw "line 1260,780 1260,860" \
  -stroke "$(rgba "$red" 0.9)" -strokewidth 10 -fill none \
  -draw "path 'M 1210,765 C 1230,740 1260,760 1260,785 C 1260,760 1290,740 1310,765'" \
  -stroke "$(rgba "$accent" 0.85)" -strokewidth 4 \
  -draw "line 1120,205 1110,330" -draw "line 1400,205 1415,350" \
  -draw "circle 900,520 900,518" -draw "circle 1630,550 1630,548" \
  -stroke "$(rgba "$yellow" 0.8)" -strokewidth 3 \
  -draw "line 1145,195 1130,285" -draw "line 1370,195 1385,300" \
  "$tmp/anatomy.png"

# A few thick outline accents on the colour blocks.
"$MAGICK" -size ${W}x${H} xc:none -stroke "$ink" -strokewidth 4 -fill none \
  -draw "line 1210,0 1290,205" -draw "line 1290,205 1800,250" \
  -draw "line 1460,285 1800,255" -draw "line 1510,575 1800,610" \
  -seed "$seed" -spread 2 "$tmp/block-lines.png"

# Compose. Each chip is a separate composite so every layer is retained.
"$MAGICK" "$tmp/base.png" \
  "$tmp/field.png" -compose over -composite \
  "$tmp/blocks.png" -compose over -composite \
  "$tmp/panel.png" -compose over -composite \
  "$tmp/figure-fill.png" -compose over -composite \
  "$tmp/figure-line.png" -compose over -composite \
  "$tmp/face.png" -compose over -composite \
  "$tmp/crown-dots.png" -compose over -composite \
  "$tmp/arms.png" -compose over -composite \
  "$tmp/scribbles.png" -compose over -composite \
  "$tmp/arrows.png" -compose over -composite \
  "$tmp/anatomy.png" -compose over -composite \
  "$tmp/block-lines.png" -compose over -composite \
  "$tmp/word.png" -compose over -composite \
  "$tmp/word2.png" -compose over -composite \
  "$tmp/labels.png" -compose over -composite \
  "$tmp/ansi-label.png" -compose over -composite \
  "$tmp/chip-red.png" -compose over -composite \
  "$tmp/chip-yellow.png" -compose over -composite \
  "$tmp/chip-green.png" -compose over -composite \
  "$tmp/chip-cyan.png" -compose over -composite \
  "$tmp/chip-blue.png" -compose over -composite \
  "$tmp/chip-magenta.png" -compose over -composite \
  -type TrueColor -define png:color-type=2 -depth 8 -strip \
  -define png:compression-level=9 "PNG24:$output"

echo "wrote $output"
