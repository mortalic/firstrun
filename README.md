# Fedora Post-Installation Setup Script

This script automates the setup of a Fedora system, including enabling repositories, installing essential software, and configuring devices. It's designed to run after a fresh installation of Fedora, helping users quickly set up their environment according to their needs.

## Features

- **RPM Fusion Repository**: Enables the RPM Fusion free and non-free repositories, essential for multimedia packages and other software not included in the official Fedora repositories.
- **Multimedia Codecs**: Installs multimedia groups for enhanced media playback capabilities.
- **Conditional Software Installation**: Prompts the user to install various applications such as Syncthing, Steam, Discord, Git, Flatpak, Signal, Beyond All Reason, Codium, and Nvidia Drivers. The user can choose to install or skip each application.
- **Drive Setup**: Offers to set up a mount point for a secondary drive, automatically adding it to the `fstab` for persistent mounting.
- **User and Permissions Management**: Sets the owner and permissions for the newly created mount point.

## Usage

1. **Clone the repository or download the script**:
    ```bash
    git clone <repository-url>
    cd <repository-directory>
    ```

2. **Make the script executable**:
    ```bash
    chmod +x setup_fedora.sh
    ```

3. **Run the script**:
    ```bash
    sudo ./setup_fedora.sh
    ```

## Requirements

- Fedora Linux (the script is tested on Fedora, adjustments might be necessary for other distributions).
- Root permissions are required for most operations.

## Components Configured

- **RPM Fusion Repositories**
- **Multimedia Codecs**
- **Optional Software**:
  - Syncthing
  - Steam
  - Discord
  - Git
  - Flatpak (including adding Flathub as a remote repository)
  - Signal (via Flatpak)
  - Beyond All Reason (via Flatpak)
  - VSCodium
  - Nvidia Drivers (including optional CUDA support)

## Customization

The script uses several global variables (`LABEL`, `USER`, `GROUP`, `PERMISSION`) to configure system settings. You can modify these variables in the script to suit your specific requirements.

## Contributions

Contributions to the script are welcome. Please ensure to test changes locally before submitting a pull request.

## License

GPL 3.0

## Contact

For bugs, feature requests, or other communications, open an issue, or better, open a Pull Request with the fix.