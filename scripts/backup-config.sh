#!/bin/bash
################################################################################
# Backup OpenCode Configuration and Findings
#
# Creates timestamped backup of your OpenCode workspace for safekeeping
# before removing USB drive or syncing to remote storage.
#
# Usage: ./backup-config.sh [remote-user@remote-host]
################################################################################

set -euo pipefail

OPENCLAW_HOME="${OPENCLAW_HOME:-$HOME/.opencode}"
BACKUP_BASE="$OPENCLAW_HOME/workspace/backups"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
BACKUP_DIR="$BACKUP_BASE/opencode-$TIMESTAMP"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}🗡️  OpenCode Backup${NC}"
echo "═══════════════════════════════════════════════════════════"
echo ""

# Create backup directory
mkdir -p "$BACKUP_DIR"

echo "Backing up configuration..."

# Backup config
cp -r "$OPENCLAW_HOME/opencode.json" "$BACKUP_DIR/" 2>/dev/null || true
cp -r "$OPENCLAW_HOME/opencode.json.bak" "$BACKUP_DIR/" 2>/dev/null || true

# Backup workspace (excluding large media files)
echo "Backing up workspace..."
rsync -av --exclude='*.mp4' --exclude='*.mov' --exclude='*.avi' \
    "$OPENCLAW_HOME/workspace/" "$BACKUP_DIR/workspace/" 2>/dev/null || \
    cp -r "$OPENCLAW_HOME/workspace/" "$BACKUP_DIR/" 2>/dev/null || true

# Backup agents/sessions
echo "Backing up agent sessions..."
cp -r "$OPENCLAW_HOME/agents/" "$BACKUP_DIR/" 2>/dev/null || true

# Backup devices
echo "Backing up device pairings..."
cp -r "$OPENCLAW_HOME/devices/" "$BACKUP_DIR/" 2>/dev/null || true

# Create manifest
cat > "$BACKUP_DIR/BACKUP-MANIFEST.txt" << EOF
OpenCode Backup Manifest
═══════════════════════════════════════════════════════════
Timestamp: $TIMESTAMP
Hostname:  $(hostname)
User:      $(whoami)
Path:      $BACKUP_DIR

Contents:
$(ls -la "$BACKUP_DIR")

═══════════════════════════════════════════════════════════
EOF

echo ""
echo -e "${GREEN}✅ Backup created:${NC} $BACKUP_DIR"
echo ""

# Calculate size
BACKUP_SIZE=$(du -sh "$BACKUP_DIR" 2>/dev/null | cut -f1)
echo "Backup size: $BACKUP_SIZE"
echo ""

# Optional: Sync to remote
REMOTE="${1:-}"
if [[ -n "$REMOTE" ]]; then
    echo -e "${YELLOW}Syncing to remote: $REMOTE${NC}"
    
    REMOTE_DIR="/backups/opencode/"
    rsync -avz -e ssh "$BACKUP_DIR" "$REMOTE:$REMOTE_DIR"
    
    echo -e "${GREEN}✅ Synced to remote${NC}"
fi

# Cleanup old backups (keep last 10)
echo ""
echo "Cleaning up old backups (keeping last 10)..."
cd "$BACKUP_BASE"
ls -dt */ 2>/dev/null | tail -n +11 | xargs rm -rf 2>/dev/null || true

echo ""
echo "═══════════════════════════════════════════════════════════"
echo "🗡️  Backup complete. Safe to remove USB."
echo "═══════════════════════════════════════════════════════════"
