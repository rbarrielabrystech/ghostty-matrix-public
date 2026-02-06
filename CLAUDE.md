# Ghostty Matrix Theme

A Matrix-inspired terminal theme for Ghostty with authentic 1999 aesthetics.

**Cross-platform:** Linux, macOS, Windows (WSL/Git Bash)

## Components

### Shaders
- **bloom.glsl** - Phosphor glow effect (recommended, readable)
- **matrix-glow.glsl** - Subtle green glow variant
- **crt.glsl** - CRT scanlines only (no curvature)
- **crt-full.glsl** - Full 1999 CRT (curvature + scanlines + shadow mask + vignette + optional noise/jitter/interlace/halation)
- **retro-crt.glsl** - Configurable CRT with switchable phosphor (green/amber/white/color) for Terminal Eras
- **crt-shutdown.glsl** - CRT power-down animation (brightness spike + collapse + phosphor afterglow)

### cxxmatrix
High-fidelity Matrix rain animation from https://github.com/akinomyoga/cxxmatrix

**Location:** `~/.local/bin/cxxmatrix`

**Startup settings (configurable in matrix.conf):**
- `--frame-rate=60` (smooth animation)
- `--diffuse` (background glow)
- `--twinkle` (brightness fluctuations)

### Shell Aliases
```bash
matrix            # Full startup sequence
matrix-rain       # Endless falling code (hi-fi)
matrix-conway     # Conway's Game of Life
matrix-mandelbrot # Mandelbrot fractal
matrix-full       # Complete show (all modes)
matrix-demo       # Reset lock and re-trigger
matrix-off        # CRT shutdown animation + exit
matrix-config     # Interactive configuration menu
matrix-era        # Launch current era boot sequence
```

## Config Locations
- Ghostty config: `~/.config/ghostty/config`
- Matrix settings: `~/.config/ghostty/matrix.conf`
- Shaders: `~/.config/ghostty/shaders/`
- Era scripts: `~/.config/ghostty/eras/`
- Interactive config: `~/.config/ghostty/matrix-config.sh`
- Startup script: `~/.config/ghostty/matrix-startup.sh` (animation)
- Header script: `~/.config/ghostty/matrix-header.sh` (quote/status)
- Shell integration: `~/.zshrc` or `~/.bashrc`

## Presets (via matrix-config)
- **Full 1999 CRT** - crt-full.glsl, curvature, scanlines, shadow mask, solid BG, thick font, noise + interlace enabled
- **CRT Lite** - crt.glsl, scanlines only, no curvature
- **Phosphor Bloom** - bloom.glsl, soft glow (recommended default)
- **Subtle Glow** - matrix-glow.glsl, minimal effect
- **Clean Terminal** - no shader, just Matrix colors

## Key Settings (matrix.conf)
- `MATRIX_ANIMATION_FREQUENCY` - daily, weekly, always, never
- `MATRIX_ANIMATION_DURATION` - seconds (default: 8)
- `MATRIX_SHOW_TEXT_SEQUENCE` - true/false
- `MATRIX_SHOW_QUOTE` - true/false
- `MATRIX_CUSTOM_QUOTES` - pipe-separated custom quotes
- `MATRIX_ALLOW_SKIP` - true/false
- `MATRIX_SHUTDOWN_ANIMATION` - true/false (CRT power-down on matrix-off)
- `MATRIX_SHUTDOWN_ON_EXIT` - true/false (auto-trigger on exit)
- `MATRIX_CRT_NOISE` - true/false (static noise, crt-full only)
- `MATRIX_CRT_JITTER` - true/false (horizontal jitter, crt-full only)
- `MATRIX_CRT_INTERLACE` - true/false (interlacing, crt-full only)
- `MATRIX_CRT_HALATION` - true/false (enhanced halation, crt-full only)
- `MATRIX_ERA` - current terminal era (empty = default Matrix theme)
- `MATRIX_ERA_INTERACTIVE` - true/false (launch interactive simulation on new terminal)

## Terminal Eras

30 historical computer eras accessible via `matrix-config` > Terminal Eras. Each era sets:
- **Color palette** - Authentic 16-color ANSI palette + bg/fg/cursor
- **Shader** - CRT phosphor variant (green/amber/white) or none
- **Boot message** - Authentic startup text
- **Interactive script** - Optional simulation (BASIC shell, punch card, Enigma, etc.)

### Era Categories
- **WWII (1940s)**: Enigma Machine, Colossus
- **Pre-CRT (1950s-60s)**: IBM Punch Card, Teletype ASR-33, Line Printer
- **Mainframes (1960s-70s)**: IBM 3270, System/360, PDP-8
- **Early Terminals (1970s)**: VT100, VT220, Altair 8800
- **Home Computers (1977-85)**: Apple II, PET, TRS-80, C64, Spectrum, BBC, Amstrad, MSX, Atari 800, Amiga
- **IBM PC (1981-95)**: MDA, CGA, MS-DOS
- **Professional (1985-98)**: Solaris, IRIX, NeXT
- **BBS (1985-97)**: Dial-up BBS terminal
- **Modern (1995-2000)**: Early Linux, Windows 98

### Interactive Scripts
- `eras/era-lib.sh` - Shared library (slow_type, ANSI helpers, input helpers)
- `eras/era-boot.sh` - Era boot sequence display
- `eras/era-punchcard.sh` - IBM 029 keypunch + card reader simulator
- `eras/era-enigma.sh` - Enigma M3 rotor machine simulator
- `eras/era-frontpanel.sh` - Altair 8800 / PDP-8 front panel simulator
- `eras/era-basic.sh` - Universal BASIC interpreter (9 home computers)
- `eras/era-dos.sh` - DOS prompt simulator (DIR, CD, TYPE, etc.)
- `eras/era-bbs.sh` - BBS terminal (ANSI art, messages, door games)
- `eras/era-teletype.sh` - ASR-33 teletype (10 cps, uppercase)
- `eras/era-3270.sh` - IBM 3270 block-mode forms + ISPF panels
- `eras/era-unix.sh` - Classic Unix login + shell (VT100, Solaris, IRIX, etc.)

## Ghostty Config
- `custom-shader = bloom.glsl` - Active shader
- `background = #0d0208` - Near-black with slight tint
- `foreground = #00FF41` - Matrix green
- `font-thicken = true` - Phosphor stroke effect

## Animation Schedule
- **Animation** (cxxmatrix): Runs based on `MATRIX_ANIMATION_FREQUENCY`
- **Header** (system info + quote): Runs on subsequent terminal windows

Lock file location (cross-platform): `$TMPDIR/.matrix_YYYY-MM-DD` or `$TMP/.matrix_YYYY-MM-DD` or `/tmp/.matrix_YYYY-MM-DD`

To re-trigger animation: `matrix-demo` or delete lock file and open new window.

## Startup Sequence

1. Matrix rain animation (cxxmatrix)
2. "Wake up, Neo..." typing effect
3. "Follow the white rabbit."
4. "Knock, knock, Neo."
5. System breach header
6. Random Matrix quote
