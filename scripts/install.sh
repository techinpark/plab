#!/bin/bash
#
# Tokscale Team Installation Script
# 팀원들을 위한 원클릭 설치 스크립트
#
# Usage:
#   curl -fsSL https://your-internal-server/install.sh | bash
#   or
#   ./scripts/install.sh
#

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Team configuration (customize these for your team)
TEAM_SERVER_URL="${TOKSCALE_TEAM_SERVER:-}"
TEAM_NAME="${TOKSCALE_TEAM_NAME:-}"

print_banner() {
    echo -e "${BLUE}"
    echo "╔═══════════════════════════════════════════════════════════╗"
    echo "║                                                           ║"
    echo "║   ████████╗ ██████╗ ██╗  ██╗███████╗ ██████╗ █████╗ ██╗  ███████╗ ║"
    echo "║      ██║   ██╔═══██╗██║ ██╔╝██╔════╝██╔════╝██╔══██╗██║  ██╔════╝ ║"
    echo "║      ██║   ██║   ██║█████╔╝ ███████╗██║     ███████║██║  █████╗   ║"
    echo "║      ██║   ██║   ██║██╔═██╗ ╚════██║██║     ██╔══██║██║  ██╔══╝   ║"
    echo "║      ██║   ╚██████╔╝██║  ██╗███████║╚██████╗██║  ██║███████╗███████╗ ║"
    echo "║      ╚═╝    ╚═════╝ ╚═╝  ╚═╝╚══════╝ ╚═════╝╚═╝  ╚═╝╚══════╝╚══════╝ ║"
    echo "║                                                           ║"
    echo "║              Team Installation Script                     ║"
    echo "╚═══════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

check_os() {
    OS="$(uname -s)"
    ARCH="$(uname -m)"

    case "$OS" in
        Linux*)     OS_TYPE="linux";;
        Darwin*)    OS_TYPE="macos";;
        MINGW*|MSYS*|CYGWIN*) OS_TYPE="windows";;
        *)          OS_TYPE="unknown";;
    esac

    log_info "Detected OS: $OS_TYPE ($ARCH)"
}

check_bun() {
    if command -v bun &> /dev/null; then
        BUN_VERSION=$(bun --version)
        log_success "Bun is already installed (v$BUN_VERSION)"
        return 0
    else
        return 1
    fi
}

install_bun() {
    log_info "Installing Bun runtime..."

    if [ "$OS_TYPE" = "windows" ]; then
        log_info "For Windows, please run in PowerShell:"
        echo "  irm bun.sh/install.ps1 | iex"
        log_warning "After installing Bun, re-run this script."
        exit 1
    fi

    # Install Bun for Linux/macOS
    curl -fsSL https://bun.sh/install | bash

    # Add to current session
    export BUN_INSTALL="$HOME/.bun"
    export PATH="$BUN_INSTALL/bin:$PATH"

    # Verify installation
    if command -v bun &> /dev/null; then
        log_success "Bun installed successfully (v$(bun --version))"
    else
        log_error "Bun installation failed. Please install manually: https://bun.sh"
        exit 1
    fi
}

install_tokscale() {
    log_info "Installing tokscale CLI..."

    # Use bunx to install globally
    bun add -g tokscale@latest

    if command -v tokscale &> /dev/null; then
        log_success "tokscale installed successfully"
    else
        # Try with bunx as fallback
        log_warning "Global install may require PATH update. You can use: bunx tokscale"
    fi
}

