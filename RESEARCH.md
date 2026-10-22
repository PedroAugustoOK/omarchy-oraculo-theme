# Oráculo — Omarchy Theme Research

**Date:** 2026-10-22
**Omarchy version tested:** 4.0.6-1
**Machine:** Arch Linux + Hyprland + Quickshell; both themes installed, `Oraculo Light` active during the final pass
**Scope:** the dark Oráculo theme and its light sibling
(`omarchy-oraculo-light-theme`).

This document records how the theme system actually behaves on the installed
version, checked against the scripts and generated configuration on this
machine — not from memory or older tutorials.

## Sources consulted

1. `https://omarchy.org/manual/making-your-own-theme/` — official manual:
   `~/.config/omarchy/themes`, `colors.toml`, `mode = "light"`, Yaru icon
   names, `unlock.png` / `preview-unlock.png`, template overrides, repository
   naming.
2. `https://omarchy.org/manual/themes/` — the stock theme catalogue and the
   light/dark pairing model.
3. `https://github.com/omacom/omarchy/blob/quattro/docs/theming.md` — theme
   activation flow, staging overlay, template rendering, installed-theme
   restrictions.
4. `/usr/share/omarchy/default/themed/*.tpl` — the 19 templates used by
   4.0.6-1.
5. `/usr/share/omarchy/themes/*/` — all 22 installed stock themes, studied as
   the structural and palette reference.
6. The user's earlier themes:
   `omarchy-ankh-theme`, `omarchy-ankh-dark-theme`, `omarchy-mooni-theme`,
   `omarchy-mooni-dark-theme`, `omarchy-veredas-theme`,
   `omarchy-lula-theme`, `omarchy-lula-light-theme`.
7. `OmarchyOpenCode` audit tools — palette contract, WCAG contrast and README
   claim verification, plus the repository's own surface-aware
   `scripts/check-theme.py`.

## 1. The contract on Omarchy 4.0.6-1

- Stock themes live in `/usr/share/omarchy/themes/<slug>/`; user themes live
  in `~/.config/omarchy/themes/<slug>/`. A user directory overlays a stock
  theme with the same slug.
- `omarchy theme install <git-url>` derives the slug from the repository name
  by stripping `omarchy-` and `-theme`, then applies the theme. This repository
  becomes `oraculo`; the light sibling becomes `oraculo-light`.
- `omarchy theme set` builds a fresh staging directory, copies the stock theme
  first and the user theme on top, then renders the built-in templates into
  `~/.local/state/omarchy/current/theme/`.
- A theme's `colors.toml` is the single palette source. The canonical contract
  is 26 flat keys: `mode`, `accent`, `selection`, `muted`, the four surfaces,
  the four foreground roles, and the eight ANSI colours plus six brights.
  Optional `hyprland_active_border` / `hyprland_inactive_border` strings feed
  the Hyprland and shell gradients through `hypr_gradient` / `shell_gradient`.
- 19 built-in templates cover Alacritty, Foot, Ghostty, Kitty, btop, Chromium,
  Neovim, Helix, VS Code, Obsidian, Claude, Pi, Hermes, T3Code, the Omarchy
  shell, Hyprland, gum, the preview-share picker and keyboard RGB.
- Hand-written files win over templates. `shell.<section>.toml` can patch a
  single shell section; a full `shell.toml` replaces the generated one.
- A theme installed from a clone is staged with a deny list: any `*.lua`,
  `alacritty.toml`, `foot.ini`, `ghostty.conf`, `kitty.conf`, `vscode.json`
  and symlinks are dropped and regenerated. A hand-written theme directory or
  a symlinked working copy is staged in full. Oráculo ships none of the denied
  files, so a normal `omarchy theme install` produces no ignored-file warnings.
- Backgrounds are read flat from `backgrounds/`; `omarchy theme bg next` cycles
  them. Previews are listed by the theme picker; `unlock.png` and
  `preview-unlock.png` add the theme to `Style > Unlock`.
- `mode = "dark"` or `"light"` is the current explicit way to pair the theme
  with the rest of the system. The old `light.mode` file still works but is
  unnecessary.

## 2. What the stock themes establish

The 22 installed themes are 17 dark and 5 light. Their common shape is lean:

- every theme has `colors.toml`, `backgrounds/`, `preview.png`,
  `preview-unlock.png`, `unlock.png` and `icons.theme`;
- only a minority add generated-equivalent extras: five themes ship a
  `hyprland.lua`, four ship `btop.theme`, five ship `chromium.theme`, and one
  ships `shell.lock.toml`;
- backgrounds range from two to nine images; the picker only needs one;
- palettes use the same 26-key shape, with one clear accent and tinted
  neutrals. Some add the optional border gradient keys.

The stock lock canvases are not one size: most are 800×188, Tokyo Night uses
1108×523, Lumon uses 541×278, and Vantablack/White use 800×378. The lock
*preview* is consistently 1920×1080. Oráculo uses the Tokyo Night canvas for
`unlock.png` and the standard 1920×1080 preview canvas, with its own sigil and
lock furniture rather than claiming to copy every stock layout.

