# Fedora 43 Post-Installation Setup Script

This script automates post-install configuration on Fedora 43, enabling common repositories, installing key applications, configuring storage, and applying AMD GPU kernel tuning for AMD setups.

## What it does

- **Hostname & identity**
  - Sets system hostname and pretty hostname.
  - Assumes a primary user (name and group) for ownership of created resources.

- **RPM Fusion repositories**
  - Enables RPM Fusion Free and Nonfree for your current Fedora release.
  - Refreshes package metadata after enabling the repos.

- **Multimedia codecs**
  - Installs `ffmpeg`, OpenH264, and a curated set of GStreamer plugins for broad media playback support (avoids fragile DNF group names).

- **Secondary drive setup**
  - Looks up a drive by filesystem label (e.g. `games`).
  - Creates a mount point with chosen owner, group, and permissions.
  - Adds an idempotent `UUID=…` entry to `/etc/fstab` and runs `mount -a`.

- **Desktop applications (DNF)**
  - Optionally installs:
    - Steam
    - Discord
    - Syncthing
    - Git

- **Flatpak & Flathub**
  - Installs Flatpak if missing.
  - Adds the Flathub remote (only if not already present).
  - Optionally installs:
    - Signal (Flatpak)
    - Beyond All Reason (Flatpak)

- **VSCodium**
  - Adds the VSCodium RPM repository (with GPG key).
  - Installs the `codium` package.

- **NVIDIA (optional)**
  - Optionally installs NVIDIA akmods and CUDA-enabled driver packages.

- **AMD GPU kernel parameters (Framework 16)**
  - Optionally configures `GRUB_CMDLINE_LINUX_DEFAULT` with:
    - `amdgpu.dcdebugmask=0x10`
    - `amdgpu.ppfeaturemask=0xffffffff`
  - Regenerates the GRUB configuration and prompts for reboot.

All operations are idempotent: re-running the script will not duplicate configuration or re-add identical entries.

## Usage

1. **Clone and enter the repository**
   ```bash
   git clone <repository-url>
   cd <repository-directory>
