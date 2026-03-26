══════════════════════════════════════════════════════════
  KALI + OPENCODE + CLI AGENT PORTABLE PENTEST USB
══════════════════════════════════════════════════════════

BOOT INSTRUCTIONS:
1. Boot from this USB
2. Select "Live USB Persistence" at boot menu
3. Login: kali / kali (default Kali credentials)

FIRST BOOT SETUP:
1. Open terminal
2. Run: sudo bash ~/opencode-setup.sh
   OR: sudo bash /path/to/postinstall/opencode-setup.sh
3. Wait for installation (~5-10 minutes)
4. Choose whether to install Ollama for offline AI

QUICK COMMANDS:
  OpenCode:
    oc-web        - Start OpenCode web interface
    oc-start      - Start OpenCode server

  CLI Agent:
    agent-chat    - Start CLI Agent with cloud API
    agent-chat --model ollama:llama3  - Use offline AI

  Ollama:
    ollama pull <model>  - Download a model
    ollama list          - List installed models

AI MODELS:
  Cloud (needs API key):
    - deepseek:deepseek-chat
    - anthropic:claude-3.5-sonnet
    - openai:gpt-4-turbo
    - gemini:gemini-2.5-flash

  Local (works offline):
    - ollama:llama3
    - ollama:codellama
    - ollama:mistral

SETUP API KEYS:
  export DEEPSEEK_API_KEY=your_key
  export ANTHROPIC_API_KEY=your_key
  export OPENAI_API_KEY=your_key

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
  - Use VPN for remote connections

GitHub: https://github.com/YOURUSERNAME/kali-opencode-usb
══════════════════════════════════════════════════════════
