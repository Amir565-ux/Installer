#!/usr/bin/env bash
# =============================================================================
#
#   ____          _ _             ____
#  / ___|___   __| (_)_ __   __ _| __ )  ___  _   _ ____
# | |   / _ \ / _` | | '_ \ / _` |  _ \ / _ \| | | |_  /
# | |__| (_) | (_| | | | | | (_| | |_) | (_) | |_| |/ /
#  \____\___/ \__,_|_|_| |_|\__, |____/ \___/ \__, /___|
#                             |___/             |___/
#
#  ______    ___ _           _   _               _
# |  ____|  |_ _| |_ ___  __| | | |__  _   _   / \  ___  ___  ___
# | |__  __  | || __/ _ \/ _` | | '_ \| | | | / _ \/ __|/ __|/ __|
# |  __|/ _` | || ||  __/ (_| | | |_) | |_| |/ ___ \__ \__ \__ \
# |_|  \__,_|___|\__\___|\__,_| |_.__/ \__, /_/   \_\___/___/___/
#                                        |___/
#
#                    ~~~ Edited by Ushi ~~~
#
#          Subscribe to CodingPlayz on YouTube for more!
#
# =============================================================================
# Script  : XRDP Installer for Ubuntu / Debian
# Purpose : Install and configure xrdp remote desktop server
# Author  : CodingBoyz  |  Edited by Ushi
# Channel : CodingPlayz
# Usage   : sudo bash install-xrdp.sh
# =============================================================================

set -euo pipefail

# ─── Colors ──────────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
RESET='\033[0m'

# ─── Banner ───────────────────────────────────────────────────────────────────
print_banner() {
  [[ -t 1 ]] && clear || true
  echo ""
  echo -e "${CYAN}${BOLD}"
  echo "  ╔═══════════════════════════════════════════════════════════════╗"
  echo "  ║                                                               ║"
  echo "  ║   ██████╗ ██████╗ ██████╗ ██╗███╗   ██╗ ██████╗             ║"
  echo "  ║  ██╔════╝██╔═══██╗██╔══██╗██║████╗  ██║██╔════╝             ║"
  echo "  ║  ██║     ██║   ██║██║  ██║██║██╔██╗ ██║██║  ███╗            ║"
  echo "  ║  ██║     ██║   ██║██║  ██║██║██║╚██╗██║██║   ██║            ║"
  echo "  ║  ╚██████╗╚██████╔╝██████╔╝██║██║ ╚████║╚██████╔╝            ║"
  echo "  ║   ╚═════╝ ╚═════╝ ╚═════╝ ╚═╝╚═╝  ╚═══╝ ╚═════╝            ║"
  echo "  ║                                                               ║"
  echo "  ║  ██████╗  ██████╗ ██╗   ██╗███████╗                         ║"
  echo "  ║  ██╔══██╗██╔═══██╗╚██╗ ██╔╝╚══███╔╝                         ║"
  echo "  ║  ██████╔╝██║   ██║ ╚████╔╝   ███╔╝                          ║"
  echo "  ║  ██╔══██╗██║   ██║  ╚██╔╝   ███╔╝                           ║"
  echo "  ║  ██████╔╝╚██████╔╝   ██║   ███████╗                         ║"
  echo "  ║  ╚═════╝  ╚═════╝    ╚═╝   ╚══════╝                         ║"
  echo "  ║                                                               ║"
  echo "  ╠═══════════════════════════════════════════════════════════════╣"
  echo -e "  ║${RESET}${YELLOW}${BOLD}               ~~~  Edited by Ushi  ~~~                       ${CYAN}${BOLD}║"
  echo -e "  ║${RESET}${MAGENTA}${BOLD}       🎬  Subscribe to CodingPlayz on YouTube!  🎬           ${CYAN}${BOLD}║"
  echo "  ╚═══════════════════════════════════════════════════════════════╝"
  echo -e "${RESET}"
  echo ""
}

# ─── Helper functions ─────────────────────────────────────────────────────────
info()    { echo -e "${CYAN}[INFO]${RESET}  $*"; }
success() { echo -e "${GREEN}[  OK ]${RESET}  $*"; }
warn()    { echo -e "${YELLOW}[ WARN]${RESET}  $*"; }
error()   { echo -e "${RED}[ERROR]${RESET}  $*" >&2; }
step()    { echo -e "\n${BLUE}${BOLD}──── $* ────${RESET}"; }

