# -*- coding: utf-8 -*-
"""Guias cortas de SkinPatch en 8 idiomas (el ReadMe completo es en ingles).
Uso: python3 docs_i18n.py <carpeta Docs>"""
import os, sys, textwrap

CREDIT = ("Isra Ortuño (Gogeta) - Amigatronics\n"
          "https://amigatronics.com  /  https://en.amigatronics.com\n"
          "amigatronics@amigatronics.com\n")

DOCS = {}

DOCS['LeemeES.txt'] = ('latin-1', """SkinPatch 1.4 - skins de ventanas para AmigaOS 3.x
==================================================

{credit}
Escrito en ensamblador 68000 con la ayuda de Claude (IA de Anthropic).


Qué hace
--------
SkinPatch cambia el aspecto de las ventanas de la pantalla del Workbench,
al estilo de las skins de MorphOS:

  - los botones de las ventanas: cerrar, profundidad, zoom, iconificar,
    profundidad de pantalla, tamaño y las flechas de desplazamiento
  - la barra de título (fondo degradado y título centrado)
  - los marcos de las ventanas (izquierdo, derecho e inferior)
  - las barras de desplazamiento del Workbench y de los programas que
    usan las barras estándar del sistema
  - el indicador de llenado de las ventanas de disco

Incluye dos skins: Ofour (estilo AmigaOS 4, de Oliver Hummel) y
OfourBlack (versión oscura de Ofour).


Instalación
-----------
Haz doble clic en "Install" y elige tu idioma. Se instala SkinPatch en C:,
SkinPrefs en SYS:Prefs, las skins en SYS:Prefs/Skins y las traducciones en
LOCALE:Catalogs, y se añade SkinPatch a S:User-Startup.

Si actualizas desde una versión anterior, reinicia el Amiga al terminar.


SkinPrefs
---------
Abre SYS:Prefs/SkinPrefs para elegir:

  Skins                   la skin que se usa, con vista previa
  Altura de la barra      "Automática" usa la altura de la barra del
                          Workbench; cada skin trae dibujos para 11 a 24
  Activado                desmárcalo para desactivar SkinPatch
  Todas las pantallas     skins en todas las pantallas, no solo Workbench
  Marco                   ancho de los marcos de las ventanas nuevas
  Buscar actualizaciones  mira en Aminet si hay una versión nueva
                          (necesita conexión a Internet y una pila
                          TCP/IP en marcha, por ejemplo Roadshow)

  Guardar   guarda los ajustes y los aplica
  Usar      los aplica hasta el próximo reinicio
  Probar    los aplica y deja la ventana abierta
  Cancelar  vuelve a los ajustes anteriores

El idioma de SkinPrefs es el que elegiste al instalar. Para cambiarlo,
vuelve a ejecutar el instalador.


Notas
-----
  - Si otros programas modifican las mismas funciones del sistema después
    que SkinPatch (VisualPrefs, MCP, TitleShadow...), SkinPatch no se puede
    detener y sigue activo hasta que reinicies.
  - La documentación completa (en inglés) está en ReadMe.txt.


Créditos
--------
SkinPatch y SkinPrefs: Isra Ortuño (Gogeta) - Amigatronics.
Skin Ofour: (C) 2005 Oliver Hummel. Redistribuible libremente (Mailware:
si te gusta, escríbele un correo). OfourBlack es una versión recoloreada
de Ofour; todo el mérito del diseño original es de Oliver Hummel.
""")

