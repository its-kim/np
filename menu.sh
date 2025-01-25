#!/bin/bash

# Global Variables
SOFTWARE_FFMPEG=(wget curl unzip build-essential libtool pkg-config cmake autoconf automake yasm gperf nasm meson python3-distutils cython3 python3-numpy)
SOFTWARE_NP=(intel-gpu-tools aspnetcore-runtime-8.0  nginx)
SOFTWARE_RUNTIME=(linux-image-generic-hwe-22.04 libxfixes3 libx11-xcb1 libxcb-dri3-0)
FFMPEG_LIBRARIES=(lame libvpx opus fdkaac libpng libx264 libx265 libogg libvorbis libtheora dav1d openjpeg)
LOG_FILE="build.log"
BASE_DIR=$(dirname "$(readlink -f "$0")")

# Color  for whiptail
export NEWT_COLORS='
root=white,blue
'

# Check sudo access
check_sudo() {
  if [[ $EUID -ne 0 ]]; then
    echo "You need sudo rights to run this script."
    exit 1
  fi
}

check_sudo

# Welcome Screen and EULA
function welcome_screen {
    # Display the welcome message
    whiptail --title "Noisypeak-UX Installer v1.0" --msgbox "Welcome to the Noisypeak-UX Installer!\n\nVersion: 1.0\n\nBefore proceeding, please read and accept the Terms & Conditions." 12 60

    # Display the Terms and Conditions
    TERMS=$(cat "$BASE_DIR/EULA.txt")
    whiptail --title "Terms & Conditions" --scrolltext --msgbox "$TERMS" 30 70

    # Check user acceptance of Terms
    if whiptail --title "Do You Accept?" --yesno "Do you accept the Terms & Conditions as described?" 12 60; then
        whiptail --title "Thank You" --msgbox "Thank you for accepting the Terms & Conditions. You can now proceed." 8 50
    else
        whiptail --title "Terms Not Accepted" --msgbox "You must accept the Terms & Conditions to use this installer." 8 50
        exit 1
    fi
}

