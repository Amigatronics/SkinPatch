# -*- coding: utf-8 -*-
"""Textos de SkinPrefs en todos los idiomas. Numero -> texto.
El 13..19 se generan de la plantilla FRAME_N (con %d = pixeles).
Limites: botones (7-10) ~11 letras, casillas (3,4) ~20, selectores (11-19)
~21, rotulo de la altura (2) ~23, boton 20 ~23."""

IDS = [
    (1, 'MSG_SKINS'), (2, 'MSG_HEIGHT'), (3, 'MSG_ENABLED'), (4, 'MSG_ALLSCREENS'),
    (5, 'MSG_PREVIEW'), (6, 'MSG_NOPREVIEW'), (7, 'MSG_SAVE'), (8, 'MSG_TEST'),
    (9, 'MSG_USE'), (10, 'MSG_CANCEL'), (11, 'MSG_AUTOMATIC'), (12, 'MSG_FRAME_DEFAULT'),
    (13, 'MSG_FRAME_4'), (14, 'MSG_FRAME_6'), (15, 'MSG_FRAME_8'), (16, 'MSG_FRAME_10'),
    (17, 'MSG_FRAME_12'), (18, 'MSG_FRAME_14'), (19, 'MSG_FRAME_16'),
    (20, 'MSG_CHECKUPDATES'), (21, 'MSG_UP_LATEST'), (22, 'MSG_UP_NEW'),
    (23, 'MSG_UP_FAIL'), (24, 'MSG_OK'),
]
FRAMES = [4, 6, 8, 10, 12, 14, 16]

# (directorio en LOCALE:Catalogs, nombre para mostrar, codificacion, textos)
LANGS = {}

LANGS['english'] = ('English', 'latin-1', {
    1: 'Skins', 2: 'Title bar height', 3: 'Enabled', 4: 'All screens', 5: 'Preview',
    6: '(no preview)', 7: 'Save', 8: 'Test', 9: 'Use', 10: 'Cancel', 11: 'Automatic',
    12: 'Frame: default (8)', 'FRAME_N': 'Frame: %d pixels',
    20: 'Check for updates',
    21: 'You have the latest version (%s).',
    22: 'A new version is available: %s\n(you have %s)\n\nGet it from Aminet (util/wb/SkinPatch.lha)\nor with Hangar.',
    23: 'Could not check for updates.\n\nIs the Amiga connected to the Internet\n(TCP/IP stack running)?',
    24: 'OK'})

LANGS['español'] = ('Español', 'latin-1', {
    1: 'Skins', 2: 'Altura de la barra', 3: 'Activado', 4: 'Todas las pantallas', 5: 'Vista previa',
    6: '(sin vista previa)', 7: 'Guardar', 8: 'Probar', 9: 'Usar', 10: 'Cancelar', 11: 'Automática',
    12: 'Marco: normal (8)', 'FRAME_N': 'Marco: %d píxeles',
    20: 'Buscar actualizaciones',
    21: 'Tienes la última versión (%s).',
    22: 'Hay una versión nueva: %s\n(tienes la %s)\n\nDescárgala de Aminet (util/wb/SkinPatch.lha)\no con Hangar.',
    23: 'No se han podido buscar actualizaciones.\n\n¿Está el Amiga conectado a Internet\n(con la pila TCP/IP en marcha)?',
    24: 'Vale'})

LANGS['deutsch'] = ('Deutsch', 'latin-1', {
    1: 'Skins', 2: 'Höhe der Titelleiste', 3: 'Aktiviert', 4: 'Alle Bildschirme', 5: 'Vorschau',
    6: '(keine Vorschau)', 7: 'Speichern', 8: 'Testen', 9: 'Benutzen', 10: 'Abbrechen', 11: 'Automatisch',
    12: 'Rahmen: Standard (8)', 'FRAME_N': 'Rahmen: %d Pixel',
    20: 'Nach Updates suchen',
    21: 'Sie haben die neueste Version (%s).',
    22: 'Eine neue Version ist verfügbar: %s\n(Sie haben %s)\n\nErhältlich im Aminet (util/wb/SkinPatch.lha)\noder mit Hangar.',
    23: 'Die Suche nach Updates ist fehlgeschlagen.\n\nIst der Amiga mit dem Internet verbunden\n(TCP/IP-Stack gestartet)?',
    24: 'OK'})

LANGS['italiano'] = ('Italiano', 'latin-1', {
    1: 'Skin', 2: 'Altezza barra titolo', 3: 'Attivo', 4: 'Tutti gli schermi', 5: 'Anteprima',
    6: '(nessuna anteprima)', 7: 'Salva', 8: 'Prova', 9: 'Usa', 10: 'Annulla', 11: 'Automatica',
    12: 'Bordo: predef. (8)', 'FRAME_N': 'Bordo: %d pixel',
    20: 'Cerca aggiornamenti',
    21: "Hai già l'ultima versione (%s).",
    22: 'È disponibile una nuova versione: %s\n(hai la %s)\n\nScaricala da Aminet (util/wb/SkinPatch.lha)\no con Hangar.',
    23: "Impossibile cercare aggiornamenti.\n\nL'Amiga è collegato a Internet\n(stack TCP/IP avviato)?",
    24: 'OK'})

