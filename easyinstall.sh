#!/bin/bash

# EasyInstall - A robust system setup script
# Author: Maninder
# Version: 0.2.1

VERSION="0.2.1"
PROJECT_NAME="easyinstall"
PROJECT_URL="https://github.com/Maninder-mike/$PROJECT_NAME"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default settings
DRY_RUN=false
INTERACTIVE=true
INSTALL_DEV=true
INSTALL_MEDIA=true
INSTALL_SYSTEM=true

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Options:
  -h, --help       Show this help message
  -v, --version    Show version
  -d, --dry-run    Show commands without executing them
  -y, --yes        Auto-confirm installation (non-interactive)
  --no-dev         Skip development tools
  --no-media       Skip media applications
  --no-system      Skip system utilities

Description:
  A script to install essential applications on Fedora, Debian/Ubuntu, Arch Linux, and macOS.
EOF
}

detect_os() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "macos"
    elif [ -f /etc/os-release ]; then
        . /etc/os-release
        echo "$ID"
    else
        echo "unknown"
    fi
}

get_packages() {
    local os=$1
    local category=$2
    
    case $os in
        debian|ubuntu|pop)
            case $category in
                dev) echo "git nodejs npm python3 python3-pip neovim vifm sqlite3" ;;
                media) echo "vlc ubuntu-restricted-extras" ;;
                system) echo "fish terminator tlp tlp-rdw gnome-tweak-tool" ;;
            esac
            ;;
        fedora)
            case $category in
                dev) echo "git nodejs npm golang sqlite sqlite-devel" ;;
                media) echo "vlc" ;;
                system) echo "fish tlp tlp-rdw" ;;
            esac
            ;;
        arch|manjaro)
            case $category in
                dev) echo "git go nodejs npm neovim vifm base-devel sqlite sqlitebrowser" ;;
                media) echo "vlc" ;;
                system) echo "tlp tlp-rdw numlockx xscreensaver cups networkmanager" ;;
            esac
            ;;
        macos)
            case $category in
                dev) echo "git nodejs npm neovim vifm python3 go" ;;
                media) echo "vlc" ;;
                system) echo "fish" ;;
            esac
            ;;
    esac
}

execute_cmd() {
    if [ "$DRY_RUN" = true ]; then
        echo "[DRY-RUN] $*"
    else
        eval "$@"
    fi
}

install_packages() {
    local os=$1
    local category=$2
    local pkgs=$(get_packages "$os" "$category")

    if [ -z "$pkgs" ]; then
        return
    fi

    case $os in
        debian|ubuntu|pop)
            log_info "Installing $category packages for Debian/Ubuntu..."
            execute_cmd "sudo apt update && sudo apt install -y $pkgs"
            ;;
        fedora)
            log_info "Installing $category packages for Fedora..."
            # RPM Fusion setup for media if needed
            if [ "$category" == "media" ]; then
                    execute_cmd "sudo dnf install -y https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-\$(rpm -E %fedora).noarch.rpm https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-\$(rpm -E %fedora).noarch.rpm"
            fi
            execute_cmd "sudo dnf install -y $pkgs"
            ;;
        arch|manjaro)
            log_info "Installing $category packages for Arch..."
            execute_cmd "sudo pacman -Syu --noconfirm $pkgs"
            ;;
        macos)
            log_info "Installing $category packages for macOS..."
            if ! command -v brew &> /dev/null; then
                log_warn "Homebrew not found. Installing..."
                execute_cmd '/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'
            fi
            execute_cmd "brew install $pkgs"
            ;;
        *)
            log_error "Unsupported OS or category: $os / $category"
            ;;
    esac
}

main() {
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help) usage; exit 0 ;;
            -v|--version) echo "EasyInstall v$VERSION"; exit 0 ;;
            -d|--dry-run) DRY_RUN=true; shift ;;
            -y|--yes) INTERACTIVE=false; shift ;;
            --no-dev) INSTALL_DEV=false; shift ;;
            --no-media) INSTALL_MEDIA=false; shift ;;
            --no-system) INSTALL_SYSTEM=false; shift ;;
            *) log_error "Unknown option: $1"; usage; exit 1 ;;
        esac
    done

    local os=$(detect_os)
    log_info "Detected OS: $os"

    if [ "$os" == "unknown" ]; then
        log_error "Could not detect a supported operating system."
        exit 1
    fi

    if [ "$INTERACTIVE" = true ] && [ "$DRY_RUN" = false ]; then
        read -p "Proceed with installation on $os? [y/N] " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_warn "Installation aborted."
            exit 0
        fi
    fi

    if [ "$INSTALL_SYSTEM" = true ]; then install_packages "$os" "system"; fi
    if [ "$INSTALL_DEV" = true ]; then install_packages "$os" "dev"; fi
    if [ "$INSTALL_MEDIA" = true ]; then install_packages "$os" "media"; fi

    log_success "Installation complete!"
}

main "$@"
