"""Snap generated launcher PNGs back to the source palette (pixel-art crispness).

`flutter_launcher_icons` downscales with smooth interpolation, which turns the
flat 8-colour pixel art into ~80 blended colours. This pass maps every generated
pixel to its nearest palette colour (taken from assets/icon/app_icon.png), which
restores hard edges without changing the artwork.

Usage:
    python3 tool/snap_icon_palette.py
"""
from __future__ import annotations

from pathlib import Path

from PIL import Image

SOURCE = Path("assets/icon/app_icon.png")
RES = Path("android/app/src/main/res")


def palette_of(image: Image.Image) -> list[tuple[int, int, int]]:
    colors = image.convert("RGBA").getcolors(maxcolors=1 << 24) or []
    return [color[:3] for _, color in colors]


def snap(path: Path, palette: list[tuple[int, int, int]]) -> int:
    image = Image.open(path).convert("RGBA")
    pixels = image.load()
    width, height = image.size
    changed = 0
    for y in range(height):
        for x in range(width):
            r, g, b, _a = pixels[x, y]
            best = min(palette, key=lambda c: (c[0] - r) ** 2 + (c[1] - g) ** 2 + (c[2] - b) ** 2)
            if (r, g, b) != best:
                changed += 1
            # The artwork is full-bleed (its own flat beige is also the adaptive
            # background), so every pixel is opaque: this removes the soft alpha
            # fringe left behind by the downscale.
            pixels[x, y] = (*best, 255)
    image.save(path)
    return changed


def main() -> None:
    palette = palette_of(Image.open(SOURCE))
    print(f"palette: {len(palette)} colours from {SOURCE}")
    targets = sorted(
        p
        for p in RES.glob("**/*.png")
        if p.name.startswith(("ic_launcher", "launcher_icon"))
    )
    for path in targets:
        changed = snap(path, palette)
        colors = len(Image.open(path).convert("RGBA").getcolors(maxcolors=1 << 24) or [])
        print(f"{path.relative_to(RES)}: snapped {changed} px -> {colors} colours")


if __name__ == "__main__":
    main()
