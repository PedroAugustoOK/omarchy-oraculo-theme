#!/bin/bash
# Generate the Oráculo lock artwork from the theme palette.
#
#   ./scripts/make-unlock.sh [theme-dir] [unlock.png] [preview-unlock.png]
#
# The mark is the Oráculo sigil: three concentric rings broken by a single
# 45-degree cut, with a solid centre. One cut runs through both sides of every
# ring, so the gaps read as a compass bearing rather than damage, and the dot
# at the centre is drawn after the cut so it stays whole — the still point the
# rings turn around.
#
#   ring 1  outer r 208, inner r 182
#   ring 2  outer r 148, inner r 122
#   ring 3  outer r  88, inner r  64
#   dot     r 30 at the centre
#   cut     rectangle -420..420 x -15..15, rotated 45deg about the centre
#
# The halo is the accent at a soft opacity profile, matching the family's
# lock art without turning into a stain on light paper.
set -euo pipefail

theme_dir=${1:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}
out_unlock=${2:-$theme_dir/unlock.png}
out_preview=${3:-$theme_dir/preview-unlock.png}

W=1108
H=523
CX=554
CY=261

color() { omarchy-theme-color "$1" --file "$theme_dir/colors.toml"; }

accent=$(color accent)
background=$(color background)
foreground=$(color foreground)

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

# --- the three rings, cut by one 45-degree stripe ---------------------------
magick -size ${W}x${H} xc:black \
  -fill white -draw "circle $CX,$CY $((CX + 208)),$CY" \
  -fill black -draw "circle $CX,$CY $((CX + 182)),$CY" \
  -fill white -draw "circle $CX,$CY $((CX + 148)),$CY" \
  -fill black -draw "circle $CX,$CY $((CX + 122)),$CY" \
  -fill white -draw "circle $CX,$CY $((CX + 88)),$CY" \
  -fill black -draw "circle $CX,$CY $((CX + 64)),$CY" \
  "$tmp/rings.png"

magick "$tmp/rings.png" \
  -fill black -draw "translate $CX,$CY rotate 45 rectangle -420,-15 420,15" \
  "$tmp/rings-cut.png"

# --- the still point --------------------------------------------------------
magick -size ${W}x${H} xc:black \
  -fill white -draw "circle $CX,$CY $((CX + 30)),$CY" \
  "$tmp/dot.png"

magick "$tmp/rings-cut.png" "$tmp/dot.png" \
  -compose Lighten -composite "$tmp/silhouette.png"

# --- the mark ---------------------------------------------------------------
# Halo: a wide blur of the silhouette on a padded canvas so the glow is not
# clipped at the edges.
magick "$tmp/silhouette.png" \
  -background black -gravity center -extent $((W + 160))x$((H + 160)) \
  -blur 0x24 \
  -gravity center -crop ${W}x${H}+0+0 +repage "$tmp/halo.png"

# The forms themselves, in the theme accent, with a one-pixel soft edge.
magick "$tmp/silhouette.png" -blur 0x0.8 "$tmp/forms.png"

magick -size ${W}x${H} "xc:$accent" "$tmp/halo.png" -alpha off \
  -compose CopyOpacity -composite "$tmp/halo-color.png"

magick -size ${W}x${H} "xc:$accent" "$tmp/forms.png" -alpha off \
  -compose CopyOpacity -composite "$tmp/forms-color.png"

magick "$tmp/halo-color.png" "$tmp/forms-color.png" -compose Over -composite \
  -depth 8 -strip "$out_unlock"

# --- lock screen preview ----------------------------------------------------
PW=1920
PH=1080

magick -size ${PW}x${PH} "xc:$background" "$out_unlock" \
  -gravity north -geometry +0+278 -compose Over -composite \
  "$tmp/preview-mark.png"

# Password field: 2px outline plus four dots, in the foreground ink.
FIELD_X=818
FIELD_Y=842
FIELD_W=283
FIELD_H=45

magick -size ${PW}x${PH} xc:none \
  -fill none -stroke "$foreground" -strokewidth 2 \
  -draw "rectangle $FIELD_X,$FIELD_Y $((FIELD_X + FIELD_W)),$((FIELD_Y + FIELD_H))" \
  -fill "$foreground" -stroke none \
  -draw "circle 840,864 843.5,864" \
  -draw "circle 852,864 855.5,864" \
  -draw "circle 864,864 867.5,864" \
  -draw "circle 876,864 879.5,864" \
  "$tmp/field.png"

# Lock glyph: shackle, body and keyhole.
magick -size ${PW}x${PH} xc:none \
  -fill none -stroke "$foreground" -strokewidth 5 \
  -draw "arc 777,848.5 792,870.5 180,360" \
  -fill "$foreground" -stroke none \
  -draw "roundrectangle 769,860 801,883 4,3" \
  -fill "$background" -stroke none \
  -draw "roundrectangle 784,868 786,875 1,1" \
  "$tmp/lock.png"

magick "$tmp/preview-mark.png" "$tmp/lock.png" -compose Over -composite "$tmp/step-lock.png"
magick "$tmp/step-lock.png" "$tmp/field.png" -compose Over -composite \
  -depth 8 -strip "$out_preview"

echo "wrote $out_unlock"
echo "wrote $out_preview"
