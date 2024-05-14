#!/bin/bash

question () {
    echo -n "$1 [y/N]: "
    read -r response
    response=$(echo "$response" | tr '[:upper:]' '[:lower:]')

    if [[ "$response" == "y" || "$response" == "yes" ]]; then
        return 1
    else
        return 0
    fi
}

# Global variables
USERNAME=$USER
if [ ! -z $SUDO_USER ]; then
    USERNAME=$SUDO_USER
fi
GROUP=$USERNAME
PERMISSION=755
NEWHOSTNAME="$(< /sys/devices/virtual/dmi/id/product_name)"
PRETTYHOSTNAME="$USERNAME's $NEWHOSTNAME"

# Device settings
question "Change the hostname to \"$PRETTYHOSTNAME\"?"
dochangehostname=$?

question "Do you want to setup a second drive?"
dosetupseconddrive=$?
if [ "$dosetupseconddrive" == 1 ]; then
    read -p "Drive label: " -r DRIVELABEL
fi

# Drivers / repos
question "Install Fedora multimedia codecs?"
doinstallmultimedia=$?

question "Enable RPM Fusion free and non-free?"
doenablerpmfusion=$?

if [ "$doenablerpmfusion" == 1 ]; then
    question "Install nVidia drivers?"
    doinstallnvidia=$?

    question "Install additional codecs?"
    doinstallcodecs=$?
    if [ "$doinstallcodecs" == 1 ]; then
        question "Install Intel(recent) hardware accelerated codec?"
        doinstallintelcodec=$?
        
        question "Install Intel(older) hardware accelerated codec?"
        doinstallinteloldercodec=$?
        
        question "Install AMD hardware accelerated codec?"
        doinstallamdcodec=$?
        
        question "Install nVidia hardware accelerated codec?"
        doinstallnvidiacodec=$?
    fi
fi

question "Install Flatpak and add Flathub repo?"
doinstallflatpakhub=$?

# Software FOSS
question "Install git?"
doinstallgit=$?

question "Install Syncthing?"
doinstallsyncthing=$?

question "Install VSCodium (from https://gitlab.com/paulcarroty/vscodium-deb-rpm-repo)?"
doinstallvscodium=$?

if [ "$doenableflatpakhub" == 1 ]; then
    question "Install Signal (from Flathub)?"
    doinstallsignal=$?

    question "Install 'Beyond All Reason'(from Flathub)?"
    doinstallbeyondallreason=$?
fi

# Software non-FOSS
if [ "$doenablerpmfusion" == 1 ]; then
    question "Install Steam (from rpmfusion-nonfree)?"
    doinstallsteam=$?

    question "Install Discord (from rpmfusion-nonfree)?"
    doinstalldiscord=$?
fi
####

# Change hostname
if [ "$dochangehostname" == 1 ]; then
    echo "Changing Hostname..."
    sudo hostnamectl set-hostname "$NEWHOSTNAME"
    sudo hostnamectl set-hostname "$PRETTYHOSTNAME" --pretty

    echo "Hostname changed to \"$PRETTYHOSTNAME\"."
fi

# Setup second drive mount point
if [ "$dosetupseconddrive" == 1 ]; then
    echo "Creating mountpoint for second drive"
    sudo mkdir /mnt/$DRIVELABEL
    sudo chown -R $USERNAME:$GROUP /mnt/$DRIVELABEL
    sudo chmod $PERMISSION /mnt/$DRIVELABEL

    # Extract UUID and FSTYPE from the drive labeled $DRIVELABEL
    INFO=$(sudo blkid | grep "LABEL=\"$DRIVELABEL\"")
    UUID=$(echo "$INFO" | awk -F '"' '{print $4}')
    FSTYPE=$(echo "$INFO" | awk -F '"' '{print $8}')

    # Check if the UUID was successfully retrieved
    if [ -n "$UUID" ]; then
        echo "UUID of $DRIVELABEL: $UUID"

        # Prepare the fstab entry string
        FSTAB_ENTRY="UUID=$UUID  /mnt/$DRIVELABEL  $FSTYPE  defaults  0  2"

        # Check if the entry already exists in fstab to avoid duplicates
        if grep -q "$FSTAB_ENTRY" /etc/fstab; then
            echo "Entry already exists in /etc/fstab."
        else
            # Append the new fstab entry
            echo "$FSTAB_ENTRY" | sudo tee -a /etc/fstab > /dev/null
            echo "New fstab entry added."
            
            echo "running daemon-reload"
            systemctl daemon-reload

            echo "mounting $DRIVELABEL"
            sudo mount -a
        fi
    else
        echo "No UUID found for the label $DRIVELABEL. Failed to setup second drive."
    fi
