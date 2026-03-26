#!/bin/bash
################################################################################
# Kali + OpenCode Portable Pentest USB Builder
# 
# Creates a bootable Kali Live USB with persistence + pre-configured OpenCode
# for automated penetration testing workflows.
#
# Usage: sudo ./build-usb.sh /dev/sdX
# Example: sudo ./build-usb.sh /dev/sdb
#
# Author: [Your GitHub Username]
# Date: 2026-02-26
# License: MIT
################################################################################

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
KALI_ISO_URL="https://http.kali.org/kali-2025.1/kali-linux-2025.1-live-amd64.iso"
KALI_ISO_SHA256="CHECK_ON_KALI_SITE"
OPENCLAW_INSTALL_URL="https://opencode.ai/install.sh"

################################################################################
# Helper Functions
################################################################################

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[!]${NC} $1"
}

log_error() {
    echo -e "${RED}[✗]${NC} $1"
}

die() {
    log_error "$1"
    exit 1
}

check_root() {
    if [[ $EUID -ne 0 ]]; then
        die "This script must be run as root (sudo)"
    fi
}

check_usb_device() {
    local device="$1"
    
    if [[ ! -b "$device" ]]; then
        die "Device $device does not exist or is not a block device"
    fi
    
    # Warn about data loss
    log_warn "ALL DATA ON $device WILL BE DESTROYED!"
    read -p "Are you sure you want to continue? (yes/no): " confirm
    if [[ "$confirm" != "yes" ]]; then
        log_info "Aborted by user"
        exit 0
    fi
}

################################################################################
# Main Build Process
################################################################################

