# Matrix Ghostty Theme

High-fidelity Matrix (1999) terminal setup for [Ghostty](https://ghostty.org/).

![Matrix Theme Demo](https://raw.githubusercontent.com/rbarrielabrystech/ghostty-matrix-public/main/demo.gif)

[Watch full demo on YouTube](https://www.youtube.com/watch?v=BE-xdpNpspE)

**Cross-platform:** Linux, macOS, Windows (WSL/Git Bash)

## Features

- **Authentic Matrix rain** using [cxxmatrix](https://github.com/akinomyoga/cxxmatrix) with half-width katakana
- **Movie-accurate startup sequence**: number fall → rain → "WAKE UP NEO" banner → "Follow the white rabbit."
- **Full 1999 CRT mode**: barrel distortion, scanlines, shadow mask, vignette — like sitting in front of a CRT monitor in 1999
- **4 shader effects**: CRT Full, CRT Scanlines, Phosphor Bloom, Matrix Glow
- **Interactive configuration TUI** (`matrix-config`): presets, shader picker, 18+ settings
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
| **Full 1999 CRT** | `crt-full.glsl` | Curvature + scanlines + shadow mask + vignette, solid BG, thick font |
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
matrix-rain         # Endless katakana rain
matrix-conway       # Conway's Game of Life
matrix-mandelbrot   # Mandelbrot fractal zoom
matrix-full         # All scenes in a loop
```

## Shaders

Located in `shaders/`. Switch between them via `matrix-config` or edit `~/.config/ghostty/config` directly.

| Shader | Description | Effect | CPU Usage |
|--------|-------------|--------|-----------|
| `crt-full.glsl` | Full 1999 CRT | Barrel distortion, scanlines, shadow mask, vignette | Medium |
| `crt.glsl` | CRT Scanlines | Scanlines only, no curvature | Medium |
| `bloom.glsl` | Phosphor Bloom (recommended) | Soft glow around bright text | Low |
| `matrix-glow.glsl` | Matrix Glow | Subtle green glow, minimal | Low |

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

## File Structure

```
~/.config/ghostty/
├── config                # Ghostty terminal config
├── matrix.conf           # Matrix theme settings
├── matrix-config.sh      # Interactive configuration TUI
├── matrix-startup.sh     # Full animation script
├── matrix-header.sh      # Header-only script
└── shaders/
    ├── crt-full.glsl     # Full 1999 CRT (curvature + mask)
    ├── crt.glsl          # CRT scanlines only
    ├── bloom.glsl        # Phosphor bloom (default)
    └── matrix-glow.glsl  # Subtle green glow

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

### cxxmatrix build fails?

```bash
# Ensure gawk is installed (not mawk)
which gawk
# If missing: brew install gawk / sudo apt install gawk
```

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