DOCS['LiesmichDE.txt'] = ('latin-1', """SkinPatch 1.4 - Fenster-Skins für AmigaOS 3.x
=============================================

{credit}
Geschrieben in 68000-Assembler mit Hilfe von Claude (KI von Anthropic).


Was es macht
------------
SkinPatch ändert das Aussehen der Fenster auf dem Workbench-Bildschirm im
Stil der MorphOS-Skins:

  - die Fenster-Gadgets: Schließen, Tiefe, Zoom, Ikonifizieren,
    Bildschirmtiefe, Größe und die Rollpfeile
  - die Titelleiste (Farbverlauf und zentrierter Titel)
  - die Fensterrahmen (links, rechts und unten)
  - die Rollbalken der Workbench und der Programme, die die
    Standard-Rollbalken des Systems verwenden
  - die Füllstandsanzeige der Laufwerksfenster

Zwei Skins sind dabei: Ofour (im Stil von AmigaOS 4, von Oliver Hummel)
und OfourBlack (eine dunkle Version von Ofour).


Installation
------------
Doppelklicken Sie auf "Install" und wählen Sie Ihre Sprache. SkinPatch
kommt nach C:, SkinPrefs nach SYS:Prefs, die Skins nach SYS:Prefs/Skins,
die Übersetzungen nach LOCALE:Catalogs, und SkinPatch wird in
S:User-Startup eingetragen.

Bei einem Update starten Sie den Amiga danach neu.


SkinPrefs
---------
Öffnen Sie SYS:Prefs/SkinPrefs, um Folgendes zu wählen:

  Skins                  der verwendete Skin, mit Vorschau
  Höhe der Titelleiste   "Automatisch" verwendet die Höhe der
                         Workbench-Titelleiste; jeder Skin hat Grafiken
                         für 11 bis 24
  Aktiviert              abwählen, um SkinPatch auszuschalten
  Alle Bildschirme       Skins auf allen Bildschirmen, nicht nur Workbench
  Rahmen                 Breite der Rahmen neuer Fenster
  Nach Updates suchen    prüft im Aminet, ob es eine neue Version gibt
                         (braucht eine Internetverbindung und einen
                         laufenden TCP/IP-Stack, z. B. Roadshow)

  Speichern   speichert die Einstellungen und wendet sie an
  Benutzen    wendet sie bis zum nächsten Neustart an
  Testen      wendet sie an und lässt das Fenster offen
  Abbrechen   zurück zu den vorherigen Einstellungen

SkinPrefs verwendet die bei der Installation gewählte Sprache. Um sie zu
ändern, starten Sie die Installation erneut.


Hinweise
--------
  - Wenn andere Programme dieselben Systemfunktionen nach SkinPatch
    patchen (VisualPrefs, MCP, TitleShadow...), kann SkinPatch nicht
    beendet werden und bleibt bis zum Neustart aktiv.
  - Die vollständige Anleitung (auf Englisch) steht in ReadMe.txt.


Danksagung
----------
SkinPatch und SkinPrefs: Isra Ortuño (Gogeta) - Amigatronics.
Ofour-Skin: (C) 2005 Oliver Hummel. Frei verteilbar (Mailware: wenn er
Ihnen gefällt, schreiben Sie ihm eine Mail). OfourBlack ist eine
umgefärbte Version von Ofour; die Grafiken stammen von Oliver Hummel.
""")

DOCS['LeggimiIT.txt'] = ('latin-1', """SkinPatch 1.4 - skin per le finestre di AmigaOS 3.x
===================================================

{credit}
Scritto in assembly 68000 con l'aiuto di Claude (IA di Anthropic).


Cosa fa
-------
SkinPatch cambia l'aspetto delle finestre dello schermo del Workbench,
nello stile delle skin di MorphOS:

  - i gadget delle finestre: chiusura, profondità, zoom, iconifica,
    profondità dello schermo, ridimensionamento e frecce di scorrimento
  - la barra del titolo (sfondo sfumato e titolo centrato)
  - i bordi delle finestre (sinistro, destro e inferiore)
  - le barre di scorrimento del Workbench e dei programmi che usano le
    barre standard del sistema
  - l'indicatore di riempimento delle finestre dei dischi

Sono incluse due skin: Ofour (in stile AmigaOS 4, di Oliver Hummel) e
OfourBlack (versione scura di Ofour).


Installazione
-------------
Fai doppio clic su "Install" e scegli la tua lingua. SkinPatch viene
copiato in C:, SkinPrefs in SYS:Prefs, le skin in SYS:Prefs/Skins, le
traduzioni in LOCALE:Catalogs, e SkinPatch viene aggiunto a
S:User-Startup.

Se aggiorni da una versione precedente, riavvia l'Amiga alla fine.


SkinPrefs
---------
Apri SYS:Prefs/SkinPrefs per scegliere:

  Skin                   la skin da usare, con anteprima
  Altezza barra titolo   "Automatica" usa l'altezza della barra del
                         Workbench; ogni skin ha immagini da 11 a 24
  Attivo                 togli la spunta per disattivare SkinPatch
  Tutti gli schermi      skin su tutti gli schermi, non solo il Workbench
  Bordo                  spessore dei bordi delle nuove finestre
  Cerca aggiornamenti    controlla su Aminet se c'è una nuova versione
                         (serve una connessione a Internet e uno stack
                         TCP/IP avviato, per esempio Roadshow)

  Salva     salva le impostazioni e le applica
  Usa       le applica fino al prossimo riavvio
  Prova     le applica e lascia aperta la finestra
  Annulla   torna alle impostazioni precedenti

SkinPrefs usa la lingua scelta durante l'installazione. Per cambiarla,
avvia di nuovo l'installazione.


Note
----
  - Se altri programmi modificano le stesse funzioni del sistema dopo
    SkinPatch (VisualPrefs, MCP, TitleShadow...), SkinPatch non può essere
    fermato e resta attivo fino al riavvio.
  - La documentazione completa (in inglese) è in ReadMe.txt.


Riconoscimenti
--------------
SkinPatch e SkinPrefs: Isra Ortuño (Gogeta) - Amigatronics.
Skin Ofour: (C) 2005 Oliver Hummel. Liberamente distribuibile (Mailware:
se ti piace, mandagli una e-mail). OfourBlack è una versione ricolorata
di Ofour; tutto il merito della grafica originale è di Oliver Hummel.
""")

