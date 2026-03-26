#!/bin/bash
################################################################################
# Kali + OpenCode + CLI Agent Setup Script
# Runs after first boot into Kali Live
################################################################################

set -euo pipefail

KALI_USER="kali"
OPENCODE_HOME="/home/$KALI_USER/.opencode"
CLI_AGENT_HOME="/home/$KALI_USER/cli-agent"

echo "🗡️  Setting up OpenCode + CLI Agent for portable pentesting..."
echo ""

# ============================================================================
# Install OpenCode
# ============================================================================
echo "[1/3] Installing OpenCode..."
if command -v opencode &> /dev/null; then
    echo "  OpenCode already installed"
else
    curl -fsSL https://opencode.ai/install.sh | bash
fi
echo ""

# ============================================================================
# Install CLI Agent
# ============================================================================
echo "[2/3] Installing CLI Agent..."
if [[ -d "$CLI_AGENT_HOME" ]]; then
    echo "  CLI Agent directory exists, updating..."
    cd "$CLI_AGENT_HOME"
    git pull origin main 2>/dev/null || true
else
    echo "  Cloning CLI Agent..."
    cd /home/$KALI_USER
    git clone https://github.com/amranu/cli-agent.git
    cd cli-agent
fi

# Create venv and install
python3 -m venv .venv
source .venv/bin/activate
pip install --upgrade pip
pip install -e .
echo ""

# ============================================================================
# Install Ollama (optional - for offline AI)
# ============================================================================
echo "[3/3] Setting up Ollama (optional)..."
if command -v ollama &> /dev/null; then
    echo "  Ollama already installed"
else
    read -p "  Install Ollama for offline AI models? (y/n): " install_ollama
    if [[ "$install_ollama" == "y" ]]; then
        curl -fsSL https://ollama.com/install.sh | bash
        
        # Pull some useful models
        echo "  Pulling default models (this may take a while)..."
        ollama pull llama3
        ollama pull codellama
        echo "  Models ready for offline use"
    fi
fi
echo ""

# ============================================================================
# Create workspace structure
# ============================================================================
echo "Creating workspace structure..."
mkdir -p "$OPENCODE_HOME/workspace/memory"
mkdir -p "$OPENCODE_HOME/workspace/templates"
mkdir -p "$OPENCODE_HOME/workspace/backups"
mkdir -p "$OPENCODE_HOME/node-templates"
echo ""

# ============================================================================
# Create bash aliases
# ============================================================================
echo "Creating bash aliases..."
cat >> "/home/$KALI_USER/.bashrc" << 'EOF'

# ═══════════════════════════════════════════════════════════
# OpenCode + CLI Agent Portable Pentest Rig
# ═══════════════════════════════════════════════════════════

# OpenCode commands
alias oc-start='opencode serve'
alias oc-web='opencode web'
alias oc-status='opencode --version'

# CLI Agent commands
alias agent-chat='source ~/cli-agent/.venv/bin/activate && agent chat'
alias agent-ask='source ~/cli-agent/.venv/bin/activate && agent ask'

# Ollama commands
alias ollama-list='ollama list'
alias ollama-run='agent chat --model ollama:llama3'

# Quick pentest
alias nmap-quick='nmap -sV -sC -oN scan-$(date +%Y%m%d).txt'
alias nmap-full='nmap -p- -T4 -oN fullscan-$(date +%Y%m%d).txt'

# Auto-check on terminal open
echo "🗡️  Kali + OpenCode + CLI Agent ready"
echo "   Run 'oc-web' for web UI or 'agent-chat' for CLI Agent"
EOF

# ============================================================================
# Create MCP config for OpenCode with CLI Agent
# ============================================================================
echo "Configuring MCP servers..."
mkdir -p "/home/$KALI_USER/.config/opencode"
cat > "/home/$KALI_USER/.config/opencode/opencode.jsonc" << 'EOF'
{
  "$schema": "https://opencode.ai/config.json",
  "mcp": {
    "cli-agent": {
      "type": "local",
      "command": ["/home/kali/cli-agent/.venv/bin/python", "/home/kali/cli-agent/mcp_server.py"],
      "enabled": true
    }
  }
}
EOF

# ============================================================================
# Final instructions
# ============================================================================
echo ""
echo "═══════════════════════════════════════════════════════════"
echo "  ✅ Setup complete!"
echo "═══════════════════════════════════════════════════════════"
echo ""
echo "Quick commands:"
echo "  oc-web       - Start OpenCode web interface"
echo "  agent-chat   - Start CLI Agent"
echo "  agent-chat --model ollama:llama3  - Use offline AI"
echo ""
echo "Available AI models:"
echo "  Cloud:  deepseek, anthropic, openai, gemini"
echo "  Local: ollama:llama3, ollama:codellama"
echo ""
echo "🗡️  Happy (legal) hacking!"
echo "═══════════════════════════════════════════════════════════"
