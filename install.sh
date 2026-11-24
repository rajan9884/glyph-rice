#!/usr/bin/env bash
# Glyph: installs everything on a clean Arch Linux and symlinks configs from this repo.
#   ./install.sh                   packages + services + symlinks; prompts for optional EXTRA
#   ./install.sh --with telegram   same without prompt (--with "" — core rice only)
#   ./install.sh --links           symlinks only (on an already configured system)
#   ./install.sh --sddm            greeter theme only (sudo); run again after edits to config/sddm
set -euo pipefail

DOTS="$(cd "$(dirname "$0")" && pwd)"
BACKUP="$HOME/.dots-backup-$(date +%F_%H-%M-%S)"

PACMAN=(
    # base
    base-devel git curl jq python
    # session
    hyprland hypridle hyprsunset hyprpicker xdg-desktop-portal-hyprland xdg-desktop-portal-gtk
    sddm quickshell polkit-gnome gnome-keyring geoclue upower xdg-user-dirs
    # audio, network, bluetooth
    pipewire pipewire-pulse pipewire-alsa wireplumber networkmanager bluez bluez-utils blueman power-profiles-daemon
    # utilities invoked by keybinds and shell
    brightnessctl playerctl wl-clipboard cliphist grim slurp swappy imagemagick libvips libqalculate
    gpu-screen-recorder intel-media-driver libva-utils ydotool libnotify trash-cli
    # terminal and console tools
    foot zsh zsh-autosuggestions zsh-syntax-highlighting zsh-completions fzf bat fd ripgrep gum tesseract tesseract-data-eng starship fastfetch btop cava eza zoxide direnv lazygit yazi tmux neovim
    # apps from variables.lua
    pavucontrol
    # fonts (cjk — kaomoji in Charms), icons (Papirus-Dark — folder theme base), dark base for gtk.css
    ttf-jetbrains-mono-nerd noto-fonts noto-fonts-cjk noto-fonts-emoji papirus-icon-theme adw-gtk-theme
)

AUR=(
    qtengine darkly-bin bibata-cursor-theme-bin
    zen-browser-bin strata-bin
)

# optional components (caelestia-style). Keybinds in special workspaces launch apps from hypr/variables.lua
declare -A EXTRA=(
    [telegram]="telegram-desktop"                                        # Super+D
    [spotify]="spotify-launcher spicetify-cli spicetify-marketplace-bin" # Super+M
    [clash]="clash-verge-rev-bin"                                        # VPN panel, Super+P
)

G=config/quickshell/glyph
# repo path → path in $HOME
LINKS=(
    "config/hypr                                .config/hypr"
    "$G                                         .config/quickshell/glyph"
    "config/quickshell/rice                     .config/quickshell/rice"
    "config/quickshell/rice/rice                .local/bin/rice"
    "config/foot                                .config/foot"
    "config/qtengine                            .config/qtengine"
    "$G/term/qtengine.colors                    .config/qtengine.colors"
    "$G/term/starship.toml                      .config/starship.toml"
    "$G/term/fastfetch                          .config/fastfetch"
    "$G/term/btop                               .config/btop"
    "$G/term/cava                               .config/cava"
    "$G/term/gtk-3.0/gtk.css                    .config/gtk-3.0/gtk.css"
    "$G/term/gtk-4.0/gtk.css                    .config/gtk-4.0/gtk.css"
    "config/fonts                               .local/share/fonts/glyph"
    # shell and configs
    "config/shell/zshrc                         .zshrc"
    "config/shell/zprofile                      .zprofile"
    "config/shell/bashrc                        .bashrc"
    "config/shell/aliases                       .bash_aliases"
    "config/shell/aliases                       .config/shell/aliases"
    "config/shell/env.sh                        .config/shell/env.sh"
    "config/shell/git-accounts.sh               .config/shell/git-accounts.sh"
    # git
    "config/git/gitconfig                       .gitconfig"
    "config/git/gitconfig-personal              .gitconfig-personal"
    "config/git/gitconfig-work                  .gitconfig-work"
    # tools and scripts
    "config/lazygit                             .config/lazygit"
    "config/yazi                                .config/yazi"
    "config/strata                              .config/strata"
    "config/nvim                                .config/nvim"
    "config/scripts/fcs                         .local/bin/fcs"
    "config/scripts/ff                          .local/bin/ff"
    "config/scripts/ffd                         .local/bin/ffd"
    "config/scripts/git-switch-account          .local/bin/git-switch-account"
    "config/scripts/git-use-personal            .local/bin/git-use-personal"
    "config/scripts/git-use-work                .local/bin/git-use-work"
    "config/scripts/git-whoami                  .local/bin/git-whoami"
    "config/scripts/ocr-extract                 .local/bin/ocr-extract"
    "config/scripts/ttfx                        .local/bin/ttfx"
    "config/scripts/wifi-enterprise             .local/bin/wifi-enterprise"
    "config/scripts/power-profile-switch        .local/bin/power-profile-switch"
    "config/scripts/gsr-record                  .local/bin/gsr-record"
)