die() {
  error "$*"
  exit 1
}

# ─── Root check ───────────────────────────────────────────────────────────────
check_root() {
  if [[ "${EUID}" -ne 0 ]]; then
    die "Please run this script as root: sudo bash $0"
  fi
}

# ─── OS check ─────────────────────────────────────────────────────────────────
check_os() {
  step "Checking operating system"

  if [[ ! -f /etc/os-release ]]; then
    die "Cannot detect OS. /etc/os-release not found."
  fi

  # shellcheck source=/dev/null
  source /etc/os-release

  if [[ "${ID}" != "ubuntu" && "${ID}" != "debian" && "${ID_LIKE}" != *"debian"* ]]; then
    die "This script supports Ubuntu / Debian only. Detected: ${ID}"
  fi

  info "Detected OS : ${PRETTY_NAME}"
  success "OS check passed."
}

# ─── Update package lists ─────────────────────────────────────────────────────
update_packages() {
  step "Updating package lists"
  apt-get update -y
  success "Package lists updated."
}

# ─── Install desktop environment (if not present) ────────────────────────────
install_desktop() {
  step "Checking for a desktop environment"

  pkg_installed() { dpkg-query -W -f='${Status}' "$1" 2>/dev/null | grep -q 'install ok installed'; }

  if pkg_installed xfce4; then
    info "XFCE4 is already installed — skipping desktop install."
    return
  fi

  if pkg_installed gnome-session; then
    info "GNOME is already installed — skipping desktop install."
    return
  fi

  warn "No desktop environment detected."
  echo ""
  echo -e "${YELLOW}xrdp requires a desktop environment to function.${RESET}"
  echo -e "Options:"
  echo -e "  ${BOLD}1)${RESET} XFCE4  (lightweight, recommended for remote desktop)"
  echo -e "  ${BOLD}2)${RESET} Skip   (if you already have one or want to install later)"
  echo ""

  de_choice=""
  if [[ -t 0 ]]; then
    read -rp "Enter choice [1-2] (default: 1): " de_choice
  else
    warn "Non-interactive mode — defaulting to XFCE4."
    de_choice="1"
  fi
  de_choice="${de_choice:-1}"

  case "${de_choice}" in
    1)
      info "Installing XFCE4 desktop environment..."
      DEBIAN_FRONTEND=noninteractive apt-get install -y \
        xfce4 \
        xfce4-goodies \
        dbus-x11
      success "XFCE4 installed."
      ;;
    2)
      warn "Skipping desktop environment installation."
      ;;
    *)
      warn "Invalid choice — defaulting to XFCE4."
      DEBIAN_FRONTEND=noninteractive apt-get install -y \
        xfce4 \
        xfce4-goodies \
        dbus-x11
      success "XFCE4 installed."
      ;;
  esac
}

# ─── Install xrdp ─────────────────────────────────────────────────────────────
install_xrdp() {
  step "Installing xrdp"

  DEBIAN_FRONTEND=noninteractive apt-get install -y \
    xrdp \
    xorgxrdp

  success "xrdp installed."
}

# ─── Configure xrdp ───────────────────────────────────────────────────────────
configure_xrdp() {
  step "Configuring xrdp"

  # Add xrdp user to ssl-cert group so it can read the certificate
  if getent group ssl-cert &>/dev/null; then
    usermod -aG ssl-cert xrdp
    info "xrdp user added to ssl-cert group."
  fi

  # Write a startup session file for XFCE if it is installed
  if dpkg-query -W -f='${Status}' xfce4 2>/dev/null | grep -q 'install ok installed'; then
    info "Configuring XFCE4 as the xrdp session..."
    STARTWM="/etc/xrdp/startwm.sh"
    if [[ -f "${STARTWM}" ]]; then
      cp "${STARTWM}" "${STARTWM}.bak.$(date +%Y%m%d%H%M%S)"
      info "Backed up existing startwm.sh."
    fi
    cat > /etc/xrdp/startwm.sh <<'EOF'
#!/bin/sh
# xrdp session startup script — generated by CodingBoyz install-xrdp.sh
unset DBUS_SESSION_BUS_ADDRESS
unset XDG_RUNTIME_DIR
startxfce4
EOF
    chmod +x /etc/xrdp/startwm.sh
    success "XFCE4 session configured for xrdp."
  fi

  # Backup original xrdp.ini then set port to 3389
  XRDP_INI="/etc/xrdp/xrdp.ini"
  if [[ -f "${XRDP_INI}" ]]; then
    cp "${XRDP_INI}" "${XRDP_INI}.bak.$(date +%Y%m%d%H%M%S)"
    # Ensure port is 3389
    sed -i 's/^port=.*/port=3389/' "${XRDP_INI}"
    info "xrdp port set to 3389."
  fi

  success "xrdp configuration complete."
}

