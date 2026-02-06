#!/bin/bash
# Matrix Ghostty Setup - Cross-Platform Installation Script
# "There is no spoon."
# Supports: Linux, macOS, Windows (WSL/Git Bash)

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Detect operating system
detect_os() {
    case "$(uname -s)" in
        Linux*)
            if grep -qi microsoft /proc/version 2>/dev/null; then
                echo "wsl"
            else
                echo "linux"
            fi
            ;;
        Darwin*)
            echo "macos"
            ;;
        MINGW*|MSYS*|CYGWIN*)
            echo "windows"
            ;;
        *)
            echo "unknown"
            ;;
    esac
}

OS_TYPE=$(detect_os)
echo -e "${GREEN}Detected OS: ${OS_TYPE}${NC}"
echo -e "${GREEN}Installing Matrix Ghostty Configuration...${NC}"

# Create directories (works on all platforms)
mkdir -p ~/.config/ghostty/shaders
mkdir -p ~/.local/bin

# Copy config files
cp config ~/.config/ghostty/config
cp matrix-startup.sh ~/.config/ghostty/matrix-startup.sh
cp matrix-header.sh ~/.config/ghostty/matrix-header.sh
cp matrix-config.sh ~/.config/ghostty/matrix-config.sh
chmod +x ~/.config/ghostty/matrix-startup.sh
chmod +x ~/.config/ghostty/matrix-header.sh
chmod +x ~/.config/ghostty/matrix-config.sh
ln -sf ~/.config/ghostty/matrix-config.sh ~/.local/bin/matrix-config

# Copy user configuration (don't overwrite if exists)
if [ ! -f ~/.config/ghostty/matrix.conf ]; then
    cp matrix.conf ~/.config/ghostty/matrix.conf
    echo -e "${GREEN}Created user configuration: ~/.config/ghostty/matrix.conf${NC}"
else
    echo -e "${YELLOW}User configuration exists, skipping: ~/.config/ghostty/matrix.conf${NC}"
    echo -e "${YELLOW}To update, delete it and re-run install or merge manually.${NC}"
fi

