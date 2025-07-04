#!/usr/bin/env bash
# ──────────────────────────────────────────────────────────
# 🔥 zoom_fix.sh: macOS Zoom Nuke & Reinstall with Ben from IT 🔥
# ──────────────────────────────────────────────────────────

set -Eeuo pipefail
trap 'echo "❌ Oops! Something went wrong at line $LINENO. Exiting…"; exit 1' ERR

LOG="$HOME/zoom_fix.log"
exec > >(tee -i "$LOG") 2>&1

USAGE="Usage: $0 [-f|--force]"

# ─── 0. Parse flags ───────────────────────────────────────
FORCE=false
while [[ $# -gt 0 ]]; do
  case $1 in
    -f|--force) FORCE=true; shift ;;
    *) echo "$USAGE"; exit 1 ;;
  esac
done

# ─── 1. Ensure macOS & deps ──────────────────────────────
[[ "$(uname)" == "Darwin" ]] || { echo "❌ Only macOS supported."; exit 1; }
for cmd in sudo curl openssl networksetup pkgutil; do
  command -v "$cmd" &>/dev/null || { echo "❌ Missing $cmd."; exit 1; }
done

# ─── 2. Detect primary interface ─────────────────────────
if networksetup -listallhardwareports | grep -q "Wi-Fi"; then
  IF=$(networksetup -listallhardwareports \
       | awk '/Wi-Fi/{getline; print $2}')
else
  IF=$(networksetup -listallhardwareports \
       | awk '/Device/ {print $2}' | grep '^en' | head -n1)
fi
[[ -n "$IF" ]] || { echo "❌ Could not find any en* interface."; exit 1; }
echo "✅ Interface: $IF"

# ─── 3. Optional confirm ──────────────────────────────────
if ! $FORCE; then
  read -p "🗑️ Delete Zoom & data? (y/n): " ans
  [[ $ans == [Yy] ]] || { echo "❌ Aborted."; exit 1; }
fi

# ─── 4. Kill & uninstall Zoom ────────────────────────────
echo "🚀 Killing Zoom…"
killall zoom.us Zoom zoom 2>/dev/null || true; sleep 2

echo "🧹 Removing app + prefs…"
sudo rm -rf /Applications/zoom.us.app
rm -rf \
  "$HOME/Library/Application Support/zoom.us" \
  "$HOME/Library/Caches/us.zoom.xos" \
  "$HOME/Library/Preferences/us.zoom.xos.plist" \
  "$HOME/Library/Logs/zoom.us" \
  "$HOME/Library/LaunchAgents/us.zoom.xos.plist" \
  "$HOME/Library/Preferences/zoom.us.conf" \
  "$HOME/Library/Containers/us.zoom.xos" \
  "$HOME/Library/Saved Application State/us.zoom.xos.savedState"

# ─── 5. Forget pkg receipts & Homebrew ────────────────────
ZOOM_PKG=$(pkgutil --pkgs | grep -i zoom | head -n1 || true)
[[ -n "$ZOOM_PKG" ]] && sudo pkgutil --forget "$ZOOM_PKG" || true

if command -v brew &>/dev/null; then
  CASK=$(brew list --cask 2>/dev/null | grep -i zoom || true)
  [[ -n "$CASK" ]] && brew uninstall --cask "$CASK"
fi

# ─── 6. Spoof MAC (try multiple syntaxes, no down/up) ────────────────────
ORIG_MAC=$(ifconfig "$IF" | awk '/ether/ {print $2}')
BACKUP="$HOME/.orig_mac_backup"
[[ -f $BACKUP ]] || echo "$ORIG_MAC" > "$BACKUP"

# Locally-administered MAC (02:xx:xx:xx:xx:xx)
NEW_MAC=$(printf '02:%02x:%02x:%02x:%02x:%02x' \
  $((RANDOM%256)) $((RANDOM%256)) $((RANDOM%256)) \
  $((RANDOM%256)) $((RANDOM%256)))

echo "🔧 Spoofing MAC: $ORIG_MAC → $NEW_MAC"

if sudo ifconfig "$IF" ether "$NEW_MAC" 2>/dev/null; then
  echo "✅ MAC spoofed via ‘ether’ syntax"
elif sudo ifconfig "$IF" lladdr "$NEW_MAC" 2>/dev/null; then
  echo "✅ MAC spoofed via ‘lladdr’ syntax"
else
  echo "⚠️ Failed to spoof MAC. If you’re on Wi-Fi, check your “Private Wi-Fi Address” setting in System Settings → Wi-Fi → Advanced and try disabling it, or test on a wired interface."
fi

# ─── 7. Flush DNS ───────────────────────────────────────
echo "🌐 Flushing DNS…"
sudo dscacheutil -flushcache
sudo killall -HUP mDNSResponder || true

# ─── 8. Restart network ──────────────────────────────────
# Skip the first “asterisk” note and any disabled (*) services
SERV=$(networksetup -listallnetworkservices \
       | tail -n +2 \
       | grep -v '^\*' \
       | head -n1)

if [[ -n "$SERV" ]]; then
  echo "🔄 Restarting network service: $SERV"
  sudo networksetup -setnetworkserviceenabled "$SERV" off
  sleep 2
  sudo networksetup -setnetworkserviceenabled "$SERV" on
  echo "✅ Network restarted"
else
  echo "⚠️ No active network service found; skipping restart"
fi

# ─── 9. Bong (optional) break ─────────────────────────────
echo "💨 Quick bong break…"; sleep 3

# ─── 10. Download & install Zoom ──────────────────────────
PKG="$HOME/Downloads/Zoom.pkg"
echo "⬇️ Downloading Zoom…"
curl -L --fail --silent --show-error -o "$PKG" "https://zoom.us/client/latest/Zoom.pkg" \
  || { echo "❌ Download failed."; exit 1; }

echo "📦 Installing…"
sudo installer -pkg "$PKG" -target / || { echo "❌ Installer failed."; exit 1; }

# ─── 11. Wipe residual data files ─────────────────────────
DATA="$HOME/Library/Application Support/zoom.us/data"
for f in viper.ini zoomus.enc.db zoommeeting.enc.db; do
  [[ -f "$DATA/$f" ]] && {
    echo "⚠️ Wiping $f"
    : > "$DATA/$f"
    chmod 400 "$DATA/$f"
  }
done

# ─── 12. Cleanup installer & finish ───────────────────────
rm -f "$PKG"
echo "🎉 All done, babe! Details in $LOG."