DOCS['LisezmoiFR.txt'] = ('latin-1', """SkinPatch 1.4 - skins de fenêtres pour AmigaOS 3.x
==================================================

{credit}
Écrit en assembleur 68000 avec l'aide de Claude (IA d'Anthropic).


Ce qu'il fait
-------------
SkinPatch change l'aspect des fenêtres de l'écran du Workbench, dans le
style des skins de MorphOS :

  - les gadgets des fenêtres : fermeture, profondeur, zoom, iconification,
    profondeur d'écran, taille et flèches de défilement
  - la barre de titre (fond en dégradé et titre centré)
  - les cadres des fenêtres (gauche, droit et bas)
  - les barres de défilement du Workbench et des programmes qui utilisent
    les barres standard du système
  - la jauge de remplissage des fenêtres de disque

Deux skins sont fournis : Ofour (style AmigaOS 4, d'Oliver Hummel) et
OfourBlack (version sombre d'Ofour).


Installation
------------
Double-cliquez sur "Install" et choisissez votre langue. SkinPatch est
copié dans C:, SkinPrefs dans SYS:Prefs, les skins dans SYS:Prefs/Skins,
les traductions dans LOCALE:Catalogs, et SkinPatch est ajouté à
S:User-Startup.

En cas de mise à jour, redémarrez l'Amiga à la fin.


SkinPrefs
---------
Ouvrez SYS:Prefs/SkinPrefs pour choisir :

  Skins                   le skin utilisé, avec aperçu
  Hauteur barre de titre  "Automatique" utilise la hauteur de la barre du
                          Workbench ; chaque skin a des images de 11 à 24
  Activé                  décochez pour désactiver SkinPatch
  Tous les écrans         skins sur tous les écrans, pas seulement le
                          Workbench
  Cadre                   largeur des cadres des nouvelles fenêtres
  Chercher mises à jour   vérifie sur Aminet s'il existe une nouvelle
                          version (il faut une connexion Internet et une
                          pile TCP/IP lancée, par exemple Roadshow)

  Sauver     enregistre les réglages et les applique
  Utiliser   les applique jusqu'au prochain redémarrage
  Tester     les applique et laisse la fenêtre ouverte
  Annuler    revient aux réglages précédents

SkinPrefs utilise la langue choisie lors de l'installation. Pour la
changer, relancez l'installation.


Remarques
---------
  - Si d'autres programmes modifient les mêmes fonctions du système après
    SkinPatch (VisualPrefs, MCP, TitleShadow...), SkinPatch ne peut pas
    être arrêté et reste actif jusqu'au redémarrage.
  - La documentation complète (en anglais) est dans ReadMe.txt.


Crédits
-------
SkinPatch et SkinPrefs : Isra Ortuño (Gogeta) - Amigatronics.
Skin Ofour : (C) 2005 Oliver Hummel. Librement distribuable (Mailware :
s'il vous plaît, envoyez-lui un e-mail). OfourBlack est une version
recolorée d'Ofour ; tout le mérite du graphisme revient à Oliver Hummel.
""")

