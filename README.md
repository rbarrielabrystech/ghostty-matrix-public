# Matrix Ghostty Theme

High-fidelity Matrix (1999) terminal setup for [Ghostty](https://ghostty.org/).

![Matrix Theme Demo](https://raw.githubusercontent.com/rbarrielabrystech/ghostty-matrix-public/main/demo.gif)

[Watch full demo on YouTube](https://www.youtube.com/watch?v=BE-xdpNpspE)

**Cross-platform:** Linux, macOS, Windows (WSL/Git Bash)

## Features

- **Authentic Matrix rain** using [cxxmatrix](https://github.com/akinomyoga/cxxmatrix) with half-width katakana
- **Movie-accurate startup sequence**: number fall → rain → "WAKE UP NEO" banner → "Follow the white rabbit."
- **CRT shader effects**: scanlines + phosphor bloom
- **Phosphor-green color scheme** with accurate `#0d0208` background
- **Fully configurable**: animation frequency, colors, quotes, and more
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

All settings are configurable via `~/.config/ghostty/matrix.conf`:

```bash
# Edit configuration
matrix-config

# Or manually
nano ~/.config/ghostty/matrix.conf
```

### Key Settings

| Setting | Options | Default | Description |
|---------|---------|---------|-------------|
| `MATRIX_ANIMATION_FREQUENCY` | daily, weekly, always, never | daily | How often to run animation |
| `MATRIX_ANIMATION_DURATION` | seconds | 8 | Duration of matrix rain |
| `MATRIX_SHOW_TEXT_SEQUENCE` | true, false | true | Show "Wake up, Neo..." |
| `MATRIX_SHOW_QUOTE` | true, false | true | Show random Matrix quote |
| `MATRIX_ALLOW_SKIP` | true, false | true | Allow skipping with keypress |
| `MATRIX_CUSTOM_QUOTES` | pipe-separated | "" | Add your own quotes |

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
matrix              # Run full startup sequence
matrix-demo         # Reset lock and re-trigger animation
matrix-rain         # Endless katakana rain
matrix-conway       # Conway's Game of Life
matrix-mandelbrot   # Mandelbrot fractal zoom
matrix-full         # All scenes in a loop
matrix-config       # Edit configuration
```

## Shaders

Located in `shaders/`:

| Shader | Description | CPU Usage |
|--------|-------------|-----------|
| `bloom.glsl` | Phosphor glow effect (recommended) | Low |
| `matrix-glow.glsl` | Subtle green glow | Low |
| `crt.glsl` | Full CRT with scanlines | Medium |

To change shader, edit `~/.config/ghostty/config`:
```bash
custom-shader = ~/.config/ghostty/shaders/bloom.glsl
```

To disable shaders, comment out the line:
```bash
# custom-shader = ...
```

## File Structure

```
~/.config/ghostty/
├── config                # Ghostty terminal config
├── matrix.conf           # Matrix theme settings
├── matrix-startup.sh     # Full animation script
├── matrix-header.sh      # Header-only script
└── shaders/
    ├── bloom.glsl        # Phosphor bloom
    ├── crt.glsl          # CRT scanlines
    └── matrix-glow.glsl  # Green glow

~/.local/bin/
└── cxxmatrix             # Matrix rain binary
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
