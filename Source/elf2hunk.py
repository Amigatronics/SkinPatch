#!/usr/bin/env python3
"""Convierte un objeto ELF32 m68k reubicable (una sola unidad) en un
ejecutable AmigaOS (formato hunk) con un unico HUNK_CODE.
Todas las secciones ALLOC se concatenan; .bss se rellena con ceros.
Al principio se pone 'jmp _start' (abs.l) para que la entrada este en 0."""
import struct, sys

SHT_PROGBITS, SHT_SYMTAB, SHT_NOBITS, SHT_RELA, SHT_REL = 1, 2, 8, 4, 9
SHF_ALLOC = 2
R_68K_32, R_68K_16, R_68K_8, R_68K_PC32, R_68K_PC16, R_68K_PC8 = 1, 2, 3, 4, 5, 6

def u32(b, o): return struct.unpack_from('>I', b, o)[0]

def main(src, dst, entry='_start'):
    e = open(src, 'rb').read()
    assert e[:4] == b'\x7fELF' and e[4] == 1 and e[5] == 2, 'no es ELF32 BE'
    (e_type, e_mach, _, _, _, e_shoff, _, _, _, _, e_shentsize, e_shnum,
     e_shstrndx) = struct.unpack_from('>HHIIIIIHHHHHH', e, 16)
    assert e_type == 1 and e_mach == 4, 'se esperaba objeto reubicable m68k'
    sh = []
    for i in range(e_shnum):
        sh.append(struct.unpack_from('>IIIIIIIIII', e, e_shoff + i * e_shentsize))
    strtab = lambda off, idx: e[sh[idx][4] + off:e.index(b'\0', sh[idx][4] + off)].decode()
    names = [strtab(s[0], e_shstrndx) for s in sh]

    HDR = 6                       # jmp abs.l
    base = {}
    img = bytearray(b'\x4e\xf9\0\0\0\0')
    for i, s in enumerate(sh):
        name_off, typ, flags, addr, off, size, link, info, align, entsize = s
        if not (flags & SHF_ALLOC) or size == 0:
            continue
        a = max(align, 4)
        while len(img) % a: img.append(0)
        base[i] = len(img)
        if typ == SHT_NOBITS:
            img += bytes(size)
        else:
            img += e[off:off + size]
        print(f'  {names[i]:<16} +0x{base[i]:05x}  {size} bytes')
    while len(img) % 4: img.append(0)

    # simbolos
    symidx = [i for i, s in enumerate(sh) if s[1] == SHT_SYMTAB][0]
    ss = sh[symidx]
    syms = []
    for k in range(ss[5] // 16):
        st_name, st_value, st_size, st_info, st_other, st_shndx = struct.unpack_from('>IIIBBH', e, ss[4] + k * 16)
        nm = strtab(st_name, ss[6]) if st_name else ''
        syms.append((nm, st_value, st_shndx))

    def symaddr(k):
        nm, val, shndx = syms[k]
        if shndx == 0:
            raise SystemExit(f'simbolo sin definir: {nm}')
        if shndx not in base:
            raise SystemExit(f'simbolo {nm} en seccion no cargada {shndx}')
        return base[shndx] + val

    relocs = []
    ent = [k for k, s in enumerate(syms) if s[0] == entry]
    assert ent, 'falta _start'
    struct.pack_into('>I', img, 2, symaddr(ent[0]))
    relocs.append(2)

    for i, s in enumerate(sh):
        if s[1] == SHT_REL:
            raise SystemExit('REL sin addend no soportado')
        if s[1] != SHT_RELA or s[7] not in base:
            continue
        tbase = base[s[7]]
        for k in range(s[5] // 12):
            r_off, r_info, r_add = struct.unpack_from('>IIi', e, s[4] + k * 12)
            sym, typ = r_info >> 8, r_info & 0xff
            S = symaddr(sym)
            P = tbase + r_off
            if typ == R_68K_32:
                struct.pack_into('>I', img, P, (S + r_add) & 0xffffffff)
                relocs.append(P)
            elif typ == R_68K_PC32:
                struct.pack_into('>i', img, P, S + r_add - P)
            elif typ == R_68K_PC16:
                v = S + r_add - P
                assert -32768 <= v <= 32767, f'PC16 fuera de rango en {P:#x}'
                struct.pack_into('>h', img, P, v)
            elif typ == R_68K_PC8:
                v = S + r_add - P
                assert -128 <= v <= 127
                struct.pack_into('>b', img, P, v)
            else:
                raise SystemExit(f'reloc no soportada tipo {typ} en {names[i]}')

    n = len(img) // 4
    out = bytearray()
    out += struct.pack('>IIIII', 0x3F3, 0, 1, 0, 0)
    out += struct.pack('>I', n)
    out += struct.pack('>II', 0x3E9, n) + img
    relocs.sort()
    out += struct.pack('>III', 0x3EC, len(relocs), 0)
    for r in relocs: out += struct.pack('>I', r)
    out += struct.pack('>I', 0)
    out += struct.pack('>I', 0x3F2)
    open(dst, 'wb').write(out)
    open(dst + '.bin', 'wb').write(img)       # imagen plana para desensamblar
    with open(dst + '.sym', 'w') as f:
        for nm, val, shndx in syms:
            if nm and shndx in base:
                f.write(f'{base[shndx] + val:08x} {nm}\n')
    print(f'{dst}: {len(out)} bytes, hunk {len(img)} bytes, {len(relocs)} reloc32')

if __name__ == '__main__':
    main(sys.argv[1], sys.argv[2])
