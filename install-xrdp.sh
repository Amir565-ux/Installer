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
# Repo    : https://github.com/Amir565-ux/install-xrdp
# Usage   : sudo bash install-xrdp.sh
#         : sudo bash <(curl -fsSL https://raw.githubusercontent.com/Amir565-ux/install-xrdp/main/install-xrdp.sh)
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

# ─── Set RDP user password ────────────────────────────────────────────────────
set_rdp_password() {
  step "Set RDP user password"

  echo ""
  echo -e "${YELLOW}You can set (or change) the password for the Linux user that"
  echo -e "will log in over RDP. Leave blank to skip.${RESET}"
  echo ""

  # List non-system users for convenience
  echo -e "${BOLD}Regular user accounts on this machine:${RESET}"
  awk -F: '$3 >= 1000 && $1 != "nobody" { print "  •  " $1 }' /etc/passwd
  echo ""

  rdp_user=""
  if [[ -t 0 ]]; then
    read -rp "Enter username to set password for (or press Enter to skip): " rdp_user
  else
    warn "Non-interactive mode — skipping password setup."
    return
  fi

  # Trim whitespace
  rdp_user="${rdp_user// /}"

  if [[ -z "${rdp_user}" ]]; then
    warn "No username entered — skipping password setup."
    return
  fi

  # Verify the user exists
  if ! id "${rdp_user}" &>/dev/null; then
    warn "User '${rdp_user}' does not exist — skipping password setup."
    return
  fi

  echo ""
  info "Setting password for user: ${BOLD}${rdp_user}${RESET}"
  echo -e "${CYAN}(You will be prompted twice for the new password)${RESET}"
  echo ""

  # Loop until passwords match or user aborts
  while true; do
    # Read password silently (no echo)
    rdp_pass1=""
    rdp_pass2=""
    read -rsp "  New password       : " rdp_pass1; echo ""
    read -rsp "  Confirm password   : " rdp_pass2; echo ""

    if [[ -z "${rdp_pass1}" ]]; then
      warn "Password cannot be empty. Try again (or press Ctrl+C to abort)."
      continue
    fi

    if [[ "${rdp_pass1}" != "${rdp_pass2}" ]]; then
      warn "Passwords do not match. Try again."
      continue
    fi

    # Apply the password via chpasswd (no subshell spawning passwd interactively)
    printf '%s:%s\n' "${rdp_user}" "${rdp_pass1}" | chpasswd
    success "Password updated for user '${rdp_user}'."
    break
  done

  # Unset password variables from memory immediately
  unset rdp_pass1 rdp_pass2
}

