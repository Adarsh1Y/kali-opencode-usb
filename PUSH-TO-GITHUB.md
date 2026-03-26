# 🚀 Publish to GitHub

## Step 1: Create a GitHub Repository

1. Go to [GitHub](https://github.com/new)
2. Repository name: `kali-opencode-usb`
3. Description: *"Bootable Kali Linux Live USB with OpenCode AI automation for portable penetration testing. Includes CLI Agent and Ollama support for offline AI assistance."*
4. Select **Private** or **Public** based on your preference
5. **Don't** initialize with README (you already have one)
6. Click **Create repository**

---

## Step 2: Connect and Push

```bash
# Navigate to repo
cd ~/kali-opencode-usb

# Add GitHub as remote (replace YOURUSERNAME)
git remote add origin https://github.com/YOURUSERNAME/kali-opencode-usb.git

# Push to GitHub
git push -u origin main
```

---

## Step 3: Customize for Your Brand

Update these files with your information:

### Update Placeholders
```bash
# Replace placeholders with your actual info
sed -i 's/YOURUSERNAME/your-github-handle/g' README.md
sed -i 's/\[Your Name\]/Your Name/g' README.md
sed -i 's/@YOURHANDLE/@your-twitter/g' README.md
```

### Add Topics to GitHub Repo

In GitHub repo settings → "Add topics":
```
kali-linux
penetration-testing
opencode
security-tools
pentest
red-team
portable
usb
automation
cybersecurity
cli-agent
ollama
```

### Repo Description

> *"Bootable Kali Linux USB with OpenCode AI + CLI Agent for portable pentesting. Pre-configured workflows, offline AI support via Ollama, and drop-box node deployment. Boot anywhere, pentest everything, leave no trace."*

---

## Step 4: Share It

### Communities

**Reddit:**
- r/netsec
- r/HowToHack
- r/KaliLinux
- r/cybersecurity

**Twitter/X:**
```
🗡️ Just shipped: Kali + OpenCode Portable Pentest USB

Bootable USB with AI-powered pentesting:
• OpenCode (cloud AI + automation)
• CLI Agent (offline-first)
• Ollama support (local models)
• Drop-box node deployment
• Leaves no trace on host

#cybersecurity #pentesting #kali #opencode
```

**Discord:**
- OpenCode Community: https://discord.gg/opencode
- NetSec communities

---

## Step 5: Maintain It

### Keep Updated

```bash
# When Kali releases new ISO
# Update KALI_ISO_URL in build-usb.sh

# When OpenCode/CLI Agent updates
# Update installation URLs in scripts

# Add new workflow templates
# Contribute back via PRs
```

### Watch for Issues

- Enable GitHub Issues
- Respond to bug reports
- Accept PRs for improvements

---

## 🎉 You Did It!

From idea → implementation → shipped in one session.

**Timestamp:** 2026-03-27  
**GitHub stars:** Incoming ⭐

---

> **Remember:** Good ideas get stolen. Ship fast. 🗡️