Blue-family references and the niche Oráculo fills:

| Theme | Mode | Blue character | What Oráculo takes from it |
|---|---|---|---|
| Tokyo Night | dark | indigo night, soft neon | blue-tinted surfaces and a restrained accent |
| Nord | dark | arctic blue-gray | cool neutrals that stay calm |
| Lumon | dark | pale institutional cyan | blue can carry a whole identity without a second accent |
| Kanagawa | dark | ink indigo | deep, quiet backgrounds |
| Lupine | light | electric blue on white | a light theme can keep a strong accent |
| White | light | neutral paper | light surfaces should stay paper-like, not pure white |

Oráculo's own position is **steel blue**: less purple than Tokyo Night or
Kanagawa, less cyan than Lumon, darker and more saturated than Nord. It is a
matched dark/light pair with the same geometry and the same accent family.

## 3. Comparison with the previous themes

| Theme family | Mode | Character | Structural lesson applied to Oráculo |
|---|---|---|---|
| Ankh / Ankh Dark | light + dark | cool slate neutrals, quiet accents | explicit foreground ramps and editor code roles matter; Oráculo keeps the ramp explicit and lets Omarchy generate the editor files |
| Mooni / Mooni Dark | light + dark | honey yellow, warm charcoal | a large `integrations/` tree and generators are valuable but expensive to keep in sync; not needed for a color theme on 4.x |
| Veredas | light | botanical green, soft washes | reproducible abstract wallpapers and a generated preview are the right asset language |
| Lula / Lula Light | dark + light | wine red, near-black/paper | the lean publishable shape: `colors.toml` + assets + docs, no denied files, sibling repos, measured README claims |
| **Oráculo / Oráculo Light** | dark + light | steel blue, high contrast | follows Lula's contract and Veredas' asset workflow, with a two-mode geometry twin |

The key decision is deliberate: **do not ship a second copy of what Omarchy
already generates**. Ankh and Mooni predate parts of the current template
coverage; their extra integrations are useful for other apps but create drift.
Oráculo relies on `colors.toml` and the 19 templates, and ships only the files
that a theme must own: palette, wallpapers, picker art, lock art, icons,
keyboard colour and documentation.

## 4. Palette engineering

The dark palette uses blue-black surfaces (`background`, `dark_background`,
`darker_background`, `lighter_background`) with a single sky-steel accent. The
foreground ramp is monotonic and explicit, so no value depends on a derived
floor. ANSI colours are tinted toward the same cool family instead of being
raw primaries.

Targets used, matching the official palette guidance and the project's audit
tool:

- body text vs background: at least 7:1 (Oráculo: 16.17:1);
- secondary text: at least 4.5:1 (8.51:1);
- accent vs background: at least 3:1, preferably above 4.5:1 (7.25:1);
- base ANSI: at least 4.5:1 on every opaque surface (background floor 5.25:1,
  raised-surface floor 4.51:1);
- bright ANSI: at least 4.5:1 on the background (bright floor 7.69:1);
- selected text: at least 4.5:1 (10.96:1);
- `selection` is a fill, not text: 1.48:1 against the background is expected;
- `muted` is chrome: 5.67:1 on the background and 3.84:1 on the selection
  fill; it is deliberately more legible than the stock themes' chrome role on
  the main surface.

The dark palette's `brown` is `#A77E64`: 5.25:1 on the background and 4.51:1 on
`lighter_background`, so base ANSI is readable on the raised surface as well as
the paper/night field. The selection fill is not treated as an ANSI text
surface: selected text uses `foreground` (10.96:1), while `red` (3.94:1) and
`brown` (3.55:1) on the fill are documented as fill exceptions, not hidden
contrast failures.

The light sibling keeps the same geometry but changes the physical model:
paper surfaces recede to cooler gray-blues, text becomes deep steel ink, and
the accent is darkened so it remains readable on paper. The measured values are
in the light theme's [RESEARCH.md](https://github.com/PedroAugustoOK/omarchy-oraculo-light-theme/blob/main/RESEARCH.md):
the base ANSI floor is 5.39:1, the bright floor is 4.51:1, `dark_foreground` is
5.40:1 and `muted` is 2.02:1. Base text roles and base ANSI clear 4.5:1 on all
opaque surfaces and on the selection fill; bright ANSI is guaranteed on the
paper background but not on the darker chrome surfaces. This is documented as
a terminal-content exception, not a hidden claim.

Borders use a two-stop steel gradient in both themes. The gradient strings are
the only non-hex palette values; the audit tool validates both stops and the
angle.

Name normalization is worth noting: Omarchy derives the display name from the
slug, so the installed theme appears as **Oraculo**, without the accent. The
repository, README and artwork keep the proper spelling.

On this development machine `~/.config/omarchy/themes/oraculo` and
`~/.config/omarchy/themes/oraculo-light` are symlinks to the working copies in
`~/dots/AnkhDiverses/`. Symlinked themes are staged in full (no deny list), but
`omarchy theme update` intentionally skips them; update the working copies with
`git -C <theme-dir> pull` instead.

