#!/usr/bin/env bash
# Fedora 43 – Personal Profile Installer (Non-Interactive)
# Converts an interactive, prompt-based setup into a toggle-based, idempotent script.
# Edit the USER CONFIG section, then run once as root.

set -Eeuo pipefail
IFS=$'\n\t'

### ===== USER CONFIG (edit these) ===== ###
# Identity & host
USER_NAME="nathan"
USER_GROUP="nathan"
SET_HOSTNAME=1
HOSTNAME_SHORT="nathan-framework16"
HOSTNAME_PRETTY="Nathan Framework 16"

# Secondary drive (by label)
CONFIGURE_SECOND_DRIVE=1
SECOND_DRIVE_LABEL="crucial2tb"            # e.g. your Steam library
SECOND_DRIVE_MOUNT="/mnt/${SECOND_DRIVE_LABEL}"
SECOND_DRIVE_MODE="0755"

# Repos & codecs
ENABLE_RPMFUSION=1
INSTALL_MULTIMEDIA=1        # Uses ffmpeg + gstreamer rather than fragile Group names

# Apps (DNF)
INSTALL_GIT=1
INSTALL_STEAM=1
INSTALL_DISCORD=1
INSTALL_SYNCTHING=1

# Flatpak & apps
INSTALL_FLATPAK=1
INSTALL_SIGNAL_FLATPAK=1
INSTALL_BAR_FLATPAK=0       # Beyond All Reason

# VSCodium
INSTALL_VSCODIUM=1

# NVIDIA drivers (only if truly needed)
INSTALL_NVIDIA=0

# Dry-run mode for testing (0 = real run, 1 = print only)
DRY_RUN=0

### ===== Helpers ===== ###
log(){ printf "\e[1;32m[+]\e[0m %s\n" "$*"; }
warn(){ printf "\e[1;33m[!]\e[0m %s\n" "$*"; }
err(){ printf "\e[1;31m[x]\e[0m %s\n" "$*" 1>&2; }
run(){ if [[ $DRY_RUN -eq 1 ]]; then printf 'DRY-RUN: %q\n' "$*"; else eval "$@"; fi }
need(){ command -v "$1" >/dev/null 2>&1 || { err "Missing command: $1"; exit 1; }; }
require_root(){ if [[ $EUID -ne 0 ]]; then err "Run as root: sudo bash $0"; exit 1; fi }

### ===== Start ===== ###
require_root
need dnf

# 0) Refresh cache early
log "Refreshing package metadata…"
run dnf -y makecache || true

# 1) Hostname (non-interactive)
if [[ $SET_HOSTNAME -eq 1 ]]; then
  log "Setting hostnames: $HOSTNAME_SHORT / $HOSTNAME_PRETTY"
  run hostnamectl set-hostname "$HOSTNAME_SHORT"
  run hostnamectl set-hostname "$HOSTNAME_PRETTY" --pretty
else
  log "Skipping hostname change"
fi

# 2) RPM Fusion
if [[ $ENABLE_RPMFUSION -eq 1 ]]; then
  FEDVER=$(rpm -E %fedora)
  log "Enabling RPM Fusion Free/Nonfree for Fedora $FEDVER"
  run dnf -y install \
    "https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-${FEDVER}.noarch.rpm" \
    "https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-${FEDVER}.noarch.rpm" || true
  run dnf -y makecache || true
else
  log "Skipping RPM Fusion"
fi

# 3) Multimedia codecs (avoid fragile group names like 'Multimedia')
if [[ $INSTALL_MULTIMEDIA -eq 1 ]]; then
  log "Installing multimedia codecs (ffmpeg, gstreamer, openh264, lame-libs)…"
  run dnf -y install ffmpeg gstreamer1-plugin-openh264 \
    gstreamer1-plugins-{bad-free,good,ugly,base} lame-libs || true
else
  log "Skipping multimedia codecs"
fi

# 4) Syncthing
if [[ ${INSTALL_SYNCTHING:-0} -eq 1 ]]; then
  log "Installing Syncthing…"
  run dnf -y install syncthing || true
else
  log "Skipping Syncthing"
fi

