#!/usr/bin/env python3
"""Genera skinprefs.catalog (IFF CTLG) de cada idioma, y skinprefs.cd y
<idioma>.ct (formato CatComp) para quien quiera corregir o traducir.
Uso: python3 mkcatalog.py <carpeta de salida>"""
import os, struct, sys
from translations import IDS, LANGS, strings

VERSION = '1.4'
DATE = '23.11.2026'
LIMITS = {2: 23, 3: 20, 4: 20, 7: 11, 8: 11, 9: 11, 10: 11, 11: 21, 12: 21, 20: 23}
for n in range(13, 20):
    LIMITS[n] = 21

def chunk(tag, data):
    c = tag + struct.pack('>I', len(data)) + data
    return c + (b'\0' if len(data) & 1 else b'')

def catalog(lang):
    _, enc, _ = LANGS[lang]
    st = strings(lang)
    strs = b''
    for n, _ in IDS:
        s = st[n].encode(enc) + b'\0'
        strs += struct.pack('>II', n, len(s)) + s + b'\0' * (-len(s) % 4)
    fver = f'$VER: skinprefs.catalog {VERSION} ({DATE})'.encode() + b'\0'
    body = (b'CTLG' + chunk(b'FVER', fver) + chunk(b'LANG', lang.encode(enc) + b'\0')
            + chunk(b'CSET', b'\0' * 32) + chunk(b'STRS', strs))
    return b'FORM' + struct.pack('>I', len(body)) + body

def cd_text():
    en = strings('english')
    out = ['; skinprefs.cd - SkinPrefs ' + VERSION + ' (Amigatronics)', '#language english', '#version 1', ';']
    for n, name in IDS:
        out += [f'{name} ({n}//)', en[n].replace('\n', '\\n'), ';']
    return '\n'.join(out) + '\n'

def ct_text(lang):
    st = strings(lang); en = strings('english')
    out = [f'## version $VER: skinprefs.catalog {VERSION} ({DATE})', f'## language {lang}', '## codeset 0', ';']
    for n, name in IDS:
        out += [name, st[n].replace('\n', '\\n'), '; ' + en[n].replace('\n', '\\n'), ';']
    return '\n'.join(out) + '\n'

def check():
    bad = []
    for lang in LANGS:
        st = strings(lang)
        for n, lim in LIMITS.items():
            if len(st[n]) > lim:
                bad.append(f'{lang} {n}: "{st[n]}" ({len(st[n])} > {lim})')
        for n in (21, 22):
            if st[n].count('%s') != strings('english')[n].count('%s'):
                bad.append(f'{lang} {n}: %s')
        st[0] = ''; [s.encode(LANGS[lang][1]) for s in st.values()]
    return bad

if __name__ == '__main__':
    out = sys.argv[1]
    bad = check()
    for b in bad: print('DEMASIADO LARGO / MAL:', b)
    os.makedirs(os.path.join(out, 'Source'), exist_ok=True)
    with open(os.path.join(out, 'Source', 'skinprefs.cd'), 'wb') as f:
        f.write(cd_text().encode('latin-1'))
    for lang in LANGS:
        if lang == 'english': continue
        d = os.path.join(out, lang); os.makedirs(d, exist_ok=True)
        with open(os.path.join(d, 'skinprefs.catalog'), 'wb') as f:
            f.write(catalog(lang))
        with open(os.path.join(out, 'Source', lang + '.ct'), 'wb') as f:
            f.write(ct_text(lang).encode(LANGS[lang][1]))
    print('catalogos:', len(LANGS) - 1, 'problemas:', len(bad))