setup_config() {
    log_info "Setting up configuration..."

    CONFIG_DIR="$HOME/.config/tokscale"
    SETTINGS_FILE="$CONFIG_DIR/settings.json"

    # Create config directory
    mkdir -p "$CONFIG_DIR"

    # Create default settings if not exists
    if [ ! -f "$SETTINGS_FILE" ]; then
        cat > "$SETTINGS_FILE" << 'EOF'
{
  "colorPalette": "blue",
  "includeUnusedModels": false,
  "autoRefreshEnabled": true,
  "autoRefreshMs": 60000
}
EOF
        log_success "Created default settings at $SETTINGS_FILE"
    else
        log_info "Settings file already exists, skipping..."
    fi

    # Configure team server if provided
    if [ -n "$TEAM_SERVER_URL" ]; then
        log_info "Configuring team server: $TEAM_SERVER_URL"
        # Add team server configuration
        TEAM_CONFIG_FILE="$CONFIG_DIR/team.json"
        cat > "$TEAM_CONFIG_FILE" << EOF
{
  "serverUrl": "$TEAM_SERVER_URL",
  "teamName": "$TEAM_NAME",
  "autoSubmit": false
}
EOF
        log_success "Team configuration saved"
    fi
}

setup_claude_retention() {
    log_info "Checking Claude Code session retention settings..."

    CLAUDE_CONFIG="$HOME/.claude/settings.json"

    if [ -f "$CLAUDE_CONFIG" ]; then
        # Check if cleanupPeriodDays is already set
        if grep -q "cleanupPeriodDays" "$CLAUDE_CONFIG"; then
            log_info "Claude retention already configured"
        else
            log_warning "Consider adding 'cleanupPeriodDays: 9999999999' to $CLAUDE_CONFIG"
            log_warning "This prevents automatic session cleanup for accurate tracking"
        fi
    else
        log_info "Claude Code config not found (this is normal if not using Claude Code)"
    fi
}

print_usage() {
    echo ""
    echo -e "${GREEN}Installation complete!${NC}"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo -e "${BLUE}Quick Start:${NC}"
    echo "  tokscale              # Launch TUI dashboard"
    echo "  tokscale --light      # Table view"
    echo "  tokscale --today      # Today's usage"
    echo "  tokscale --week       # This week's usage"
    echo ""
    echo -e "${BLUE}Team Commands:${NC}"
    echo "  tokscale login        # Login with GitHub"
    echo "  tokscale submit       # Submit to team leaderboard"
    echo "  tokscale models       # Detailed model breakdown"
    echo ""
    echo -e "${BLUE}Configuration:${NC}"
    echo "  Settings: ~/.config/tokscale/settings.json"
    echo ""
    if [ -n "$TEAM_SERVER_URL" ]; then
        echo -e "${BLUE}Team Server:${NC} $TEAM_SERVER_URL"
        echo ""
    fi
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "Run 'tokscale --help' for more options"
    echo ""
}

add_shell_integration() {
    log_info "Adding shell integration..."

    # Detect shell
    SHELL_NAME=$(basename "$SHELL")

    case "$SHELL_NAME" in
        bash)
            RC_FILE="$HOME/.bashrc"
            ;;
        zsh)
            RC_FILE="$HOME/.zshrc"
            ;;
        *)
            log_warning "Unknown shell: $SHELL_NAME. Please add Bun to PATH manually."
            return
            ;;
    esac

    # Add Bun to PATH if not already present
    if ! grep -q 'BUN_INSTALL' "$RC_FILE" 2>/dev/null; then
        echo '' >> "$RC_FILE"
        echo '# Bun' >> "$RC_FILE"
        echo 'export BUN_INSTALL="$HOME/.bun"' >> "$RC_FILE"
        echo 'export PATH="$BUN_INSTALL/bin:$PATH"' >> "$RC_FILE"
        log_success "Added Bun to $RC_FILE"
        log_warning "Please restart your terminal or run: source $RC_FILE"
    fi
}

main() {
    print_banner

    echo ""
    log_info "Starting Tokscale installation for team use..."
    echo ""

    # Step 1: Check OS
    check_os

    # Step 2: Check/Install Bun
    if ! check_bun; then
        install_bun
        add_shell_integration
    fi

    # Step 3: Install tokscale
    install_tokscale

    # Step 4: Setup configuration
    setup_config

    # Step 5: Check Claude retention
    setup_claude_retention

    # Done!
    print_usage
}

# Run main function
main "$@"