DOCS['CzytajPL.txt'] = ('iso-8859-2', """SkinPatch 1.4 - skórki okien dla AmigaOS 3.x
============================================

{credit}
Napisany w asemblerze 68000 z pomocą Claude (SI firmy Anthropic).


Co robi
-------
SkinPatch zmienia wygląd okien na ekranie Workbencha w stylu skórek
MorphOS:

  - gadżety okien: zamykanie, głębia, zoom, ikonifikacja, głębia ekranu,
    zmiana rozmiaru i strzałki przewijania
  - pasek tytułu (tło z gradientem i wyśrodkowany tytuł)
  - ramki okien (lewa, prawa i dolna)
  - paski przewijania Workbencha i programów, które używają
    standardowych pasków systemu
  - wskaźnik zapełnienia w oknach dysków

Dołączone są dwie skórki: Ofour (w stylu AmigaOS 4, autor Oliver Hummel)
i OfourBlack (ciemna wersja Ofour).


Instalacja
----------
Kliknij dwukrotnie "Install" i wybierz język. SkinPatch trafi do C:,
SkinPrefs do SYS:Prefs, skórki do SYS:Prefs/Skins, tłumaczenia do
LOCALE:Catalogs, a SkinPatch zostanie dodany do S:User-Startup.

Przy aktualizacji uruchom Amigę ponownie po zakończeniu.


SkinPrefs
---------
Otwórz SYS:Prefs/SkinPrefs, aby wybrać:

  Skórki                  używana skórka, z podglądem
  Wysokość paska tytułu   "Automatyczna" używa wysokości paska
                          Workbencha; każda skórka ma grafiki od 11 do 24
  Włączone                odznacz, aby wyłączyć SkinPatch
  Wszystkie ekrany        skórki na wszystkich ekranach, nie tylko na
                          Workbenchu
  Ramka                   szerokość ramek nowych okien
  Sprawdź aktualizacje    sprawdza w Aminecie, czy jest nowa wersja
                          (wymaga połączenia z Internetem i działającego
                          stosu TCP/IP, np. Roadshow)

  Zapisz    zapisuje ustawienia i je stosuje
  Użyj      stosuje je do następnego uruchomienia
  Testuj    stosuje je i zostawia okno otwarte
  Anuluj    przywraca poprzednie ustawienia

SkinPrefs używa języka wybranego podczas instalacji. Aby go zmienić,
uruchom instalację ponownie.


Uwagi
-----
  - Jeśli inne programy zmieniają te same funkcje systemu po SkinPatch
    (VisualPrefs, MCP, TitleShadow...), SkinPatch nie może zostać
    zatrzymany i działa do ponownego uruchomienia.
  - Pełna dokumentacja (po angielsku) jest w pliku ReadMe.txt.


Podziękowania
-------------
SkinPatch i SkinPrefs: Isra Ortuño (Gogeta) - Amigatronics.
Skórka Ofour: (C) 2005 Oliver Hummel. Do swobodnego rozpowszechniania
(Mailware: jeśli ci się podoba, wyślij mu e-mail). OfourBlack to
przekolorowana wersja Ofour; cała zasługa za grafikę należy do Olivera
Hummela.
""")

