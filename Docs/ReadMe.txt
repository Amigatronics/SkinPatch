SkinPatch 1.4 - window skins for AmigaOS 3.x
============================================

Made by Isra Ortuño (Gogeta) - Amigatronics
https://amigatronics.com  /  https://en.amigatronics.com
amigatronics@amigatronics.com

Written in 68000 assembly with the help of Claude (Anthropic AI).
MorphOS skins are converted to IFF with a Python tool.


What it does
------------
SkinPatch changes the look of the windows on the Workbench screen, in
the style of MorphOS skins:

  - window gadgets: close, depth, zoom, iconify, screen depth, size and
    the scroll arrows
  - the title bar (gradient background and centred title)
  - the window frames (left, right and bottom)
  - the fill gauge of disk windows (left border)
  - the scroll bars of Workbench windows and of programs that use
    standard BOOPSI scrollers (knob and track drawn with the skin)

Two skins are included:

  Ofour       an AmigaOS 4 styled skin made for MorphOS by Oliver
              Hummel (see "Credits")
  OfourBlack  a dark version of Ofour: black title bar and frames on
              the active window, inactive windows as in Ofour


What's new in 1.4
-----------------
  - the Workbench font or screen mode can be changed again while
    SkinPatch is running (the screen was kept locked); SkinPatch
    follows the new Workbench screen by itself
  - the disk fill gauge uses a shade of the skin colours instead of
    black (darker on light skins, lighter on dark skins)
  - "Check for updates" understands versions like 1.4.1


What's new in 1.3
-----------------
  - SkinPrefs and the installer in 9 languages: English, Español,
    Deutsch, Italiano, Français, Polski, Català, Euskara and Galego
    (short guides in each language in the Docs drawer)
  - "Check for updates" button in SkinPrefs (looks at Aminet)
  - the fill gauge of disk windows is drawn with the skin
  - works with Directory Opus: its listers get the skin too, including
    the iconify gadget and the scroll bars


What's new in 1.2
-----------------
  - the iconify gadget of AmigaOS 3.2.3 windows is skinned too
  - turning SkinPatch off in SkinPrefs gives the Workbench scroll bars
    back to the system at once (they were left blank until the window
    was closed)
  - SkinPrefs shows the SkinPatch logo


What's new in 1.1
-----------------
  - "Enabled" switch in SkinPrefs: turn the skins off without
    uninstalling
  - the iconify gadget of title bars is skinned
  - scroll bars of programs (BOOPSI propgclass) are skinned too, also
    after moving or resizing the window
  - new dark skin OfourBlack; the title text is drawn white or black
    depending on the brightness of the title bar
  - gaps around the scroll arrows and the size gadget are filled with
    the window frame
  - faster repainting while windows are moved or resized
  - new icons


Requirements
------------
  - AmigaOS 3.0 or newer (tested on AmigaOS 3.2 / CaffeineOS in WinUAE
    and on a real Amiga with AmigaOS 3.2.3 and PiStorm)
  - any 68000 or better CPU
  - works on native and RTG (graphics card) screens
  - works with the Workbench and with Directory Opus listers


Installation
------------
Double-click "Install" and choose your language. It copies:

  SkinPatch   to C:
  SkinPrefs   to SYS:Prefs
  Skins       to SYS:Prefs/Skins
  Catalogs    to LOCALE:Catalogs (translations of SkinPrefs)

and adds "Run >NIL: C:SkinPatch" to S:User-Startup. The first time it
also installs default settings (Ofour skin, automatic height,
8 pixel frames).

If you are updating, reboot after installing: a running SkinPatch
cannot always be stopped (see "Notes").


SkinPrefs
---------
Open SYS:Prefs/SkinPrefs to choose:

  Skins             the skin to use, with a preview
  Title bar height  "Automatic" uses the height of your Workbench title
                    bar; each skin has graphics for heights 11 to 24
  Enabled           uncheck it to turn SkinPatch off
  All screens       skin windows on every screen, not only Workbench
  Frame             width of the window frames for windows opened from
                    now on (default 8 pixels)
  Check for updates asks Aminet for the latest version; needs an
                    Internet connection and a running TCP/IP stack
                    (Roadshow, Miami, AmiTCP...)

  Save    keep the settings (ENVARC:) and apply them
  Use     apply them until the next reboot
  Test    apply them and keep the window open
  Cancel  go back to the previous settings

SkinPrefs uses the language chosen in the installer (it is kept in
ENVARC:SkinPatch.language). Run the installer again to change it. New
translations are welcome: the catalog sources are in Source/Catalogs.


Shell usage
-----------
  SkinPatch [SKIN=<drawer>] [ALLSCREENS] [BORDER=<n>] [QUIT]

  SKIN=<drawer>  use the skin images in that drawer
  ALLSCREENS     skin windows on every screen
  BORDER=<n>     frame width in pixels (2-16), overrides SkinPrefs
  QUIT           stop the running SkinPatch (when possible)


Skins
-----
A skin is a drawer in SYS:Prefs/Skins with one sub-drawer per title bar
height (11 ... 24). Each one holds IFF ILBM images; every image has
three frames side by side: [normal][pressed][inactive window].

  close.iff depth.iff zoom.iff iconify.iff  title bar gadgets
  sdepth.iff                                 screen depth gadget
  size.iff left.iff right.iff up.iff down.iff border gadgets
  bar.iff                                    title bar background
  frameh.iff framev.iff                      window frames
  knobh.iff knobv.iff                        scroll bar knobs
  troughh.iff troughv.iff                    scroll bar tracks

Converting MorphOS skins: the drawer "Tools" holds mos2skin.py, a Python
3 script (needs Pillow) that runs on a PC:

  python3 mos2skin.py <MorphOS skin drawer> <output drawer> 11 12 ... 24

Copy the output drawer to SYS:Prefs/Skins/<name>. Please respect the
licence of each skin before sharing converted skins. makedark.py, in
the same drawer, is the script that made OfourBlack from Ofour.


Notes
-----
  - SkinPatch patches the sysiclass and propgclass image/gadget
    classes, SetWindowTitles, CloseWindow and (New)ModifyProp. If other
    programs patch the same functions after it (VisualPrefs, MCP,
    TitleShadow...), SkinPatch cannot stop safely; "SkinPatch QUIT"
    will say so and it stays active until you reboot.
  - The Workbench scroll bars are drawn by SkinPatch while their window
    is open; everything is given back to Workbench when it closes.
  - While a window is being resized, a little of the system frame can
    show for a moment next to the scroll arrows.
  - Some systems (for example CaffeineOS) draw an extra line inside the
    window around the scroll gadgets; SkinPatch leaves it alone because
    it belongs to the window contents.


Credits
-------
SkinPatch and SkinPrefs: Isra Ortuño (Gogeta) - Amigatronics, written
in 68000 assembly with the help of Claude (Anthropic AI).
Contact: amigatronics@amigatronics.com

Ofour skin: (C) 2005 Oliver Hummel. An OS4 styled Intuition skin for
MorphOS, "freely redistributable. You may use it for your own skin
e.g. Visual Prefs." It is Mailware: if you like it, send him a mail.
Its original ReadMe is in SYS:Prefs/Skins/Ofour/Ofour_ReadMe.txt.
Converted to SkinPatch format; the MUI, requester and menu artwork of
the original package is not included.

OfourBlack: a recoloured version of Ofour by Isra Ortuño (Gogeta) -
Amigatronics. All credit for the original artwork goes to Oliver
Hummel.

AmigaOS is a trademark of Hyperion Entertainment. MorphOS is a
trademark of the MorphOS Team.