fi

# Multimedia codecs, allows gifs, videos and all streaming services
if [ "$doinstallmultimedia" == 1 ]; then
    echo "Installing Fedora multimedia codes"
    sudo dnf group install -y Multimedia
fi

# Enable RPM Fusion
if [ "$doenablerpmfusion" == 1 ]; then
    echo "Enabling RPM Fusion free and non-free"
    sudo dnf install -y https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm
    sudo dnf install -y https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
fi

# Install nVidia drivers
if [ "$doinstallnvidia" == 1 ]; then
    echo "Installing nVidia Drivers..."
    sudo dnf update -y # and reboot if you are not on the latest kernel
    sudo dnf install -y akmod-nvidia # rhel/centos users can use kmod-nvidia instead
    sudo dnf install -y xorg-x11-drv-nvidia-cuda #optional for cuda/nvdec/nvenc support
fi

if [ "$doinstallcodecs" == 1 ]; then
    echo "Installing additional codecs..."
    sudo dnf -y swap ffmpeg-free ffmpeg --allowerasing
    sudo dnf -y groupupdate multimedia --setopt="install_weak_deps=False" --exclude=PackageKit-gstreamer-plugin
    sudo dnf -y groupupdate sound-and-video

    if [ "$doinstallintelcodec" == 1 ]; then
        sudo dnf install -y intel-media-driver
    fi
    if [ "$doinstallinteloldercodec" == 1 ]; then
        sudo dnf install -y libva-intel-driver
    fi
    if [ "$doinstallamdcodec" == 1 ]; then
        sudo dnf -y swap mesa-va-drivers mesa-va-drivers-freeworld
        sudo dnf -y swap mesa-vdpau-drivers mesa-vdpau-drivers-freeworld
    fi
    if [ "$doinstallnvidiacodec" == 1 ]; then
        sudo dnf install -y nvidia-vaapi-driver
    fi
fi

# Install Flatpak/Flathub
if [ "$doenableflatpakhub" == 1 ]; then
    echo "Installing flatpak..."
    sudo dnf install -y flatpak
    flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
fi

# Install Git
if [ "$doinstallgit" == 1 ]; then
    echo "Installing git..."
    sudo dnf install -y git
fi

# Install Syncthing
if [ "$doinstallsyncthing" == 1 ]; then
    echo "Installing Syncthing..."
    sudo dnf install -y syncthing
fi

# Install VSCodium
if [ "$doinstallvscodium" == 1 ]; then
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
fi

# Install Signal
if [ "$doinstallsignal" == 1 ]; then
    echo "Installing signal..."
    flatpak install flathub org.signal.Signal
fi

# Install Beyond All Reason
if [ "$doinstallbeyondallreason" == 1 ]; then
    echo "Installing Beyond All Reason..."
    flatpak install flathub info.beyondallreason.bar
fi

# Install Steam
if [ "$doinstallsteam" == 1 ]; then
    echo "Installing steam..."
    sudo dnf install -y steam
fi

# Install Discord
if [ "$doinstalldiscord" == 1 ]; then
    echo "Installing discord..."
    sudo dnf install -y discord
fi
