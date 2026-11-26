#!/usr/bin/env python3
"""Convierte una skin de MorphOS (carpeta con subcarpetas 24/26/28... y PNG)
al formato de SkinPatch: un IFF ILBM por gadget con 3 fotogramas
[normal][pulsado][inactivo], escalado a la altura de barra de titulo pedida.

uso: mos2skin.py <carpeta_skin_morphos> <carpeta_salida> <altura> [<altura> ...]
"""
import os, sys, struct
from PIL import Image

# nombre SkinPatch -> (nombre MorphOS, n fotogramas, tipo)
MAP = {
    'close':  ('SysIclassClose', 3, 'title'),
    'depth':  ('SysIclassDepth', 3, 'title'),
    'zoom':   ('SysIclassZoom', 3, 'title'),
    'iconify': ('SysIclassIconify', 3, 'title'),
    'sdepth': ('SysIclassSDepth', 2, 'screen'),
    'size':   ('SysIclassSize', 3, 'border'),
    'left':   ('SysIclassLeft', 3, 'border'),
    'right':  ('SysIclassRight', 3, 'border'),
    'up':     ('SysIclassUp', 3, 'border'),
    'down':   ('SysIclassDown', 3, 'border'),
}
BORDER_BG = (0xAA, 0xAA, 0xAA)

def find(folder, name):
    for f in os.listdir(folder):
        if f.lower() == name.lower():
            return os.path.join(folder, f)
    return None

def split_frames(im, n):
    W = im.width
    frames = []
    for i in range(n):
        x0, x1 = round(i * W / n), round((i + 1) * W / n)
        fr = im.crop((x0, 0, x1, im.height))
        bb = fr.getchannel('A').getbbox()
        if bb:
            fr = fr.crop((bb[0], 0, bb[2], im.height))
        frames.append(fr)
    return frames

