#!/bin/bash

# ======================================================
#   MASTER SCRIPT: CodingBoyz XRDP Auto-Installer
#   Run via: bash <(curl -sL <YOUR_GITHUB_RAW_LINK>)
# ======================================================

export DEBIAN_FRONTEND=noninteractive

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
WHITE='\033[1;37m'
NC='\033[0m'
BOLD='\033[1m'
DIM='\033[2m'

# ------------------------------------------------------
# STEP 0: Big Title + Small Subscribe
# ------------------------------------------------------
clear

apt-get update -y > /dev/null 2>&1
apt-get install -y figlet > /dev/null 2>&1

echo -e "${CYAN}"
figlet -w 120 -c "CodingBoyz"
echo -e "${NC}"
echo -e "${DIM}                     Subscribe to CodingBoyz${NC}"
echo ""
echo -e "${YELLOW}============================================================${NC}"
echo ""

apt-get remove -y figlet > /dev/null 2>&1
apt-get autoremove -y > /dev/null 2>&1

# ------------------------------------------------------
# STEP 1: Root Check
# ------------------------------------------------------
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}[ERROR] Please run this script as root (sudo).${NC}"
    exit 1
fi

# ------------------------------------------------------
# STEP 2: Ask Username & Password (Visible)
# ------------------------------------------------------
echo -e "${CYAN}============================================================${NC}"
echo -e "${BOLD}${WHITE}                      XRDP USER SETUP${NC}"
echo -e "${CYAN}============================================================${NC}"
echo ""

while true; do
    read -p "$(echo -e ${GREEN}Enter XRDP Username : ${NC})" USERNAME
    if [ -z "$USERNAME" ]; then
        echo -e "${RED}[ERROR] Username cannot be empty!${NC}"
        continue
    fi
    if [[ "$USERNAME" =~ [^a-zA-Z0-9_] ]]; then
        echo -e "${RED}[ERROR] Only letters, numbers, and underscores allowed!${NC}"
        continue
    fi
    break
done

