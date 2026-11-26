# SkinPatch

**MorphOS-style window skins for AmigaOS 3.x**

SkinPatch changes the look of the windows on the Workbench screen in the style of MorphOS skins. It comes with two skins: **Ofour**, an AmigaOS 4 styled skin by Oliver Hummel converted to work on AmigaOS 3.x, and **OfourBlack**, a dark version of it.

- **Version:** 1.4
- **Requires:** AmigaOS 3.0+, any 68000+ CPU
- **Download:** [Aminet (util/wb)](https://aminet.net/package/util/wb/SkinPatch) · [Hangar](https://hangar.freemem.space)

## What gets skinned

- Window gadgets: close, depth, zoom, iconify, screen depth, size, scroll arrows
- The title bar: gradient background and centred title
- The window frames (left, right and bottom), with adjustable width
- The scroll bars of Workbench windows and of programs that use standard BOOPSI scrollers: knob and track drawn with the skin

## Features

- **SkinPrefs:** preferences editor with preview, skin selection, title bar height (automatic or 11-24), frame width, "all screens" and "enabled"
- Skins are plain IFF ILBM images, one drawer per title bar height
- Works on native (OCS/ECS/AGA) and RTG screens
- Works with the Workbench and with Directory Opus listers
- Changes are applied live from SkinPrefs, no reboot needed
- Small: SkinPatch is about 46 KB, SkinPrefs about 19 KB
- Installer script included; adds SkinPatch to `S:User-Startup`
- SkinPrefs and installer in 9 languages (EN, ES, DE, IT, FR, PL, CA, EU, GL)
- `Tools/mos2skin.py`: Python 3 converter for MorphOS skins (runs on PC)
- Full source code (68000 assembly)

## Installation

Unpack the archive and double-click **Install**. Read `ReadMe.txt` for details and Shell options. When updating, reboot after installing.

## Notes

SkinPatch patches `sysiclass`, `propgclass`, `SetWindowTitles`, `CloseWindow` and `(New)ModifyProp`. If other programs (VisualPrefs, MCP, TitleShadow...) patch the same functions after it, SkinPatch cannot be stopped safely and stays active until you reboot.

Tested on AmigaOS 3.2 (CaffeineOS) under WinUAE and on a real Amiga with AmigaOS 3.2.3 and PiStorm.

## History

**1.4**
- The Workbench font or screen mode can be changed again while SkinPatch is running (the screen was kept locked); SkinPatch follows the new Workbench screen by itself
- The disk fill gauge uses a shade of the skin colours instead of black (darker on light skins, lighter on dark skins)
- "Check for updates" understands versions like 1.4.1

**1.3**
- SkinPrefs and installer in 9 languages, with short guides in each language
- "Check for updates" button in SkinPrefs (needs TCP/IP)
- Fill gauge of disk windows drawn with the skin
- Works with Directory Opus: its listers get the skin too (iconify gadget and scroll bars)

**1.2**
- Iconify gadget of AmigaOS 3.2.3 windows skinned
- Workbench scroll bars given back at once when SkinPatch is turned off in SkinPrefs
- SkinPrefs shows the SkinPatch logo

**1.1**
- "Enabled" switch in SkinPrefs
- Iconify gadget and program scroll bars skinned
- OfourBlack dark skin; title text colour follows the title bar
- Gaps around the scroll arrows filled with the window frame
- Faster repainting while windows are moved or resized
- New icons

**1.0**
- First release

## Credits

SkinPatch and SkinPrefs by **Isra Ortuño (Gogeta) - Amigatronics**.
Written in 68000 assembly with the help of Claude (Anthropic AI).

[amigatronics.com](https://amigatronics.com) · [en.amigatronics.com](https://en.amigatronics.com) · amigatronics@amigatronics.com

Ofour skin (C) 2005 Oliver Hummel. Freely redistributable Mailware: if you like it, send him a mail. Original ReadMe included. OfourBlack is a recoloured version of Ofour; all credit for the artwork goes to Oliver Hummel.

AmigaOS is a trademark of Hyperion Entertainment. MorphOS is a trademark of the MorphOS Team.

## License

SkinPatch and SkinPrefs are released under the [MIT License](LICENSE). The Ofour and OfourBlack skins keep their own terms (see above).
