import json
import sys

from PIL import Image, ImageFilter, ImageOps

skin_path, invert, config_path, out_dir = sys.argv[1:5]
CELL = 32

sheet = Image.open(skin_path).convert("RGBA")
if invert == "1":
    r, g, b, a = sheet.split()
    rgb = ImageOps.invert(Image.merge("RGB", (r, g, b)))
    sheet = Image.merge("RGBA", (*rgb.split(), a))
sheet.save(f"{out_dir}/skin.png")

alpha = sheet.getchannel("A").point(lambda v: 255 if v > 0 else 0)


def runs(img, x0, y):
    spans, start = [], None
    for x in range(CELL):
        on = img.getpixel((x0 + x, y)) > 0
        if on and start is None:
            start = x
        if not on and start is not None:
            spans.append((start, x - start))
            start = None
    if start is not None:
        spans.append((start, CELL - start))
    return spans


masks = {}
cols, rows = sheet.width // CELL, sheet.height // CELL
for c in range(cols):
    for r in range(rows):
        cell = alpha.crop((c * CELL, r * CELL, (c + 1) * CELL, (r + 1) * CELL)).filter(ImageFilter.MaxFilter(3))
        rects, open_rects = [], {}
        for y in range(CELL):
            current = runs(cell, 0, y)
            next_open = {}
            for span in current:
                if span in open_rects:
                    next_open[span] = open_rects.pop(span)
                else:
                    next_open[span] = y
            for (x, w), y0 in open_rects.items():
                rects.append([x, y0, w, y - y0])
            open_rects = next_open
        for (x, w), y0 in open_rects.items():
            rects.append([x, y0, w, CELL - y0])
        masks[f"{c},{r}"] = rects

config = json.load(open(config_path))
with open(f"{out_dir}/data.js", "w") as f:
    f.write(".pragma library\n\n")
    f.write("var config = " + json.dumps(config) + ";\n")
    f.write("var masks = " + json.dumps(masks, separators=(",", ":")) + ";\n")