def bg_strip(path, h):
    if not path:
        return None
    im = Image.open(path).convert('RGB')
    col = im.crop((im.width // 2, 0, im.width // 2 + 1, im.height))
    return col.resize((1, h), Image.LANCZOS)

def write_ilbm(path, img):
    """img: imagen en modo 'P' (hasta 256 colores)."""
    w, h = img.size
    pal = img.getpalette()[:768]
    ncol = max(img.getdata()) + 1
    planes = max(1, (ncol - 1).bit_length())
    bmhd = struct.pack('>HHhhBBBBHBBhh', w, h, 0, 0, planes, 0, 0, 0, 0, 10, 11, w, h)
    cmap = bytes(pal[:3 * (1 << planes)]).ljust(3 * (1 << planes), b'\0')
    rb = ((w + 15) // 16) * 2
    px = img.load()
    body = bytearray()
    for y in range(h):
        for p in range(planes):
            row = bytearray(rb)
            for x in range(w):
                if (px[x, y] >> p) & 1:
                    row[x >> 3] |= 0x80 >> (x & 7)
            body += row
    def chunk(tag, d):
        return tag + struct.pack('>I', len(d)) + d + (b'\0' if len(d) & 1 else b'')
    form = b'ILBM' + chunk(b'BMHD', bmhd) + chunk(b'CMAP', cmap) + chunk(b'BODY', bytes(body))
    open(path, 'wb').write(b'FORM' + struct.pack('>I', len(form)) + form)

def lerp(a, b, t): return tuple(int(round(a[k] + (b[k] - a[k]) * t)) for k in range(3))

def prop_profile(T, edge, hi, c0, c1, sh):
    """Perfil de T pixeles: borde, brillo, degradado c0->c1, sombra, borde."""
    p = [edge, hi]
    n = T - 4
    for k in range(n): p.append(lerp(c0, c1, k / max(1, n - 1)))
    p += [sh, edge]
    return p

def write_props(dst):
    T, L = 10, 16
    knob = [prop_profile(T, (10, 41, 101), (58, 96, 160), (62, 102, 166), (118, 158, 222), (48, 80, 140)),
            prop_profile(T, (10, 41, 101), (110, 150, 210), (116, 156, 216), (165, 198, 245), (80, 118, 182)),
            prop_profile(T, (70, 70, 70), (160, 160, 160), (165, 165, 165), (205, 205, 205), (120, 120, 120))]
    # canal: del mismo azul que el marco, como en AmigaOS 4
    trough = [[(88, 124, 186)] + [(102, 139, 202)] * (T - 2) + [(112, 150, 212)],
              [(88, 124, 186)] + [(102, 139, 202)] * (T - 2) + [(112, 150, 212)],
              [(165, 165, 165)] + [(180, 180, 180)] * (T - 2) + [(190, 190, 190)]]
    caps = [(10, 41, 101), (10, 41, 101), (70, 70, 70)]
    tcap = [(88, 124, 186), (88, 124, 186), (165, 165, 165)]
    def sheet(profiles, capc, vertical):
        im = Image.new('RGB', (3 * T, L) if vertical else (3 * L, T))
        for f in range(3):
            for a in range(T):
                for b in range(L):
                    c = profiles[f][a]
                    if b in (0, L - 1): c = capc[f]
                    if vertical: im.putpixel((f * T + a, b), c)
                    else: im.putpixel((f * L + b, a), c)
        return im
    for name, prof, cap in (('knob', knob, caps), ('trough', trough, tcap)):
        for v, suf in ((True, 'v'), (False, 'h')):
            im = sheet(prof, cap, v)
            q = im.quantize(colors=32, method=Image.Quantize.MEDIANCUT, dither=Image.Dither.NONE)
            write_ilbm(os.path.join(dst, f'{name}{suf}.iff'), q)
            im.save(os.path.join(dst, f'{name}{suf}.png'))

def convert(src, dst, H):
    sizes = sorted(int(d) for d in os.listdir(src) if d.isdigit() and os.path.isdir(os.path.join(src, d)))
    pick = min(sizes, key=lambda s: (s < H, abs(s - H)))   # preferir >= H (reducir)
    sd = os.path.join(src, str(pick))
    os.makedirs(dst, exist_ok=True)
    bg_act = bg_strip(find(sd, 'WindowTitlebarLActive'), H)
    bg_ina = bg_strip(find(sd, 'WindowTitlebarL'), H)
    bg_scr = bg_strip(find(sd, 'STitleBarBackground'), H)
    done = []
    for out, (mname, n, kind) in MAP.items():
        p = find(sd, mname)
        if not p:
            continue
        frames = split_frames(Image.open(p).convert('RGBA'), n)
        if n == 2:                       # sin fotograma inactivo: repetir el normal
            frames.append(frames[0])
        th = H if kind in ('title', 'screen') else (H - 1 if H <= 12 else max(H - 1 if H <= 12 else 0, round(H * 0.74)))
        fh = frames[0].height
        fw = max(f.width for f in frames)
        nw = max(1, round(fw * th / fh))
        frames = [f.resize((max(1, round(f.width * th / fh)), th), Image.LANCZOS) for f in frames]
        if kind == 'border':
            P = nw
            bgs = [None, None, None]
        else:
            P = max(nw, round(H * 2.2))
            bgs = [bg_scr] * 3 if kind == 'screen' else [bg_act, bg_act, bg_ina]
        sheet = Image.new('RGB', (P * 3, th), BORDER_BG)
        for i, f in enumerate(frames):
            tile = Image.new('RGBA', (P, th), BORDER_BG + (255,))
            if bgs[i] is not None:
                tile = bgs[i].resize((P, th)).convert('RGBA')
            tile.alpha_composite(f, ((P - f.width) // 2, 0))
            sheet.paste(tile.convert('RGB'), (i * P, 0))
        q = sheet.quantize(colors=64, method=Image.Quantize.MEDIANCUT, dither=Image.Dither.NONE)
        write_ilbm(os.path.join(dst, out + '.iff'), q)
        sheet.save(os.path.join(dst, out + '.png'))     # vista previa (no la usa el Amiga)
        done.append(f'{out} {P}x{th}')
    # barra de titulo: degradado (columna central) en mosaico, 64 px por fotograma
    pa, pi = find(sd, 'WindowTitlebarM1Active'), find(sd, 'WindowTitlebarM1')
    if pa and pi:
        def col(p):
            im = Image.open(p).convert('RGBA')
            c = im.crop((im.width // 2, 0, im.width // 2 + 1, im.height)).resize((1, H), Image.LANCZOS)
            bg = Image.new('RGBA', (1, H), BORDER_BG + (255,)); bg.alpha_composite(c)
            return bg.convert('RGB').resize((64, H))
        a, i = col(pa), col(pi)
        sheet = Image.new('RGB', (192, H))
        sheet.paste(a, (0, 0)); sheet.paste(a, (64, 0)); sheet.paste(i, (128, 0))
        q = sheet.quantize(colors=32, method=Image.Quantize.MEDIANCUT, dither=Image.Dither.NONE)
        write_ilbm(os.path.join(dst, 'bar.iff'), q)
        sheet.save(os.path.join(dst, 'bar.png'))
        done.append(f'bar 64x{H}')
        # marcos: inferior = mismo perfil; laterales = perfil girado
        write_ilbm(os.path.join(dst, 'frameh.iff'), q)
        v = Image.new('RGB', (3 * H, 64))
        for k, im in enumerate((a, a, i)):
            v.paste(im.crop((0, 0, 1, H)).transpose(Image.Transpose.TRANSPOSE).resize((H, 64)), (k * H, 0))
        qv = v.quantize(colors=32, method=Image.Quantize.MEDIANCUT, dither=Image.Dither.NONE)
        write_ilbm(os.path.join(dst, 'framev.iff'), qv)
        v.save(os.path.join(dst, 'framev.png'))
        done.append('marcos')
    # barras deslizantes: tirador y canal (perfil a lo ancho; tapas a lo largo)
    write_props(dst)
    done.append('barras')
    return pick, done

if __name__ == '__main__':
    src, dst = sys.argv[1], sys.argv[2]
    for h in map(int, sys.argv[3:]):
        pick, done = convert(src, os.path.join(dst, str(h)), h)
        print(f'altura {h} (desde {pick}): ' + ', '.join(done))