# ─── Install Tailscale ────────────────────────────────────────────────────────
install_tailscale() {
  step "Installing Tailscale"

  # ── Ensure curl and ca-certificates are present ──────────────────────────
  if ! command -v curl &>/dev/null; then
    info "curl not found — installing it first..."
    DEBIAN_FRONTEND=noninteractive apt-get install -y curl ca-certificates
    success "curl installed."
  fi

  # ── Install Tailscale if not already present ──────────────────────────────
  if command -v tailscale &>/dev/null; then
    info "Tailscale is already installed — skipping install."
  else
    info "Downloading and running the official Tailscale install script..."
    # Official vendor install method: fetched over HTTPS from tailscale.com.
    # Running as root is required; this is the supported installation path.
    curl -fsSL https://tailscale.com/install.sh | sh
    success "Tailscale installed."
  fi

  # ── Start tailscaled daemon directly (no systemctl / systemd required) ──────
  # Create the state directory if missing
  mkdir -p /var/lib/tailscale

  if pgrep -x tailscaled &>/dev/null; then
    info "tailscaled is already running."
  else
    info "Starting tailscaled daemon in the background..."
    # Run tailscaled detached; redirect output to a log file for debugging
    nohup tailscaled \
      --state=/var/lib/tailscale/tailscaled.state \
      --socket=/run/tailscale/tailscaled.sock \
      > /var/log/tailscaled.log 2>&1 &

    TAILSCALED_PID=$!

    # Give it up to 10 s to become ready
    TS_STARTED=false
    for _ in $(seq 1 10); do
      sleep 1
      if tailscale status &>/dev/null; then
        TS_STARTED=true
        break
      fi
    done

    if [[ "${TS_STARTED}" == "false" ]]; then
      error "tailscaled did not start in time. Check: /var/log/tailscaled.log"
      export TAILSCALE_IP="ERROR"
      return 1
    fi

    success "tailscaled started (PID ${TAILSCALED_PID})."
    info "Log file: /var/log/tailscaled.log"
  fi

  # ── Authenticate ─────────────────────────────────────────────────────────
  echo ""
  echo -e "${YELLOW}${BOLD}Tailscale needs to be authenticated with your account.${RESET}"
  echo -e "Running ${BOLD}tailscale up${RESET} — a login URL will appear below."
  echo -e "Open it in your browser, sign in, then press Enter here to continue."
  echo ""

  # tailscale up blocks until authenticated when run interactively.
  # If it fails (e.g. network error), report and continue with a pending state.
  TS_AUTH_OK=true
  tailscale up --accept-routes || TS_AUTH_OK=false

  if [[ "${TS_AUTH_OK}" == "false" ]]; then
    warn "tailscale up returned a non-zero exit. Authentication may be incomplete."
    warn "You can authenticate later with: sudo tailscale up"
  fi

  # ── Wait for an IP (up to 60 s) ───────────────────────────────────────────
  info "Waiting for Tailscale IP assignment (up to 60 s)..."
  TS_IP=""
  for _ in $(seq 1 12); do
    TS_IP="$(tailscale ip -4 2>/dev/null || true)"
    [[ -n "${TS_IP}" ]] && break
    sleep 5
  done

  if [[ -n "${TS_IP}" ]]; then
    success "Tailscale IP: ${BOLD}${TS_IP}${RESET}"
    export TAILSCALE_IP="${TS_IP}"
    export TAILSCALE_READY="yes"
  else
    warn "Tailscale IP not yet assigned — authentication may still be pending."
    warn "After logging in, run:  tailscale ip -4"
    export TAILSCALE_IP="pending"
    export TAILSCALE_READY="no"
  fi
}

