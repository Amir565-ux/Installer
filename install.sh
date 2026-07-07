#!/bin/bash
clear

# Colors (Clean & visible on white/dark backgrounds)
B='\033[1;34m'
G='\033[0;32m'
Y='\033[1;33m'
R='\033[0;31m'
W='\033[1;37m'
N='\033[0m'

[ "$(id -u)" -eq 0 ] && S="" || S="sudo"

# Packages Array (100+)
PKGS=(sudo curl wget git vim nano htop tmux screen tree jq unzip zip tar p7zip-full rar openssh-client openssh-server socat net-tools iproute2 nmap iptables wireguard-tools ngrok cloudflared autossh aria2 rsync lsof strace iotop atop crontab ffmpeg imagemagick file ufw fail2ban ca-certificates gnupg qemu-utils cloud-image-utils netcat-openbsd traceroute mtr-tiny whois dnsutils sipcalc bridge-utils vlan iw wpasupplicant ethtool pciutils usbutils smartmontools hdparm lm-sensors acpi bash-completion man-db apparmor auditd logrotate rsyslog unattended-upgrades apt-listchanges needrestart debconf-utils geoip-bin mmdb-bin binutils gdb valgrind bc dc software-properties-common apt-transport-https lsb-release systemd-resolved build-essential gcc g++ make cmake python3 python3-pip python3-venv nodejs npm ruby ruby-dev php-cli libssl-dev libffi-dev libxml2-dev libxslt1-dev zlib1g-dev libjpeg-dev libpng-dev libwebp-dev docker.io docker-compose mysql-client postgresql-client sqlite3 redis-tools mongosh fzf ripgrep fd-find bat exa lsd tldr zsh fish)

show_menu() {
clear
echo -e "${B}==========================================================${N}"
echo -e "${W}                [ CODINGBOYZ VPS MANAGER ]                ${N}"
echo -e "${B}==========================================================${N}"
echo -e "${B}   ██████╗  █████╗ ██████╗ ████████╗██╗███╗   ███╗███████╗${N}"
echo -e "${B}   ██╔══██╗██╔══██╗██╔══██╗╚══██╔══╝██║████╗ ████║██╔════╝${N}"
echo -e "${B}   ██████╔╝███████║██████╔╝   ██║   ██║██╔████╔██║█████╗  ${N}"
echo -e "${B}   ██╔═══╝ ██╔══██║██╔══██╗   ██║   ██║██║╚██╔╝██║██╔══╝  ${N}"
echo -e "${B}   ██║     ██║  ██║██║  ██║   ██║   ██║██║ ╚═╝ ██║███████╗${N}"
echo -e "${B}   ╚═╝     ╚═╝  ╚═╝╚═╝  ╚═╝   ╚═╝   ╚═╝╚═╝     ╚═╝╚══════╝${N}"
echo -e "${B}==========================================================${N}"
echo -e "${W}                      Made by CodingBoyz                    ${N}"
BLUE=$(tput setaf 4)
YELLOW=$(tput setaf 3)
RESET=$(tput sgr0)

echo "${YELLOW}============================${RESET}"
echo -e "${Y} SELECT AN OPTION:${N}"
echo "${BLUE}[1]${RESET} Port Forward"
echo "${BLUE}[2]${RESET} QEMU Install"
echo "${BLUE}[3]${RESET} Package Manager"
echo "${BLUE}[4]${RESET} Back to Main Menu"
echo "${YELLOW}============================${RESET}"
echo -e "${B}==========================================================${N}"
echo -ne "${W}> Enter Choice [1-5]: ${N}"
read C
case $C in 1) create_vps;; 2) restart_vps;; 3) edit_config;; 4) show_tools;; 5) exit 0;; *) echo -e "${R}[X] Invalid${N}"; sleep 1; show_menu;; esac
}

show_tools() {
clear
echo -e "${B}==========================================================${N}"
echo -e "${W}                     CODINGBOYZ TOOLS                     ${N}"
echo -e "${B}==========================================================${N}"
echo "  ${B}[1]${N} Port Forwarding"
echo "  ${B}[2]${N} Qemu Installer"
echo "  ${B}[3]${N} Packages Installer"
echo "  ${B}[4]${N} Back to Main Menu"
echo -e "${B}==========================================================${N}"
echo -ne "${W}> Select Tool [1-4]: ${N}"
read T
case $T in 1) tool_port;; 2) tool_qemu;; 3) tool_pkgs;; 4) show_menu;; *) echo -e "${R}[X] Invalid${N}"; sleep 1; show_tools;; esac
}

