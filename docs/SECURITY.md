# Security Considerations

## ⚠️ Legal Warning

> **This tool is for authorized security testing ONLY.**

Unauthorized access to computer systems is illegal in most jurisdictions (CFAA in the US, Computer Misuse Act in the UK, etc.). Always obtain **written authorization** before testing any system you don't own.

### Before Any Engagement

- [ ] Obtain signed engagement letter specifying scope
- [ ] Document authorized targets in `workspace/authorization/`
- [ ] Verify rules of engagement (ROE)
- [ ] Confirm emergency contact procedures
- [ ] Understand what's out of scope

---

## Operational Security (OpSec)

### Physical Security

| Risk | Mitigation |
|------|------------|
| USB lost/stolen | Encrypt persistence partition |
| Left unattended | Never leave USB plugged in unattended |
| Seized by client | Use panic-wipe script (see below) |
| Compromised host | Boot Live USB - nothing touches host disk |

### Encryption

**Encrypt your persistence partition:**

```bash
# During USB creation
sudo cryptsetup luksFormat /dev/sdX3
sudo cryptsetup open /dev/sdX3 persistence
sudo mkfs.ext4 /dev/mapper/persistence
```

Now you'll need a passphrase at boot to access persistence.

### Panic Wipe

For high-risk engagements, create an emergency wipe script:

```bash
#!/bin/bash
# panic-wipe.sh - EMERGENCY USE ONLY

echo "⚠️  PANIC WIPE INITIATED ⚠️"
echo "This will destroy all data on the USB persistence partition."
read -p "Are you sure? (YES): " confirm

if [[ "$confirm" == "YES" ]]; then
    # Shred sensitive files
    find ~/.opencode/workspace -type f -exec shred -u {} \;
    
    # Zero free space
    dd if=/dev/zero of=/home/kali/zero.file bs=1M
    rm -f /home/kali/zero.file
    
    # Clear bash history
    history -c
    rm -f ~/.bash_history
    
    echo "Wipe complete. Remove USB immediately."
    sudo shutdown now
fi
```

---

## Network Security

### Gateway Exposure

By default, the gateway binds to LAN. Consider:

```bash
# Bind to localhost only (more secure)
opencode config set gateway.bind localhost

# Or use TLS for remote connections
opencode config set gateway.tls true
```

### Remote Node Connections

When deploying nodes on target network:

1. **Use TLS** - Encrypt all node↔gateway traffic
2. **Token rotation** - Change gateway tokens regularly
3. **Firewall rules** - Only allow specific IPs to connect
4. **Monitoring** - Log all node connections

```bash
# Deploy node with TLS
opencode node run --host <gateway> --port 18789 --tls --tls-fingerprint <fingerprint>
```

### VPS Gateway (Recommended)

Instead of running gateway on USB:

```
┌─────────────┐      TLS      ┌─────────────┐      Local     ┌─────────────┐
│  Target Net │ ────────────► │  VPS Gateway│ ◄────────────► │  Your USB   │
│   Nodes     │               │             │                │  (Control)  │
└─────────────┘               └─────────────┘                └─────────────┘
```

**Benefits:**
- USB never directly connected to target network
- Centralized logging and control
- Can control multiple engagements simultaneously
- USB can be removed after deployment

---

## Data Handling

### Sensitive Data

**Never store in plaintext:**

- Client credentials
- Exploited passwords/hash dumps
- PII (personally identifiable information)
- Proprietary client data

**Use encrypted storage:**

```bash
# Create encrypted volume for sensitive data
cryptsetup luksFormat sensitive.img
cryptsetup open sensitive.img sensitive_data
mkdir /mnt/sensitive
mount /dev/mapper/sensitive_data /mnt/sensitive

# Work in encrypted volume
# When done:
umount /mnt/sensitive
cryptsetup close sensitive_data
```

### Data Retention

**After engagement:**

1. Backup findings to secure storage
2. Shred local copies:
   ```bash
   find workspace/engagements/client-name -type f -exec shred -u {} \;
   ```
3. Verify deletion:
   ```bash
   find workspace/ -name "*client-name*"  # Should return nothing
   ```

---

## Tool Security

### Allowlist Management

Only approve tools you actually need:

```bash
# View current allowlist
opencode approvals allowlist list

# Remove unused tools
opencode approvals allowlist remove --node localhost "/usr/bin/unneeded-tool"
```

### Supply Chain

**Verify installations:**

```bash
# Check OpenCode integrity
opencode doctor

# Verify Node.js
node -v
npm -v

# Check for unexpected processes
ps aux | grep -E "(node|opencode)"
```

### Updates

**Keep everything updated:**

```bash
# Update Kali
sudo apt update && sudo apt full-upgrade -y

# Update OpenCode
opencode update

# Update node packages
npm update -g opencode
```

---

## Engagement Checklist

### Pre-Engagement

- [ ] Signed authorization obtained
- [ ] Scope clearly defined
- [ ] Emergency contacts documented
- [ ] USB encryption enabled
- [ ] Backup of current config created
- [ ] Tools tested and working
- [ ] Gateway configured securely

### During Engagement

- [ ] All activities logged in memory files
- [ ] Authorization documents accessible
- [ ] USB never left unattended
- [ ] Only in-scope targets tested
- [ ] Regular backups created

### Post-Engagement

- [ ] All findings documented
- [ ] Sensitive data securely deleted
- [ ] Backup synced to secure storage
- [ ] Logs reviewed for completeness
- [ ] Lessons learned documented

---

## Incident Response

### If USB is Lost/Stolen

1. **Change all credentials** that were on the USB
2. **Notify affected clients** if their data was stored
3. **Revoke any API keys/tokens** that were saved
4. **Document the incident** for legal/compliance

### If Compromised During Engagement

1. **Disconnect immediately** - Remove USB
2. **Document what happened** - Timeline, indicators
3. **Preserve evidence** - Don't wipe until forensics done
4. **Notify client** - Per engagement terms

---

## Best Practices Summary

| Do | Don't |
|----|-------|
| Encrypt persistence | Store credentials in plaintext |
| Document authorization | Test out-of-scope targets |
| Backup regularly | Leave USB unattended |
| Use TLS for remote | Run gateway on public IP without auth |
| Shred sensitive data | Just delete files (use shred) |
| Keep tools updated | Use outdated Kali images |
| Log all activities | Share engagement details publicly |

---

## Resources

- [Kali Security](https://kali.org/docs/)
- [OpenCode Security Docs](https://trust.opencode.ai)
- [MITRE ATT&CK](https://attack.mitre.org/) - Adversary tactics
- [PTES](http://www.pentest-standard.org/) - Penetration Testing Execution Standard
- [OWASP](https://owasp.org/) - Web security guidelines

---

> **Remember:** With great power comes great responsibility. Use this tool ethically and legally.