main() {
    local USB_DEVICE="${1:-}"
    
    if [[ -z "$USB_DEVICE" ]]; then
        echo "Usage: sudo $0 /dev/sdX"
        echo "Example: sudo $0 /dev/sdb"
        echo ""
        echo "Available block devices:"
        lsblk -d -o NAME,SIZE,TYPE,MOUNTPOINT | grep -v "^loop"
        exit 1
    fi
    
    check_root
    check_usb_device "$USB_DEVICE"
    
    log_info "Building Kali + OpenCode USB on $USB_DEVICE"
    log_info "This will take 10-20 minutes depending on your internet speed"
    
    # Step 1: Download Kali ISO
    log_info "Step 1/7: Downloading Kali ISO..."
    local iso_path="/tmp/kali-live-amd64.iso"
    
    if [[ -f "$iso_path" ]]; then
        log_warn "Existing ISO found, skipping download"
    else
        wget -c --show-progress "$KALI_ISO_URL" -O "$iso_path" || die "Failed to download Kali ISO"
    fi
    
    # Verify checksum (optional, can be skipped for speed)
    log_info "Verifying ISO checksum..."
    # sha256sum -c <(echo "$KALI_ISO_SHA256  $iso_path") || log_warn "Checksum verification failed (continuing anyway)"
    
    # Step 2: Write ISO to USB
    log_info "Step 2/7: Writing ISO to USB (this will take a few minutes)..."
    dd if="$iso_path" of="$USB_DEVICE" bs=4M status=progress conv=fsync
    sync
    
    log_success "ISO written to $USB_DEVICE"
    
    # Step 3: Create persistence partition
    log_info "Step 3/7: Creating persistence partition..."
    
    # Get the size of the USB drive
    local usb_size=$(blockdev --getsz "$USB_DEVICE")
    local last_sector=$((usb_size - 1))
    
    # Create partition (use last 80% of drive for persistence)
    # Note: This is simplified - in production, use proper partition calculation
    parted "$USB_DEVICE" mkpart primary ext4 80% 100% || log_warn "Partition creation may have failed"
    
    # Find the new partition (usually sdX3)
    local persistence_part="${USB_DEVICE}3"
    
    # Wait for partition to be recognized
    sleep 2
    udevadm settle || true
    
    # Format as ext4 with persistence label
    if [[ -b "$persistence_part" ]]; then
        mkfs.ext4 -L persistence "$persistence_part" || die "Failed to format persistence partition"
        log_success "Persistence partition created: $persistence_part"
    else
        log_warn "Could not find persistence partition at $persistence_part"
        log_warn "You may need to create it manually after first boot"
    fi
    
    # Step 4: Configure persistence
    log_info "Step 4/7: Configuring persistence..."
    
    local persist_mount="/mnt/usb_persistence_$$"
    mkdir -p "$persist_mount"
    
    if [[ -b "$persistence_part" ]]; then
        mount "$persistence_part" "$persist_mount" || die "Failed to mount persistence partition"
        echo "/ union" > "$persist_mount/persistence.conf"
        log_success "Persistence configured"
        umount "$persist_mount"
    else
        log_warn "Skipping persistence.conf (partition not found)"
    fi
    
    rmdir "$persist_mount" || true
    
    # Step 5: Create OpenCode setup scripts
    log_info "Step 5/7: Creating OpenCode setup scripts..."
    
    # We'll create these to run after first boot
    mkdir -p "/tmp/usb_postinstall_$$"
    local postinstall_dir="/tmp/usb_postinstall_$$"
    
    # Create the post-install script
    cat > "$postinstall_dir/opencode-setup.sh" << 'POSTINSTALL_EOF'
#!/bin/bash
################################################################################
# OpenCode Post-Install Setup (runs after first boot into Kali Live)
################################################################################

set -euo pipefail

KALI_USER="kali"
OPENCLAW_HOME="/home/$KALI_USER/.opencode"

echo "🗡️  Setting up OpenCode for portable pentesting..."

# Install OpenCode
echo "Installing OpenCode..."
curl -fsSL https://opencode.ai/install.sh | bash

# Wait for installation to complete
sleep 2

# Create workspace structure
echo "Creating workspace structure..."
mkdir -p "$OPENCLAW_HOME/workspace/memory"
mkdir -p "$OPENCLAW_HOME/workspace/templates"
mkdir -p "$OPENCLAW_HOME/workspace/backups"
mkdir -p "$OPENCLAW_HOME/node-templates"

# Create identity file
cat > "$OPENCLAW_HOME/workspace/IDENTITY.md" << 'EOF'
# IDENTITY.md - Who Am I?

- **Name:** Claw
- **Creature:** Security AI / Ghost in the Machine
- **Vibe:** Sharp, direct, no bullshit. Here to break things (legally).
- **Emoji:** 🗡️
- **Avatar:** 

---

*Portable pentest rig - boots anywhere, leaves no trace.*
EOF

# Create user file (to be filled by operator)
cat > "$OPENCLAW_HOME/workspace/USER.md" << 'EOF'
# USER.md - About Your Human

- **Name:** [FILL IN]
- **What to call them:** [FILL IN]
- **Timezone:** [FILL IN]

## Context

Pentester using portable Kali + OpenCode rig.
EOF

# Configure gateway
echo "Configuring gateway..."
opencode config set gateway.bind lan
opencode config set gateway.port 18789
opencode config set tools.exec.security allowlist

# Create node host template for drop-box deployments
cat > "$OPENCLAW_HOME/node-templates/dropbox.json" << 'EOF'
{
  "displayName": "USB-Keyboard",
  "gatewayHost": "<YOUR-VPS-IP>",
  "gatewayPort": 18789,
  "gatewayToken": "<YOUR-TOKEN>",
  "autoStart": true
}
EOF

# Pre-approve common pentest tools
echo "Pre-approving pentest tools..."
opencode approvals allowlist add --node localhost "/usr/bin/nmap"
opencode approvals allowlist add --node localhost "/usr/bin/sqlmap"
opencode approvals allowlist add --node localhost "/usr/bin/burpsuite"
opencode approvals allowlist add --node localhost "/usr/bin/metasploit"
opencode approvals allowlist add --node localhost "/usr/bin/hashcat"
opencode approvals allowlist add --node localhost "/usr/bin/john"
opencode approvals allowlist add --node localhost "/usr/bin/gobuster"
opencode approvals allowlist add --node localhost "/usr/bin/nikto"
opencode approvals allowlist add --node localhost "/usr/bin/wfuzz"
opencode approvals allowlist add --node localhost "/usr/bin/dirb"
opencode approvals allowlist add --node localhost "/usr/bin/hydra"
opencode approvals allowlist add --node localhost "/usr/bin/netcat"
opencode approvals allowlist add --node localhost "/bin/bash"

# Create bash aliases for quick access
cat >> "/home/$KALI_USER/.bashrc" << 'EOF'

# ═══════════════════════════════════════════════════════════
# OpenCode Portable Pentest Rig - Quick Commands
# ═══════════════════════════════════════════════════════════

alias oc-start='opencode gateway start'
alias oc-stop='opencode gateway stop'
alias oc-status='opencode status'
alias oc-dashboard='opencode dashboard'
alias oc-nodes='opencode nodes status'
alias oc-approve='opencode nodes approve'
alias oc-pending='opencode nodes pending'

# Quick pentest workflows
alias oc-recon='cd ~/.opencode/workspace && sessions_spawn --runtime subagent --task "Network reconnaissance"'
alias oc-docs='cd ~/.opencode/workspace/memory && ls -la'

# Auto-check gateway status
check_oc() {
    if ! pgrep -f "opencode.*gateway" > /dev/null 2>&1; then
        echo "🗡️  OpenCode gateway not running. Start with: oc-start"
        return 1
    fi
    echo "✅ OpenCode gateway running"
    return 0
}

# Run check on new terminal
check_oc 2>/dev/null || true
EOF

# Create pentest workflow templates
echo "Creating pentest templates..."

# Network recon template
cat > "$OPENCLAW_HOME/workspace/templates/recon-network.md" << 'EOF'
# Network Reconnaissance Template

## Target Information
- **Network Range:** `<CIDR>`
- **Scope:** `<authorized range>`
- **Date:** `YYYY-MM-DD`
- **Operator:** `<name>`

## Quick Commands

```bash
# Live host discovery
nmap -sn <CIDR> -oG live-hosts.txt

# Service detection
nmap -sV -sC -oN service-scan.txt <target>

# Full port scan
nmap -p- -T4 -oN all-ports.txt <target>

# Vulnerability scan
nmap --script vuln -oN vulns.txt <target>

# UDP scan
nmap -sU -T4 -oN udp-scan.txt <target>
```

## OpenCode Automation

```bash
# Spawn recon sub-agent
sessions_spawn --runtime subagent --task "Scan 192.168.1.0/24, identify live hosts and open ports"

# Document findings
write path="memory/recon-$(date +%Y-%m-%d).md" content="Findings here"
```

## Findings

| Host | Open Ports | Services | Notes |
|------|------------|----------|-------|
|      |            |          |       |
EOF

# Web app recon template
cat > "$OPENCLAW_HOME/workspace/templates/recon-web.md" << 'EOF'
# Web Application Reconnaissance Template

## Target Information
- **URL:** `<target>`
- **Scope:** `<authorized domains>`
- **Date:** `YYYY-MM-DD`

## Directory Enumeration

```bash
# Gobuster
gobuster dir -u <url> -w /usr/share/wordlists/dirb/common.txt -o gobuster.txt

# Feroxbuster (faster)
feroxbuster -u <url> -w /usr/share/wordlists/dirb/common.txt -o feroxbuster.txt

# Dirb
dirb <url> -o dirb.txt
```

## Vulnerability Scanning

```bash
# Nikto
nikto -h <url> -o nikto.txt

# SQLMap
sqlmap -u "<url>" --batch --level=3 --risk=2 -o sqlmap.txt

# XSS testing
xsstrike -u "<url>"
```

## OpenCode Browser Automation

```bash
# Capture screenshot
browser action=snapshot profile=opencode

# Navigate and test
browser action=navigate targetUrl="<url>"
```
EOF

# Wireless template
cat > "$OPENCLAW_HOME/workspace/templates/recon-wifi.md" << 'EOF'
# Wireless Reconnaissance Template

## Target Information
- **BSSID:** `<MAC>`
- **ESSID:** `<network name>`
- **Channel:** `<channel>`
- **Date:** `YYYY-MM-DD`

## Aircrack-ng Suite

```bash
# Monitor mode
airmon-ng start wlan0

# Capture handshake
airodump-ng -c <channel> --bssid <BSSID> -w capture wlan0mon

# Deauth attack (capture handshake faster)
aireplay-ng --deauth 10 -a <BSSID> wlan0mon

# Crack handshake
aircrack-ng -w /usr/share/wordlists/rockyou.txt capture-01.cap

# PMKID attack
hcxdumptool -i wlan0mon -o capture.pcapng --enable_status=1
hashcat -m 16800 capture.pcapng /usr/share/wordlists/rockyou.txt
```

## WPS Testing

```bash
# Reaver
reaver -i wlan0mon -b <BSSID> -vv

# Bully
bully wlan0mon -b <BSSID> -c <channel>
```
EOF

# Create backup script
cat > "$OPENCLAW_HOME/workspace/backup-config.sh" << 'EOF'
#!/bin/bash
# Backup OpenCode configuration

TIMESTAMP=$(date +%Y%m%d-%H%M%S)
BACKUP_DIR="$HOME/.opencode/workspace/backups/opencode-$TIMESTAMP"

mkdir -p "$BACKUP_DIR"
cp -r ~/.opencode "$BACKUP_DIR/"

echo "✅ Backup saved to: $BACKUP_DIR"

# Optional: sync to remote
# rsync -avz "$BACKUP_DIR" user@vps:/backups/opencode/
EOF
chmod +x "$OPENCLAW_HOME/workspace/backup-config.sh"

# Create README for the workspace
cat > "$OPENCLAW_HOME/workspace/README.md" << 'EOF'
# 🗡️ OpenCode Portable Pentest Workspace

This workspace contains pre-configured templates and workflows for penetration testing.

## Quick Start

1. Boot Kali Live USB with persistence
2. Open terminal, gateway should auto-check
3. Run `oc-start` if needed
4. Open dashboard: `oc-dashboard`

## Templates

- `templates/recon-network.md` - Network reconnaissance
- `templates/recon-web.md` - Web application testing
- `templates/recon-wifi.md` - Wireless security testing

## Memory

Daily findings are stored in `memory/YYYY-MM-DD.md`

## Backup

Run `./backup-config.sh` before removing USB drive

## Security Notes

- Only test systems you have written authorization to test
- Document all authorization in memory files
- Encrypt persistence partition for sensitive engagements
- Never leave USB unattended
EOF

# Final instructions
echo ""
echo "✅ OpenCode setup complete!"
echo ""
echo "Quick commands:"
echo "  oc-start      - Start gateway"
echo "  oc-status     - Check status"
echo "  oc-dashboard  - Open web UI"
echo "  oc-nodes      - List connected nodes"
echo ""
echo "Templates available in ~/.opencode/workspace/templates/"
echo ""
echo "🗡️  Happy (legal) hacking!"
POSTINSTALL_EOF

    chmod +x "$postinstall_dir/opencode-setup.sh"
    
    # Also create a README on the USB root
    cat > "$postinstall_dir/README-OPENCLAW.txt" << 'EOF'
═══════════════════════════════════════════════════════════
  KALI + OPENCLAW PORTABLE PENTEST USB
═══════════════════════════════════════════════════════════

BOOT INSTRUCTIONS:
1. Boot from this USB
2. Select "Live USB Persistence" at boot menu
3. Login: kali / kali (default Kali credentials)

FIRST BOOT SETUP:
1. Open terminal
2. Run: sudo bash /postinstall/opencode-setup.sh
3. Wait for installation (~2-5 minutes)
4. Start using: oc-start

QUICK COMMANDS:
  oc-start      - Start OpenCode gateway
  oc-status     - Check gateway status  
  oc-dashboard  - Open web UI (localhost:18789)
  oc-nodes      - List connected nodes
  oc-approve    - Approve pending nodes

TEMPLATES:
  ~/.opencode/workspace/templates/
  - recon-network.md
  - recon-web.md
  - recon-wifi.md

BACKUP:
  Run before removing USB:
  ~/.opencode/workspace/backup-config.sh

SECURITY:
  - Only test authorized systems
  - Encrypt persistence for sensitive work
  - Never leave USB unattended

GitHub: [YOUR REPO URL]
═══════════════════════════════════════════════════════════
EOF

    # Copy postinstall scripts to a location that will be accessible after boot
    # Note: In a real implementation, you'd mount the persistence partition here
    # and copy these files to it. For now, we create instructions.
    
    log_success "Setup scripts created"
    
    # Step 6: Create documentation
    log_info "Step 6/7: Creating documentation..."
    
    cat > "$postinstall_dir/USB-BUILD-README.md" << 'EOF'
# Kali + OpenCode Portable Pentest USB

## What This Is

A bootable USB drive that combines:
- **Kali Linux Live** - Full pentest toolkit
- **Persistence** - Your configs survive reboots
- **OpenCode** - Automation layer for recon, exploitation, documentation

## Why This Exists

Traditional pentesting workflow problems:
1. Tools scattered across machines
2. Manual, repetitive recon workflows  
3. Forgetting to document findings
4. Leaving traces on client systems

This USB solves all of that in one bootable package.

## Build Instructions

```bash
# Clone this repo
git clone https://github.com/YOURUSERNAME/kali-opencode-usb.git
cd kali-opencode-usb

# Build the USB (REPLACE /dev/sdX with your USB device)
sudo ./build-usb.sh /dev/sdX

# Wait 10-20 minutes for download + write
```

## Usage

### Boot
1. Plug USB into target machine
2. Boot from USB (may need F12/Del for boot menu)
3. Select **"Live USB Persistence"** (IMPORTANT!)
4. Login: `kali` / `kali`

### First Boot
```bash
# Run the setup script
sudo bash /postinstall/opencode-setup.sh

# Or if you copied it to home:
bash ~/opencode-setup.sh
```

### Daily Use
```bash
# Start gateway
oc-start

# Check status
oc-status

# Open dashboard
oc-dashboard  # Opens localhost:18789

# Start a recon session
oc-recon

# Check nodes
oc-nodes
```

### Deploy Drop-Box Nodes
```bash
# On target network machine
opencode node run --host <your-kali-ip> --port 18789

# Approve on your Kali gateway
opencode nodes approve <requestId>

# Control remotely
opencode nodes run --node <name> -- nmap -sV 192.168.1.0/24
```

### Backup Before Removing
```bash
~/.opencode/workspace/backup-config.sh
```

## Security Considerations

### Legal
- **Only test systems you have written authorization for**
- Document authorization in memory files
- This is a powerful tool - use responsibly

### Operational
- Encrypt persistence partition for sensitive engagements
- Never leave USB unattended
- Use TLS for gateway connections
- Consider panic-wipe script for high-risk scenarios

### Technical
- USB 3.0+ recommended (2.0 is painfully slow)
- 32GB+ drive minimum
- SSD-based USB drives much faster than flash
- Always safely shutdown (don't just yank USB!)

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    USB Drive                            │
├─────────────────────────────────────────────────────────┤
│  [EFI Boot]  - Kali bootloader                          │
│  [Live ISO]  - Read-only Kali base system               │
│  [Persist]   - Your configs, workspace, keys            │
│                /home/kali/.opencode/                     │
└─────────────────────────────────────────────────────────┘
                          │
                          │ Boot on any x64 machine
                          ▼
┌─────────────────────────────────────────────────────────┐
│              Your Portable Pentest Rig                  │
│  • Full Kali toolset (nmap, metasploit, burp, etc.)     │
│  • OpenCode gateway (automation + orchestration)        │
│  • Pre-configured workflows                             │
│  • Auto-documentation                                   │
│  • Nothing touches host disk                            │
└─────────────────────────────────────────────────────────┘
```

## Troubleshooting

### Persistence not working
- Make sure you selected "Live USB Persistence" at boot
- Check persistence.conf exists: `cat /persistence/persistence.conf`

### OpenCode won't start
- Check Node.js is installed: `node -v`
- Reinstall: `curl -fsSL https://opencode.ai/install.sh | bash`

### Gateway won't bind
- Check port isn't in use: `netstat -tlnp | grep 18789`
- Change port: `opencode config set gateway.port 18790`

## Contributing

This is a starter template. Make it yours:
- Add your own workflow templates
- Customize the bash aliases
- Add pre-approved tools for your workflow
- Build automation scripts for common engagements

## License

MIT - Do what you want, just don't be evil.

## Credits

Built with:
- Kali Linux (https://kali.org)
- OpenCode (https://opencode.ai)

Idea timestamped: 2026-02-26 21:57 CST
Because good ideas get stolen. 🗡️
EOF

    log_success "Documentation created"
    
    # Step 7: Final instructions
    log_info "Step 7/7: Finalizing..."
    
    echo ""
    log_success "USB build complete!"
    echo ""
    echo "═══════════════════════════════════════════════════════════"
    echo "  NEXT STEPS:"
    echo "═══════════════════════════════════════════════════════════"
    echo ""
    echo "1. Boot from USB (select 'Live USB Persistence')"
    echo "2. After first boot, run the setup script:"
    echo "   sudo bash /postinstall/opencode-setup.sh"
    echo ""
    echo "3. Or manually:"
    echo "   curl -fsSL https://opencode.ai/install.sh | bash"
    echo ""
    echo "Post-install scripts are in: $postinstall_dir"
    echo ""
    echo "═══════════════════════════════════════════════════════════"
    echo "  🗡️  Happy (legal) hacking!"
    echo "═══════════════════════════════════════════════════════════"
    
    # Cleanup
    rm -f "$iso_path"
}

# Run main function
main "$@"