## 5. Assets

- **Wallpapers:** three per theme, native **3840×2160**, truecolor PNG, about
  2.6 MB each (dark) and 2.1 MB each (light). They are procedural soft-wash
  fields with broad asymmetric Gaussian blooms and no imagery, generated by
  `scripts/make-wallpapers.sh` from the palette. The dark names are Veil, Tide
  and Dusk; the light names are Mist, Linen and Haze. A fixed seed and fine
  grain keep the render deterministic and prevent visible banding.
- **Preview:** 1800×1012, a static artwork included with the theme. It is an
  original neo-expressionist composition inspired by Basquiat's visual
  language — crown, rough anatomical figure, medical and maritime motifs, paint
  marks, marginalia and a D20. It is not generated at build time and is not a
  desktop screenshot.
- **Lock/boot art:** `scripts/make-unlock.sh` draws the Oráculo sigil — three
  concentric rings cut by one 45-degree stripe, plus a solid still point. The
  transparent PNG is 1108×523 (the Tokyo Night canvas); the lock preview is
  1920×1080 and uses the theme's own lock glyph and password field on the stock
  preview canvas. The light theme reuses the exact geometry with the light
  accent and a softer bloom.
- **Icons / keyboard:** `icons.theme` is `Yaru-blue` in both themes;
  `keyboard.rgb` is the theme's own accent (`5fa8d3` dark, `2b6a96` light),
  matching what the built-in keyboard template would generate.

## 6. Verification performed

- `omarchy-theme-color --file colors.toml --all` resolves **58 keys** for each
  theme on 4.0.6-1, including `mode`, `theme_type`, aliases, ANSI 0–15 and both
  border gradients.
- `scripts/check-theme.py` validates the 26 canonical keys, the monotonic
  surface ramp, every text/base-ANSI role on all four opaque surfaces,
  selected-text contrast, asset dimensions, `keyboard.rgb`, denied files and
  symlinks. Both themes pass with no blocking problems. The notes record the
  selection-fill exception and the light bright-ANSI chrome limitation.
- The README claim checker verifies every hex code and every contrast ratio
  quoted in both READMEs against the real `colors.toml`.
- The lock and wallpaper scripts were re-run after the final palette change.
  The lock art is deterministic (`compare -metric AE` = 0 across two runs); the
  wallpaper script uses a fixed seed (`20261022`) and the same ImageMagick
  build. The preview is a static asset. Committed dimensions are 1800×1012
  (preview), 1108×523 (unlock), 1920×1080 (lock preview) and 3840×2160
  (wallpapers).
- Headless staging (`OMARCHY_THEME_HEADLESS=1 OMARCHY_THEME_SKIP_BACKGROUND=1
  omarchy theme set ...`) is run for both themes, with no ignored-file warnings
  and no unresolved `{{ ... }}` placeholders in generated text configs. The
  staged tree also carries the source README/RESEARCH files; their literal
  `{{ ... }}` example is documentation, not an unresolved template.
- A clean install from the public URL is exercised in an isolated `HOME` for
  both repositories. Both clone, stage and apply without ignored-file warnings;
  the staged text configs have zero unresolved placeholders.
- The active theme is reapplied as **Oraculo Light** and the active background
  remains **Oraculo Light Mist** after the final asset refresh.
- CI (`.github/workflows/ci.yml`) runs the palette/contrast/asset audit, shell
  syntax checks, and the lock render on every push and pull request. The 4K
  wallpaper render is intentionally local-only because it is CPU-heavy.

## 7. Limits and decisions

- The preview is curated artwork, not a screenshot. It represents the palette
  and wordmark but does not claim to show the live desktop.
- Plymouth is machine-local and optional; the theme ships the art and the
  preview, but does not change the boot screen automatically.
- No animated intros: the OWE engine is optional and the theme stays static.
- No `.lua`, terminal configs or `vscode.json` are shipped, by design. They
  would be dropped by git staging, and the generated versions already follow
  the palette.
- The light bright-ANSI exception is explicit: brights are tuned for the paper
  background and are not used as chrome text on darker surfaces. This is the
  same trade-off the official light themes make, but Oráculo documents it.
- Visual inspection of every application is out of scope for a static audit;
  the shell, terminal and editor files are generated from the same palette, so
  they cannot drift from it.

## 8. Repository checklist

- [x] `colors.toml` with all 26 canonical keys and both border gradients.
- [x] Three native 4K wallpapers per theme, flat `backgrounds/`, about 2.1–2.7
  MB each.
- [x] `preview.png`, `unlock.png`, `preview-unlock.png`.
- [x] `icons.theme` and `keyboard.rgb`.
- [x] README with install, activation, update, removal, surface-aware contrast
  and measured palette values.
- [x] RESEARCH.md (this file).
- [x] MIT LICENSE and `.gitignore`.
- [x] No denied files; no symlinks in the repository.
- [x] Seeded wallpaper and deterministic lock scripts; static preview.
- [x] CI workflow and `scripts/check-theme.py` surface-aware audit.
