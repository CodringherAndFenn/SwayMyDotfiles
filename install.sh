#!/usr/bin/env bash
# Restore the CachyOS + Sway + Noctalia setup from SwayMyDotfiles on a fresh install.
# Run from anywhere:  bash ~/.dotfiles/SwayMyDotfiles/install.sh
set -euo pipefail

DOTS="$HOME/.dotfiles/SwayMyDotfiles"
STAMP="$(date +%Y%m%d-%H%M%S)"
cd "$DOTS"

echo "==> Packages (repo)"
sudo pacman -S --needed paru
sudo pacman -S --needed - < packages.txt

if [[ -s packages-aur.txt ]]; then
  echo "==> Packages (AUR)"
  paru -S --needed - < packages-aur.txt
fi

echo "==> Linking configs into ~/.config"
mkdir -p "$HOME/.config"
for d in alacritty fastfetch fuzzel sway way-displays nvim yazi noctalia qt6ct; do
  [[ -e "$DOTS/$d" ]] || continue
  target="$HOME/.config/$d"
  if [[ -e "$target" && ! -L "$target" ]]; then
    mv "$target" "$target.bak-$STAMP"
    echo "    backed up $target"
  fi
  ln -sfn "$DOTS/$d" "$target"
  echo "    linked $d"
done

echo "==> Portal config"
mkdir -p "$HOME/.config/xdg-desktop-portal"
ln -sfn "$DOTS/sway-portals.conf" "$HOME/.config/xdg-desktop-portal/sway-portals.conf"

echo "==> fish: y function and EDITOR"
mkdir -p "$HOME/.config/fish/functions"
ln -sfn "$DOTS/fish/functions/y.fish" "$HOME/.config/fish/functions/y.fish"
fish -c 'set -Ux EDITOR nvim'

echo "==> Yazi flavor"
ya pkg install || echo "    (run 'ya pkg install' manually if this failed)"

echo "==> Default apps and GTK"
mkdir -p "$HOME/.config"
echo "Alacritty.desktop" > "$HOME/.config/xdg-terminals.list"
xdg-mime default nemo.desktop inode/directory
xdg-mime default nvim.desktop text/plain
gsettings set org.cinnamon.desktop.default-applications.terminal exec alacritty
gsettings set org.gnome.desktop.interface gtk-theme 'adw-gtk3-dark'
gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'

echo "==> Qt theme variable"
grep -q '^QT_QPA_PLATFORMTHEME=' /etc/environment \
  || echo 'QT_QPA_PLATFORMTHEME=qt6ct' | sudo tee -a /etc/environment >/dev/null

echo "==> Ly (Gruvbox login screen)"
sudo cp /etc/ly/config.ini "/etc/ly/config.ini.bak-$STAMP"
sudo cp "$DOTS/system/ly-config.ini" /etc/ly/config.ini
sudo mkdir -p /etc/systemd/system/ly@.service.d
sudo cp "$DOTS/system/ly-override.conf" /etc/systemd/system/ly@.service.d/override.conf
sudo systemctl daemon-reload

echo
echo "==> Done. Next:"
echo "    1. sway --validate"
echo "    2. swaymsg -t get_outputs  (after login: check monitor names match the output blocks)"
echo "    3. Reboot, log in through Ly, then run: noctalia msg templates-apply"
