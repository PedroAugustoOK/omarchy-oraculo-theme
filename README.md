# Oráculo for Omarchy

[![CI](https://github.com/PedroAugustoOK/omarchy-oraculo-theme/actions/workflows/ci.yml/badge.svg)](https://github.com/PedroAugustoOK/omarchy-oraculo-theme/actions/workflows/ci.yml)

A steel-blue Omarchy theme. Deep blue-black surfaces, a calm sky-steel accent,
and cool, highly legible text. The palette is built around one accent used
where it matters — focused borders, active bar elements, selections — with
tinted neutrals that keep the whole desktop in the same blue family.

Its light sibling, **Oráculo Light** (cool paper surfaces, deep steel-blue ink,
the same accent family), lives at
[PedroAugustoOK/omarchy-oraculo-light-theme](https://github.com/PedroAugustoOK/omarchy-oraculo-light-theme).

![Basquiat-inspired Oráculo preview](preview.png)

The preview is original neo-expressionist artwork inspired by the visual
language of Jean-Michel Basquiat: a crown, a rough figure, paint marks,
marginalia and the six ANSI colours. It is generated from `colors.toml` by
`scripts/make-preview.sh`; it is not a desktop screenshot and does not reproduce
a specific artwork.

## Palette

Every generated config — Hyprland borders, the shell (bar, menus, launcher,
notifications, OSD, lock screen), Alacritty/Foot/Ghostty/Kitty, btop,
Chromium, Neovim, Helix, VS Code, Obsidian, Claude/Pi/Hermes/T3Code, gum,
the preview-share picker and the keyboard backlight — derives from `colors.toml`
through Omarchy's built-in templates.

| Key | Value | Role | Contrast on background |
|---|---|---|---|
| `mode` | `dark` | blue-black surfaces, cool text | — |
| `background` | `#0B1118` | primary surface, ANSI 0 | — |
| `foreground` | `#E6EEF5` | primary text, ANSI 7 | **16.17:1** |
| `accent` / `blue` | `#5FA8D3` | one accent, sky steel, ANSI 4 | **7.25:1** |
| `selection` | `#1E3446` | selected-text fill | 1.48:1 (fill) |
| `muted` | `#7A8FA3` | comments, placeholders, ANSI 8 | 5.67:1 (chrome) |
| `dark_foreground` | `#9DB0C2` | secondary text | **8.51:1** |
| `light_foreground` | `#F0F6FA` | emphasised text | **17.40:1** |
| `bright_foreground` | `#FAFCFE` | cursor, ANSI 15 | **18.44:1** |

Full ANSI set (all measured against `background #0B1118`):

- `red #E2686F` 5.82:1, `yellow #DDB86A` 10.06:1, `orange #DD8B5F` 7.16:1
- `green #7FB98A` 8.31:1, `cyan #6CC5CE` 9.49:1, `magenta #B98CD4` 7.01:1
- `brown #A77E64` 5.25:1
- bright variants: `bright_red #F4848B` 7.69:1, `bright_yellow #EFCB84` 12.23:1,
  `bright_green #98D3A4` 11.00:1, `bright_cyan #8ADDE4` 12.23:1,
  `bright_blue #82C4E8` 9.94:1, `bright_magenta #D2A8E8` 9.49:1

The base ANSI floor is **5.25:1** (brown); the bright floor is **7.69:1**.
Selected text (`foreground` on `selection`) keeps **10.96:1**.

`scripts/check-theme.py` also measures every text role and base ANSI colour
against all four opaque surfaces. The tightest result is `brown` on
`lighter_background` at **4.51:1**. `selection` is a fill, not a text surface:
selected text uses `foreground` (10.96:1), and ANSI inside the selection is not
a supported text pairing (`red` 3.94:1, `brown` 3.55:1). `muted` is chrome —
5.67:1 on the background and 3.84:1 on the selection fill — not body text. The
selection fill itself is 1.48:1 against the background, which is a visible
state change rather than a contrast failure.

Window borders use a steel-blue gradient:

```toml
hyprland_active_border = "rgba(5FA8D3ee) rgba(1E4A6Dee) 45deg"
hyprland_inactive_border = "rgba(7A8FA3aa)"
```

## Wallpapers

Three **3840×2160** abstract wallpapers in `backgrounds/` (switch with
`omarchy theme bg next` or the shell's background switcher). They follow the
quiet, soft-focus language of
[Veredas](https://github.com/PedroAugustoOK/omarchy-veredas-theme): no imagery,
just slow washes of steel blue and blue-black.

| Wallpaper | Description |
|---|---|
| ![01 Oráculo Veil](backgrounds/001-oraculo-veil.png) `001-oraculo-veil.png` | A single broad sky-steel bloom dissolving into the field |
| ![02 Oráculo Tide](backgrounds/002-oraculo-tide.png) `002-oraculo-tide.png` | A quiet vertical recess with a cool highlight and a faint accent edge |
| ![03 Oráculo Dusk](backgrounds/003-oraculo-dusk.png) `003-oraculo-dusk.png` | One slow diagonal wash, low and off-centre |

Native 4K PNG, truecolor, about 2.6 MB each, with fine grain to break up
banding. Original abstract artwork generated programmatically with ImageMagick;
no third-party imagery. Nothing animated.

## Installation

```bash
omarchy theme install https://github.com/PedroAugustoOK/omarchy-oraculo-theme
```

This clones to `~/.config/omarchy/themes/oraculo` and applies it immediately
(menu path: `Install > Style > Theme`).

## Activation

```bash
omarchy theme list            # confirm `Oraculo` is listed
omarchy theme set oraculo
omarchy theme current         # should print `Oraculo`
omarchy theme bg next         # advance to the next wallpaper
```

Omarchy derives the display name from the repository slug, so the menu and
`omarchy theme current` show **Oraculo** without the accent.

Preview the palette without applying:

```bash
omarchy dev theme-preview oraculo
```

## Update and removal

```bash
omarchy theme update             # pull latest for all git-installed themes
omarchy theme refresh            # re-apply the current theme after an Omarchy upgrade
omarchy theme remove oraculo     # delete the local clone
```

After an `omarchy update`, run `omarchy theme refresh` once so staged configs
are regenerated with the current templates.

To switch to the light sibling: `omarchy theme set oraculo-light`.

## Lock / boot art

`unlock.png` and `preview-unlock.png` are generated from `colors.toml` by
`scripts/make-unlock.sh`. The mark is the Oráculo sigil: three concentric
rings broken by a single 45-degree cut, with a solid centre. One cut runs
through both sides of every ring, so the gaps read as a compass bearing rather
than damage, and the centre dot is drawn after the cut so it stays whole — the
still point the rings turn around. The dark theme paints the forms in the sky
steel accent with a soft halo of the same colour.

The lock preview is 1920×1080. The transparent art is 1108×523, the same canvas
size as Tokyo Night's stock lock art. The preview places the sigil on the stock
1920×1080 canvas with the theme's own lock glyph and password field; it is not a
pixel-for-pixel copy of every stock theme's furniture.

## Compatibility

- Omarchy **4.x**, tested on `4.0.6-1`.
- Requires the `colors.toml` theme system with `mode`, template expansion and
  `hypr_gradient` support.
- Everything is derived from `colors.toml` through Omarchy's built-in
  templates. The repository ships **no** `.lua`, terminal configs,
  `vscode.json` or symlinks, since those are dropped or regenerated for
  git-installed themes. The theme looks correct from `colors.toml` alone.
- Icons: `Yaru-blue`. Keyboard backlight: sky steel `5fa8d3`.
- No animated `backgrounds/intros/`; the OWE wallpaper engine is optional and
  this theme stays static.

### Asset tooling

- Bash, ImageMagick 7 (`magick`; ImageMagick 6's `convert` is used as a
  fallback), and fontconfig with Liberation Sans or DejaVu Sans for the preview.
- `omarchy-theme-color` is optional: the scripts fall back to parsing
  `colors.toml` directly, so the artwork can be regenerated outside an Omarchy
  host.
- `scripts/check-theme.py` uses only the Python 3 standard library.
- The 4K wallpaper render is CPU-heavy (a few minutes per theme). CI validates
  the palette, contrast, assets and the preview/lock renders; it intentionally
  does not rerender the 4K wallpaper set.

## Repository structure

```text
omarchy-oraculo-theme/
├── .github/workflows/ci.yml  # palette, contrast, asset and render checks
├── colors.toml          # the palette — the only required file
├── backgrounds/         # 3 abstract 3840×2160 wallpapers
├── icons.theme          # Yaru-blue
├── keyboard.rgb         # 5fa8d3
├── preview.png          # 1800×1012 theme-picker artwork
├── unlock.png           # transparent lock/boot art (Oráculo sigil)
├── preview-unlock.png   # 1920×1080 lock/boot styles preview
├── scripts/             # make-preview.sh, make-unlock.sh, make-wallpapers.sh, check-theme.py
├── README.md
├── RESEARCH.md          # how Omarchy theming was verified and compared
└── LICENSE              # MIT
```

The asset scripts are reproducible from `colors.toml` alone. Regenerate the
artwork and run the audit with:

```bash
./scripts/make-preview.sh . "Oráculo" preview.png
./scripts/make-unlock.sh .
./scripts/make-wallpapers.sh .
./scripts/check-theme.py .
```

## Credits and license

- Theme, palette, wallpapers, lock art and preview: original work for this
  repository, generated programmatically with ImageMagick. No third-party
  assets.
- The preview is an original neo-expressionist composition inspired by
  Jean-Michel Basquiat's visual language; no specific artwork is reproduced.
- Palette and configuration: MIT (see [LICENSE](LICENSE)).
- Wallpapers and previews: same MIT license (original works).
- Built for [Omarchy](https://omarchy.org) (`basecamp/omarchy`). Icon set names
  belong to Yaru; font rendering in previews uses system fonts, which are not
  shipped with the repository.
