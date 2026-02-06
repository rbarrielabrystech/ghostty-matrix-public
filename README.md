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

## Terminal Eras — Time Machine

Transform your terminal into any classic computer from the 1940s to 2000. Each era is a living, interactive experience — you don't just read about punch cards, you punch them.

Access via `matrix-config` > `e) Terminal Eras...`.

### How It Works

When you select an era, four things change simultaneously:

1. **Color palette** — All 16 ANSI colors, background, foreground, and cursor are set to match the original hardware. The Commodore 64 gets its Pepto-measured blue palette. The VT100 gets green phosphor. The ZX Spectrum gets its 8+8 bright/normal scheme.

2. **CRT shader** — Early terminals get the `retro-crt.glsl` shader with the correct phosphor color (green for VT100/Apple II, amber for VT220, white for TRS-80). Color systems like the C64 get CRT effects without phosphor tinting. Pre-CRT machines (punch cards, teletypes) get no shader at all — they didn't have screens.

3. **Boot message** — Every new terminal window displays the exact startup text you'd see powering on the real machine. The C64 shows `**** COMMODORE 64 BASIC V2 ****` / `64K RAM SYSTEM  38911 BASIC BYTES FREE`. The Linux era boots through LILO with kernel messages and BogoMIPS calibration.

4. **Interactive simulation** (optional) — With interactive mode enabled, the era's simulator launches automatically. A working BASIC interpreter, a functional punch card machine, a real Enigma cipher — not mockups, but actual implementations you can use.

### Quick Start

```bash
matrix-config          # Open configuration TUI
                       # Press 'e' for Terminal Eras
                       # Select a category (1-9)
                       # Pick an era
                       # Press 'i' to toggle interactive mode
```

Or launch an era boot directly:

```bash
matrix-era             # Show current era's boot sequence
```

To return to the default Matrix theme, press `m` in the Terminal Eras menu.

### All 30 Eras

#### WWII Computing (1940s)

| # | Era | Simulation | Description |
|---|-----|-----------|-------------|
| 1 | **Enigma Machine** | Rotor encryption | Authentic M3 with 5 rotors, reflector B, plugboard, real-time stepping |
| 2 | **Colossus** | Boot message | Bletchley Park's codebreaking computer, vacuum tube status display |

#### Pre-CRT Era (1950s-1960s)

| # | Era | Simulation | Description |
|---|-----|-----------|-------------|
| 3 | **IBM Punch Card** | Keypunch + reader | 80-column Hollerith encoding, card deck, JCL job processing |
| 4 | **Teletype ASR-33** | 110 baud teletype | 10 chars/sec output, uppercase only, paper tape punching |
| 5 | **Line Printer** | Boot message | IBM 1403 greenbar output aesthetic |

#### Mainframes (1960s-1970s)

| # | Era | Simulation | Description |
|---|-----|-----------|-------------|
| 6 | **IBM 3270** | Block-mode terminal | TSO login, ISPF panels, dataset lists, PF keys |
| 7 | **IBM System/360** | Boot message | Mainframe IPL sequence with channel status |
| 8 | **DEC PDP-8** | Front panel | 12-bit octal, LED display, toggle switches, memory examine/deposit |

#### Early Terminals (1970s)

| # | Era | Simulation | Description |
|---|-----|-----------|-------------|
| 9 | **DEC VT100** | Unix shell | Green phosphor CRT, BSD 4.2 on a PDP-11/70 |
| 10 | **DEC VT220** | Unix shell | Amber phosphor CRT, VAX/VMS 4.7 |
| 11 | **Altair 8800** | Front panel | 16-bit address, 8-bit data, "Kill the Bit" game included |

#### Home Computers (1977-1985)

