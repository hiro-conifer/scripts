#!/bin/bash

yay -S --noconfirm hyprland hypridle hyprlock swaybg xdg-desktop-portal-hyprland qt5-wayland waybar wofi mako ranger pywal-16-colors \
                   pipewire wireplumber pipewire-alsa pipewire-pulse pavucontrol playerctl \
                   bluez bluez-utils blueman \
                   fcitx5 fcitx5-im fcitx5-mozc \
                   kitty starship zsh yarn neofetch btop \
                   nwg-look catppuccin-mocha-dark-cursors kora-icon-theme layan-gtk-theme-git \
                   greetd greetd-tuigreet \
                   ttf-all-the-icons ttf-font-awesome ttf-ubuntu-mono-nerd otf-font-awesome noto-fonts noto-fonts-cjk noto-fonts-emoji noto-fonts-extra ttf-joypixels ttf-jetbrains-mono ttf-poppins ttf-noto-nerd adobe-source-han-sans-jp-fonts adobe-source-han-serif-jp-fonts otf-ipafont ttf-mona ttf-monapo ttf-ipa-mona ttf-vlgothic ttf-mplus ttf-koruri ttf-mplus ttf-sazanami ttf-hanazono \
                   vivaldi rclone fuse3 chezmoi steam


dir_share=~/.local/share
rm -rf ~/.config
mkdir -p $dir_share
git clone https://github.com/hiro-conifer/dotfiles.git
mv ~/dotfiles ${dir_share}/chezmoi
chezmoi apply

sudo sed -i -e "s/agreety --cmd \/bin\/sh/tuigreet -t -r --remember-session --asterisks/" /etc/greetd/config.toml

sudo systemctl enable bluetooth.service greetd.service