DOCS['LlegeixmeCA.txt'] = ('latin-1', """SkinPatch 1.4 - skins de finestres per a AmigaOS 3.x
====================================================

{credit}
Escrit en assemblador 68000 amb l'ajuda de Claude (IA d'Anthropic).


Què fa
------
SkinPatch canvia l'aspecte de les finestres de la pantalla del Workbench,
a l'estil de les skins de MorphOS:

  - els botons de les finestres: tancar, profunditat, zoom, iconificar,
    profunditat de pantalla, mida i les fletxes de desplaçament
  - la barra de títol (fons degradat i títol centrat)
  - els marcs de les finestres (esquerre, dret i inferior)
  - les barres de desplaçament del Workbench i dels programes que fan
    servir les barres estàndard del sistema
  - l'indicador d'ocupació de les finestres de disc

Inclou dues skins: Ofour (estil AmigaOS 4, d'Oliver Hummel) i OfourBlack
(versió fosca d'Ofour).


Instal·lació
------------
Fes doble clic a "Install" i tria el teu idioma. S'instal·la SkinPatch a
C:, SkinPrefs a SYS:Prefs, les skins a SYS:Prefs/Skins i les traduccions
a LOCALE:Catalogs, i s'afegeix SkinPatch a S:User-Startup.

Si actualitzes des d'una versió anterior, reinicia l'Amiga en acabar.


SkinPrefs
---------
Obre SYS:Prefs/SkinPrefs per triar:

  Skins                   la skin que es fa servir, amb vista prèvia
  Alçada de la barra      "Automàtica" fa servir l'alçada de la barra del
                          Workbench; cada skin té dibuixos de 11 a 24
  Activat                 desmarca'l per desactivar SkinPatch
  Totes les pantalles     skins a totes les pantalles, no només al
                          Workbench
  Marc                    amplada dels marcs de les finestres noves
  Cerca actualitzacions   mira a Aminet si hi ha una versió nova
                          (cal connexió a Internet i una pila TCP/IP en
                          marxa, per exemple Roadshow)

  Desa       desa els ajustos i els aplica
  Usa        els aplica fins al proper reinici
  Prova      els aplica i deixa la finestra oberta
  Cancel·la  torna als ajustos anteriors

SkinPrefs fa servir l'idioma que vas triar en instal·lar. Per canviar-lo,
torna a executar l'instal·lador.


Notes
-----
  - Si altres programes modifiquen les mateixes funcions del sistema
    després de SkinPatch (VisualPrefs, MCP, TitleShadow...), SkinPatch no
    es pot aturar i continua actiu fins que reiniciïs.
  - La documentació completa (en anglès) és a ReadMe.txt.


Crèdits
-------
SkinPatch i SkinPrefs: Isra Ortuño (Gogeta) - Amigatronics.
Skin Ofour: (C) 2005 Oliver Hummel. Redistribuïble lliurement (Mailware:
si t'agrada, envia-li un correu). OfourBlack és una versió recolorida
d'Ofour; tot el mèrit del disseny original és d'Oliver Hummel.
""")

DOCS['IrakurriEU.txt'] = ('latin-1', """SkinPatch 1.4 - AmigaOS 3.x-ko leihoen azalak
=============================================

{credit}
68000 mihiztadura-lengoaian idatzia, Claude-ren laguntzarekin
(Anthropic-en AA).


Zer egiten du
-------------
SkinPatch-ek Workbench pantailako leihoen itxura aldatzen du, MorphOS-eko
azalen estiloan:

  - leihoen botoiak: itxi, sakonera, zoom, ikonotu, pantailaren sakonera,
    tamaina eta korritze-geziak
  - titulu-barra (atzealde gradientea eta titulu zentratua)
  - leihoen markoak (ezkerrekoa, eskuinekoa eta behekoa)
  - Workbench-eko eta sistemaren barra estandarrak erabiltzen dituzten
    programen korritze-barrak
  - disko-leihoen betetze-adierazlea

Bi azal daude: Ofour (AmigaOS 4 estiloa, Oliver Hummel-ena) eta
OfourBlack (Ofour-en bertsio iluna).


Instalazioa
-----------
Egin klik bikoitza "Install"-en eta aukeratu zure hizkuntza. SkinPatch
C:-n instalatzen da, SkinPrefs SYS:Prefs-en, azalak SYS:Prefs/Skins-en eta
itzulpenak LOCALE:Catalogs-en, eta SkinPatch S:User-Startup-era gehitzen
da.

Aurreko bertsio batetik eguneratzen baduzu, berrabiarazi Amiga amaitzean.


SkinPrefs
---------
Ireki SYS:Prefs/SkinPrefs hauek aukeratzeko:

  Azalak                   erabiltzen den azala, aurrebistarekin
  Titulu-barraren altuera  "Automatikoa"-k Workbench-eko barraren
                           altuera erabiltzen du; azal bakoitzak 11tik
                           24rako irudiak ditu
  Gaituta                  kendu marka SkinPatch desgaitzeko
  Pantaila guztiak         azalak pantaila guztietan, ez Workbench-en
                           bakarrik
  Markoa                   leiho berrien markoen zabalera
  Bilatu eguneraketak      Aminet-en bertsio berririk dagoen begiratzen du
                           (Interneteko konexioa eta TCP/IP pila bat
                           martxan behar dira, adibidez Roadshow)

  Gorde     ezarpenak gordetzen eta aplikatzen ditu
  Erabili   hurrengo berrabiarazi arte aplikatzen ditu
  Probatu   aplikatu eta leihoa irekita uzten du
  Utzi      aurreko ezarpenetara itzultzen da

SkinPrefs-ek instalatzean aukeratutako hizkuntza erabiltzen du. Aldatzeko,
abiarazi berriro instalatzailea.


Oharrak
-------
  - Beste programa batzuek sistemaren funtzio berberak aldatzen badituzte
    SkinPatch-en ondoren (VisualPrefs, MCP, TitleShadow...), SkinPatch ezin
    da gelditu eta aktibo jarraitzen du berrabiarazi arte.
  - Dokumentazio osoa (ingelesez) ReadMe.txt fitxategian dago.


Kredituak
---------
SkinPatch eta SkinPrefs: Isra Ortuño (Gogeta) - Amigatronics.
Ofour azala: (C) 2005 Oliver Hummel. Libreki bana daiteke (Mailware:
gustatzen bazaizu, bidali mezu bat). OfourBlack Ofour-en bertsio
birkoloreztatua da; jatorrizko diseinuaren merezimendu guztia Oliver
Hummel-ena da.
""")