# 5) Second drive setup (by label)
if [[ $CONFIGURE_SECOND_DRIVE -eq 1 ]]; then
  need blkid
  log "Configuring second drive: LABEL='${SECOND_DRIVE_LABEL}' at '${SECOND_DRIVE_MOUNT}'"

  # Create mountpoint & ownership/mode (idempotent)
  run install -d -m "$SECOND_DRIVE_MODE" -o "$USER_NAME" -g "$USER_GROUP" "$SECOND_DRIVE_MOUNT"

  # Extract UUID & FSTYPE from blkid
  INFO=$(blkid | grep -E "LABEL=\"${SECOND_DRIVE_LABEL}\"" || true)
  if [[ -n "$INFO" ]]; then
    UUID=$(awk -F '"' '{for(i=1;i<=NF;i++){if($(i-1)~/(^| )UUID=$/){print $i}}}' <<<"$INFO" | head -n1)
    FSTYPE=$(awk -F '"' '{for(i=1;i<=NF;i++){if($(i-1)~/(^| )TYPE=$/){print $i}}}' <<<"$INFO" | head -n1)
  else
    UUID=""; FSTYPE=""
  fi

  if [[ -z "$UUID" || -z "$FSTYPE" ]]; then
    warn "Could not resolve UUID/FSTYPE for LABEL='${SECOND_DRIVE_LABEL}'. Skipping fstab update."
  else
    FSTAB_ENTRY="UUID=${UUID}  ${SECOND_DRIVE_MOUNT}  ${FSTYPE}  defaults  0  2"
    log "Ensuring /etc/fstab contains entry for ${SECOND_DRIVE_LABEL} (${FSTYPE})"
    if grep -Fqx -- "$FSTAB_ENTRY" /etc/fstab 2>/dev/null; then
      log "fstab entry already present"
    else
      run bash -c "printf '%s\n' '$FSTAB_ENTRY' >> /etc/fstab"
      log "fstab entry added"
    fi
    log "Reloading units & mounting all"
    run systemctl daemon-reload || true
    run mount -a || warn "mount -a returned non-zero; verify filesystem"
  fi
else
  log "Skipping second drive configuration"
fi

# 6) Steam
if [[ $INSTALL_STEAM -eq 1 ]]; then
  log "Installing Steam…"
  run dnf -y install steam || true
else
  log "Skipping Steam"
fi

# 7) Discord
if [[ $INSTALL_DISCORD -eq 1 ]]; then
  log "Installing Discord…"
  run dnf -y install discord || true
else
  log "Skipping Discord"
fi

# 8) Git
if [[ $INSTALL_GIT -eq 1 ]]; then
  log "Installing Git…"
  run dnf -y install git || true
else
  log "Skipping Git"
fi

# 9) Flatpak + Flathub + Apps
if [[ $INSTALL_FLATPAK -eq 1 ]]; then
  if command -v flatpak >/dev/null 2>&1; then
    log "Flatpak already present"
  else
    log "Installing Flatpak…"
    run dnf -y install flatpak || true
  fi
  log "Enabling Flathub remote (idempotent)…"
  run flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo || true

  if [[ $INSTALL_SIGNAL_FLATPAK -eq 1 ]]; then
    log "Installing Signal (Flatpak)…"
    run flatpak install -y flathub org.signal.Signal || true
  fi
  if [[ $INSTALL_BAR_FLATPAK -eq 1 ]]; then
    log "Installing Beyond All Reason (Flatpak)…"
    run flatpak install -y flathub info.beyondallreason.bar || true
  fi
else
  log "Skipping Flatpak setup"
fi

# 10) VSCodium repo + install (idempotent)
if [[ $INSTALL_VSCODIUM -eq 1 ]]; then
  log "Setting up VSCodium repo + installing codium…"
  GPG_KEY_URL="https://gitlab.com/paulcarroty/vscodium-deb-rpm-repo/-/raw/master/pub.gpg"
  REPO_FILE="/etc/yum.repos.d/vscodium.repo"
  REPO_CONTENT="[gitlab.com_paulcarroty_vscodium_repo]\nname=download.vscodium.com\nbaseurl=https://download.vscodium.com/rpms/\nenabled=1\ngpgcheck=1\nrepo_gpgcheck=1\ngpgkey=${GPG_KEY_URL}\nmetadata_expire=1h"

  # Import key (safe to re-run)
  run rpmkeys --import "$GPG_KEY_URL" || true

  if [[ -f "$REPO_FILE" ]]; then
    log "VSCodium repo already exists"
  else
    log "Creating $REPO_FILE"
    run bash -c "printf '%b' '$REPO_CONTENT' > '$REPO_FILE'"
  fi
  run dnf -y install codium || true
else
  log "Skipping VSCodium"
fi

# 11) NVIDIA drivers (if you truly need them)
if [[ $INSTALL_NVIDIA -eq 1 ]]; then
  log "Installing NVIDIA akmods & CUDA packages…"
  run dnf -y upgrade --refresh || true
  run dnf -y install akmod-nvidia xorg-x11-drv-nvidia-cuda || true
else
  log "Skipping NVIDIA drivers"
fi

log "Done. Re-run safely anytime; steps are idempotent."
