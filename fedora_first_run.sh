#!/bin/bash

# Global variables
#the LABEL of the second nvme drive (steam library for me)
LABEL=crucial2tb
USER=nathan
GROUP=nathan
PERMISSION=755

#Enable RPM Fusion:
echo "Enabling RPM Fusion free and non-free"
sudo dnf install -y https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm
sudo dnf install -y https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm

# Multimedia codecs, allows gifs, videos and all streaming services
echo "Installing Fedora multimedia codes"
sudo dnf group install -y Multimedia

# Syncthing
echo "Do you want to install Syncthing? (y/n)"
read -r response

response=$(echo "$response" | tr '[:upper:]' '[:lower:]')
if [[ "$response" == "y" || "$response" == "yes" ]]; then
    echo "Installing Syncthing..."
    sudo dnf install -y syncthing
else
    echo "Installation aborted by the user."
fi


#Setup second drive mount point
echo "Do you have a second drive you would like to setup (y/n)"
read -r response
response=$(echo "$response" | tr '[:upper:]' '[:lower:]')
if [[ "$response" == "y" || "$response" == "yes" ]]; then
    echo "Creating mountpoint for second drive"
    sudo mkdir /mnt/$LABEL
    sudo chown -R $USER:$GROUP /mnt/$LABEL
    sudo chmod $PERMISSION /mnt/$LABEL
else
    echo "Installation aborted by the user."
fi


# Extract UUID and FSTYPE from the drive labeled $LABEL
INFO=$(sudo blkid | grep "LABEL=\"$LABEL\"")
UUID=$(echo "$INFO" | awk -F '"' '{print $4}')
FSTYPE=$(echo "$INFO" | awk -F '"' '{print $8}')

# Check if the UUID was successfully retrieved
if [ -n "$UUID" ]; then
    echo "UUID of $LABEL: $UUID"

    # Prepare the fstab entry string
    FSTAB_ENTRY="UUID=$UUID  /mnt/$LABEL  $FSTYPE  defaults  0  2"

    # Check if the entry already exists in fstab to avoid duplicates
    if grep -q "$FSTAB_ENTRY" /etc/fstab; then
        echo "Entry already exists in /etc/fstab."
    else
        # Append the new fstab entry
        echo "$FSTAB_ENTRY" | sudo tee -a /etc/fstab > /dev/null
        echo "New fstab entry added."
    fi
else
    echo "No UUID found for the label $LABEL"
fi

echo "running daemon-reload"
systemctl daemon-reload

echo "mounting $LABEL"
sudo mount -a

#install steam
echo "Do you want to install steam? (y/n)"
read -r response
response=$(echo "$response" | tr '[:upper:]' '[:lower:]')
if [[ "$response" == "y" || "$response" == "yes" ]]; then
    echo "Installing steam..."
    sudo dnf install -y steam
else
    echo "Installation aborted by the user."
fi


#install discord
echo "Do you want to install discord? (y/n)"
read -r response
response=$(echo "$response" | tr '[:upper:]' '[:lower:]')
if [[ "$response" == "y" || "$response" == "yes" ]]; then
    echo "Installing discord..."
    sudo dnf install -y discord
else
    echo "Installation aborted by the user."
fi

# Installing Git
echo "Do you want to install git? (y/n)"
read -r response
response=$(echo "$response" | tr '[:upper:]' '[:lower:]')
if [[ "$response" == "y" || "$response" == "yes" ]]; then
    echo "Installing git..."
    sudo dnf install -y git
else
    echo "Installation aborted by the user."
fi

# Installing Flatpak
echo "Do you want to install flatpak? (y/n)"
read -r response
response=$(echo "$response" | tr '[:upper:]' '[:lower:]')
if [[ "$response" == "y" || "$response" == "yes" ]]; then
    echo "Installing flatpak..."
    sudo dnf install -y flatpak
    flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

else
    echo "Installation aborted by the user."
fi

#Installing Signal
echo "Do you want to install signal (Flatpak)? (y/n)"
read -r response
response=$(echo "$response" | tr '[:upper:]' '[:lower:]')
if [[ "$response" == "y" || "$response" == "yes" ]]; then
    echo "Installing signal..."
    flatpak install flathub org.signal.Signal

else
    echo "Installation aborted by the user."
fi

#Install Beyond All Reason
echo "Do you want to install Beyond All Reason (Flatpak)? (y/n)"
read -r response
response=$(echo "$response" | tr '[:upper:]' '[:lower:]')
if [[ "$response" == "y" || "$response" == "yes" ]]; then
    echo "Installing Beyond All Reason..."
    flatpak install flathub info.beyondallreason.bar

else
    echo "Installation aborted by the user."
fi

#Install codium
echo "Do you want to install Codium? (y/n)"
read -r response
response=$(echo "$response" | tr '[:upper:]' '[:lower:]')
if [[ "$response" == "y" || "$response" == "yes" ]]; then
    echo "Installing Codium..."
    GPG_KEY_URL="https://gitlab.com/paulcarroty/vscodium-deb-rpm-repo/-/raw/master/pub.gpg"
    REPO_FILE="/etc/yum.repos.d/vscodium.repo"
    REPO_NAME="gitlab.com_paulcarroty_vscodium_repo"
    REPO_BASEURL="https://download.vscodium.com/rpms/"

    # Import the GPG key for the repository
    sudo rpmkeys --import "$GPG_KEY_URL"

    # Check if the repo file already exists to prevent duplicate entries
    if [ ! -f "$REPO_FILE" ]; then
        # Create the repo file
        echo -e "[${REPO_NAME}]\nname=download.vscodium.com\nbaseurl=${REPO_BASEURL}\nenabled=1\ngpgcheck=1\nrepo_gpgcheck=1\ngpgkey=${GPG_KEY_URL}\nmetadata_expire=1h" | sudo tee "$REPO_FILE"
    else
        echo "Repository file already exists, skipping creation."
    fi

    # Install Codium using DNF
    sudo dnf install -y codium
else
    echo "Installation aborted by the user."
fi

#Install Beyond All Reason
echo "Do you want to install nVidia Drivers? (y/n)"
read -r response
response=$(echo "$response" | tr '[:upper:]' '[:lower:]')
if [[ "$response" == "y" || "$response" == "yes" ]]; then
    echo "Installing nVidia Drivers..."
    sudo dnf update -y # and reboot if you are not on the latest kernel
    sudo dnf install akmod-nvidia # rhel/centos users can use kmod-nvidia instead
    sudo dnf install xorg-x11-drv-nvidia-cuda #optional for cuda/nvdec/nvenc support

else
    echo "Installation aborted by the user."
fi