DOCS['LeameGL.txt'] = ('latin-1', """SkinPatch 1.4 - skins de xanelas para AmigaOS 3.x
=================================================

{credit}
Escrito en ensamblador 68000 coa axuda de Claude (IA de Anthropic).


Que fai
-------
SkinPatch cambia o aspecto das xanelas da pantalla do Workbench, ao
estilo das skins de MorphOS:

  - os botóns das xanelas: pechar, profundidade, zoom, iconificar,
    profundidade de pantalla, tamaño e as frechas de desprazamento
  - a barra de título (fondo degradado e título centrado)
  - os marcos das xanelas (esquerdo, dereito e inferior)
  - as barras de desprazamento do Workbench e dos programas que usan as
    barras estándar do sistema
  - o indicador de ocupación das xanelas de disco

Inclúe dúas skins: Ofour (estilo AmigaOS 4, de Oliver Hummel) e
OfourBlack (versión escura de Ofour).


Instalación
-----------
Fai dobre clic en "Install" e escolle o teu idioma. Instálase SkinPatch
en C:, SkinPrefs en SYS:Prefs, as skins en SYS:Prefs/Skins e as
traducións en LOCALE:Catalogs, e engádese SkinPatch a S:User-Startup.

Se actualizas desde unha versión anterior, reinicia o Amiga ao rematar.


SkinPrefs
---------
Abre SYS:Prefs/SkinPrefs para escoller:

  Skins                   a skin que se usa, con vista previa
  Altura da barra         "Automática" usa a altura da barra do
                          Workbench; cada skin trae debuxos de 11 a 24
  Activado                desmárcao para desactivar SkinPatch
  Todas as pantallas      skins en todas as pantallas, non só no
                          Workbench
  Marco                   ancho dos marcos das xanelas novas
  Buscar actualizacións   mira en Aminet se hai unha versión nova
                          (precisa conexión a Internet e unha pila TCP/IP
                          en marcha, por exemplo Roadshow)

  Gardar    garda os axustes e aplícaos
  Usar      aplícaos ata o seguinte reinicio
  Probar    aplícaos e deixa a xanela aberta
  Cancelar  volve aos axustes anteriores

SkinPrefs usa o idioma que escolliches ao instalar. Para cambialo, volve
executar o instalador.


Notas
-----
  - Se outros programas modifican as mesmas funcións do sistema despois
    de SkinPatch (VisualPrefs, MCP, TitleShadow...), SkinPatch non se pode
    deter e segue activo ata que reinicies.
  - A documentación completa (en inglés) está en ReadMe.txt.


Créditos
--------
SkinPatch e SkinPrefs: Isra Ortuño (Gogeta) - Amigatronics.
Skin Ofour: (C) 2005 Oliver Hummel. Redistribuíble libremente (Mailware:
se che gusta, envíalle un correo). OfourBlack é unha versión recolorida
de Ofour; todo o mérito do deseño orixinal é de Oliver Hummel.
""")

if __name__ == '__main__':
    out = sys.argv[1]; os.makedirs(out, exist_ok=True)
    for fn, (enc, txt) in DOCS.items():
        t = txt.format(credit=CREDIT).replace('Ortuño', 'Ortuño')
        if enc != 'latin-1':
            t = t.replace('Ortuño', 'Ortuno')   # la ñ no existe en ISO-8859-2
        data = t.encode(enc)
        assert max(len(l) for l in t.split('\n')) <= 78, fn
        open(os.path.join(out, fn), 'wb').write(data)
    print('docs:', len(DOCS))
