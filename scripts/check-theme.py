#!/usr/bin/env python3
"""Validate an Oráculo theme: palette contract, surface-aware contrast, assets.

Usage:
    python3 scripts/check-theme.py [theme-dir]

The audit is deliberately honest about roles. Text roles and base ANSI colours
must clear 4.5:1 on every opaque surface. `selection` is a fill, and `muted` is
a hairline/chrome colour; they are reported separately. Bright ANSI colours are
required on the paper background, but on light themes they are allowed to sit
below 4.5:1 on the darker chrome surfaces, where they are not used for body
text. Those cases are printed as notes, not failures.

Only the Python standard library is used, so the same check runs locally and in
GitHub Actions without extra dependencies.
"""

from __future__ import annotations

import re
import struct
import sys
from pathlib import Path

REQUIRED_KEYS = [
    "mode",
    "accent",
    "selection",
    "muted",
    "background",
    "dark_background",
    "darker_background",
    "lighter_background",
    "foreground",
    "dark_foreground",
    "light_foreground",
    "bright_foreground",
    "red",
    "yellow",
    "orange",
    "green",
    "cyan",
    "blue",
    "magenta",
    "brown",
    "bright_red",
    "bright_yellow",
    "bright_green",
    "bright_cyan",
    "bright_blue",
    "bright_magenta",
]

TEXT_ROLES = [
    "foreground",
    "dark_foreground",
    "light_foreground",
    "bright_foreground",
    "accent",
]

BASE_ANSI = ["red", "yellow", "orange", "green", "cyan", "blue", "magenta", "brown"]
BRIGHT_ANSI = [
    "bright_red",
    "bright_yellow",
    "bright_green",
    "bright_cyan",
    "bright_blue",
    "bright_magenta",
]
OPAQUE_SURFACES = [
    "background",
    "dark_background",
    "darker_background",
    "lighter_background",
]
DENIED = {
    "alacritty.toml",
    "foot.ini",
    "ghostty.conf",
    "kitty.conf",
    "vscode.json",
}


def parse_colors(path: Path) -> dict[str, str]:
    colors: dict[str, str] = {}
    if not path.exists():
        return colors
    for raw in path.read_text(encoding="utf-8").splitlines():
        match = re.match(r'\s*([A-Za-z0-9_]+)\s*=\s*"([^"]+)"', raw)
        if match:
            colors[match.group(1)] = match.group(2)
    return colors


def rgb(hex_color: str) -> tuple[int, int, int]:
    value = hex_color.lstrip("#")
    return tuple(int(value[i : i + 2], 16) for i in (0, 2, 4))


def luminance(hex_color: str) -> float:
    def channel(value: int) -> float:
        x = value / 255
        return x / 12.92 if x <= 0.04045 else ((x + 0.055) / 1.055) ** 2.4

    r, g, b = rgb(hex_color)
    return 0.2126 * channel(r) + 0.7152 * channel(g) + 0.0722 * channel(b)


def contrast(a: str, b: str) -> float:
    x, y = luminance(a), luminance(b)
    return (max(x, y) + 0.05) / (min(x, y) + 0.05)


def png_size(path: Path) -> tuple[int, int] | None:
    try:
        data = path.read_bytes()[:33]
    except OSError:
        return None
    if len(data) < 24 or data[:8] != b"\x89PNG\r\n\x1a\n":
        return None
    width, height = struct.unpack(">II", data[16:24])
    return width, height


def fmt(value: float) -> str:
    return f"{value:.2f}:1"


