#!/usr/bin/env python3
"""Genera iconos clasicos de Workbench (.info, 4 colores) para SkinPatch.
Paleta OS3: 0 gris, 1 negro, 2 blanco, 3 azul."""
import struct, sys, os
from PIL import Image

WBDISK, WBDRAWER, WBTOOL, WBPROJECT = 1, 2, 3, 4
PAL = [(0xAA, 0xAA, 0xAA), (0, 0, 0), (0xFF, 0xFF, 0xFF), (0x66, 0x88, 0xBB)]

def canvas(w, h):
    return [[0] * w for _ in range(h)]

def rect(g, x0, y0, x1, y1, c, fill=None):
    for y in range(y0, y1 + 1):
        for x in range(x0, x1 + 1):
            if y in (y0, y1) or x in (x0, x1):
                g[y][x] = c
            elif fill is not None:
                g[y][x] = fill

def line(g, x0, y0, x1, y1, c):
    n = max(abs(x1 - x0), abs(y1 - y0))
    for i in range(n + 1):
        x = round(x0 + (x1 - x0) * i / n); y = round(y0 + (y1 - y0) * i / n)
        g[y][x] = c

# ---------------- dibujos (pixeles anchos: ~2:1 como el Workbench hires)
def img_prefs():
    W, H = 52, 24
    g = canvas(W, H)
    rect(g, 2, 1, 41, 20, 1, 0)           # ventana
    for y in range(2, 6):                 # barra de titulo azul
        for x in range(3, 41):
            g[y][x] = 3
    line(g, 3, 6, 40, 6, 1)
    rect(g, 4, 2, 9, 5, 1, 2)             # cerrar
    g[3][6] = g[3][7] = g[4][6] = g[4][7] = 1
    rect(g, 31, 2, 35, 4, 1, 2)           # profundidad
    rect(g, 34, 3, 39, 5, 1, 2)
    for y in range(8, 19):                # sombra
        g[y + 1][42] = 1
    for x in range(4, 43):
        g[21][x] = 1
    # pincel cruzando la ventana
    for i in range(12):
        x = 30 + 2 * i // 1 // 2 * 2 // 2
    line(g, 47, 2, 33, 14, 1)
    line(g, 48, 3, 34, 15, 1)
    line(g, 46, 2, 32, 14, 1)
    rect(g, 26, 14, 33, 18, 1, 3)         # punta azul
    g[19][24] = g[19][25] = g[20][22] = g[20][23] = 3
    # muestras de color
    rect(g, 6, 9, 13, 12, 1, 3)
    rect(g, 6, 14, 13, 17, 1, 2)
    rect(g, 16, 9, 23, 12, 1, 2)
    return g