tool_pkgs() {
PAGE=0
PER_PAGE=20
TOTAL=${#PKGS[@]}
PAGES=$(( (TOTAL + PER_PAGE - 1) / PER_PAGE ))

while true; do
clear
echo -e "${B}==========================================================${N}"
echo -e "${W}                    PACKAGES INSTALLER                     ${N}"
echo -e "${B}==========================================================${N}"
echo -e "${Y} Type number to install | next | back | menu${N}"
echo -e "${B}----------------------------------------------------------${N}"

START=$((PAGE * PER_PAGE))
END=$((START + PER_PAGE))
[ $END -gt $TOTAL ] && END=$TOTAL

# Fixed numbering logic using strict printf alignment
for (( i=START; i<END; i++ )); do
    NUM=$((i + 1))
    printf " ${W}[%3d]${N} %-35s\n" "$NUM" "${PKGS[$i]}"
done

echo -e "${B}----------------------------------------------------------${N}"
echo -e "${W} Page $((PAGE+1)) of $PAGES${N}"
echo -ne "${W}> Action: ${N}"
read ANS

if [[ "$ANS" =~ ^[0-9]+$ ]]; then
    IDX=$((ANS - 1))
    if [ $IDX -ge 0 ] && [ $IDX -lt $TOTAL ]; then
        echo -e "${G}[...] Installing ${PKGS[$IDX]}...${N}"
        $S apt-get install -y "${PKGS[$IDX]}" > /dev/null 2>&1
        echo -e "${G}[OK] Done.${N}"
        sleep 1
    else
        echo -e "${R}[X] Invalid number.${N}"; sleep 1
    fi
elif [[ "$ANS" == "next" ]]; then
    [ $PAGE -lt $((PAGES - 1)) ] && ((PAGE++)) || { echo -e "${R}[X] Last page.${N}"; sleep 1; }
elif [[ "$ANS" == "back" ]]; then
    [ $PAGE -gt 0 ] && ((PAGE--)) || { echo -e "${R}[X] First page.${N}"; sleep 1; }
elif [[ "$ANS" == "menu" ]]; then
    show_tools; return
fi
done
}

tool_port() {
clear
echo -e "${B}==========================================================${N}"
echo -e "${W}                   PORT FORWARDING TOOL                   ${N}"
echo -e "${B}==========================================================${N}"
echo -ne "${W}> Enter Port to open (e.g 8080): ${N}"
read PORT
if [[ -z "$PORT" || ! "$PORT" =~ ^[0-9]+$ ]]; then echo -e "${R}[X] Invalid port.${N}"; sleep 2; show_tools; return; fi
if ! command -v socat &> /dev/null; then $S apt-get install -y socat > /dev/null 2>&1; fi
if $S lsof -i :$PORT > /dev/null 2>&1; then echo -e "${R}[X] Port $PORT in use.${N}"; sleep 2; show_tools; return; fi
echo -e "${G}[...] Binding Port $PORT...${N}"
 $S nohup socat TCP-LISTEN:$PORT,fork,reuseaddr TCP:10.0.2.15:$PORT > /dev/null 2>&1 &
sleep 1
echo -e "${G}[OK] Port $PORT routed to VPS.${N}"
echo -ne "${W}> Press Enter...${N}"; read
show_tools
}

tool_qemu() {
clear
echo -e "${B}==========================================================${N}"
echo -e "${W}                    QEMU INSTALLER                        ${N}"
echo -e "${B}==========================================================${N}"
echo -e "${G}[...] Installing QEMU...${N}"
 $S apt-get update -y > /dev/null 2>&1
 $S apt-get install -y qemu-system cloud-image-utils wget lsof > /dev/null 2>&1
if command -v qemu-system-x86_64 &> /dev/null; then echo -e "${G}[OK] QEMU Installed.${N}"; else echo -e "${R}[X] Failed.${N}"; fi
echo -ne "${W}> Press Enter...${N}"; read
show_tools
}

edit_config() {
[ -f ".vps_env" ] && source .vps_env || { RAM_GB=4; CPU_CORES=2; DISK_ADD=10; USER_NAME=root; USER_PASS=1234; TCP_HOST_PORT=2222; }
clear
echo -e "${B}==========================================================${N}"
echo -e "${W}                  EDIT VM CONFIGURATION                   ${N}"
echo -e "${B}==========================================================${N}"
echo -e "${Y} Leave blank to keep current value.${N}"
echo -ne "${W}> RAM GB [${G}$RAM_GB${W}]: ${N}"; read N_RAM; RAM_GB=${N_RAM:-$RAM_GB}
echo -ne "${W}> CPU Cores [${G}$CPU_CORES${W}]: ${N}"; read N_CPU; CPU_CORES=${N_CPU:-$CPU_CORES}
echo -ne "${W}> Disk ADD GB [${G}$DISK_ADD${W}]: ${N}"; read N_DISK; DISK_ADD=${N_DISK:-$DISK_ADD}
echo -ne "${W}> Username [${G}$USER_NAME${W}]: ${N}"; read N_USER; USER_NAME=${N_USER:-$USER_NAME}
echo -ne "${W}> Password [${G}$USER_PASS${W}]: ${N}"; read N_PASS; USER_PASS=${N_PASS:-$USER_PASS}

if [ -f "/home/daytona/ubuntu22.qcow2" ]; then
    $S virt-customize -a /home/daytona/ubuntu22.qcow2 --run-command 'rm -rf /var/lib/cloud/instances/*' 2>/dev/null || \
    ($S qemu-nbd --connect=/dev/nbd0 /home/daytona/ubuntu22.qcow2 2>/dev/null && $S mkdir -p /mnt/vm && $S mount /dev/nbd0p1 /mnt/vm 2>/dev/null && $S rm -rf /mnt/vm/var/lib/cloud/instances/* 2>/dev/null && $S umount /mnt/vm 2>/dev/null && $S qemu-nbd --disconnect /dev/nbd0 2>/dev/null)
fi

cat <<EOF > user-data
#cloud-config
disable_root: false
ssh_pwauth: True
chpasswd:
  list: |
    ${USER_NAME}:${USER_PASS}
  expire: False
runcmd:
  - sed -i 's/^#PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config
  - sed -i 's/^PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config
  - systemctl restart sshd
EOF
cloud-localds seed.img user-data > /dev/null 2>&1
[ ! -z "$N_DISK" ] && [ -f "/home/daytona/ubuntu22.qcow2" ] && $S qemu-img resize /home/daytona/ubuntu22.qcow2 +${DISK_ADD}G > /dev/null 2>&1
save_env
echo -e "${G}[OK] Updated. Use Option 2 to restart.${N}"; sleep 2; show_menu
}

create_vps() {
if ! command -v qemu-system-x86_64 &> /dev/null; then
clear; echo -e "${R}[!] QEMU NOT INSTALLED.${N}"; echo -e "${Y}> Go to [4] Tools -> [2] Qemu Installer first.${N}"; sleep 3; show_menu; return; fi
clear
echo -e "${B}==========================================================${N}"
echo -e "${W}         CONFIGURE VIRTUAL MACHINE SPECIFICATIONS          ${N}"
echo -e "${B}==========================================================${N}"
echo -ne "${W}> RAM (GB): ${N}"; read RAM_GB
echo -ne "${W}> CPU Cores: ${N}"; read CPU_CORES
echo -ne "${W}> Disk ADD (GB): ${N}"; read DISK_ADD
echo -ne "${W}> User [root]: ${N}"; read USER_NAME; USER_NAME=${USER_NAME:-root}
echo -ne "${W}> Pass [1234]: ${N}"; read USER_PASS; USER_PASS=${USER_PASS:-1234}
TCP_HOST_PORT=${TCP_HOST_PORT:-2222}; TCP_GUEST_PORT=22

 $S mkdir -p /home/daytona > /dev/null 2>&1
if [ ! -f "/home/daytona/ubuntu22.qcow2" ]; then
    echo -e "${G}[...] Downloading Ubuntu Image...${N}"
    $S wget -q --show-progress https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img -O /home/daytona/ubuntu22.qcow2
    $S chmod 666 /home/daytona/ubuntu22.qcow2
fi

echo -e "${G}[...] Generating Cloud-Init...${N}"
cat <<EOF > user-data
#cloud-config
disable_root: false
ssh_pwauth: True
chpasswd:
  list: |
    ${USER_NAME}:${USER_PASS}
  expire: False
runcmd:
  - sed -i 's/^#PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config
  - sed -i 's/^PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config
  - systemctl restart sshd
EOF
cloud-localds seed.img user-data > /dev/null 2>&1
echo -e "${G}[...] Expanding Disk...${N}"
 $S qemu-img resize /home/daytona/ubuntu22.qcow2 +${DISK_ADD}G > /dev/null 2>&1
save_env; boot_qemu
}

save_env() {
echo "RAM_GB=${RAM_GB:-4}" > .vps_env
echo "CPU_CORES=${CPU_CORES:-2}" >> .vps_env
echo "DISK_ADD=${DISK_ADD:-10}" >> .vps_env
echo "USER_NAME=${USER_NAME:-root}" >> .vps_env
echo "USER_PASS=${USER_PASS:-1234}" >> .vps_env
echo "TCP_HOST_PORT=${TCP_HOST_PORT:-2222}" >> .vps_env
echo "TCP_GUEST_PORT=${TCP_GUEST_PORT:-22}" >> .vps_env
}

boot_qemu() {
[ -f ".vps_env" ] && source .vps_env
TCP_HOST_PORT=${TCP_HOST_PORT:-2222}; TCP_GUEST_PORT=${TCP_GUEST_PORT:-22}; RAM_VALUE="${RAM_GB:-4}G"

if pgrep -x "qemu-system-x86" > /dev/null; then
    echo -e "${Y}[!] Stopping old VPS...${N}"; pkill -9 qemu-system-x86; sleep 2
fi

clear
sshx_log=$(mktemp)
{ curl -sSf https://sshx.io/get | sh -s run > "$sshx_log" 2>&1 & } 2>/dev/null
sleep 5
SSHX_URL=$(grep -o 'https://sshx.io/s/[a-zA-Z0-9]*' "$sshx_log" | head -n 1)
rm -f "$sshx_log"

clear
echo -e "${B}==========================================================${N}"
echo -e "${G}              CODINGBOYZ - VM NETWORK ACTIVE              ${N}"
echo -e "${B}==========================================================${N}"
echo -e "${W} User : ${G}${USER_NAME:-root}${N}"
echo -e "${W} Pass : ${G}${USER_PASS:-1234}${N}"
echo -e "${W} Specs: ${G}${RAM_VALUE} RAM | ${CPU_CORES:-2} Cores${N}"
echo -e "${W} Port : ${Y}Host ${TCP_HOST_PORT} -> VM ${TCP_GUEST_PORT}${N}"
echo -e "${B}----------------------------------------------------------${N}"
[ ! -z "$SSHX_URL" ] && echo -e "${W} Web Link : ${G}$SSHX_URL${N}" || echo -e "${Y}[i] Web tunnel skipped.${N}"
echo -e "${B}----------------------------------------------------------${N}"
echo -e "${W} SSH Cmd  : ${G}ssh ${USER_NAME:-root}@localhost -p ${TCP_HOST_PORT}${N}"
echo -e "${B}==========================================================${N}"
echo ""

qemu-system-x86_64 \
-hda /home/daytona/ubuntu22.qcow2 \
-m $RAM_VALUE \
-smp ${CPU_CORES:-2} \
-drive file=seed.img,format=raw \
-nographic \
-netdev user,id=net0,hostfwd=tcp::${TCP_HOST_PORT}-:${TCP_GUEST_PORT} \
-device e1000,netdev=net0
}

restart_vps() {
if [ -f "/home/daytona/ubuntu22.qcow2" ] && [ -f "seed.img" ]; then boot_qemu
else echo -e "${R}[X] No VPS found. Create one first.${N}"; sleep 2; show_menu; fi
}

show_menu
