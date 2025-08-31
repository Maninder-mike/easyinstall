#!/usr/bin/env bash
# ==============================================
# EasyInstall - Cross-platform bootstrap script
# Supports: Linux (Debian/Arch/Fedora), macOS (brew), Windows (winget)
# Author: Maninder Singh
# Version: 0.5.0
# Repo: https://github.com/Maninder-mike/easyinstall
# ==============================================

set -euo pipefail
IFS=$'\n\t'

VERSION="0.5.0"
PROJECT_NAME="easyinstall"
PROJECT_URL="https://github.com/Maninder-mike/${PROJECT_NAME}"

# -------------------
# Helpers
# -------------------
log()    { echo -e "[+] $*"; }
warn()   { echo -e "[!] $*" >&2; }
error()  { echo -e "[x] $*" >&2; exit 1; }

require_root() {
    if [[ $EUID -ne 0 ]]; then
        warn "Some packages may fail without root. Run with sudo if needed."
    fi
}

# -------------------
# Package Lists
# -------------------
ESSENTIAL_PACKAGES=(git curl wget htop neovim unzip tar)
DEV_PACKAGES=(nodejs npm python3 python3-pip go sqlite sqlitebrowser docker docker-compose \
              openjdk maven gradle rust cargo cmake make gcc g++ fish zsh)
MULTIMEDIA_PACKAGES=(vlc ffmpeg imagemagick pulseaudio pamixer audacity gimp inkscape)
PRODUCTIVITY_PACKAGES=(firefox chromium libreoffice thunderbird obs-studio)

SYSTEM_PACKAGES=(tlp tlp-rdw networkmanager cups terminator tmux)

# -------------------
# Linux Installers
# -------------------
install_arch() {
    log "Updating Arch system..."
    sudo pacman -Syyu --noconfirm
    sudo pacman -S --noconfirm "$@"
}

install_debian() {
    log "Updating Debian/Ubuntu system..."
    sudo apt update && sudo apt upgrade -y
    sudo apt install -y "$@"
}

install_fedora() {
    log "Updating Fedora system..."
    sudo dnf -y update
    sudo dnf install -y \
        "https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm" \
        "https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm"
    sudo dnf install -y "$@"
    [[ " $* " == *" tlp "* ]] && sudo systemctl enable tlp
}

# -------------------
# macOS Installer (brew)
# -------------------
install_brew() {
    if ! command -v brew >/dev/null 2>&1; then
        log "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        eval "$(/opt/homebrew/bin/brew shellenv)" || eval "$(/usr/local/bin/brew shellenv)"
    fi
    brew update
    brew install "$@" || true
}

# -------------------
# Windows Installer (winget)
# -------------------
install_winget() {
    if ! command -v winget >/dev/null 2>&1; then
        error "winget is not installed. Install from Microsoft Store first."
    fi
    for pkg in "$@"; do
        winget install -e --id "$pkg" || true
    done
}

# -------------------
# Distro / OS Detection
# -------------------
detect_platform() {
    case "$(uname -s)" in
        Linux*)
            if command -v dnf >/dev/null 2>&1; then echo "fedora"
            elif command -v apt >/dev/null 2>&1; then echo "debian"
            elif command -v pacman >/dev/null 2>&1; then echo "arch"
            else error "Unsupported Linux distribution."
            fi
            ;;
        Darwin*) echo "macos" ;;
        MINGW*|MSYS*|CYGWIN*) echo "windows" ;;
        *) error "Unsupported platform: $(uname -s)" ;;
    esac
}

# -------------------
# Package Groups
# -------------------
resolve_packages() {
    case "$1" in
        minimal)     PACKAGES=("${ESSENTIAL_PACKAGES[@]}") ;;
        dev)         PACKAGES=("${ESSENTIAL_PACKAGES[@]}" "${DEV_PACKAGES[@]}") ;;
        multimedia)  PACKAGES=("${ESSENTIAL_PACKAGES[@]}" "${MULTIMEDIA_PACKAGES[@]}") ;;
        full)        PACKAGES=("${ESSENTIAL_PACKAGES[@]}" "${DEV_PACKAGES[@]}" "${MULTIMEDIA_PACKAGES[@]}" "${PRODUCTIVITY_PACKAGES[@]}" "${SYSTEM_PACKAGES[@]}") ;;
        *) error "Unknown mode: $1" ;;
    esac
}

# -------------------
# Interactive Menu
# -------------------
choose_setup() {
    echo "=============================================="
    echo "   EasyInstall v$VERSION - Choose your setup"
    echo "=============================================="
    echo "1) Minimal (Essentials only)"
    echo "2) Developer setup"
    echo "3) Multimedia setup"
    echo "4) Full install (everything)"
    echo "=============================================="
    read -rp "Select option [1-4]: " choice

    case "$choice" in
        1) resolve_packages minimal ;;
        2) resolve_packages dev ;;
        3) resolve_packages multimedia ;;
        4) resolve_packages full ;;
        *) error "Invalid choice. Exiting." ;;
    esac
}

# -------------------
# Entry Point
# -------------------
main() {
    require_root
    local platform mode
    platform=$(detect_platform)

    # Non-interactive mode
    if [[ $# -gt 0 ]]; then
        case "$1" in
            --minimal)    resolve_packages minimal ;;
            --dev)        resolve_packages dev ;;
            --multimedia) resolve_packages multimedia ;;
            --full)       resolve_packages full ;;
            *) error "Unknown option: $1" ;;
        esac
    else
        choose_setup
    fi

    log "Detected platform: $platform"
    log "Installing selected packages: ${PACKAGES[*]}"

    case $platform in
        fedora)  install_fedora "${PACKAGES[@]}" ;;
        debian)  install_debian "${PACKAGES[@]}" ;;
        arch)    install_arch "${PACKAGES[@]}" ;;
        macos)   install_brew "${PACKAGES[@]}" ;;
        windows)
            WIN_PACKAGES=(
                "Git.Git"
                "Python.Python.3"
                "NodeJS.NodeJS"
                "GoLang.Go"
                "SQLite.SQLite"
                "Neovim.Neovim"
                "VideoLAN.VLC"
                "Mozilla.Firefox"
                "Microsoft.VisualStudioCode"
                "Docker.DockerDesktop"
                "GnuWin32.Make"
            )
            install_winget "${WIN_PACKAGES[@]}"
            ;;
        *) error "Unsupported platform" ;;
    esac

    log "✅ Installation completed!"
    log "Project: ${PROJECT_URL}"
}

main "$@"
