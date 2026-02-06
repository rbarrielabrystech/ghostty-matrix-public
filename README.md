# Matrix Ghostty Theme

High-fidelity Matrix (1999) terminal setup for [Ghostty](https://ghostty.org/).

![Matrix Theme Demo](https://raw.githubusercontent.com/rbarrielabrystech/ghostty-matrix-public/main/demo.gif)

[Watch full demo on YouTube](https://www.youtube.com/watch?v=BE-xdpNpspE)

**Cross-platform:** Linux, macOS, Windows (WSL/Git Bash)

## Features

- **Authentic Matrix rain** using [cxxmatrix](https://github.com/akinomyoga/cxxmatrix) with half-width katakana
- **Movie-accurate startup sequence**: number fall → rain → "WAKE UP NEO" banner → "Follow the white rabbit."
- **Full 1999 CRT mode**: barrel distortion, scanlines, shadow mask, vignette — like sitting in front of a CRT monitor in 1999
- **CRT shutdown animation**: authentic power-down effect (brightness spike → vertical collapse → phosphor afterglow)
- **Enhanced CRT effects**: toggleable static noise, horizontal jitter, interlacing, and halation
- **6 shader effects**: CRT Full, Retro CRT (switchable phosphor), CRT Scanlines, Phosphor Bloom, Matrix Glow, CRT Shutdown
- **30 Terminal Eras**: Time-travel from WWII Enigma machines to Windows 98 with authentic palettes, boot messages, and interactive simulators
- **Interactive configuration TUI** (`matrix-config`): presets, terminal eras, shader picker, CRT effects, shutdown config, 25+ settings
- **5 one-click presets**: Full 1999 CRT, CRT Lite, Phosphor Bloom, Subtle Glow, Clean Terminal
- **Phosphor-green color scheme** with accurate `#0d0208` background
- **Fully configurable**: animation frequency, duration, sequences, colors, quotes, and more
- **Skip animation** with any keypress
- **Cross-platform**: Works on Linux, macOS, and Windows (WSL/Git Bash)

## Quick Install

```bash
git clone https://github.com/rbarrielabrystech/ghostty-matrix-public.git
cd ghostty-matrix-public
chmod +x install.sh
./install.sh
```

The installer will:
- Detect your OS (Linux, macOS, WSL, Windows)
- Copy configuration files
- Add shell integration to your `.zshrc` or `.bashrc`
- Provide instructions for installing dependencies

## Platform Support

| Platform | Status | Notes |
|----------|--------|-------|
| Linux | Full | Tested on Ubuntu, Arch, Fedora |
| macOS | Full | Tested on macOS 12+ |
| WSL2 | Full | Best Windows experience |
| Git Bash | Partial | Some features limited |

## Configuration

Run the interactive configuration menu:

```bash
matrix-config
```

This opens a full TUI with two screens:

### Presets (one-click setup)

| Preset | Shader | Description |
|--------|--------|-------------|
| **Full 1999 CRT** | `crt-full.glsl` | Curvature + scanlines + shadow mask + vignette, noise + interlace, shutdown animation |
| **CRT Lite** | `crt.glsl` | Scanlines without curvature, slightly transparent |
| **Phosphor Bloom** | `bloom.glsl` | Soft glow around text, very readable (recommended) |
| **Subtle Glow** | `matrix-glow.glsl` | Minimal green glow, for daily driving |
| **Clean Terminal** | none | Matrix colors only, no shader effects |

### Custom Settings

Press `c` from the presets screen to access individual controls:

| Category | Settings |
|----------|----------|
| **Shader** | Shader picker with descriptions for all 5 options |
| **Animation** | Frequency, duration, sequence, text sequence, typing speed, skip, diffuse, twinkle |
| **Terminal** | Font thicken (phosphor), font size, background opacity, cursor style/blink, window padding |
| **Header** | Show/hide header, quote, system info |
| **CRT Effects** | Static noise, horizontal jitter, interlacing, enhanced halation (crt-full only) |
| **Shutdown** | CRT shutdown effect on/off, auto-trigger on exit |

### Manual Configuration

You can also edit the config files directly:

```bash
# Matrix animation/behavior settings
nano ~/.config/ghostty/matrix.conf

# Ghostty terminal settings (shader, font, colors)
nano ~/.config/ghostty/config
```

### Key Settings (matrix.conf)

| Setting | Options | Default | Description |
|---------|---------|---------|-------------|
| `MATRIX_ANIMATION_FREQUENCY` | daily, weekly, always, never | daily | How often to run animation |
| `MATRIX_ANIMATION_DURATION` | seconds | 8 | Duration of matrix rain |
| `MATRIX_SHOW_TEXT_SEQUENCE` | true, false | true | Show "Wake up, Neo..." |
| `MATRIX_SHOW_QUOTE` | true, false | true | Show random Matrix quote |
| `MATRIX_ALLOW_SKIP` | true, false | true | Allow skipping with keypress |
| `MATRIX_CUSTOM_QUOTES` | pipe-separated | "" | Add your own quotes |
| `MATRIX_SEQUENCE` | see below | number,rain,banner | cxxmatrix animation sequence |
| `MATRIX_DIFFUSE` | true, false | true | Background glow in animation |
| `MATRIX_TWINKLE` | true, false | true | Brightness fluctuations |
| `MATRIX_SHUTDOWN_ANIMATION` | true, false | true | CRT power-down on `matrix-off` |
| `MATRIX_SHUTDOWN_ON_EXIT` | true, false | false | Auto-trigger shutdown on `exit` |
| `MATRIX_CRT_NOISE` | true, false | false | Static noise (crt-full only) |
| `MATRIX_CRT_JITTER` | true, false | false | Horizontal jitter (crt-full only) |
| `MATRIX_CRT_INTERLACE` | true, false | false | Interlacing (crt-full only) |
| `MATRIX_CRT_HALATION` | true, false | false | Enhanced halation (crt-full only) |
| `MATRIX_ERA` | era ID or empty | "" | Current terminal era (empty = Matrix) |
| `MATRIX_ERA_INTERACTIVE` | true, false | false | Launch interactive simulation on new terminal |

See `matrix.conf` for all available options.

## Startup Sequence

When you open Ghostty (first terminal of the day by default):

1. **Number fall** - Digits raining down
2. **Katakana rain** - Authentic half-width characters
3. **"WAKE UP NEO"** - Banner emerges from the rain
4. **Typing effect** - "Wake up, Neo... The Matrix has you... Follow the white rabbit."
5. **System info** - Your operator status
6. **Random quote** - Classic Matrix wisdom

Press any key to skip at any point.

## Commands

```bash
matrix-config       # Interactive configuration TUI
matrix              # Run full startup sequence
matrix-demo         # Reset lock and re-trigger animation
matrix-off          # CRT shutdown animation + exit
matrix-era          # Launch current era boot sequence
matrix-rain         # Endless katakana rain
matrix-conway       # Conway's Game of Life
matrix-mandelbrot   # Mandelbrot fractal zoom
matrix-full         # All scenes in a loop
```

## Shaders

Located in `shaders/`. Switch between them via `matrix-config` or edit `~/.config/ghostty/config` directly.

| Shader | Description | Effect | CPU Usage |
|--------|-------------|--------|-----------|
| `crt-full.glsl` | Full 1999 CRT | Barrel distortion, scanlines, shadow mask, vignette, optional noise/jitter/interlace/halation | Medium |
| `retro-crt.glsl` | Retro CRT (Eras) | Switchable phosphor (green/amber/white/color), softer defaults | Medium |
| `crt.glsl` | CRT Scanlines | Scanlines only, no curvature | Medium |
| `bloom.glsl` | Phosphor Bloom (recommended) | Soft glow around bright text | Low |
| `matrix-glow.glsl` | Matrix Glow | Subtle green glow, minimal | Low |
| `crt-shutdown.glsl` | CRT Shutdown | Power-down animation (used internally by `matrix-off`) | Low |

To change shader manually:
```bash
# In ~/.config/ghostty/config
custom-shader = ~/.config/ghostty/shaders/crt-full.glsl
```

To disable shaders:
```bash
# Comment out or remove the line
# custom-shader = ...
```

### CRT Shutdown Animation

Run `matrix-off` to trigger a classic CRT power-down sequence before closing the terminal:

1. **Brightness spike** (0.0-0.25s) — capacitor discharge, screen flashes white-green
2. **Vertical collapse** (0.25-0.70s) — screen squeezes to a horizontal line
3. **Horizontal shrink** (0.70-1.10s) — line collapses to a center dot
4. **Phosphor afterglow** (1.10-1.60s) — green dot fades with P1 phosphor color
5. **Black** (1.60s+) — terminal exits

This works by exploiting Ghostty's shader hot-reload (1.2.0+) — the shell function swaps the active shader to `crt-shutdown.glsl`, waits for the animation, restores the original shader, then exits. In non-Ghostty terminals, `matrix-off` simply exits.

To auto-trigger on every `exit`, set `MATRIX_SHUTDOWN_ON_EXIT=true` in `matrix.conf`.

### Enhanced CRT Effects (crt-full only)

When using the `crt-full.glsl` shader, four additional effects can be toggled via `matrix-config` (Custom > CRT Effects) or by editing the shader directly:

| Effect | Description | Default |
|--------|-------------|---------|
| **Static Noise** | Film grain / signal noise | Off |
| **Horizontal Jitter** | Per-scanline signal instability | Off |
| **Interlacing** | Alternating field darkening (60Hz) | Off |
| **Enhanced Halation** | Wide-spread bloom from internal glass reflections | Off |

The **Full 1999 CRT** preset enables noise + interlacing automatically. Changes take effect in real-time via Ghostty's shader hot-reload.

## Terminal Eras - Time Machine

Transform your terminal into any classic computer from the 1940s to 2000. Access via `matrix-config` > `e) Terminal Eras...`.

Each era applies:
- **Authentic color palette** (16 ANSI colors + background/foreground)
- **Period-correct CRT shader** (green phosphor, amber phosphor, white, or color)
- **Boot message** (the exact text you'd see powering on the real machine)
- **Interactive simulation** (optional - a working punch card, BASIC interpreter, etc.)

### All 30 Eras

| Era | Period | Interactive | Description |
|-----|--------|-------------|-------------|
| **Enigma Machine** | 1940s | Rotor encryption simulator | Real M3 rotor wirings, plugboard, lampboard |
| **Colossus** | 1940s | Boot only | Bletchley Park codebreaking computer |
| **IBM Punch Card** | 1950s | Keypunch simulator | Type characters, see Hollerith punches, submit card deck |
| **Teletype ASR-33** | 1960s | 10 cps teletype | Slow printing, uppercase only, paper tape |
| **Line Printer** | 1960s | Boot only | IBM 1403 greenbar output |
| **IBM 3270** | 1970s | Block-mode terminal | TSO login, ISPF panels, forms-based input |
| **IBM System/360** | 1960s | Boot only | Mainframe IPL sequence |
| **DEC PDP-8** | 1960s | Front panel | LED display, toggle switches, octal entry |
| **DEC VT100** | 1978 | Unix shell | Green phosphor, BSD 4.2 |
| **DEC VT220** | 1983 | Unix shell | Amber phosphor, VMS-style |
| **Altair 8800** | 1975 | Front panel | Toggle in programs, Kill the Bit game |
| **Apple II** | 1977 | BASIC interpreter | Applesoft BASIC, green phosphor |
| **Commodore PET** | 1977 | BASIC interpreter | Commodore BASIC, green CRT |
| **TRS-80** | 1977 | BASIC interpreter | Level II BASIC, white phosphor |
| **Commodore 64** | 1982 | BASIC interpreter | BASIC V2, blue-on-blue Pepto palette |
| **ZX Spectrum** | 1982 | BASIC interpreter | Keyword entry mode (P=PRINT) |
| **BBC Micro** | 1981 | BASIC interpreter | BBC BASIC |
| **Amstrad CPC** | 1984 | BASIC interpreter | Locomotive BASIC, yellow-on-blue |
| **MSX** | 1983 | BASIC interpreter | MSX-BASIC, white-on-blue |
| **Atari 800** | 1979 | BASIC interpreter | Atari BASIC |
| **Commodore Amiga** | 1985 | Unix shell | AmigaDOS Workbench |
| **IBM MDA** | 1981 | DOS prompt | Green phosphor, DOS 3.30 |
| **IBM CGA** | 1981 | DOS prompt | Color graphics adapter |
| **MS-DOS** | 1991 | DOS prompt | DOS 6.22, DIR/CD/TYPE/MEM |
| **Sun Solaris** | 1997 | Unix shell | SunOS 5.6, sparc workstation |
| **SGI IRIX** | 1998 | Unix shell | Silicon Graphics |
| **NeXT** | 1995 | Unix shell | NeXTSTEP 3.3, grayscale |
| **BBS Terminal** | 1993 | Full BBS | Modem connect, ANSI art, message boards, door games |
| **Early Linux** | 1998 | Unix shell | Slackware 3.6, LILO boot, kernel 2.0 |
| **Windows 98** | 1998 | DOS prompt | MS-DOS under Windows |

### Using Terminal Eras

```bash
matrix-config    # Open config TUI
# Press 'e' for Terminal Eras
# Select a category (1-9)
# Select an era
# Press 'i' to toggle interactive mode
```

When an era is active, new terminals show the boot message. With interactive mode enabled (`MATRIX_ERA_INTERACTIVE=true`), the era's simulation launches automatically.

To return to the Matrix theme: press `m` in the Terminal Eras menu.

### Interactive Simulators

**IBM 029 Keypunch**: Type characters to punch Hollerith codes on 80-column cards. See the real punch patterns appear. Release cards to your deck, then submit to the card reader.

**Enigma M3**: Configure rotors (I-V), ring settings, plugboard pairs. Type to encrypt with real-time rotor stepping. Letters never encrypt to themselves. Output in 5-letter groups.

**Front Panel (Altair/PDP-8)**: Toggle switches to enter octal data. Examine and deposit memory. Load pre-built programs. Play "Kill the Bit" — the classic front-panel game.

**BASIC Interpreter**: A real BASIC shell supporting PRINT, LET, IF/THEN, GOTO, FOR/NEXT, INPUT, GOSUB/RETURN, and more. Line-numbered program storage with RUN, LIST, NEW, LOAD, SAVE. Configured per-era (C64 says `READY.`, Spectrum has keyword entry, Apple II is uppercase-only).

**DOS Prompt**: Virtual filesystem with DIR, CD, TYPE, COPY, DEL, MKDIR, CLS, VER, MEM, TREE. Pre-populated AUTOEXEC.BAT and CONFIG.SYS. Drive letter support (C:\, A:\).

**BBS Terminal**: Full dial-up BBS experience. Modem connect simulation, ANSI art welcome screen, message bases, file areas with download progress bars, a text adventure door game, and "NO CARRIER" disconnect.

**IBM 3270**: Block-mode forms terminal. TSO login screen, ISPF primary option menu, utilities panel, dataset list, TSO command line. Tab between fields, Enter to submit.

**Classic Unix**: Login prompt with era-appropriate MOTD. Commands: ls, cat, cd, pwd, who, date, uname, ps, df. Variants for VT100 (BSD), Solaris, IRIX, NeXT, Amiga, early Linux.

**Teletype ASR-33**: 10 characters per second output. Uppercase only. Carriage return delays. Paper tape display for saved programs.

## File Structure

```
~/.config/ghostty/
├── config                # Ghostty terminal config
├── matrix.conf           # Matrix theme settings
├── matrix-config.sh      # Interactive configuration TUI
├── matrix-startup.sh     # Full animation script
├── matrix-header.sh      # Header-only script
├── shaders/
│   ├── crt-full.glsl     # Full 1999 CRT (curvature + mask + optional effects)
│   ├── retro-crt.glsl    # Configurable CRT (green/amber/white phosphor)
│   ├── crt-shutdown.glsl # CRT power-down animation
│   ├── crt.glsl          # CRT scanlines only
│   ├── bloom.glsl        # Phosphor bloom (default)
│   └── matrix-glow.glsl  # Subtle green glow
└── eras/
    ├── era-lib.sh        # Shared library
    ├── era-boot.sh       # Era boot sequence display
    ├── era-punchcard.sh  # IBM 029 keypunch simulator
    ├── era-enigma.sh     # Enigma M3 rotor machine
    ├── era-frontpanel.sh # Altair/PDP-8 front panel
    ├── era-basic.sh      # Universal BASIC interpreter
    ├── era-dos.sh        # DOS prompt simulator
    ├── era-bbs.sh        # BBS terminal
    ├── era-teletype.sh   # ASR-33 teletype
    ├── era-3270.sh       # IBM 3270 block mode
    └── era-unix.sh       # Classic Unix shells

~/.local/bin/
├── cxxmatrix             # Matrix rain binary
└── matrix-config         # Symlink to config TUI
```

## Manual Installation

### Linux (Debian/Ubuntu)

```bash
# Install dependencies
sudo apt install gawk make g++

# Install cxxmatrix
git clone https://github.com/akinomyoga/cxxmatrix /tmp/cxxmatrix
cd /tmp/cxxmatrix && make
mkdir -p ~/.local/bin && cp cxxmatrix ~/.local/bin/

# Install fallback
sudo apt install cmatrix

# Run installer
./install.sh
```

### Linux (Arch)

```bash
# Install dependencies
sudo pacman -S gawk make gcc

# Install cxxmatrix
git clone https://github.com/akinomyoga/cxxmatrix /tmp/cxxmatrix
cd /tmp/cxxmatrix && make
mkdir -p ~/.local/bin && cp cxxmatrix ~/.local/bin/

# Install fallback
sudo pacman -S cmatrix

# Run installer
./install.sh
```

### macOS

```bash
# Install dependencies
brew install gawk make

# Install cxxmatrix
git clone https://github.com/akinomyoga/cxxmatrix /tmp/cxxmatrix
cd /tmp/cxxmatrix && make
mkdir -p ~/.local/bin && cp cxxmatrix ~/.local/bin/

# Install fallback
brew install cmatrix

# Run installer
./install.sh
```

### Windows (WSL2 recommended)

```bash
# In WSL2 Ubuntu
sudo apt install gawk make g++
git clone https://github.com/akinomyoga/cxxmatrix /tmp/cxxmatrix
cd /tmp/cxxmatrix && make
mkdir -p ~/.local/bin && cp cxxmatrix ~/.local/bin/
sudo apt install cmatrix

# Run installer
./install.sh
```

## Troubleshooting

### Animation not running?

```bash
# Clear lock files and test
rm -f /tmp/.matrix_* /tmp/.matrix_week_*
~/.config/ghostty/matrix-startup.sh
```

### Wrong config loading? (macOS)

```bash
ls -la ~/Library/Application\ Support/com.mitchellh.ghostty/config
# Should symlink to ~/.config/ghostty/config
```

### Shader not working?

1. Ensure path is correct in config
2. Press `Cmd+Shift+,` (macOS) or restart Ghostty
3. Check Ghostty supports custom shaders

### `matrix-off` not animating?

- Requires Ghostty 1.2.0+ (shader hot-reload support)
- Check that `MATRIX_SHUTDOWN_ANIMATION=true` in `~/.config/ghostty/matrix.conf`
- Verify `crt-shutdown.glsl` exists: `ls ~/.config/ghostty/shaders/crt-shutdown.glsl`
- Only works in interactive Ghostty shells (falls back to plain `exit` elsewhere)

### cxxmatrix build fails?

```bash
# Ensure gawk is installed (not mawk)
which gawk
# If missing: brew install gawk / sudo apt install gawk
```

## Documentation

- **[HISTORY.md](HISTORY.md)** — Comprehensive history of every terminal era, the Matrix philosophy, CRT technology, and the cultural context of 55 years of computing

## Credits & Acknowledgments

This project builds upon and is inspired by the following open source projects:

### Core Dependencies

- **[cxxmatrix](https://github.com/akinomyoga/cxxmatrix)** by Koichi Murase (akinomyoga)
  - High-fidelity Matrix digital rain effect
  - License: MIT
  - Provides the authentic katakana character rain animation

- **[cmatrix](https://github.com/abishekvashok/cmatrix)** by Abishek V Ashok
  - Classic Matrix rain (fallback)
  - License: GPL-2.0
  - Used when cxxmatrix is not available

### Shaders

- **[ghostty-shaders](https://github.com/0xhckr/ghostty-shaders)** (CRT/bloom shaders)
  - Inspired CRT and bloom shader implementations
  - Various community contributors

### Terminal

- **[Ghostty](https://ghostty.org/)** by Mitchell Hashimoto
  - The terminal emulator this theme is designed for
  - Fast, feature-rich, GPU-accelerated terminal

### Inspiration

- **The Matrix (1999)** - Warner Bros.
  - The iconic visual aesthetic and quotes
  - "Follow the white rabbit."

## License

MIT License

Copyright (c) 2025

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

---

*"There is no spoon."* - Spoon Boy