# 1. Check and install base software
# 1.1 Check Ubuntu version
function install_base_soft {
    UBUNTU_VERSION=$(lsb_release -rs)
    EXPECTED_VERSION="22.04"
    if [[ "$UBUNTU_VERSION" != "$EXPECTED_VERSION" ]]; then
        whiptail --title "Unsupported Linux Version" --msgbox "This installer is designed for Ubuntu $EXPECTED_VERSION. Exiting." 8 50
        exit 1
    fi

# 1.2 Install Software NP
function check_install_software_np {
    TO_INSTALL=()
    for SOFTWARE in "${SOFTWARE_NP[@]}"; do
        if ! dpkg -l | grep -qw "^ii.*$SOFTWARE"; then
            TO_INSTALL+=("$SOFTWARE")
        fi
    done

    if [[ ${#TO_INSTALL[@]} -gt 0 ]]; then
        PACKAGES_TO_INSTALL=$(printf "%s\n" "${TO_INSTALL[@]}")
        if whiptail --title "Confirm Installation" --yesno "The following packages will be installed:\n\n$PACKAGES_TO_INSTALL\n\nDo you want to proceed?" 20 70; then
            for SOFTWARE in "${TO_INSTALL[@]}"; do
                sudo apt install -y "$SOFTWARE"
            done
            whiptail --title "Installation Complete" --msgbox "Installation of standard software is complete." 8 50
        fi
    else
        whiptail --title "No Installation Needed" --msgbox "All required software is already installed." 8 50
    fi
}

# 1.3 Configure Nginx
function configure_nginx {
    mkdir -p /etc/nginx/conf.d/remuxer 
    rm -f /etc/nginx/sites-available/default

    cat > /etc/nginx/conf.d/np.conf <<'EOF'
server {
        server_name _;
        listen 80;
        include /etc/nginx/conf.d/remuxer/*.conf;

        location / {
            proxy_pass http://127.0.0.1:5000;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $remote_addr;
            proxy_set_header Host $host;
            proxy_set_header X-Forwarded-Port $server_port;
        }
}
EOF

    systemctl restart nginx
}

# 1.4 Deploy NP
function deploy_np_ux {
    mkdir -p /opt/noisypeak
    tar -xzf dist/np-ux.tar.gz -C /opt/noisypeak
    cd /opt/noisypeak/np-ux && ./run.sh
}

    # 1.2 Install Standard Software
    check_install_software_np

    # 1.3 Configure Nginx
    configure_nginx

    # 1.4 Deploy NP
    deploy_np_ux

main_menu
}

# 2. Install FFmpeg with Custom Libraries
# 2.1 Build and install FFmpeg
function install_ffmpeg {
    OPTIONS=$(whiptail --title "FFmpeg Options" --checklist \
        "Select the options to enable:" 20 78 10 \
        "qsv" "Enable Intel Quick Sync Video (QSV)" OFF \
        "nvenc" "Enable NVIDIA NVENC" OFF \
        "tenbit" "Enable 10-bit encoding/decoding" OFF 3>&1 1>&2 2>&3)

    if [ $? -ne 0 ]; then
        whiptail --title "Installation Cancelled" --msgbox "Installation cancelled." 8 50
        exit 1
    fi

    FFMPEG_OPTIONS=""
    if echo "$OPTIONS" | grep -q "qsv"; then
        FFMPEG_OPTIONS="$FFMPEG_OPTIONS --qsv"
    fi
    if echo "$OPTIONS" | grep -q "nvenc"; then
        FFMPEG_OPTIONS="$FFMPEG_OPTIONS --nvenc"
    fi
    if echo "$OPTIONS" | grep -q "tenbit"; then
        FFMPEG_OPTIONS="$FFMPEG_OPTIONS --10bit"
    fi

    LIBRARIES=$(whiptail --title "FFmpeg Libraries" --checklist \
        "Select the libraries to install:" 20 78 15 \
        "zlib" "Compression library                                " ON \
        "fribidi" "Bi-directional text support" ON \
        "freetype" "Font rendering library" ON \
        "libuuid" "UUID library" ON \
        "libxml2" "XML parsing library" ON \
        "fontconfig" "Font configuration library" ON \
        "libass" "ASS/SSA subtitle library" ON \
        "nasm" "Assembler for codec support" ON \
        "zimg" "Image scaling library" ON \
        "vmaf" "Video quality metric library" ON \
        "lame" "MP3 encoding" OFF \
        "libvpx" "VP8/VP9 codec" OFF \
        "opus" "Opus audio codec" OFF \
        "fdkaac" "AAC encoding" OFF \
        "libpng" "PNG image library" OFF \
        "libx264" "H.264 codec" OFF \
        "libx265" "H.265 codec" OFF \
        "libogg" "Ogg container format" OFF \
        "libvorbis" "Vorbis codec" OFF \
        "libtheora" "Theora codec" OFF \
        "dav1d" "AV1 codec" OFF \
        "openjpeg" "JPEG2000" OFF 3>&1 1>&2 2>&3)

    if [ $? -ne 0 ]; then
        whiptail --title "Installation Cancelled" --msgbox "Installation cancelled." 8 50
        exit 1
    fi

    LIBRARIES=$(echo "$LIBRARIES" | tr -d '"')

    if [ -z "$LIBRARIES" ]; then
        whiptail --title "No Libraries Selected" --msgbox "No libraries selected. Exiting." 8 50
        exit 1
    fi

    FFMPEG_LIBRARIES=""
    for lib in $LIBRARIES; do
        FFMPEG_LIBRARIES="$FFMPEG_LIBRARIES $lib"
    done

    echo "Compiling FFmpeg with the following libraries: $FFMPEG_LIBRARIES with options: $FFMPEG_OPTIONS"
    ./build-ffmpeg.sh $FFMPEG_LIBRARIES $FFMPEG_OPTIONS
}

# 3. Install hardware acceleration runtime
function install_hardware_acc {
    # 3.1 Check Kernel version
    CURRENT_KERNEL=$(uname -r | awk -F'-' '{print $1}')
    TARGET_KERNEL="6.8.0"
    if dpkg --compare-versions "$CURRENT_KERNEL" lt "$TARGET_KERNEL"; then
        if whiptail --title "Kernel Update Confirmation" --yesno "Your current kernel version is $CURRENT_KERNEL. Do you want to update?" 15 60; then
            sudo apt update && sudo apt install -y "${SOFTWARE_RUNTIME[@]}"
            whiptail --title "Kernel Updated" --msgbox "Kernel updated successfully." 15 60
        fi
    fi

    # 3.2 Check for Intel GPU
    check_intel_gpu

    # 3.3 Install Intel GPU Runtime
    install_intel_gpu_runtime

main_menu
}

# 3.2 Check for Intel GPU (Graphics Processing Unit)
function check_intel_gpu {
    if ! lspci | grep -iq "Intel Corporation.*Graphics"; then
        whiptail --title "No Intel GPU Detected" --msgbox "An Intel GPU (Graphics Processing Unit) is required to continue. Please ensure your system has an Intel GPU and try again." 10 60
        exit 1
    fi

    whiptail --title "Intel GPU Detected" --msgbox "Intel GPU (Graphics Processing Unit) detected. Proceeding with the installation." 8 50
}


# 3.3 Install Intel GPU Runtime
function install_intel_gpu_runtime {
    if ldconfig -p | grep -q "libmfx"; then
        whiptail --title "Intel GPU Runtime" --msgbox "Intel GPU Runtime is already installed. Proceeding to the next step." 10 60
        return 0
    fi

    echo "Installing Intel GPU Runtime..." >> "$LOG_FILE"
    tar xf "$BASE_DIR/dist/MediaStack.tar.gz" -C "$BASE_DIR" >> "$LOG_FILE" 2>&1
    cd "$BASE_DIR/MediaStack" && ./install_media.sh >> "$LOG_FILE" 2>&1
    if [[ $? -eq 0 ]]; then
        echo "Intel GPU Runtime installed successfully." >> "$LOG_FILE"
        if whiptail --title "Reboot Required" --yesno "Intel GPU Runtime installed successfully. A reboot is required. Reboot now?" 10 60; then
            echo "Rebooting the system..." >> "$LOG_FILE"
            sudo reboot
        fi
    else
        whiptail --title "Installation Failed" --msgbox "Intel GPU Runtime installation failed. Check the log file for details." 10 60
        return 1
    fi
}

# 4. Update version
function update {
    NEW_VERSION=$(whiptail --title "Update Version" --inputbox "Enter the version to install (e.g., 6.1):" 10 60 3>&1 1>&2 2>&3)

    if [[ -z "$NEW_VERSION" ]]; then
        whiptail --title "No Version Entered" --msgbox "You did not enter a version. Returning to the main menu." 8 50
        main_menu
    else
        whiptail --title "Updating" --msgbox "Updating to version $NEW_VERSION..." 8 50
        sudo apt update && sudo apt install -y "${SOFTWARE_RUNTIME[@]}" "${SOFTWARE_FFMPEG[@]}" "${SOFTWARE_NP[@]}"
        ./build-ffmpeg.sh --ffmpeg-version "$NEW_VERSION"
        whiptail --title "Updated" --msgbox "Has been successfully updated to version $NEW_VERSION." 8 50
        main_menu
    fi
}

# 5. Remove Installed Software
function remove_all {
    if whiptail --title "Remove Software" --yesno "This will remove the following software packages:\n${SOFTWARE_FFMPEG[*]}\n${SOFTWARE_NP[*]}\nDo you want to proceed?" 20 70; then
        sudo apt purge -y "${SOFTWARE_FFMPEG[@]}" "${SOFTWARE_NP[@]}" "${SOFTWARE_RUNTIME[@]}"
        sudo apt autoremove -y
        sudo apt clean
        sudo rm -rf /opt/noisypeak
        whiptail --title "Removal Complete" --msgbox "All specified software has been removed." 8 50
    else
        whiptail --title "Operation Canceled" --msgbox "The removal process has been canceled." 8 50
    fi

main_menu
}

# Main Menu
function main_menu {
    CHOICE=$(whiptail --title "Installer Menu" --menu "Choose an option" 15 60 5 \
        "1" "Install base software" \
        "2" "Build and Install FFmpeg" \
        "3" "Install hardware acceleration runtime" \
        "4" "Update version" \
        "5" "Remove all" 3>&1 1>&2 2>&3)

    case $CHOICE in
        1) install_base_soft ;;
        2) install_ffmpeg ;;
        3) install_hardware_acc ;;
        4) update ;;
        5) remove_all ;;
        *) exit 0 ;;
    esac
}

welcome_screen
main_menu