# Copy shaders
cp shaders/*.glsl ~/.config/ghostty/shaders/

# Platform-specific setup
case "$OS_TYPE" in
    macos)
        # Symlink for macOS Ghostty app
        mkdir -p ~/Library/Application\ Support/com.mitchellh.ghostty
        ln -sf ~/.config/ghostty/config ~/Library/Application\ Support/com.mitchellh.ghostty/config
        echo -e "${GREEN}Symlinked config for macOS${NC}"

        # macOS package manager instructions
        if ! command -v cxxmatrix &> /dev/null && [ ! -f ~/.local/bin/cxxmatrix ]; then
            echo -e "${YELLOW}cxxmatrix not found. To install:${NC}"
            echo "  brew install gawk make"
            echo "  git clone https://github.com/akinomyoga/cxxmatrix /tmp/cxxmatrix"
            echo "  cd /tmp/cxxmatrix && make && cp cxxmatrix ~/.local/bin/"
        fi

        if ! command -v cmatrix &> /dev/null; then
            echo -e "${GREEN}Installing cmatrix fallback...${NC}"
            brew install cmatrix 2>/dev/null || echo "Install cmatrix: brew install cmatrix"
        fi
        ;;
    linux)
        # Linux-specific setup
        if ! command -v cxxmatrix &> /dev/null && [ ! -f ~/.local/bin/cxxmatrix ]; then
            echo -e "${YELLOW}cxxmatrix not found. To install:${NC}"
            echo "  # Debian/Ubuntu:"
            echo "  sudo apt install gawk make g++"
            echo "  git clone https://github.com/akinomyoga/cxxmatrix /tmp/cxxmatrix"
            echo "  cd /tmp/cxxmatrix && make && cp cxxmatrix ~/.local/bin/"
            echo ""
            echo "  # Arch Linux:"
            echo "  sudo pacman -S gawk make gcc"
            echo "  git clone https://github.com/akinomyoga/cxxmatrix /tmp/cxxmatrix"
            echo "  cd /tmp/cxxmatrix && make && cp cxxmatrix ~/.local/bin/"
        fi

        if ! command -v cmatrix &> /dev/null; then
            echo -e "${GREEN}Installing cmatrix fallback...${NC}"
            if command -v apt &> /dev/null; then
                sudo apt install -y cmatrix 2>/dev/null || echo "Install cmatrix: sudo apt install cmatrix"
            elif command -v pacman &> /dev/null; then
                sudo pacman -S --noconfirm cmatrix 2>/dev/null || echo "Install cmatrix: sudo pacman -S cmatrix"
            elif command -v dnf &> /dev/null; then
                sudo dnf install -y cmatrix 2>/dev/null || echo "Install cmatrix: sudo dnf install cmatrix"
            else
                echo "Install cmatrix using your package manager"
            fi
        fi
        ;;
    wsl)
        # Windows Subsystem for Linux
        echo -e "${GREEN}Detected Windows Subsystem for Linux${NC}"

        if ! command -v cxxmatrix &> /dev/null && [ ! -f ~/.local/bin/cxxmatrix ]; then
            echo -e "${YELLOW}cxxmatrix not found. To install:${NC}"
            echo "  sudo apt install gawk make g++"
            echo "  git clone https://github.com/akinomyoga/cxxmatrix /tmp/cxxmatrix"
            echo "  cd /tmp/cxxmatrix && make && cp cxxmatrix ~/.local/bin/"
        fi

        if ! command -v cmatrix &> /dev/null; then
            echo -e "${GREEN}Installing cmatrix fallback...${NC}"
            sudo apt install -y cmatrix 2>/dev/null || echo "Install cmatrix: sudo apt install cmatrix"
        fi
        ;;
    windows)
        # Git Bash / MSYS2 / Cygwin on Windows
        echo -e "${YELLOW}Windows detected (Git Bash/MSYS2/Cygwin)${NC}"
        echo -e "${YELLOW}Note: Some features may be limited on native Windows.${NC}"
        echo -e "${YELLOW}For best experience, use WSL2 with Ubuntu.${NC}"

        # Windows-specific Ghostty config path (if it exists)
        APPDATA_PATH="${APPDATA:-$HOME/AppData/Roaming}"
        if [ -d "$APPDATA_PATH" ]; then
            mkdir -p "$APPDATA_PATH/com.mitchellh.ghostty"
            cp ~/.config/ghostty/config "$APPDATA_PATH/com.mitchellh.ghostty/config" 2>/dev/null || true
            echo -e "${GREEN}Copied config to Windows AppData${NC}"
        fi
        ;;
    *)
        echo -e "${YELLOW}Unknown OS. Proceeding with generic installation.${NC}"
        ;;
esac

# Detect shell and add integration
detect_shell_rc() {
    if [ -n "$ZSH_VERSION" ] || [ -f ~/.zshrc ]; then
        echo "$HOME/.zshrc"
    elif [ -n "$BASH_VERSION" ] || [ -f ~/.bashrc ]; then
        echo "$HOME/.bashrc"
    else
        echo "$HOME/.profile"
    fi
}

SHELL_RC=$(detect_shell_rc)
echo -e "${GREEN}Detected shell config: ${SHELL_RC}${NC}"

# Add shell integration if not present
if ! grep -q "matrix-startup.sh" "$SHELL_RC" 2>/dev/null; then
    echo -e "${GREEN}Adding Matrix startup to ${SHELL_RC}${NC}"
    cat >> "$SHELL_RC" << 'EOF'

# ============================================================
# THE MATRIX STARTUP (Ghostty only)
# Cross-platform: Linux, macOS, Windows (WSL/Git Bash)
# Configure in ~/.config/ghostty/matrix.conf
# ============================================================
if [[ $- == *i* ]] && [[ "$TERM_PROGRAM" == "ghostty" ]]; then
    # Load configuration
    MATRIX_CONFIG="$HOME/.config/ghostty/matrix.conf"
    MATRIX_ANIMATION_FREQUENCY="daily"
    [ -f "$MATRIX_CONFIG" ] && source "$MATRIX_CONFIG"

    # Cross-platform temp directory
    _matrix_tmp="${TMPDIR:-${TMP:-/tmp}}"

    # Determine lock file based on frequency
    case "$MATRIX_ANIMATION_FREQUENCY" in
        always)
            # Always run animation
            ~/.config/ghostty/matrix-startup.sh
            ;;
        never)
            # Only show header, never animation
            ~/.config/ghostty/matrix-header.sh
            ;;
        weekly)
            # Once per week
            _matrix_week=$(date +%Y-%W)
            _matrix_lock="${_matrix_tmp}/.matrix_week_${_matrix_week}"
            if [[ ! -f "$_matrix_lock" ]]; then
                touch "$_matrix_lock"
                ~/.config/ghostty/matrix-startup.sh
            else
                ~/.config/ghostty/matrix-header.sh
            fi
            unset _matrix_lock _matrix_week
            ;;
        daily|*)
            # Once per day (default)
            _matrix_date=$(date +%Y-%m-%d)
            _matrix_lock="${_matrix_tmp}/.matrix_${_matrix_date}"
            if [[ ! -f "$_matrix_lock" ]]; then
                touch "$_matrix_lock"
                ~/.config/ghostty/matrix-startup.sh
            else
                ~/.config/ghostty/matrix-header.sh
            fi
            unset _matrix_lock _matrix_date
            ;;
    esac
    unset _matrix_tmp MATRIX_CONFIG MATRIX_ANIMATION_FREQUENCY
fi
# ============================================================

# Matrix aliases
alias matrix='~/.config/ghostty/matrix-startup.sh'
alias matrix-demo='rm -f ${TMPDIR:-${TMP:-/tmp}}/.matrix_$(date +%Y-%m-%d) ${TMPDIR:-${TMP:-/tmp}}/.matrix_week_$(date +%Y-%W) && ~/.config/ghostty/matrix-startup.sh'
alias matrix-rain='~/.local/bin/cxxmatrix -s rain-forever 2>/dev/null || cxxmatrix -s rain-forever'
alias matrix-conway='~/.local/bin/cxxmatrix -s conway 2>/dev/null || cxxmatrix -s conway'
alias matrix-mandelbrot='~/.local/bin/cxxmatrix -s mandelbrot 2>/dev/null || cxxmatrix -s mandelbrot'
alias matrix-full='~/.local/bin/cxxmatrix -s number,banner,rain,conway,mandelbrot,loop 2>/dev/null || cxxmatrix -s number,banner,rain,conway,mandelbrot,loop'
alias matrix-custom='~/.local/bin/cxxmatrix -m 2>/dev/null || cxxmatrix -m'
alias matrix-config='~/.config/ghostty/matrix-config.sh'

# CRT shutdown animation (swap shader, animate, restore, exit)
matrix-shutdown() {
    # Only works in interactive Ghostty terminals
    if [[ "$TERM_PROGRAM" != "ghostty" ]] || [[ $- != *i* ]]; then
        builtin exit "$@"
        return
    fi

    # Check if shutdown animation is enabled
    local _conf="$HOME/.config/ghostty/matrix.conf"
    local _enabled="true"
    if [ -f "$_conf" ]; then
        _enabled=$(grep -E "^MATRIX_SHUTDOWN_ANIMATION=" "$_conf" 2>/dev/null | tail -1 | cut -d'=' -f2- | tr -d '"' | tr -d "'")
        [ -z "$_enabled" ] && _enabled="true"
    fi

    if [ "$_enabled" != "true" ]; then
        builtin exit "$@"
        return
    fi

    local _ghostty_conf="$HOME/.config/ghostty/config"
    local _shutdown_shader="$HOME/.config/ghostty/shaders/crt-shutdown.glsl"

    # Shader file must exist
    if [ ! -f "$_shutdown_shader" ] || [ ! -f "$_ghostty_conf" ]; then
        builtin exit "$@"
        return
    fi

    # Record current shader
    local _original_shader
    _original_shader=$(grep -E "^custom-shader\s*=" "$_ghostty_conf" 2>/dev/null | tail -1 | sed 's/^[^=]*=\s*//')

    # BSD/GNU sed detection
    local _sed_i
    if sed --version 2>/dev/null | grep -q GNU; then
        _sed_i="sed -i"
    else
        _sed_i="sed -i ''"
    fi

    # Swap to shutdown shader (triggers hot-reload)
    if grep -qE "^custom-shader\s*=" "$_ghostty_conf" 2>/dev/null; then
        eval "$_sed_i" "'s|^custom-shader *=.*|custom-shader = $_shutdown_shader|'" "$_ghostty_conf"
    else
        echo "custom-shader = $_shutdown_shader" >> "$_ghostty_conf"
    fi

    # Wait for animation (1.6s + buffer)
    sleep 2

    # Restore original shader
    if [ -n "$_original_shader" ]; then
        eval "$_sed_i" "'s|^custom-shader *=.*|custom-shader = $_original_shader|'" "$_ghostty_conf"
    else
        eval "$_sed_i" "'/^custom-shader *=/d'" "$_ghostty_conf"
    fi

    builtin exit "$@"
}