def main() -> int:
    theme_dir = Path(sys.argv[1] if len(sys.argv) > 1 else ".").expanduser().resolve()
    problems: list[str] = []
    notes: list[str] = []

    print(f"\n{'=' * 72}")
    print(f"  theme check  {theme_dir}")
    print(f"{'=' * 72}")

    colors = parse_colors(theme_dir / "colors.toml")
    if not colors:
        print("  FAIL  colors.toml is missing or empty")
        return 1

    missing = [key for key in REQUIRED_KEYS if key not in colors]
    if missing:
        problems.append("missing keys: " + ", ".join(missing))
    else:
        print("  ok    all 26 canonical palette keys are present")

    mode = colors.get("mode", "?")
    print(f"  ok    mode = {mode}")

    # Surface ramp: darker <= dark <= background <= lighter.
    ramp = [
        ("darker_background", colors.get("darker_background", "")),
        ("dark_background", colors.get("dark_background", "")),
        ("background", colors.get("background", "")),
        ("lighter_background", colors.get("lighter_background", "")),
    ]
    if all(value.startswith("#") for _, value in ramp):
        lums = [luminance(value) for _, value in ramp]
        if lums != sorted(lums):
            problems.append("surface ramp is not monotonic")
        else:
            print("  ok    surface ramp is monotonic")

    # Text roles and base ANSI on every opaque surface.
    print("\n  text roles vs opaque surfaces (floor 4.5:1)")
    for role in TEXT_ROLES + BASE_ANSI:
        value = colors.get(role, "")
        if not value.startswith("#"):
            problems.append(f"{role}: not a hex colour")
            continue
        worst = min((contrast(value, colors.get(surface, "#000000")), surface) for surface in OPAQUE_SURFACES)
        status = "ok  " if worst[0] >= 4.5 else "FAIL"
        if worst[0] < 4.5:
            problems.append(f"{role} is {fmt(worst[0])} on {worst[1]}")
        print(f"  {status} {role:18} {fmt(worst[0]):>8}  ({worst[1]})")

    # Foreground on the selection fill.
    fg = colors.get("foreground", "")
    selection = colors.get("selection", "")
    if fg.startswith("#") and selection.startswith("#"):
        ratio = contrast(fg, selection)
        status = "ok  " if ratio >= 4.5 else "FAIL"
        if ratio < 4.5:
            problems.append(f"foreground on selection is {fmt(ratio)}")
        print(f"\n  {status} selected text (foreground/selection) {fmt(ratio)}")
        print(f"  info  selection fill vs background            {fmt(contrast(selection, colors.get('background', '#000000')))}")

    # Bright ANSI on the paper background is required; secondary surfaces are
    # terminal-only for light themes and are reported as notes.
    print("\n  bright ANSI")
    bg = colors.get("background", "#000000")
    secondary_failures: list[str] = []
    for role in BRIGHT_ANSI:
        value = colors.get(role, "")
        if not value.startswith("#"):
            problems.append(f"{role}: not a hex colour")
            continue
        ratio = contrast(value, bg)
        status = "ok  " if ratio >= 4.5 else "FAIL"
        if ratio < 4.5:
            problems.append(f"{role} on background is {fmt(ratio)}")
        for surface in OPAQUE_SURFACES[1:] + ["selection"]:
            if contrast(value, colors.get(surface, "#000000")) < 4.5:
                secondary_failures.append(role)
                break
        print(f"  {status} {role:18} {fmt(ratio):>8} on background")
    if secondary_failures:
        notes.append(
            "bright ANSI is terminal-only on light chrome surfaces: "
            + ", ".join(secondary_failures)
        )

    muted = colors.get("muted", "")
    if muted.startswith("#"):
        worst = min((contrast(muted, colors.get(surface, "#000000")), surface) for surface in OPAQUE_SURFACES)
        print(f"\n  info  muted/chrome floor {fmt(worst[0])} on {worst[1]} (not a text role)")

    # Base ANSI on selection is informational: selected text uses foreground.
    selection_failures: list[str] = []
    for role in BASE_ANSI:
        value = colors.get(role, "")
        if value.startswith("#") and selection.startswith("#") and contrast(value, selection) < 4.5:
            selection_failures.append(role)
    if selection_failures:
        notes.append(
            "base ANSI on the selection fill is not a text pairing: "
            + ", ".join(selection_failures)
            + " (selected text uses foreground)"
        )

    # Files and dimensions.
    print("\n  assets")
    expected = {
        "preview.png": (1800, 1012),
        "preview-unlock.png": (1920, 1080),
        "unlock.png": (1108, 523),
    }
    required_files = ["colors.toml", "README.md", "RESEARCH.md", "LICENSE", "icons.theme", "keyboard.rgb"]
    for name in required_files:
        path = theme_dir / name
        if not path.is_file():
            problems.append(f"missing {name}")
        else:
            print(f"  ok    {name}")

    for name, expected_size in expected.items():
        path = theme_dir / name
        size = png_size(path)
        if size is None:
            problems.append(f"missing or invalid {name}")
            continue
        if size != expected_size:
            problems.append(f"{name} is {size[0]}x{size[1]}, expected {expected_size[0]}x{expected_size[1]}")
            print(f"  FAIL  {name}: {size[0]}x{size[1]}")
        else:
            print(f"  ok    {name}: {size[0]}x{size[1]}")

    bg_dir = theme_dir / "backgrounds"
    backgrounds = sorted(bg_dir.glob("*.png")) if bg_dir.is_dir() else []
    if len(backgrounds) != 3:
        problems.append(f"backgrounds/ must contain exactly 3 PNGs, found {len(backgrounds)}")
    for path in backgrounds:
        size = png_size(path)
        mb = path.stat().st_size / (1024 * 1024)
        if size is None:
            problems.append(f"invalid PNG: {path.name}")
        elif size != (3840, 2160):
            problems.append(f"{path.name} is {size[0]}x{size[1]}, expected 3840x2160")
        else:
            print(f"  ok    {path.name}: {size[0]}x{size[1]}, {mb:.2f} MB")
        if mb > 3.5:
            notes.append(f"{path.name} is {mb:.2f} MB; above the 3.5 MB guideline")

    keyboard = (theme_dir / "keyboard.rgb").read_text(encoding="utf-8").strip().lower() if (theme_dir / "keyboard.rgb").is_file() else ""
    accent = colors.get("accent", "").lstrip("#").lower()
    if keyboard and accent and keyboard != accent:
        problems.append(f"keyboard.rgb is {keyboard}, expected the accent {accent}")

    # Denied files and symlinks. Git-staged themes drop these, so shipping them
    # would make the repository diverge from what Omarchy installs.
    for path in theme_dir.rglob("*"):
        if ".git" in path.parts:
            continue
        if path.is_symlink():
            problems.append(f"symlink in repository: {path.relative_to(theme_dir)}")
        if path.name.endswith(".lua") or path.name in DENIED:
            problems.append(f"denied file in repository: {path.relative_to(theme_dir)}")

    print("\n  notes")
    if not notes:
        print("  none")
    for note in notes:
        print(f"  - {note}")

    print("\n" + "=" * 72)
    if problems:
        print(f"  {len(problems)} problem(s):")
        for problem in problems:
            print(f"    x {problem}")
        return 1
    print("  all checks passed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
