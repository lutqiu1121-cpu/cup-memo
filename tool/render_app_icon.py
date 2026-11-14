"""Render the original app_icon.svg geometry to app_icon.png.

The SVG is the design source. This script deliberately contains no external
image input; it reproduces the same original cup, steam, ceramic shading and
filter-free shadow using supersampled Pillow primitives.
"""
from pathlib import Path
from PIL import Image, ImageDraw

S = 4
W = H = 2048
INK = (81, 74, 66, 255)
BG = (239, 233, 221, 255)
CERAMIC = (248, 245, 239, 255)
SHADE = (216, 209, 198, 132)
COFFEE = (141, 103, 77, 255)
COFFEE_HI = (185, 150, 121, 210)


def p(x, y):
    return (int(x * S), int(y * S))


def cubic(a, b, c, d, steps=64):
    out = []
    for i in range(steps + 1):
        t = i / steps
        u = 1 - t
        out.append((
            u**3*a[0] + 3*u*u*t*b[0] + 3*u*t*t*c[0] + t**3*d[0],
            u**3*a[1] + 3*u*u*t*b[1] + 3*u*t*t*c[1] + t**3*d[1],
        ))
    return out


def line(draw, points, fill, width, round_caps=True):
    pts = [p(*x) for x in points]
    draw.line(pts, fill=fill, width=width*S, joint='curve')
    if round_caps:
        r = width*S/2
        for x, y in (pts[0], pts[-1]):
            draw.ellipse((x-r, y-r, x+r, y+r), fill=fill)


def ellipse(draw, box, fill, outline=None, width=1):
    draw.ellipse(tuple(v*S for v in box), fill=fill, outline=outline, width=width*S)


def render():
    image = Image.new('RGBA', (W*S, H*S), BG)
    draw = ImageDraw.Draw(image)

    # Filter-free soft floating shadow.
    ellipse(draw, (494, 1443, 1554, 1627), (139, 129, 116, 20))
    ellipse(draw, (629, 1460, 1419, 1576), (139, 129, 116, 26))
    ellipse(draw, (759, 1470, 1289, 1538), (139, 129, 116, 31))

    # Steam ribbon.
    steam = cubic((1018, 625), (927, 550), (1088, 464), (1005, 372))
    steam += cubic((1005, 372), (946, 307), (1002, 237), (1055, 193))
    line(draw, steam, (98, 90, 80, 224), 30)

    # Handle behind the cup body.
    handle = cubic((1468, 932), (1716, 871), (1790, 1010), (1770, 1168))
    handle += cubic((1770, 1168), (1744, 1368), (1533, 1414), (1358, 1320))
    line(draw, handle, INK, 30)
    handle_inner = cubic((1485, 1002), (1621, 972), (1684, 1042), (1667, 1150))
    handle_inner += cubic((1667, 1150), (1648, 1268), (1531, 1288), (1425, 1247))
    line(draw, handle_inner, (216, 209, 198, 255), 52)

    # Rear rim highlight.
    ellipse(draw, (545, 651, 1455, 919), (217, 208, 194, 140))

    # Main bowl silhouette.
    body = [(575, 795), (1508, 795)]
    body += cubic((1508, 795), (1491, 1030), (1462, 1280), (1364, 1402))
    body += cubic((1364, 1402), (1277, 1512), (1157, 1552), (1042, 1552))
    body += cubic((1042, 1552), (928, 1552), (808, 1512), (720, 1402))
    body += cubic((720, 1402), (622, 1280), (592, 1030), (575, 795))
    draw.polygon([p(*x) for x in body], fill=CERAMIC)
    line(draw, body + [body[0]], INK, 28, round_caps=False)

    # Flat side shade.
    shade = [(1340, 867)]
    shade += cubic((1340, 867), (1325, 1115), (1282, 1310), (1204, 1402))
    shade += cubic((1204, 1402), (1147, 1469), (1096, 1494), (1042, 1511))
    shade += cubic((1042, 1511), (1205, 1514), (1323, 1459), (1380, 1363))
    shade += cubic((1380, 1363), (1455, 1238), (1481, 1015), (1493, 827))
    shade += [(1340, 867)]
    draw.polygon([p(*x) for x in shade], fill=SHADE)

    # Rim, coffee and a simple highlight.
    ellipse(draw, (576, 642, 1508, 932), (253, 251, 247, 255), INK, 28)
    ellipse(draw, (678, 716, 1406, 884), COFFEE, INK, 22)
    coffee_curve = cubic((760, 788), (876, 738), (1162, 720), (1320, 793))
    line(draw, coffee_curve, COFFEE_HI, 22)
    ellipse(draw, (810, 745, 990, 791), (217, 189, 165, 122))
    highlight = cubic((750, 1010), (764, 1200), (800, 1324), (872, 1380))
    line(draw, highlight, (255, 255, 255, 158), 34)

    return image.resize((W, H), Image.Resampling.LANCZOS)


if __name__ == '__main__':
    output = Path('assets/icon/app_icon.png')
    output.parent.mkdir(parents=True, exist_ok=True)
    render().save(output, optimize=True)
    print(output, output.stat().st_size, 'bytes')