# ─── Enable and start xrdp service ───────────────────────────────────────────
enable_xrdp_service() {
  step "Enabling and starting xrdp service"

  systemctl enable xrdp
  systemctl restart xrdp

  if systemctl is-active --quiet xrdp; then
    success "xrdp service is running."
  else
    error "xrdp failed to start. Check logs: journalctl -xeu xrdp"
    exit 1
  fi
}

# ─── Configure firewall (ufw) if active ───────────────────────────────────────
configure_firewall() {
  step "Checking firewall (ufw)"

  if ! command -v ufw &>/dev/null; then
    info "ufw not found — skipping firewall configuration."
    return
  fi

  UFW_STATUS="$(ufw status | head -1)"
  if [[ "${UFW_STATUS}" != *"active"* ]]; then
    info "ufw is not active — skipping firewall rule."
    return
  fi

  info "ufw is active — allowing RDP port 3389..."
  ufw allow 3389/tcp
  success "Port 3389 allowed through ufw."
}

# ─── Show connection info ─────────────────────────────────────────────────────
show_connection_info() {
  step "Installation complete"

  # Retrieve the primary IP address
  PRIMARY_IP="$(hostname -I | awk '{print $1}')"

  echo ""
  echo -e "${GREEN}${BOLD}╔══════════════════════════════════════════════╗${RESET}"
  echo -e "${GREEN}${BOLD}║   xrdp is installed and running!             ║${RESET}"
  echo -e "${GREEN}${BOLD}╠══════════════════════════════════════════════╣${RESET}"
  echo -e "${GREEN}${BOLD}║${RESET}  Host / IP   : ${BOLD}${PRIMARY_IP}${RESET}"
  echo -e "${GREEN}${BOLD}║${RESET}  Port        : ${BOLD}3389${RESET}"
  echo -e "${GREEN}${BOLD}║${RESET}  Protocol    : RDP"
  echo -e "${GREEN}${BOLD}║${RESET}"
  echo -e "${GREEN}${BOLD}║${RESET}  Connect using Windows Remote Desktop (mstsc),"
  echo -e "${GREEN}${BOLD}║${RESET}  Remmina, or any RDP-compatible client."
  echo -e "${GREEN}${BOLD}║${RESET}"
  echo -e "${GREEN}${BOLD}║${RESET}  Log in with your existing Linux username"
  echo -e "${GREEN}${BOLD}║${RESET}  and password."
  echo -e "${GREEN}${BOLD}╚══════════════════════════════════════════════╝${RESET}"
  echo ""
  echo -e "${MAGENTA}${BOLD}  ──────────────────────────────────────────────${RESET}"
  echo -e "${MAGENTA}${BOLD}   🎬  Thanks for using CodingBoyz scripts!     ${RESET}"
  echo -e "${YELLOW}${BOLD}   👉  Subscribe to CodingPlayz on YouTube!     ${RESET}"
  echo -e "${MAGENTA}${BOLD}   ✏️   Edited by Ushi                          ${RESET}"
  echo -e "${MAGENTA}${BOLD}  ──────────────────────────────────────────────${RESET}"
  echo ""
}

# ─── Main ─────────────────────────────────────────────────────────────────────
main() {
  print_banner
  check_root
  check_os
  update_packages
  install_desktop
  install_xrdp
  configure_xrdp
  enable_xrdp_service
  configure_firewall
  show_connection_info
}

main "$@"
