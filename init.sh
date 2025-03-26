#!/bin/sh
set -e
# pnimrp installer with improved universal Linux support
# Targets FreeBSD, Linux (various distros, including Alpine), and Android Termux
# Package info (unused for now, but good practice)
PNIMRP_VERSION="0.1.0"
PNIMRP_DESCRIPTION="Terminal radio player in Nim"
# --- Helper Functions ---
# Function to run commands as root (direct or via sudo)
run_as_root() {
    if [ "$(id -u)" -eq 0 ]; then
        "$@" # Already root, run directly
    elif command -v sudo >/dev/null; then
        echo "==> Running with sudo: $*"
        sudo "$@" # Use sudo
    else
        echo "Error: This script needs to run commands as root." >&2
        echo "Please run as root or install 'sudo'." >&2
        exit 1
    fi
}
# --- OS/Package Manager Detection ---
detect_os() {
    OS=""
    PKGMGR=""
    DISTRO="" # More specific Linux/Android type
    case $(uname -s) in
        Linux)
            if [ -f /system/build.prop ] || [ -d /system/app ]; then
                OS="Android"
                if [ -d /data/data/com.termux/files/usr ]; then
                    DISTRO="termux"
                    PKGMGR="pkg" # Termux uses pkg
                else
                    DISTRO="android" # Non-Termux Android
                fi
            else
                OS="Linux"
                # Detect primary package manager
                if command -v apt-get >/dev/null; then
                    PKGMGR="apt"
                    DISTRO=$(lsb_release -is 2>/dev/null || cat /etc/os-release 2>/dev/null | grep '^ID=' | cut -d= -f2 || echo "debian_like")
                elif command -v dnf >/dev/null; then
                    PKGMGR="dnf"
                    DISTRO=$(cat /etc/os-release 2>/dev/null | grep '^ID=' | cut -d= -f2 || echo "fedora_like")
                elif command -v yum >/dev/null; then
                    PKGMGR="yum"
                     DISTRO=$(cat /etc/os-release 2>/dev/null | grep '^ID=' | cut -d= -f2 || echo "rhel_like")
                elif command -v pacman >/dev/null; then
                    PKGMGR="pacman"
                    DISTRO="arch_like"
                elif command -v zypper >/dev/null; then
                    PKGMGR="zypper"
                    DISTRO="opensuse_like"
                elif command -v apk >/dev/null; then # Added apk check
                    PKGMGR="apk"
                    DISTRO="alpine"
                else
                    echo "Warning: Could not detect a supported package manager (apt, dnf, yum, pacman, zypper, apk)." >&2
                    # PKGMGR remains empty
                fi
            fi
            ;;
        FreeBSD)
            OS="FreeBSD"
            PKGMGR="pkg"
            ;;
        *)
            OS="$(uname -s)"
            echo "Error: Unsupported OS '$OS'." >&2
            exit 1
            ;;
    esac
    echo "Detected OS: $OS ($DISTRO)"
    [ -n "$PKGMGR" ] && echo "Detected Package Manager: $PKGMGR"
}
# --- Package Installation Logic ---
# Installs packages using the detected manager
# Takes generic dependency names as arguments (e.g., 'c_compiler', 'git')
install_packages() {
    if [ -z "$PKGMGR" ]; then
        echo "Error: No package manager detected or supported. Cannot install: $*" >&2
        echo "Please install manually." >&2
        exit 1
    fi
    packages_to_install=""
    needs_update=false
    # Map generic names to specific package names
    for generic_name in "$@"; do
        specific_name=""
        case "$generic_name" in
            c_compiler)
                case "$PKGMGR" in
                    apt) specific_name="build-essential gcc" ;;
                    dnf | yum) specific_name="gcc make" ;;
                    pacman) specific_name="base-devel gcc" ;;
                    zypper) specific_name="gcc make patterns-devel-base-devel_basis" ;;
                    apk) specific_name="build-base" ;; # Alpine's equivalent meta-package for build tools (gcc, make, etc.)
                    pkg) # FreeBSD or Termux
                      if [ "$OS" = "Android" ]; then specific_name="clang"; else specific_name="gcc"; fi
                      ;;
                esac
                ;;
            git)
                specific_name="git" # Usually just 'git'
                ;;
            mpv)
                specific_name="mpv" # Runtime usually just 'mpv'
                ;;
            mpv_dev) # Add dev package if needed, make optional?
                case "$PKGMGR" in
                    apt) specific_name="libmpv-dev" ;;
                    dnf | yum) specific_name="mpv-devel" ;;
                    pacman) specific_name="mpv" ;; # Arch often includes headers in main package or handles differently
                    zypper) specific_name="mpv-devel" ;;
                    apk) specific_name="mpv-dev" ;; # Alpine has -dev packages
                    pkg) # FreeBSD/Termux typically don't need separate -dev
                       if [ "$OS" != "Android" ]; then specific_name="mpv"; fi # Assume included in mpv for FreeBSD/Termux
                       ;;
                esac
                ;;
             nim)
                case "$PKGMGR" in
                    apt) specific_name="nim" ;;
                    dnf | yum) specific_name="nim" ;;
                    pacman) specific_name="nim" ;;
                    zypper) specific_name="nim" ;;
                    apk) 
                        specific_name="nim nimble" ;; # Add nimble for Alpine Linux
                    pkg) 
                        specific_name="nim" ;;
                esac
                ;;
             curl)
                specific_name="curl" # Usually 'curl'
                ;;
             *)
                echo "Warning: Unknown generic package name '$generic_name'" >&2
                specific_name="$generic_name" # Try installing by the name given
                ;;
        esac
        # Add the specific name(s) to the list, avoiding duplicates
        if [ -n "$specific_name" ]; then
            for pkg in $specific_name; do
                 # Simple check to avoid adding the same package multiple times in one call
                 case " $packages_to_install " in
                     *" $pkg "*) ;;
                     *) packages_to_install="$packages_to_install $pkg" ;;
                 esac
            done
        fi
    done
    # Trim leading space
    packages_to_install=$(echo "$packages_to_install" | sed 's/^ *//')
    if [ -z "$packages_to_install" ]; then
        echo "No specific packages determined for input: $*"
        return 0 # Nothing to install
    fi
    echo "Attempting to install specific packages: $packages_to_install"
    # Run install command using run_as_root helper
    case "$PKGMGR" in
        apt)
            # Run update before install for apt
            echo "Running apt update..."
            run_as_root apt-get update -qq || echo "Warning: apt-get update failed."
            run_as_root apt-get install -y $packages_to_install
            ;;
        dnf)
            run_as_root dnf install -y $packages_to_install
            ;;
        yum)
            run_as_root yum install -y $packages_to_install
            ;;
        pacman)
            # Avoid -Sy; users should update manually with -Syu
            run_as_root pacman -S --noconfirm $packages_to_install
            ;;
        zypper)
            run_as_root zypper install -y $packages_to_install
            ;;
        apk) # Added apk install logic
            echo "Running apk update..."
            run_as_root apk update || echo "Warning: apk update failed."
            run_as_root apk add $packages_to_install # apk doesn't typically use -y
            ;;
        pkg) # FreeBSD / Termux
            # Termux doesn't use sudo/root
            if [ "$OS" = "Android" ]; then
                pkg update -y || echo "Warning: pkg update failed."
                pkg install -y $packages_to_install
            else
                 # FreeBSD needs root
                run_as_root pkg update -q || echo "Warning: pkg update failed."
                run_as_root pkg install -y $packages_to_install
            fi
            ;;
        *)
            echo "Error: Package manager '$PKGMGR' install logic not implemented." >&2
            exit 1
            ;;
    esac || {
        echo "Error: Failed to install packages: $packages_to_install" >&2
        echo "Please try installing them manually." >&2
        exit 1
    }
    echo "Successfully installed (or already present): $packages_to_install"
}
# --- Dependency Installation Functions ---
install_c_compiler() {
    if command -v cc >/dev/null || command -v gcc >/dev/null || command -v clang >/dev/null; then
        echo "C compiler detected."
        return 0
    fi
    echo "Installing C compiler..."
    install_packages c_compiler
    # Verify installation
    if ! (command -v cc >/dev/null || command -v gcc >/dev/null || command -v clang >/dev/null); then
        echo "Error: Failed to install C compiler. Please install manually (e.g., gcc, clang, build-essential, base-devel, build-base)." >&2
        exit 1
    fi
}
install_git() {
    if command -v git >/dev/null; then return 0; fi
    echo "Installing Git..."
    install_packages git
}
install_mpv() {
    if command -v mpv >/dev/null; then return 0; fi
    echo "Installing MPV..."
    # Also attempt to install dev package, might be needed for nimble build
    # If mpv_dev maps to nothing on a platform, it won't hurt
    install_packages mpv mpv_dev
     if ! command -v mpv >/dev/null; then
        echo "Error: Failed to install MPV. Please install manually." >&2
        exit 1
     fi
}
install_nim() {
    if command -v nim >/dev/null; then
        echo "Nim detected."
        return 0
    fi
    echo "Installing Nim..."
    # Try system package manager first if available
    nim_installed=false
    if [ -n "$PKGMGR" ]; then
        echo "Attempting Nim installation via $PKGMGR..."
        # Use install_packages, but don't exit if it fails, fallback to choosenim
        # Pass generic name 'nim'
        if install_packages nim && command -v nim >/dev/null; then
            echo "Nim installed via system package manager."
            nim_installed=true
        else
            echo "Failed to install Nim via $PKGMGR or verification failed."
        fi
    fi
    # Fallback to choosenim if system install failed or wasn't attempted
    if [ "$nim_installed" = false ]; then
        echo "Trying choosenim..."
        # Ensure curl is installed
        if ! command -v curl >/dev/null; then
             echo "Installing curl (needed for choosenim)..."
             install_packages curl # Pass generic name 'curl'
             if ! command -v curl >/dev/null; then
                 echo "Error: Failed to install curl. Cannot use choosenim." >&2
                 exit 1
             fi
        fi
        # Execute choosenim installer
        # Consider non-interactive flags if needed/available
        export CHOOSENIM_NO_ANALYTICS=1 # Opt-out of analytics
        if sh -c 'curl -sSf https://nim-lang.org/choosenim/init.sh | sh'; then
            echo "choosenim installation script finished."
            # Source the environment variables for the current script session
            if [ -f "$HOME/.nimble/bin/nim" ]; then
                 export PATH="$HOME/.nimble/bin:$PATH"
                 echo "Nim installed via choosenim."
                 nim_installed=true # Mark as installed for verification
            else
                 echo "choosenim script ran, but Nim command not found in expected location."
            fi
        else
            echo "choosenim download or execution failed."
        fi
        # Add Nim to PATH for future shell sessions
        if [ -f "$HOME/.nimble/bin/nim" ]; then
            echo "Adding Nim to PATH for future sessions..."
            # Always add to shell rc files, even if duplicates exist
            echo "export PATH=\"\$HOME/.nimble/bin:\$PATH\"" >> ~/.profile
            echo "export PATH=\"\$HOME/.nimble/bin:\$PATH\"" >> ~/.bashrc
            if [ -f "$HOME/.zshrc" ]; then
                 echo "export PATH=\"\$HOME/.nimble/bin:\$PATH\"" >> ~/.zshrc
            fi
             # Fish shell uses a different config file and syntax
            if command -v fish >/dev/null && [ -d "$HOME/.config/fish" ]; then
                mkdir -p "$HOME/.config/fish" # Ensure directory exists
                echo 'set -gx PATH "$HOME/.nimble/bin" $PATH' >> "$HOME/.config/fish/config.fish"
            fi
        fi
    fi
    # Final verification
    if ! command -v nim >/dev/null; then
        echo "Error: Failed to install Nim using package manager or choosenim." >&2
        echo "Please install Nim manually: https://nim-lang.org/install.html" >&2
        exit 1
    fi
}
# --- Install pnimrp ---
install_pnimrp() {
    echo "Installing pnimrp..."
    # Ensure nimble is available (should be after install_nim)
    if ! command -v nimble >/dev/null; then
        echo "Error: 'nimble' command not found. Nim installation might be incomplete." >&2
        exit 1
    fi
    echo "Attempting install via 'nimble install pnimrp'..."
    # Run nimble as the regular user, NOT with run_as_root
    if nimble install pnimrp; then
        echo "pnimrp successfully installed via nimble."
    else
        echo "Warning: 'nimble install pnimrp' failed. Attempting fallback: clone and build."
        # Ensure git and C compiler are available (should have been installed)
        command -v git >/dev/null || { echo "Error: git not found for fallback." >&2; exit 1; }
        (command -v cc >/dev/null || command -v gcc >/dev/null || command -v clang >/dev/null) || { echo "Error: C compiler not found for fallback." >&2; exit 1; }
        echo "Cloning pnimrp repository..."
        # Use a temporary directory for cloning
        TMP_DIR=$(mktemp -d)
        echo "Using temporary directory: $TMP_DIR"
        cd "$TMP_DIR"
        if ! git clone https://github.com/bloomingchad/pnimrp.git; then
            echo "Error: Failed to clone pnimrp repository." >&2
            rm -rf "$TMP_DIR" # Clean up
            exit 1
        fi
        cd pnimrp
        echo "Building pnimrp from source using nimble..."
        if nimble build -d:release; then # Build optimized release version
            echo "Build successful."
            # Install to user's local bin directory (common practice)
            mkdir -p "$HOME/.local/bin"
            if cp -r assets pnimrp "$HOME/.local/bin/"; then
                echo "pnimrp binary copied to $HOME/.local/bin/"
                # Always add $HOME/.local/bin to PATH
                echo "export PATH=\"\$HOME/.local/bin:\$PATH\"" >> ~/.profile
                echo "export PATH=\"\$HOME/.local/bin:\$PATH\"" >> ~/.bashrc
                if [ -f "$HOME/.zshrc" ]; then
                    echo "export PATH=\"\$HOME/.local/bin:\$PATH\"" >> ~/.zshrc
                fi
                if command -v fish >/dev/null && [ -d "$HOME/.config/fish" ]; then
                    mkdir -p "$HOME/.config/fish" # Ensure directory exists
                    echo 'set -gx PATH "$HOME/.local/bin" $PATH' >> "$HOME/.config/fish/config.fish"
                fi
            else
                 echo "Error: Failed to copy binary to $HOME/.local/bin/" >&2
                 # Don't exit, nimble install might have partially worked or user can find binary in TMP_DIR/pnimrp/bin
            fi
        else
            echo "Error: Failed to build pnimrp from source." >&2
            # Don't exit, let user troubleshoot if needed
        fi
        # Clean up temporary directory
        echo "Cleaning up temporary directory..."
        cd / # Move out of TMP_DIR before removing it
        rm -rf "$TMP_DIR"
    fi
     # Verify final installation (check common paths)
     if ! (command -v pnimrp || [ -f "$HOME/.nimble/bin/pnimrp" ] || [ -f "$HOME/.local/bin/pnimrp" ]); then
        echo "Warning: Could not verify pnimrp installation automatically."
        echo "Please check '$HOME/.nimble/bin' or '$HOME/.local/bin' or build output."
     fi
}
# --- Main Execution ---
main() {
    echo "Starting pnimrp installation script..."
    detect_os
    # Handle non-Termux Android early
    if [ "$OS" = "Android" ] && [ "$DISTRO" != "termux" ]; then
        echo "Error: Non-Termux Android detected. Termux is required for installation." >&2
        exit 1
    fi
    install_c_compiler
    install_git
    install_mpv
    install_nim
    install_pnimrp
    echo ""
    echo "--- Installation Summary ---"
    echo "pnimrp installation process finished."
    echo "Dependencies checked/installed: C Compiler, Git, MPV, Nim."
    echo "pnimrp installed via nimble or built from source."
    echo ""
    echo "To run the application, type: pnimrp"
    echo ""
    echo "IMPORTANT:"
    echo "If this is your first time installing Nim via choosenim or if pnimrp was installed to ~/.local/bin,"
    echo "you might need to restart your shell or source your configuration file:"
    echo "  For bash/zsh: source ~/.bashrc  OR  source ~/.zshrc  OR  source ~/.profile"
    echo "  For fish: source ~/.config/fish/config.fish"
    echo "Alternatively, you can temporarily add the path:"
    echo "  export PATH=\"\$HOME/.nimble/bin:\$HOME/.local/bin:\$PATH\""
    echo "-----------------------------"
}
# Run main function with all script arguments (though none are currently used)
main "$@"