| # | Era | Simulation | Description |
|---|-----|-----------|-------------|
| 12 | **Apple II** | BASIC interpreter | Applesoft BASIC, green phosphor, uppercase-only mode |
| 13 | **Commodore PET** | BASIC interpreter | Commodore BASIC, `*** COMMODORE BASIC ***` / `31743 BYTES FREE` |
| 14 | **TRS-80** | BASIC interpreter | Radio Shack Level II BASIC, white phosphor CRT |
| 15 | **Commodore 64** | BASIC interpreter | BASIC V2, authentic Pepto palette, blue-on-blue |
| 16 | **ZX Spectrum** | BASIC interpreter | Sinclair BASIC with keyword entry (P=PRINT, G=GOTO) |
| 17 | **BBC Micro** | BASIC interpreter | BBC BASIC, `BBC Computer 32K` / `Acorn DFS` |
| 18 | **Amstrad CPC** | BASIC interpreter | Locomotive BASIC, yellow-on-blue |
| 19 | **MSX** | BASIC interpreter | MSX-BASIC 1.0, white-on-blue, Microsoft copyright |
| 20 | **Atari 800** | BASIC interpreter | Atari BASIC |
| 21 | **Commodore Amiga** | Unix shell | AmigaDOS 3.1 / Workbench 3.1, blue/orange palette |

#### IBM PC Era (1981-1995)

| # | Era | Simulation | Description |
|---|-----|-----------|-------------|
| 22 | **IBM MDA** | DOS prompt | Monochrome Display Adapter, green phosphor, DOS 3.30 |
| 23 | **IBM CGA** | DOS prompt | Color Graphics Adapter, 16-color palette |
| 24 | **MS-DOS** | DOS prompt | MS-DOS 6.22, HIMEM, full command set |

#### Professional Unix (1985-1998)

| # | Era | Simulation | Description |
|---|-----|-----------|-------------|
| 25 | **Sun Solaris** | Unix shell | SunOS 5.6 on SPARCstation, CDE-era |
| 26 | **SGI IRIX** | Unix shell | IRIX 6.5 on an Octane workstation |
| 27 | **NeXT** | Unix shell | NeXTSTEP 3.3, grayscale aesthetic |

#### BBS & Online (1985-1997)

| # | Era | Simulation | Description |
|---|-----|-----------|-------------|
| 28 | **BBS Terminal** | Full BBS | Modem dial-up, ANSI art, message boards, door games |

#### Modern (1995-2000)

| # | Era | Simulation | Description |
|---|-----|-----------|-------------|
| 29 | **Early Linux** | Unix shell | Slackware 3.6, LILO boot, kernel 2.0.36, BogoMIPS |
| 30 | **Windows 98** | DOS prompt | Microsoft Windows 98 command prompt |

### Interactive Simulators

Each simulator is a self-contained bash script that recreates the authentic experience of using the original hardware.

#### IBM 029 Keypunch (`era-punchcard.sh`)

A real punch card machine. Type characters and watch Hollerith punch patterns appear on an 80-column, 12-row card in real time. The encoding is authentic — `A` punches rows 12+1, `Z` punches rows 0+9, just like the real IBM 029.

- **Type** any character to punch it onto the card
- **Ctrl-R** (REL) — Release current card to the deck, feed a new blank card
- **Ctrl-D** (DUP) — Duplicate the previous card
- **Ctrl-S** (SUBMIT) — Feed the entire deck through the card reader
- **JCL support** — Cards starting with `//` are processed as Job Control Language
- **Greenbar output** — Job results printed on alternating green/white paper

```
╔══════════════════════════════════════════════════════════════╗
║ IBM 029 KEYPUNCH                              COLUMN: 06    ║
╠══════════════════════════════════════════════════════════════╣
║ CARD: HELLO _                                               ║
║ 12: □□■□□ □□□□□ □□□□□ □□□□□ ...                            ║
║ 11: □□□□□ □□□□□ □□□□□ □□□□□ ...                            ║
║  0: □□□□□ ■□□□□ □□□□□ □□□□□ ...                            ║
║  1: □□□□□ □□□□□ □□□□□ □□□□□ ...                            ║
║  ...                                                         ║
╚══════════════════════════════════════════════════════════════╝
```

#### Enigma M3 Cipher Machine (`era-enigma.sh`)

A cryptographically accurate simulation of the Wehrmacht Enigma M3. Configure the machine exactly as a real operator would — select three rotors from five (I-V), set ring positions, choose starting positions, and wire plugboard pairs. Then type plaintext to encrypt.