say() { printf '\e[38;2;215;25;33m●\e[0m %s\n' "$*"; }

extras() { # --with or interactive prompt → EXT, installs via yay separately from core AUR
    local w; EXT=()
    if [ -z "${WITH+x}" ]; then
        say "anything else to install? space-separated, Enter for none"
        for w in "${!EXTRA[@]}"; do printf '  %-9s %s\n' "$w" "${EXTRA[$w]}"; done
        read -rp "  > " WITH || true
    fi
    for w in ${WITH//,/ }; do
        [ -n "${EXTRA[$w]-}" ] || { echo "no such extra: $w (available: ${!EXTRA[*]})"; exit 1; }
        EXT+=(${EXTRA[$w]})
    done
}

packages() {
    say "pacman"
    # pulseaudio modules require pulseaudio itself — pacman would block replacing with pipewire-pulse.
    # List explicitly, not grep '^pulseaudio-': pulseaudio-alsa and pulseaudio-qt coexist with pipewire
    local pa; pa=$(pacman -Qq pulseaudio-{bluetooth,jack,lirc,rtp,zeroconf,equalizer,equalizer-ladspa} 2>/dev/null || true)
    [ -z "$pa" ] || sudo pacman -R $pa
    pacman -Q pulseaudio &>/dev/null && say "pacman will ask \"Remove pulseaudio?\": answer y, pipewire-pulse replaces it"
    # without --noconfirm: on conflict (pulseaudio → pipewire-pulse) it would default to 'no' and abort
    sudo pacman -Syu --needed "${PACMAN[@]}"

    if ! command -v yay >/dev/null; then
        say "yay"
        local tmp; tmp="$(mktemp -d)"
        git clone --depth 1 https://aur.archlinux.org/yay-bin.git "$tmp/yay-bin"
        (cd "$tmp/yay-bin" && makepkg -si --noconfirm)
        rm -rf "$tmp"
    fi

    say "aur"
    # AUR is optional: if package fails — proceed with services and symlinks anyway
    yay -S --needed --noconfirm "${AUR[@]}" || say "aur: some packages failed, see above"
    # separate: if spicetify fails to build — core AUR remains unaffected
    [ ${#EXT[@]} -eq 0 ] || yay -S --needed --noconfirm "${EXT[@]}" || say "extras: some packages failed, see above"
}

services() {
    say "services"
    sudo systemctl enable NetworkManager bluetooth power-profiles-daemon
    systemctl is-enabled -q display-manager.service 2>/dev/null || sudo systemctl enable sddm
    systemctl --user enable pipewire-pulse.socket wireplumber ydotool
    sudo usermod -aG video "$USER" # brightnessctl

    # Dynamic power profile switching on AC (performance) / Battery (balanced)
    sudo cp "$DOTS/config/scripts/power-profile-switch" /usr/local/bin/power-profile-switch
    sudo chmod +x /usr/local/bin/power-profile-switch
    sudo cp "$DOTS/config/udev/99-power-switch.rules" /etc/udev/rules.d/99-power-switch.rules
    sudo cp "$DOTS/config/systemd/power-profile-switch.service" /etc/systemd/system/power-profile-switch.service
    sudo udevadm control --reload 2>/dev/null || true
    sudo systemctl daemon-reload 2>/dev/null || true
    sudo systemctl enable power-profile-switch.service 2>/dev/null || true

    # ydotool writes to /dev/uinput: access given to active desktop user (uaccess, like steam-devices). Not 'input' group: that
    # reads /dev/input/event* — any user process could snoop keystrokes/passwords. Takes effect after reboot
    echo 'KERNEL=="uinput", SUBSYSTEM=="misc", TAG+="uaccess", OPTIONS+="static_node=uinput"' \
        | sudo tee /etc/udev/rules.d/70-glyph-uinput.rules >/dev/null
    xdg-user-dirs-update
}

links() {
    say "symlinks (old files → $BACKUP)"
    local src dst
    for l in "${LINKS[@]}"; do
        read -r src dst <<<"$l"
        src="$DOTS/$src" dst="$HOME/$dst"
        [ "$(readlink "$dst")" = "$src" ] && continue
        if [ -e "$dst" ] || [ -L "$dst" ]; then
            mkdir -p "$BACKUP/$(dirname "${dst#"$HOME"/}")"
            mv "$dst" "$BACKUP/${dst#"$HOME"/}"
        fi
        mkdir -p "$(dirname "$dst")"
        ln -s "$src" "$dst"
        echo "  $dst"
    done
    # rules.json and kitty.conf will be generated by shell; rice starts glyph and builds folder theme
    mkdir -p "$HOME/.config/demonshot" "${XDG_STATE_HOME:-$HOME/.local/state}/rice"
    echo glyph > "${XDG_STATE_HOME:-$HOME/.local/state}/rice/shell"
    mkdir -p "$HOME/Pictures/Wallpapers" # wallpaper picker (Super+Shift+W) reads from here
    fc-cache -f >/dev/null

    # SSH config for dual-account github
    mkdir -p "$HOME/.ssh"
    if ! grep -q "Host github.com-personal" "$HOME/.ssh/config" 2>/dev/null; then
        cat <<'SSH_SNIP' >> "$HOME/.ssh/config"

# Personal Account
Host github.com-personal
  HostName github.com
  User git
  IdentityFile ~/.ssh/id_ed25519_personal

# Work Account
Host github.com-work
  HostName github.com
  User git
  IdentityFile ~/.ssh/id_ed25519_work
SSH_SNIP
    fi
    chmod 700 "$HOME/.ssh" 2>/dev/null || true
    chmod 600 "$HOME/.ssh/config" 2>/dev/null || true

    # Switch default shell to zsh
    if command -v zsh >/dev/null 2>&1 && [ "${SHELL:-}" != "$(command -v zsh)" ]; then
        chsh -s "$(command -v zsh)" 2>/dev/null || sudo chsh -s "$(command -v zsh)" "$USER" 2>/dev/null || true
    fi

    command -v gsettings >/dev/null || return 0 # --links on systems without GNOME schemas
    # Dark mode for Zen, Electron, and libadwaita (via portal) and dark gtk3 base for our gtk.css
    gsettings set org.gnome.desktop.interface color-scheme prefer-dark
    gsettings set org.gnome.desktop.interface gtk-theme adw-gtk3-dark
    # set strata as default file manager
    command -v xdg-mime >/dev/null && xdg-mime default io.github.lgse.Strata.desktop inode/directory 2>/dev/null || true
    command -v xdg-mime >/dev/null && xdg-mime default io.github.lgse.Strata.desktop x-scheme-handler/trash 2>/dev/null || true
}

greeter() { # Login theme. Copy rather than symlink: sddm user cannot read restricted $HOME
    say "sddm: glyph theme"
    [ -d /usr/share/sddm/themes ] || { say "sddm isn't installed, skipping the theme"; return 0; }
    # rm: files removed from repo don't linger in theme; chmod: umask 077 would copy as 600 which sddm cannot read
    sudo rm -rf /usr/share/sddm/themes/glyph
    # without -L: root does not follow symlinks from theme — link to /etc/shadow would become readable to all after chmod.
    # The only internal symlink, fonts → config/fonts, is replaced with fonts themselves
    sudo cp -rT "$DOTS/config/sddm/glyph" /usr/share/sddm/themes/glyph
    sudo rm /usr/share/sddm/themes/glyph/fonts
    sudo cp -rT "$DOTS/config/fonts" /usr/share/sddm/themes/glyph/fonts
    sudo chmod -R a+rX /usr/share/sddm/themes/glyph
    # Empty InputMethod: sddm default is qtvirtualkeyboard which displays a full-screen on-screen keyboard with this theme
    sudo mkdir -p /etc/sddm.conf.d
    # zz-: conf.d files are read alphabetically, subsequent files override — ours loaded last over third-party configs
    printf '[Theme]\nCurrent=glyph\n\n[General]\nInputMethod=\n' | sudo tee /etc/sddm.conf.d/zz-glyph.conf >/dev/null
    # /etc/sddm.conf takes precedence over conf.d
    if grep -qsE '^\s*Current=' /etc/sddm.conf && ! grep -qsE '^\s*Current=glyph\s*$' /etc/sddm.conf; then
        say "/etc/sddm.conf sets its own theme and wins over conf.d: set Current=glyph there"
    fi
}

[ "$EUID" -eq 0 ] && { echo "run as your user, not root: sudo asks when it needs to"; exit 1; }

case "${1:-}" in
    --links) links ;; # on any distribution (NixOS, Fedora…): install native packages, package list in README
    --sddm) greeter ;;
    ""|--with) command -v pacman >/dev/null || { echo "packages install on Arch only; on another distro: $0 --links"; exit 1; }
        [ "${1:-}" = --with ] && WITH="${*:2}" # comma- or space-separated
        extras; packages; services; links; greeter
        # spicetify requires Spotify already installed and logged in; nothing to apply before first launch
        [[ " ${WITH//,/ } " == *" spotify "* ]] && say "spotify: launch it, log in, then run spicetify config custom_apps marketplace && spicetify backup apply"
        say "done. reboot and pick Hyprland in sddm" ;;
    *) echo "usage: $0 [--with telegram,spotify,clash | --links | --sddm]"; exit 1 ;;
esac