def img_install():
    W, H = 52, 24
    g = canvas(W, H)
    rect(g, 10, 11, 41, 21, 1, 2)         # caja
    line(g, 10, 11, 4, 7, 1); line(g, 41, 11, 47, 7, 1)   # solapas
    line(g, 4, 7, 10, 7, 1); line(g, 41, 7, 47, 7, 1)
    for y in range(13, 20):
        line(g, 13, y, 38, y, 0)
    for y in range(1, 9):                 # flecha azul
        for x in range(22, 30):
            g[y][x] = 3
    for k in range(7):
        for x in range(18 + k * 2 // 2 + k, 34 - k):
            if 9 + k < H:
                g[9 + k][x] = 3
    rect(g, 21, 0, 30, 0, 1)
    return g

def img_drawer():
    W, H = 52, 24
    g = canvas(W, H)
    rect(g, 4, 3, 47, 21, 1, 0)
    rect(g, 7, 6, 44, 12, 1, 0)
    rect(g, 7, 14, 44, 19, 1, 0)
    rect(g, 21, 8, 30, 10, 1, 2)          # tiradores
    rect(g, 21, 15, 30, 17, 1, 2)
    for y in range(4, 6):
        for x in range(5, 47):
            g[y][x] = 3
    return g

def img_text():
    W, H = 36, 24
    g = canvas(W, H)
    rect(g, 8, 1, 27, 22, 1, 2)
    for y in range(4, 20, 3):
        line(g, 11, y, 24 if y % 2 else 21, y, 1)
    line(g, 11, 4, 18, 4, 3)
    return g

# ---------------- escritura del .info
def planes(g):
    H, W = len(g), len(g[0])
    rb = ((W + 15) // 16) * 2
    out = bytearray()
    for p in range(2):
        for y in range(H):
            row = bytearray(rb)
            for x in range(W):
                if (g[y][x] >> p) & 1:
                    row[x >> 3] |= 0x80 >> (x & 7)
            out += row
    return bytes(out)

def amigastr(s):
    b = s.encode('latin1') + b'\0'
    return struct.pack('>I', len(b)) + b

def info(path, typ, g, deftool=None, tooltypes=None, stack=0):
    H, W = len(g), len(g[0])
    gadget = struct.pack('>IhhhhHHHIIIIIHI',
                         0, 0, 0, W, H + 1,
                         0x0004,          # GFLG_GADGIMAGE, resalte por complemento
                         0x0003,          # RELVERIFY | GADGIMMEDIATE
                         0x0001,          # BOOLGADGET
                         1, 0, 0, 0, 0,   # GadgetRender (!=0), SelectRender, Text, MutEx, Special
                         0, 1)            # GadgetID, UserData = WB_DISKREVISION 1
    assert len(gadget) == 44
    head = struct.pack('>HH', 0xE310, 1) + gadget + struct.pack('>BBIIiiIII',
                       typ, 0, 1 if deftool else 0, 1 if tooltypes else 0,
                       -0x80000000, -0x80000000,
                       1 if typ in (WBDISK, WBDRAWER) else 0, 0, stack)
    assert len(head) == 78
    data = bytearray(head)
    if typ in (WBDISK, WBDRAWER):
        nw = struct.pack('>hhhhBBIIIIIIIhhHHH', 60, 40, 420, 160, 255, 255, 0, 0, 0, 0, 0, 0, 0,
                         90, 40, 0xFFFF, 0xFFFF, 1)
        assert len(nw) == 48
        data += nw + struct.pack('>ii', 0, 0)
    data += struct.pack('>hhhhhIBBI', 0, 0, W, H, 2, 1, 3, 0, 0)
    data += planes(g)
    if deftool:
        data += amigastr(deftool)
    if tooltypes:
        data += struct.pack('>I', (len(tooltypes) + 1) * 4)
        for t in tooltypes:
            data += amigastr(t)
    if typ in (WBDISK, WBDRAWER):
        data += struct.pack('>IH', 0, 0)    # DrawerData2: dd_Flags, dd_ViewModes
    open(path, 'wb').write(data)

def preview(gs, path):
    S = 4; pad = 8
    W = sum(len(g[0]) for g in gs) + pad * (len(gs) + 1); H = max(len(g) for g in gs) + 2 * pad
    im = Image.new('RGB', (W, H), PAL[0]); x = pad
    for g in gs:
        for y, row in enumerate(g):
            for xx, c in enumerate(row):
                im.putpixel((x + xx, pad + y), PAL[c])
        x += len(g[0]) + pad
    im.resize((W * S, H * S // 2 * 1), Image.NEAREST).resize((W * S, H * S), Image.NEAREST).save(path)

if __name__ == '__main__':
    out = sys.argv[1]
    gp, gi, gd, gt = img_prefs(), img_install(), img_drawer(), img_text()
    info(os.path.join(out, 'SkinPrefs.info'), WBTOOL, gp, stack=65536)
    info(os.path.join(out, 'Install.info'), WBPROJECT, gi, deftool='Installer',
         tooltypes=['APPNAME=SkinPatch', 'MINUSER=AVERAGE', 'DEFUSER=AVERAGE'], stack=65536)
    info(os.path.join(out, 'ReadMe.txt.info'), WBPROJECT, gt, deftool='SYS:Utilities/MultiView', stack=8192)
    info(os.path.join(os.path.dirname(out.rstrip('/')), 'SkinPatch.info'), WBDRAWER, gd)
    
    print('iconos escritos')