- **Real rotor wirings** — All five Enigma I/M3 rotor wiring tables, Reflector B
- **Rotor stepping** — Correct turnover behavior including double-stepping
- **No letter encrypts to itself** — The fundamental Enigma property, enforced by the reflector
- **Reciprocal encryption** — Type ciphertext with the same settings to decrypt
- **5-letter groups** — Output formatted in the standard military format
- **Plugboard** — Up to 13 letter-pair swaps

#### Front Panel — Altair 8800 / PDP-8 / IMSAI 8080 (`era-frontpanel.sh`)

An ASCII-art front panel with blinking LEDs and toggle switches. Three machines available:

- **Altair 8800** — 16-bit address, 8-bit data, the machine that launched the microcomputer revolution
- **PDP-8** — 12-bit address, 12-bit data, DEC's iconic minicomputer
- **IMSAI 8080** — The Altair's competitor, as seen in *WarGames*

Toggle switches with number keys 0-7, then use commands to interact:

| Key | Command | Description |
|-----|---------|-------------|
| E | Examine | Read memory at current address |
| D | Deposit | Store switch value at current address |
| N | Deposit Next | Advance address, then deposit |
| R | Run | Execute from current address (LEDs animate) |
| S | Stop | Halt execution |
| L | Load Address | Set address register from switches |
| P | Load Program | Choose a pre-built program |
| K | Kill the Bit | Launch the classic front-panel game |

#### BASIC Interpreter (`era-basic.sh`)

A real BASIC interpreter implemented in bash, configured per-era to match 9 different home computers. This isn't a mockup — it parses, stores, and executes BASIC programs.

**Supported statements:** `PRINT`, `LET`, `IF...THEN`, `GOTO`, `FOR...NEXT`, `INPUT`, `REM`, `END`, `GOSUB`, `RETURN`

**Commands:** `RUN`, `LIST`, `NEW`, `CLR`, `LOAD`, `SAVE`, `QUIT`

**Functions:** `INT()`, `RND()`, `ABS()`, `LEN()`, `LEFT$()`, `RIGHT$()`, `MID$()`, `CHR$()`, `ASC()`

**Variables:** Numeric (`A`-`Z`, `A0`-`Z9`) and string (`A$`-`Z$`)

Per-era differences:

| Era | Prompt | Boot Banner | Special |
|-----|--------|-------------|---------|
| Apple II | `]` | `APPLE ][` / `*APPLE II BASIC*` | Uppercase only |
| PET | `READY.` | `*** COMMODORE BASIC ***` | |
| TRS-80 | `READY` / `>` | `RADIO SHACK LEVEL II BASIC` | Uppercase only |
| C64 | `READY.` | `**** COMMODORE 64 BASIC V2 ****` | |
| ZX Spectrum | `K>` | `(c) 1982 Sinclair Research Ltd` | Single-key keywords (P=PRINT) |
| BBC Micro | `>` | `BBC Computer 32K` / `BASIC` | |
| Amstrad CPC | `Ready` | `Locomotive BASIC 1.0` | |
| MSX | `Ok` | `MSX BASIC version 1.0` | |
| Atari 800 | `READY` | (minimal) | |

Example session:
```
**** COMMODORE 64 BASIC V2 ****
64K RAM SYSTEM  38911 BASIC BYTES FREE

READY.
10 FOR I=1 TO 5
20 PRINT I*I
30 NEXT I
RUN
1
4
9
16
25

READY.
```

#### DOS Prompt (`era-dos.sh`)

A virtual DOS environment with an in-memory filesystem. Three variants: IBM PC DOS 3.30 (for MDA/CGA eras), MS-DOS 6.22, and Windows 98.

**Commands:** `DIR`, `CD`, `TYPE`, `COPY`, `DEL`, `REN`, `MKDIR`, `RMDIR`, `CLS`, `VER`, `DATE`, `TIME`, `MEM`, `TREE`, `HELP`, `ECHO`, `EXIT`

