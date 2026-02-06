# Ghostty Matrix Theme

A Matrix-inspired terminal theme for Ghostty with authentic 1999 aesthetics.

**Cross-platform:** Linux, macOS, Windows (WSL/Git Bash)

## Components

### Shaders
- **bloom.glsl** - Phosphor glow effect (recommended, readable)
- **matrix-glow.glsl** - Subtle green glow variant
- **crt.glsl** - CRT scanlines only (no curvature)
- **crt-full.glsl** - Full 1999 CRT (curvature + scanlines + shadow mask + vignette + optional noise/jitter/interlace/halation)
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
```

## Config Locations
- Ghostty config: `~/.config/ghostty/config`
- Matrix settings: `~/.config/ghostty/matrix.conf`
- Shaders: `~/.config/ghostty/shaders/`
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
