#!/usr/bin/env python3
"""makedark.py - makes OfourBlack from the converted Ofour skin
(Ofour (C) 2005 Oliver Hummel).

  python3 makedark.py <Ofour output drawer> <new drawer> black

Reads the PNG files written by mos2skin.py (<drawer>/<height>/*.png) and
writes recoloured IFF images: active windows dark grey, inactive windows
unchanged."""
import os, sys, colorsys
from PIL import Image
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from mos2skin import write_ilbm

GLYPH = {'close', 'depth', 'zoom', 'sdepth', 'iconify', 'size', 'left', 'right', 'up', 'down'}

def recolor(im, name, mode='blue'):
    im = im.convert('RGB'); out = im.copy(); px = out.load()
    fw = im.width // 3
    vertical = name in ('framev', 'knobv', 'troughv')
    for y in range(im.height):
        for x in range(im.width):
            f = min(2, x // fw) if fw else 0
            r, g, b = [c / 255 for c in px[x, y]]
            h, s, v = colorsys.rgb_to_hsv(r, g, b)
            glyph = name in GLYPH and f != 2 and s < 0.2 and v > 0.78
            if mode == 'black':
                if f == 2:
                    continue                       # inactiva: como Ofour
                blue = 0.50 <= h <= 0.75
                if not blue and s > 0.25:
                    continue                       # acentos de color (pulsado)
                w = 0.0 if not blue else max(0.0, min(1.0, (s - 0.12) / 0.30))
                g = w * (0.04 + 0.24 * v) + (1 - w) * v
                q = int(g * 255)
                px[x, y] = (q, q, q)
                continue
            if f == 2:                         # ventana inactiva: grises
                v2 = 0.08 + 0.42 * v
                s2 = 0.0
            else:                              # activa: azul oscuro
                v2 = 0.92 if glyph else 0.10 + 0.52 * v
                s2 = min(1.0, s * 1.05)
                if glyph: s2 = 0.08
            rr, gg, bb = colorsys.hsv_to_rgb(h, s2, v2)
            px[x, y] = (int(rr * 255), int(gg * 255), int(bb * 255))
    return out

def main(src, dst, mode='blue'):
    for hd in sorted(os.listdir(src)):
        sd = os.path.join(src, hd)
        if not os.path.isdir(sd): continue
        od = os.path.join(dst, hd); os.makedirs(od, exist_ok=True)
        for fn in sorted(os.listdir(sd)):
            if not fn.endswith('.png'): continue
            name = fn[:-4]
            im = recolor(Image.open(os.path.join(sd, fn)), name, mode)
            im.save(os.path.join(od, fn))
            q = im.quantize(colors=48 if name in GLYPH else 32, method=Image.Quantize.MEDIANCUT, dither=Image.Dither.NONE)
            write_ilbm(os.path.join(od, name + '.iff'), q)
            if name == 'bar':
                write_ilbm(os.path.join(od, 'frameh.iff'), q)
        print('altura', hd, 'ok')

if __name__ == '__main__':
    main(sys.argv[1], sys.argv[2], sys.argv[3] if len(sys.argv) > 3 else 'blue')