Pre-populated filesystem:
```
C:\
├── AUTOEXEC.BAT      (viewable with TYPE)
├── CONFIG.SYS        (viewable with TYPE)
├── COMMAND.COM
├── DOS\
│   ├── EDIT.COM, FORMAT.COM, FDISK.EXE
│   ├── HIMEM.SYS, EMM386.EXE, DOSKEY.COM
│   └── MEM.EXE, CHKDSK.EXE, XCOPY.EXE
├── GAMES\
│   ├── DOOM.EXE, WOLF3D.EXE, PRINCE.EXE
├── WINDOWS\
└── UTILS\
```

#### BBS Terminal (`era-bbs.sh`)

The complete 1990s dial-up BBS experience:

1. **Modem connection** — `ATDT 555-0199` → `RING...` → `CONNECT 14400/ARQ/V.32bis/LAPM`
2. **ANSI art welcome screen** — Colorful ASCII art banner
3. **Login** — Handle and password prompt
4. **Main menu** — Navigate with single-key commands:
   - **(M)** Message Bases — Read and post messages
   - **(F)** File Areas — Browse files with download progress bars
   - **(D)** Door Games — Play "Dragon's Lair" text adventure
   - **(W)** Who's Online — See connected users
   - **(S)** Your Stats — Call count, messages posted, files downloaded
   - **(C)** Chat with SysOp
   - **(G)** Goodbye — `NO CARRIER` disconnect
5. **Time limit** — "Time Left: 45 min" countdown in status bar

#### IBM 3270 Block-Mode Terminal (`era-3270.sh`)

A TSO/ISPF mainframe experience circa 1990s:

- **TSO Login** — `IKJ56700A ENTER USERID` prompt with RACF authentication fields
- **ISPF Primary Option Menu** — Settings, View, Edit, Utilities, Batch, Command, Tutorial
- **Utilities Panel** — Library, Dataset, Move/Copy, Dslist
- **Dataset List** — Browse `USERID.*` datasets (JCL, COBOL.SOURCE, LOAD, etc.)
- **TSO Command Shell** — Enter commands: `TIME`, `LISTCAT`, `STATUS`, `SEND`, `HELP`, `LOGOFF`
- **Status line** — System name, clock, `COMMAND ===>` prompt at bottom

#### Classic Unix Shell (`era-unix.sh`)

A simulated Unix login with per-era personality. Virtual filesystem with `/home/user`, `/etc`, `/usr/bin`, `/var/log`, and pre-populated config files.

**Commands:** `ls` (with `-l`, `-la`), `cat`, `cd`, `pwd`, `who`, `date`, `uname` (`-a`), `man`, `ps` (`-ef`), `df` (`-h`), `uptime`, `hostname`, `echo`, `clear`, `exit`

7 variants, each with authentic boot sequence, MOTD, and prompt:

| Variant | Host | System | Prompt |
|---------|------|--------|--------|
| VT100 | `pdp11` | BSD 4.2 | `% ` |
| VT220 | `vax780` | VAX/VMS 4.7 | `$ ` |
| Solaris | `sunbox` | SunOS 5.6 | `sunbox% ` |
| IRIX | `octane` | IRIX64 6.5 | `octane% ` |
| NeXT | `next` | NeXTSTEP 3.3 | `next:~> ` |
| Amiga | `amiga` | AmigaOS 3.1 | `1.RAM:> ` |
| Linux | `linux` | Linux 2.0.36 | `user@linux:~$ ` |

The Linux variant boots through LILO with full kernel messages. The Solaris variant shows the SunOS copyright. The Amiga variant supports `DIR` as an alias for `ls`.

#### Teletype ASR-33 (`era-teletype.sh`)

A Model 33 teletype at 110 baud — every character printed with a ~100ms delay, simulating the mechanical print head. All output is uppercase. Includes BASIC mode (launches `era-basic.sh` in teletype mode) and a standalone command mode with paper tape punching.

### Era Settings

| Setting | Options | Default | Description |
|---------|---------|---------|-------------|
| `MATRIX_ERA` | era ID or empty | `""` | Current terminal era (empty = Matrix theme) |
| `MATRIX_ERA_INTERACTIVE` | true, false | `false` | Launch interactive simulation on new terminal |

Set via the TUI or directly in `~/.config/ghostty/matrix.conf`.

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