alias matrix-off='matrix-shutdown'

# Opt-in: wrap 'exit' to trigger shutdown animation
if [[ "$TERM_PROGRAM" == "ghostty" ]] && [[ $- == *i* ]]; then
    _matrix_conf="$HOME/.config/ghostty/matrix.conf"
    _matrix_exit_enabled="false"
    if [ -f "$_matrix_conf" ]; then
        _matrix_exit_enabled=$(grep -E "^MATRIX_SHUTDOWN_ON_EXIT=" "$_matrix_conf" 2>/dev/null | tail -1 | cut -d'=' -f2- | tr -d '"' | tr -d "'")
    fi
    if [ "$_matrix_exit_enabled" = "true" ]; then
        exit() { matrix-shutdown "$@"; }
    fi
    unset _matrix_conf _matrix_exit_enabled
fi
EOF
fi

# Upgrade: add matrix-shutdown if shell integration exists but function is missing
if grep -q "matrix-startup.sh" "$SHELL_RC" 2>/dev/null && ! grep -q "matrix-shutdown" "$SHELL_RC" 2>/dev/null; then
    echo -e "${GREEN}Upgrading shell integration with shutdown function...${NC}"
    cat >> "$SHELL_RC" << 'SHUTDOWN_EOF'

# CRT shutdown animation (swap shader, animate, restore, exit)
matrix-shutdown() {
    if [[ "$TERM_PROGRAM" != "ghostty" ]] || [[ $- != *i* ]]; then
        builtin exit "$@"
        return
    fi
    local _conf="$HOME/.config/ghostty/matrix.conf"
    local _enabled="true"
    if [ -f "$_conf" ]; then
        _enabled=$(grep -E "^MATRIX_SHUTDOWN_ANIMATION=" "$_conf" 2>/dev/null | tail -1 | cut -d'=' -f2- | tr -d '"' | tr -d "'")
        [ -z "$_enabled" ] && _enabled="true"
    fi
    if [ "$_enabled" != "true" ]; then
        builtin exit "$@"
        return
    fi
    local _ghostty_conf="$HOME/.config/ghostty/config"
    local _shutdown_shader="$HOME/.config/ghostty/shaders/crt-shutdown.glsl"
    if [ ! -f "$_shutdown_shader" ] || [ ! -f "$_ghostty_conf" ]; then
        builtin exit "$@"
        return
    fi
    local _original_shader
    _original_shader=$(grep -E "^custom-shader\s*=" "$_ghostty_conf" 2>/dev/null | tail -1 | sed 's/^[^=]*=\s*//')
    local _sed_i
    if sed --version 2>/dev/null | grep -q GNU; then
        _sed_i="sed -i"
    else
        _sed_i="sed -i ''"
    fi
    if grep -qE "^custom-shader\s*=" "$_ghostty_conf" 2>/dev/null; then
        eval "$_sed_i" "'s|^custom-shader *=.*|custom-shader = $_shutdown_shader|'" "$_ghostty_conf"
    else
        echo "custom-shader = $_shutdown_shader" >> "$_ghostty_conf"
    fi
    sleep 2
    if [ -n "$_original_shader" ]; then
        eval "$_sed_i" "'s|^custom-shader *=.*|custom-shader = $_original_shader|'" "$_ghostty_conf"
    else
        eval "$_sed_i" "'/^custom-shader *=/d'" "$_ghostty_conf"
    fi
    builtin exit "$@"
}
alias matrix-off='matrix-shutdown'
if [[ "$TERM_PROGRAM" == "ghostty" ]] && [[ $- == *i* ]]; then
    _matrix_conf="$HOME/.config/ghostty/matrix.conf"
    _matrix_exit_enabled="false"
    if [ -f "$_matrix_conf" ]; then
        _matrix_exit_enabled=$(grep -E "^MATRIX_SHUTDOWN_ON_EXIT=" "$_matrix_conf" 2>/dev/null | tail -1 | cut -d'=' -f2- | tr -d '"' | tr -d "'")
    fi
    if [ "$_matrix_exit_enabled" = "true" ]; then
        exit() { matrix-shutdown "$@"; }
    fi
    unset _matrix_conf _matrix_exit_enabled
fi
SHUTDOWN_EOF
fi

echo ""
echo -e "${GREEN}Installation complete!${NC}"
echo ""
echo "Platform: $OS_TYPE"
echo ""
echo "Configuration:"
echo "  matrix-config - Interactive configuration menu"
echo "  Presets: Full 1999 CRT, CRT Lite, Phosphor Bloom, Subtle, Clean"
echo ""
echo "Commands:"
echo "  matrix        - Run the full startup sequence"
echo "  matrix-demo   - Reset lock and re-trigger animation"
echo "  matrix-rain   - Endless falling code"
echo "  matrix-off    - CRT shutdown animation + exit"
echo "  matrix-config - Interactive configuration (shader, animation, more)"
echo ""
echo "Next steps:"
echo "  1. Restart Ghostty (close all windows, then reopen)"
echo "  2. Enjoy the Matrix!"
echo ""
echo "The animation runs based on your configured frequency (default: daily)."
echo "Subsequent terminals show the header with a random quote."
