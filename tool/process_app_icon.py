"""Post-process the confirmed 32x32 pixel-art icon into a 1024x1024 launcher asset.

Pipeline (exactly what the artwork owner asked for):
  1. read the 32x32 source,
  2. detect the flat beige background colour,
  3. add a 4 px beige border on every side (32 -> 40),
  4. upscale 40 -> 1024 with NEAREST (no interpolation, no anti-aliasing),
  5. write assets/icon/app_icon.png.

The script asserts that the upscale introduced no new colours, which is the
machine-checkable proof that the pixel edges stayed crisp.

Usage:
    python3 tool/process_app_icon.py <source.png> [--out assets/icon/app_icon.png]
"""
from __future__ import annotations

import argparse
from collections import Counter
from pathlib import Path

from PIL import Image

PAD = 4
SIZE = 1024


def detect_background(image: Image.Image) -> tuple[int, int, int]:
    """Return the most common edge colour (the flat beige backdrop)."""
    rgb = image.convert("RGB")
    width, height = rgb.size
    edge: list[tuple[int, int, int]] = []
    for x in range(width):
        edge.append(rgb.getpixel((x, 0)))
        edge.append(rgb.getpixel((x, height - 1)))
    for y in range(height):
        edge.append(rgb.getpixel((0, y)))
        edge.append(rgb.getpixel((width - 1, y)))
    background, _ = Counter(edge).most_common(1)[0]
    return background


def process(source: Path, output: Path) -> None:
    image = Image.open(source).convert("RGBA")
    if image.size != (32, 32):
        raise SystemExit(f"expected a 32x32 source, got {image.size}")

    background = detect_background(image)
    print(f"background: #{background[0]:02X}{background[1]:02X}{background[2]:02X}")

    padded_size = image.width + PAD * 2
    padded = Image.new("RGBA", (padded_size, padded_size), (*background, 255))
    padded.paste(image, (PAD, PAD))
    print(f"padding: {image.width}x{image.height} -> {padded_size}x{padded_size} ({PAD}px each side)")

    upscaled = padded.resize((SIZE, SIZE), Image.Resampling.NEAREST)

    # A NEAREST upscale must be a pure pixel replication: same colour set.
    before = set(padded.getcolors(maxcolors=1 << 24) or [])
    after = set(upscaled.getcolors(maxcolors=1 << 24) or [])
    before_colours = {colour for _, colour in before}
    after_colours = {colour for _, colour in after}
    extra = after_colours - before_colours
    if extra:
        raise SystemExit(f"NEAREST produced {len(extra)} new colours: {sorted(extra)[:5]}")
    print(f"colours: {len(before_colours)} -> {len(after_colours)} (no anti-aliasing)")

    output.parent.mkdir(parents=True, exist_ok=True)
    upscaled.save(output)
    print(f"wrote {output} ({output.stat().st_size} bytes, {SIZE}x{SIZE}, mode={upscaled.mode})")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("source", type=Path)
    parser.add_argument("--out", type=Path, default=Path("assets/icon/app_icon.png"))
    args = parser.parse_args()
    process(args.source, args.out)


if __name__ == "__main__":
    main()
