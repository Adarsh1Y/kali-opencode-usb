# 🗡️ Kali + OpenCode Portable Pentest USB

> **Boot anywhere. Pentest everything. Leave no trace.**

A bootable USB drive combining **Kali Linux Live** with **OpenCode AI automation** for portable, automated penetration testing. Includes optional **CLI Agent** for local/offline AI assistance.

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Kali](https://img.shields.io/badge/Kali-2025.1-blue)](https://kali.org)
[![OpenCode](https://img.shields.io/badge/OpenCode-latest-green)](https://opencode.ai)
[![CLI Agent](https://img.shields.io/badge/CLI%20Agent-v1.2.6-orange)](https://github.com/amranu/cli-agent)

---

## 🔥 Why This Exists

Traditional pentesting workflow problems:

| Problem | This Solution |
|---------|---------------|
| Tools scattered across machines | Single USB, everything pre-configured |
| Manual, repetitive recon workflows | OpenCode + CLI Agent automate workflows |
| Forgetting to document findings | Auto-documentation and memory files |
| Leaving traces on client systems | Boot Live USB, nothing touches host disk |
| API dependency for AI tools | CLI Agent works offline with local models |
| Different environments per engagement | Consistent rig every time |

---

## 📦 What You Get

- **Full Kali Linux** - Every pentest tool you know (nmap, metasploit, burp, hashcat, etc.)
- **OpenCode** - Modern AI CLI with native MCP support, web interface, and multi-agent coordination
- **CLI Agent** - Lightweight AI agent that works offline with Ollama/local models
- **Persistence** - Your configs, workflows, and findings survive reboots
- **Pre-configured Templates** - Network recon, web app testing, wireless audits
- **Drop-Box Node Support** - Deploy remote nodes on target network
- **Forensically Clean** - Remove USB, no trace on host (RAM only)

---

## 🚀 Quick Start

### Build the USB

```bash
# Clone this repo
git clone https://github.com/YOURUSERNAME/kali-opencode-usb.git
cd kali-opencode-usb

# Build the USB (REPLACE /dev/sdX with your USB device)
sudo ./build-usb.sh /dev/sdX

# Wait 10-20 minutes (downloads ~3GB Kali ISO)
```

### Boot

1. Plug USB into target machine
2. Boot from USB (F12/Del/Esc for boot menu)
3. **IMPORTANT:** Select **"Live USB Persistence"** at boot menu
4. Login: `kali` / `kali` (default Kali credentials)

### First Boot Setup

```bash
# Run the post-install script
sudo bash ~/opencode-setup.sh

# Or manually install OpenCode
curl -fsSL https://opencode.ai/install.sh | bash
```

### Daily Use

```bash
# Start OpenCode
opencode

# Or use CLI Agent with local models (offline capable)
opencode-agent chat --model ollama:llama3

# Quick commands
alias opencode-start='opencode serve'
alias agent-chat='opencode-agent chat'
```

---

## 🤖 AI Tool Options

This USB includes **two** AI tools for maximum flexibility:

### OpenCode (Cloud + Local)

```bash
# Start OpenCode
opencode

# Open web interface
opencode web

# MCP server for AI models
opencode mcp serve
```

**Features:**
- Modern TUI and web interface
- Native MCP protocol support
- Multi-agent coordination
- GitHub integration
- Session management

### CLI Agent (Local-First)

```bash
# Start CLI Agent
agent chat

# Or with local Ollama models (no internet needed!)
agent chat --model ollama:llama3

# MCP server for exposing models
python mcp_server.py --stdio
```

**Features:**
- Works completely offline with Ollama
- Supports: Claude, GPT, DeepSeek, Gemini, OpenRouter, Ollama
- Built-in tools: file ops, bash, web fetch, grep, glob
- Subagent spawning for parallel tasks
- Deep research workflow

### Ollama (Local Models)

```bash
# Install Ollama
curl -fsSL https://ollama.com/install.sh | bash

# Pull a model
ollama pull llama3
ollama pull codellama

# Use with CLI Agent
agent chat --model ollama:llama3
```

---

## 📁 Repository Structure

```
kali-opencode-usb/
├── build-usb.sh              # Main build script
├── postinstall/
│   ├── opencode-setup.sh     # First-boot setup
│   └── README-OPENCODE.txt   # Quick reference
├── templates/
│   ├── recon-network.md      # Network reconnaissance
│   ├── recon-web.md          # Web app testing
│   └── recon-wifi.md         # Wireless audits
├── scripts/
│   ├── backup-config.sh      # Backup before removing USB
│   └── deploy-node.sh        # Deploy drop-box nodes
├── docs/
│   ├── USAGE.md              # Detailed usage guide
│   ├── SECURITY.md           # Security considerations
│   └── TROUBLESHOOTING.md    # Common issues
└── README.md                 # This file
```

---

## 🎯 Use Cases

### 1. On-Site Penetration Testing

```bash
# Boot USB on your laptop at client site
opencode

# Run AI-assisted network recon
# Use OpenCode's TUI or CLI Agent for guidance

# Document findings in real-time
write path="memory/client-engagement.md" content="..."
```

### 2. Offline/Air-Gapped Testing

```bash
# Install Ollama with models before engagement
ollama pull llama3
ollama pull codellama

# Use CLI Agent offline
agent chat --model ollama:llama3

# All AI assistance works without internet
```

### 3. Remote Node Orchestration

```bash
# Deploy node on target network machine
opencode node run --host <your-kali-ip> --port 18789 --display-name "Target-Box"

# Approve on your USB gateway
opencode nodes approve <requestId>

# Run scans remotely
opencode nodes run --node "Target-Box" -- nmap -sV 192.168.1.0/24
```

### 4. Security Audits + Compliance

```bash
# Automated documentation
# All tool outputs captured in memory files

# Backup findings
./backup-config.sh

# Sync to secure storage
rsync -avz ~/.opencode/workspace/backups user@vps:/secure/
```

---

## 🛠️ Pre-Configured Tools

The build script pre-configures OpenCode to allow these common pentest tools:

| Tool | Purpose |
|------|---------|
| `nmap` | Network discovery + port scanning |
| `sqlmap` | SQL injection testing |
| `burpsuite` | Web app proxy + scanner |
| `metasploit` | Exploitation framework |
| `hashcat` | Password cracking |
| `john` | John the Ripper |
| `gobuster` | Directory enumeration |
| `nikto` | Web server scanning |
| `wfuzz` | Web fuzzing |
| `dirb` | Directory brute-forcing |
| `hydra` | Online password cracking |
| `netcat` | Network utility |

---

## 🔐 Security Considerations

### Legal

> ⚠️ **Only test systems you have written authorization to test.**

- Document all authorization in memory files
- Keep engagement letters in `workspace/authorization/`
- This is a powerful tool — use responsibly

### Operational Security

- **Encrypt persistence partition** for sensitive engagements
- **Never leave USB unattended**
- **Use TLS** for gateway connections
- **Consider panic-wipe script** for high-risk scenarios
- **Use a VPS gateway** instead of running on USB for remote operations

### Technical

- USB 3.0+ **strongly recommended** (2.0 is painfully slow)
- **32GB+ drive minimum** (Kali + tools + persistence)
- **SSD-based USB drives** (Samsung Fit, etc.) much faster than flash
- **Always safely shutdown** — don't just yank USB!

---

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    USB Drive                            │
├─────────────────────────────────────────────────────────┤
│  [EFI Boot]  - Kali bootloader                        │
│  [Live ISO]  - Read-only Kali base system             │
│  [Persist]   - /home/kali/.opencode/                  │
│                - /home/kali/.config/opencode/          │
│                - Your configs, workspace, keys          │
│                - Ollama models (if downloaded)          │
└─────────────────────────────────────────────────────────┘
                           │
                           │ Boot on any x64 machine
                           ▼
┌─────────────────────────────────────────────────────────┐
│              Your Portable Pentest Rig                  │
│  • Full Kali toolset                                  │
│  • OpenCode (cloud + local AI)                       │
│  • CLI Agent (offline-first AI)                      │
│  • Ollama support (local models)                     │
│  • Pre-configured workflows                          │
│  • Auto-documentation                                │
│  • Nothing touches host disk                         │
└─────────────────────────────────────────────────────────┘
```

---

## 📚 Documentation

- **[USAGE.md](docs/USAGE.md)** - Detailed usage guide
- **[SECURITY.md](docs/SECURITY.md)** - Security best practices
- **[TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md)** - Common issues + fixes

---

## 🤝 Contributing

This is a **starter template**. Make it yours:

1. **Add your workflow templates** - Every engagement is different
2. **Customize bash aliases** - Build your muscle memory
3. **Add pre-approved tools** - Your toolkit, your rules
4. **Build automation scripts** - Common engagements → one command
5. **Share back** - Submit PRs for useful additions

### Ideas for Extensions

- [ ] Encrypted persistence partition setup
- [ ] Auto-sync to secure cloud storage
- [ ] Pre-configured VPS gateway deployment
- [ ] Hardware token integration (YubiKey)
- [ ] Panic-wipe script for emergencies
- [ ] Custom Kali ISO with OpenCode + CLI Agent pre-installed
- [ ] Docker-based alternative build

---

## 🐛 Troubleshooting

### Persistence not working
```bash
# Verify you selected "Live USB Persistence" at boot
cat /persistence/persistence.conf  # Should contain: "/ union"
```

### OpenCode won't start
```bash
# Check installation
opencode --version

# Reinstall OpenCode
curl -fsSL https://opencode.ai/install.sh | bash
```

### CLI Agent won't start
```bash
# Check Python environment
which python3 && python3 --version

# Reinstall CLI Agent
cd ~/cli-agent && pip install -e .
```

### Gateway won't bind to port
```bash
# Check if port is in use
netstat -tlnp | grep 18789

# Change port in OpenCode config
```

### USB not booting
- Try different USB port (USB 3.0 vs 2.0)
- Disable Secure Boot in BIOS
- Try Rufus (Windows) or Etcher (Mac/Linux) to write ISO

---

## 📜 License

**MIT License** — Do what you want, just don't be evil.

```
Copyright (c) 2026 [Your Name]

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

---

## 🙏 Credits

Built with:
- **[Kali Linux](https://kali.org)** - The penetration testing distribution
- **[OpenCode](https://opencode.ai)** - Modern AI CLI for developers
- **[CLI Agent](https://github.com/amranu/cli-agent)** - MCP-enabled AI assistant with local model support
- **[Ollama](https://ollama.com)** - Local AI model runtime

---

## 📬 Contact

- **GitHub:** [@YOURUSERNAME](https://github.com/YOURUSERNAME)
- **OpenCode Discord:** [OpenCode Community](https://discord.gg/opencode)
- **Twitter:** [@YOURHANDLE]

---

> **Disclaimer:** This tool is for authorized security testing only. The authors are not responsible for misuse. Always obtain written permission before testing any system you don't own.