LANGS['français'] = ('Français', 'latin-1', {
    1: 'Skins', 2: 'Hauteur barre de titre', 3: 'Activé', 4: 'Tous les écrans', 5: 'Aperçu',
    6: "(pas d'aperçu)", 7: 'Sauver', 8: 'Tester', 9: 'Utiliser', 10: 'Annuler', 11: 'Automatique',
    12: 'Cadre : défaut (8)', 'FRAME_N': 'Cadre : %d pixels',
    20: 'Chercher mises à jour',
    21: 'Vous avez la dernière version (%s).',
    22: 'Une nouvelle version est disponible : %s\n(vous avez la %s)\n\nTéléchargez-la sur Aminet (util/wb/SkinPatch.lha)\nou avec Hangar.',
    23: "Impossible de chercher les mises à jour.\n\nL'Amiga est-il connecté à Internet\n(pile TCP/IP lancée) ?",
    24: 'OK'})

LANGS['polski'] = ('Polski', 'iso-8859-2', {
    1: 'Skórki', 2: 'Wysokość paska tytułu', 3: 'Włączone', 4: 'Wszystkie ekrany', 5: 'Podgląd',
    6: '(brak podglądu)', 7: 'Zapisz', 8: 'Testuj', 9: 'Użyj', 10: 'Anuluj', 11: 'Automatyczna',
    12: 'Ramka: domyślna (8)', 'FRAME_N': 'Ramka: %d pikseli', 'FRAME_4': 'Ramka: 4 piksele',
    20: 'Sprawdź aktualizacje',
    21: 'Masz najnowszą wersję (%s).',
    22: 'Dostępna jest nowa wersja: %s\n(masz %s)\n\nPobierz ją z Aminetu (util/wb/SkinPatch.lha)\nlub przez Hangar.',
    23: 'Nie można sprawdzić aktualizacji.\n\nCzy Amiga jest podłączona do Internetu\n(stos TCP/IP uruchomiony)?',
    24: 'OK'})

LANGS['català'] = ('Català', 'latin-1', {
    1: 'Skins', 2: 'Alçada de la barra', 3: 'Activat', 4: 'Totes les pantalles', 5: 'Vista prèvia',
    6: '(sense vista prèvia)', 7: 'Desa', 8: 'Prova', 9: 'Usa', 10: 'Cancel·la', 11: 'Automàtica',
    12: 'Marc: per defecte (8)', 'FRAME_N': 'Marc: %d píxels',
    20: 'Cerca actualitzacions',
    21: 'Tens la darrera versió (%s).',
    22: "Hi ha una versió nova: %s\n(tens la %s)\n\nBaixa-la d'Aminet (util/wb/SkinPatch.lha)\no amb Hangar.",
    23: "No s'han pogut cercar actualitzacions.\n\nL'Amiga està connectat a Internet\n(amb la pila TCP/IP en marxa)?",
    24: "D'acord"})

LANGS['euskara'] = ('Euskara', 'latin-1', {
    1: 'Azalak', 2: 'Titulu-barraren altuera', 3: 'Gaituta', 4: 'Pantaila guztiak', 5: 'Aurrebista',
    6: '(aurrebistarik ez)', 7: 'Gorde', 8: 'Probatu', 9: 'Erabili', 10: 'Utzi', 11: 'Automatikoa',
    12: 'Markoa: lehenet. (8)', 'FRAME_N': 'Markoa: %d pixel',
    20: 'Bilatu eguneraketak',
    21: 'Azken bertsioa duzu (%s).',
    22: 'Bertsio berria dago: %s\n(%s duzu)\n\nJaitsi Aminetetik (util/wb/SkinPatch.lha)\nedo Hangar bidez.',
    23: 'Ezin izan dira eguneraketak bilatu.\n\nAmiga Internetera konektatuta dago\n(TCP/IP pila martxan)?',
    24: 'Ados'})

LANGS['galego'] = ('Galego', 'latin-1', {
    1: 'Skins', 2: 'Altura da barra', 3: 'Activado', 4: 'Todas as pantallas', 5: 'Vista previa',
    6: '(sen vista previa)', 7: 'Gardar', 8: 'Probar', 9: 'Usar', 10: 'Cancelar', 11: 'Automática',
    12: 'Marco: normal (8)', 'FRAME_N': 'Marco: %d píxeles',
    20: 'Buscar actualizacións',
    21: 'Tes a última versión (%s).',
    22: 'Hai unha versión nova: %s\n(tes a %s)\n\nDescárgaa de Aminet (util/wb/SkinPatch.lha)\nou con Hangar.',
    23: 'Non se puideron buscar actualizacións.\n\nEstá o Amiga conectado a Internet\n(coa pila TCP/IP en marcha)?',
    24: 'Vale'})


def strings(lang):
    """Diccionario completo numero -> texto para un idioma."""
    _, _, t = LANGS[lang]
    out = {k: v for k, v in t.items() if isinstance(k, int)}
    for i, px in enumerate(FRAMES):
        key = f'FRAME_{px}'
        out[13 + i] = t[key] if key in t else t['FRAME_N'] % px
    return out