# ─── Show connection info ─────────────────────────────────────────────────────
show_connection_info() {
  step "All done — connection details"

  LOCAL_IP="$(hostname -I | awk '{print $1}')"
  TS_IP="${TAILSCALE_IP:-pending}"
  TS_READY="${TAILSCALE_READY:-no}"

  echo ""

  if [[ "${TS_READY}" == "yes" ]]; then
    # ── Tailscale is connected and has an IP ─────────────────────────────────
    echo -e "${GREEN}${BOLD}╔════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${GREEN}${BOLD}║        xrdp + Tailscale — Ready to connect!  ✔         ║${RESET}"
    echo -e "${GREEN}${BOLD}╠════════════════════════════════════════════════════════╣${RESET}"
    echo -e "${GREEN}${BOLD}║${RESET}"
    echo -e "${GREEN}${BOLD}║${RESET}  ${BOLD}Connect via Tailscale (recommended):${RESET}"
    echo -e "${GREEN}${BOLD}║${RESET}    Address  :  ${CYAN}${BOLD}${TS_IP}${RESET}"
    echo -e "${GREEN}${BOLD}║${RESET}    Port     :  ${BOLD}3389${RESET}"
    echo -e "${GREEN}${BOLD}║${RESET}"
    echo -e "${GREEN}${BOLD}║${RESET}  ${BOLD}Local network (same LAN only):${RESET}"
    echo -e "${GREEN}${BOLD}║${RESET}    Address  :  ${LOCAL_IP}"
    echo -e "${GREEN}${BOLD}║${RESET}    Port     :  3389"
    echo -e "${GREEN}${BOLD}║${RESET}"
    echo -e "${GREEN}${BOLD}╠════════════════════════════════════════════════════════╣${RESET}"
    echo -e "${GREEN}${BOLD}║${RESET}  ${BOLD}How to connect:${RESET}"
    echo -e "${GREEN}${BOLD}║${RESET}   Windows  → Win+R → mstsc → enter ${CYAN}${TS_IP}:3389${RESET}"
    echo -e "${GREEN}${BOLD}║${RESET}   macOS    → Microsoft Remote Desktop → Add PC"
    echo -e "${GREEN}${BOLD}║${RESET}   Linux    → Remmina → New → RDP → ${CYAN}${TS_IP}${RESET}"
    echo -e "${GREEN}${BOLD}║${RESET}   Android  → RD Client app → Add PC → ${CYAN}${TS_IP}${RESET}"
    echo -e "${GREEN}${BOLD}║${RESET}"
    echo -e "${GREEN}${BOLD}║${RESET}  Log in with your Linux username & the password"
    echo -e "${GREEN}${BOLD}║${RESET}  you set during this script (or your existing one)."
    echo -e "${GREEN}${BOLD}║${RESET}"
    echo -e "${GREEN}${BOLD}║${RESET}  ${YELLOW}⚠  Tailscale must also be installed on your client device.${RESET}"
    echo -e "${GREEN}${BOLD}║${RESET}     → https://tailscale.com/download"
    echo -e "${GREEN}${BOLD}╚════════════════════════════════════════════════════════╝${RESET}"
  else
    # ── Tailscale authentication is still pending ────────────────────────────
    echo -e "${YELLOW}${BOLD}╔════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${YELLOW}${BOLD}║     xrdp installed — Tailscale auth pending  ⚠         ║${RESET}"
    echo -e "${YELLOW}${BOLD}╠════════════════════════════════════════════════════════╣${RESET}"
    echo -e "${YELLOW}${BOLD}║${RESET}"
    echo -e "${YELLOW}${BOLD}║${RESET}  xrdp is running and ready on port ${BOLD}3389${RESET}."
    echo -e "${YELLOW}${BOLD}║${RESET}  Tailscale is installed but not yet authenticated."
    echo -e "${YELLOW}${BOLD}║${RESET}"
    echo -e "${YELLOW}${BOLD}║${RESET}  ${BOLD}To finish Tailscale setup, run:${RESET}"
    echo -e "${YELLOW}${BOLD}║${RESET}    ${CYAN}sudo tailscale up${RESET}"
    echo -e "${YELLOW}${BOLD}║${RESET}  Then open the login URL shown and sign in."
    echo -e "${YELLOW}${BOLD}║${RESET}"
    echo -e "${YELLOW}${BOLD}║${RESET}  ${BOLD}Once authenticated, get your Tailscale IP:${RESET}"
    echo -e "${YELLOW}${BOLD}║${RESET}    ${CYAN}tailscale ip -4${RESET}"
    echo -e "${YELLOW}${BOLD}║${RESET}"
    echo -e "${YELLOW}${BOLD}║${RESET}  ${BOLD}Local network fallback (same LAN only):${RESET}"
    echo -e "${YELLOW}${BOLD}║${RESET}    Address  :  ${LOCAL_IP}"
    echo -e "${YELLOW}${BOLD}║${RESET}    Port     :  3389"
    echo -e "${YELLOW}${BOLD}║${RESET}"
    echo -e "${YELLOW}${BOLD}║${RESET}  Install Tailscale on your client: https://tailscale.com/download"
    echo -e "${YELLOW}${BOLD}╚════════════════════════════════════════════════════════╝${RESET}"
  fi

  echo ""
  echo -e "${MAGENTA}${BOLD}  ──────────────────────────────────────────────────────${RESET}"
  echo -e "${MAGENTA}${BOLD}   🎬  Thanks for using CodingBoyz scripts!             ${RESET}"
  echo -e "${YELLOW}${BOLD}   👉  Subscribe to CodingPlayz on YouTube!             ${RESET}"
  echo -e "${MAGENTA}${BOLD}   ✏️   Edited by Ushi                                  ${RESET}"
  echo -e "${MAGENTA}${BOLD}  ──────────────────────────────────────────────────────${RESET}"
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
  set_rdp_password
  install_tailscale
  show_connection_info
}

main "$@"
