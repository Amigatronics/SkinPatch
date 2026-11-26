#!/usr/bin/env python3
"""Iconos GlowIcons (OS3.5+/3.2) para SkinPatch a partir de una imagen PNG.
Cada .info lleva el icono clasico de 4 colores (reserva) y el chunk IFF
FORM ICON con dos imagenes de color (normal y seleccionada)."""
import struct, sys, os
from PIL import Image, ImageEnhance
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import mkicons
from mkicons import info, WBDRAWER, WBTOOL, PAL

def chunk(tag, data):
    c = tag + struct.pack('>I', len(data)) + data
    return c + (b'\0' if len(data) & 1 else b'')

def packbits(data):
    out = bytearray(); i = 0; n = len(data)
    while i < n:
        j = i
        while j < n and j - i < 128 and data[j] == data[i]: j += 1
        if j - i >= 2:
            out.append((257 - (j - i)) & 0xFF); out.append(data[i]); i = j; continue
        j = i
        while j < n and j - i < 128 and not (j + 1 < n and data[j] == data[j + 1]): j += 1
        if j == i: j = i + 1
        out.append(j - i - 1); out += data[i:j]; i = j
    return bytes(out)

def imag(im):
    """im: RGBA -> chunk IMAG (indice 0 transparente, 8 bits, RLE)."""
    alpha = im.getchannel('A')
    q = im.convert('RGB').quantize(colors=255, method=Image.Quantize.MEDIANCUT, dither=Image.Dither.FLOYDSTEINBERG)
    pal = q.getpalette()[:255 * 3]
    px = bytearray()
    for y in range(im.height):
        for x in range(im.width):
            px.append(0 if alpha.getpixel((x, y)) < 128 else q.getpixel((x, y)) + 1)
    used = max(px) + 1
    palette = bytes([0, 0, 0]) + bytes(pal[:(used - 1) * 3])
    body = packbits(bytes(px))
    hdr = struct.pack('>BBBBBBHH', 0, used - 1, 0x03, 1, 0, 8, len(body) - 1, len(palette) - 1)
    return chunk(b'IMAG', hdr + body + palette), used

def glow(src, h):
    im = Image.open(src).convert('RGBA')
    if h:                                  # h = 0: la imagen ya tiene su tamano
        bb = im.getchannel('A').getbbox(); im = im.crop(bb)
        w = max(1, round(im.width * h / im.height))
        im = im.resize((w, h), Image.LANCZOS)
    w, h = im.size
    sel = ImageEnhance.Brightness(im).enhance(1.45)
    sel = ImageEnhance.Contrast(sel).enhance(1.1)
    sel.putalpha(im.getchannel('A'))
    i1, n1 = imag(im); i2, n2 = imag(sel)
    face = chunk(b'FACE', struct.pack('>BBBBH', w - 1, h - 1, 0, 0x11, max(n1, n2) * 3 - 1))
    form = b'ICON' + face + i1 + i2
    return b'FORM' + struct.pack('>I', len(form)) + form, im, sel

def classic(im):
    """4 colores de reserva (paleta OS3: gris, negro, blanco, azul)."""
    a = im.getchannel('A'); rgb = im.convert('RGB')
    g = [[0] * im.width for _ in range(im.height)]
    for y in range(im.height):
        for x in range(im.width):
            if a.getpixel((x, y)) < 128: continue
            r, gg, b = rgb.getpixel((x, y))
            l = 0.3 * r + 0.59 * gg + 0.11 * b
            if l < 70: c = 1
            elif l > 200: c = 2
            elif b > r + 20: c = 3
            else: c = 1 if l < 120 else 0
            g[y][x] = c if c else 1 if l < 150 else 2
    return g

def write(path, typ, src, h, **kw):
    form, im, sel = glow(src, h)
    info(path, typ, classic(im), **kw)
    with open(path, 'ab') as f: f.write(form)
    return im, sel

if __name__ == '__main__':
    src, out, h = sys.argv[1], sys.argv[2], int(sys.argv[3]) if len(sys.argv) > 3 else 64
    os.makedirs(out, exist_ok=True)
    im, sel = write(os.path.join(out, 'SkinPatch.info'), WBDRAWER, src, h)
    write(os.path.join(out, 'SkinPrefs.info'), WBTOOL, src, h, stack=65536)
    pv = Image.new('RGB', (im.width * 2 + 30, im.height + 20), (0x95, 0x95, 0x95))
    pv.paste(im, (10, 10), im); pv.paste(sel, (im.width + 20, 10), sel)
    pv.resize((pv.width * 4, pv.height * 4), Image.NEAREST).save(os.path.join(out, 'preview.png'))
    print('iconos', im.size)
