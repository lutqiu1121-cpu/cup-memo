"""Post-process the confirmed pixel-art icon into a 1024x1024 launcher asset.

The artwork is delivered as a pixel grid that may already be integer-scaled
(this revision ships 512x512, i.e. a 32x32 grid at 16x). The pipeline:

  1. read the source and detect the pixel grid (gcd of colour run lengths),
  2. recover the logical pixel art losslessly (asserted by re-upscaling),
  3. add a 4 px border of the detected background colour,
  4. upscale to 1024x1024 with NEAREST (no interpolation, no anti-aliasing),
  5. write assets/icon/app_icon.png and assert no new colours appeared.

Usage:
    python3 tool/process_app_icon.py <source.png> [--out assets/icon/app_icon.png]
"""
from __future__ import annotations

import argparse
from collections import Counter
from math import gcd
from pathlib import Path

from PIL import Image

PAD = 4
SIZE = 1024


def _runs(sequence: list[tuple[int, ...]]) -> list[int]:
    lengths: list[int] = []
    current = sequence[0]
    count = 1
    for value in sequence[1:]:
        if value == current:
            count += 1
        else:
            lengths.append(count)
            current = value
            count = 1
    lengths.append(count)
    return lengths


def detect_grid(image: Image.Image) -> int:
    """Return the integer scale factor of the delivered pixel-art grid."""
    pixels = image.load()
    width, height = image.size
    lengths: list[int] = []
    for y in range(0, height, max(1, height // 16)):
        lengths += _runs([pixels[x, y] for x in range(width)])
    for x in range(0, width, max(1, width // 16)):
        lengths += _runs([pixels[x, y] for y in range(height)])
    factor = 0
    for length in lengths:
        factor = gcd(factor, length)
    return max(1, factor)


def recover_grid(image: Image.Image, factor: int) -> Image.Image:
    """Sample the centre of every block to rebuild the logical pixel art."""
    if factor <= 1:
        return image
    logical = image.width // factor
    recovered = Image.new("RGBA", (logical, logical), (0, 0, 0, 0))
    offset = factor // 2
    for y in range(logical):
        for x in range(logical):
            recovered.putpixel((x, y), image.getpixel((x * factor + offset, y * factor + offset)))
    return recovered


def detect_background(image: Image.Image) -> tuple[int, int, int, int]:
    pixels = image.load()
    width, height = image.size
    edge: list[tuple[int, int, int, int]] = []
    for x in range(width):
        edge.append(pixels[x, 0])
        edge.append(pixels[x, height - 1])
    for y in range(height):
        edge.append(pixels[0, y])
        edge.append(pixels[width - 1, y])
    return Counter(edge).most_common(1)[0][0]


def colours(image: Image.Image) -> set[tuple[int, ...]]:
    return {colour for _, colour in (image.getcolors(maxcolors=1 << 24) or [])}


def process(source: Path, output: Path) -> None:
    image = Image.open(source).convert("RGBA")
    factor = detect_grid(image)
    print(f"source: {image.width}x{image.height}, pixel grid factor {factor}x")

    art = recover_grid(image, factor)
    if factor > 1:
        rebuilt = art.resize(image.size, Image.Resampling.NEAREST)
        if rebuilt.tobytes() != image.tobytes():
            raise SystemExit("grid recovery was not lossless - aborting")
        print(f"recovered logical art: {art.width}x{art.height} (lossless round-trip verified)")

    background = detect_background(art)
    print(f"background: #{background[0]:02X}{background[1]:02X}{background[2]:02X}")

    padded_size = art.width + PAD * 2
    padded = Image.new("RGBA", (padded_size, padded_size), background)
    padded.paste(art, (PAD, PAD))
    print(f"padding: {art.width}x{art.height} -> {padded_size}x{padded_size} ({PAD}px each side)")

    upscaled = padded.resize((SIZE, SIZE), Image.Resampling.NEAREST)
    extra = colours(upscaled) - colours(padded)
    if extra:
        raise SystemExit(f"NEAREST produced {len(extra)} new colours: {sorted(extra)[:5]}")
    print(f"colours: {len(colours(padded))} -> {len(colours(upscaled))} (no anti-aliasing)")

    output.parent.mkdir(parents=True, exist_ok=True)
    upscaled.save(output)
    print(f"wrote {output} ({output.stat().st_size} bytes, {SIZE}x{SIZE})")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("source", type=Path)
    parser.add_argument("--out", type=Path, default=Path("assets/icon/app_icon.png"))
    args = parser.parse_args()
    process(args.source, args.out)


if __name__ == "__main__":
    main()