while true; do
    read -p "$(echo -e ${GREEN}Enter XRDP Password : ${NC})" PASSWORD
    if [ -z "$PASSWORD" ]; then
        echo -e "${RED}[ERROR] Password cannot be empty!${NC}"
        continue
    fi
    if [ ${#PASSWORD} -lt 4 ]; then
        echo -e "${RED}[ERROR] Password must be at least 4 characters!${NC}"
        continue
    fi
    break
done

echo ""
echo -e "${YELLOW}============================================================${NC}"
echo ""

# ------------------------------------------------------
# STEP 3: Update System
# ------------------------------------------------------
echo -e "${BOLD}${WHITE}[1/5] Updating System Packages...${NC}"
apt-get update -y > /dev/null 2>&1
apt-get upgrade -y > /dev/null 2>&1
echo -e "${GREEN}       [DONE] System Updated Successfully.${NC}"
echo ""

# ------------------------------------------------------
# STEP 4: Install Desktop Environment
# ------------------------------------------------------
echo -e "${BOLD}${WHITE}[2/5] Installing XFCE4 Desktop Environment...${NC}"
apt-get install -y xfce4 xfce4-goodies > /dev/null 2>&1
echo -e "${GREEN}       [DONE] Desktop Environment Installed.${NC}"
echo ""

# ------------------------------------------------------
# STEP 5: Install & Configure XRDP
# ------------------------------------------------------
echo -e "${BOLD}${WHITE}[3/5] Installing and Configuring XRDP...${NC}"
apt-get install -y xrdp > /dev/null 2>&1

echo "xfce4-session" > /root/.xsession

if [ -f /etc/xrdp/startwm.sh ]; then
    sed -i 's/test -x \/etc\/X11\/Xsession \&\& exec \/etc\/X11\/Xsession/exec \/etc\/X11\/Xsession/g' /etc/xrdp/startwm.sh
fi

usermod -aG ssl-cert xrdp > /dev/null 2>&1

systemctl enable xrdp > /dev/null 2>&1
systemctl restart xrdp > /dev/null 2>&1

if command -v ufw &> /dev/null; then
    ufw allow 3389/tcp > /dev/null 2>&1
fi

echo -e "${GREEN}       [DONE] XRDP Installed and Running on Port 3389.${NC}"
echo ""

# ------------------------------------------------------
# STEP 6: Create User
# ------------------------------------------------------
echo -e "${BOLD}${WHITE}[4/5] Creating User '$USERNAME'...${NC}"

if id "$USERNAME" &>/dev/null; then
    echo -e "${YELLOW}       [WARN] User already exists. Updating password...${NC}"
    echo "$USERNAME:$PASSWORD" | chpasswd
else
    useradd -m -s /bin/bash "$USERNAME" > /dev/null 2>&1
    echo "$USERNAME:$PASSWORD" | chpasswd
    usermod -aG sudo "$USERNAME" > /dev/null 2>&1
fi

echo "xfce4-session" > /home/$USERNAME/.xsession
chown $USERNAME:$USERNAME /home/$USERNAME/.xsession

echo -e "${GREEN}       [DONE] User '$USERNAME' is ready for login.${NC}"
echo ""

# ------------------------------------------------------
# STEP 7: Install Tailscale & Get Login URL
# ------------------------------------------------------
echo -e "${BOLD}${WHITE}[5/5] Installing Tailscale...${NC}"
curl -fsSL https://tailscale.com/install.sh | sh > /dev/null 2>&1
systemctl enable tailscaled > /dev/null 2>&1
systemctl start tailscaled > /dev/null 2>&1

# Start tailscale login to get the clickable URL
TS_OUTPUT=$(tailscale up 2>&1)
TS_LOGIN_URL=$(echo "$TS_OUTPUT" | grep -oP 'https://login\.tailscale\.com/a/[a-zA-Z0-9]+' | head -1)

echo -e "${GREEN}       [DONE] Tailscale Installed.${NC}"
echo ""

# ------------------------------------------------------
# STEP 8: Show Login URL & Wait for Connection
# ------------------------------------------------------
echo -e "${CYAN}============================================================${NC}"
echo -e "${BOLD}${WHITE}              CONNECT THIS VPS TO TAILSCALE${NC}"
echo -e "${CYAN}============================================================${NC}"
echo ""

if [ -n "$TS_LOGIN_URL" ]; then
    echo -e "${YELLOW}  Click this link in your browser to authenticate:${NC}"
    echo ""
    echo -e "${CYAN}  ┌──────────────────────────────────────────────────────────┐${NC}"
    echo -e "${CYAN}  │${NC} ${BOLD}${GREEN}$TS_LOGIN_URL${NC}"
    echo -e "${CYAN}  └──────────────────────────────────────────────────────────┘${NC}"
    echo ""
    echo -e "${WHITE}  If you don't have Tailscale on your PC, download it from:${NC}"
    echo -e "${GREEN}  https://tailscale.com/download${NC}"
    echo ""
    echo -e "${YELLOW}  Waiting for you to click and authenticate...${NC}"
    echo ""

    # Wait for Tailscale to connect (check every 2 seconds, max 120 seconds)
    CONNECTED=0
    for i in $(seq 1 60); do
        if tailscale status 2>/dev/null | grep -q "connected"; then
            CONNECTED=1
            break
        fi
        sleep 2
        # Show a spinner/dot
        printf "${DIM}."
    done
    echo ""
    echo ""

    if [ $CONNECTED -eq 1 ]; then
        TS_IP=$(tailscale ip -4 2>/dev/null)
        echo -e "${GREEN}  [SUCCESS] Tailscale connected! IP: $TS_IP${NC}"
        echo ""
    else
        echo -e "${RED}  [TIMEOUT] Tailscale did not connect in time.${NC}"
        echo -e "${YELLOW}  You can connect manually later: tailscale up${NC}"
        echo ""
        TS_IP=""
    fi
else
    echo -e "${RED}  [ERROR] Could not generate Tailscale login URL.${NC}"
    echo -e "${YELLOW}  Connect manually later: tailscale up${NC}"
    echo ""
    TS_IP=""
fi

# ------------------------------------------------------
# Gather Public IP
# ------------------------------------------------------
PUBLIC_IP=$(curl -s --max-time 5 ifconfig.me 2>/dev/null || curl -s --max-time 5 icanhazip.com 2>/dev/null || echo "Could not fetch IP")

# ------------------------------------------------------
# FINAL OUTPUT SCREEN
# ------------------------------------------------------
echo -e "${CYAN}============================================================${NC}"
echo ""
echo -e "${BOLD}${GREEN}              ██  XRDP INSTALLED  ██${NC}"
echo ""
echo -e "${CYAN}============================================================${NC}"
echo ""

if [ -n "$TS_IP" ]; then
    echo -e "${BOLD}${WHITE}  Connect via Tailscale (Recommended):${NC}"
    echo ""
    echo -e "${CYAN}  ┌────────────────────────────────────────────┐${NC}"
    echo -e "${CYAN}  │${NC} ${WHITE}Tailscale IP : ${GREEN}$TS_IP${NC}"
    echo -e "${CYAN}  │${NC} ${WHITE}Port        : ${GREEN}3389${NC}"
    echo -e "${CYAN}  │${NC} ${WHITE}Username    : ${GREEN}$USERNAME${NC}"
    echo -e "${CYAN}  │${NC} ${WHITE}Password    : ${GREEN}$PASSWORD${NC}"
    echo -e "${CYAN}  └────────────────────────────────────────────┘${NC}"
    echo ""
    echo -e "${WHITE}  RDP Link : ${GREEN}rdp://$TS_IP:3389${NC}"
    echo ""
fi

echo -e "${BOLD}${WHITE}  Connect via Public IP (Alternative):${NC}"
echo ""
echo -e "${CYAN}  ┌────────────────────────────────────────────┐${NC}"
echo -e "${CYAN}  │${NC} ${WHITE}Public IP   : ${GREEN}$PUBLIC_IP${NC}"
echo -e "${CYAN}  │${NC} ${WHITE}Port        : ${GREEN}3389${NC}"
echo -e "${CYAN}  │${NC} ${WHITE}Username    : ${GREEN}$USERNAME${NC}"
echo -e "${CYAN}  │${NC} ${WHITE}Password    : ${GREEN}$PASSWORD${NC}"
echo -e "${CYAN}  └────────────────────────────────────────────┘${NC}"
echo ""
echo -e "${WHITE}  RDP Link : ${GREEN}rdp://$PUBLIC_IP:3389${NC}"
echo ""

echo -e "${CYAN}============================================================${NC}"
echo -e "${DIM}                     Subscribe to CodingBoyz${NC}"
echo -e "${CYAN}============================================================${NC}"
