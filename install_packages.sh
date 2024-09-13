#!/bin/bash

# Update the system
echo "Updating the system..."
sudo dnf update -y
sudo dnf upgrade -y

# Checking regular 1st Party repo packages
echo "Checking 1st Party repo packages..."
all_packages_found=true
for package in $(cat ./1st-party.rpm-packages.list)
do
    if ! dnf info $package > /dev/null;
    then
        echo "$package not found"
        all_packages_found=false
    fi
done
if [ $all_packages_found = false ]
then
    echo "Some packages not found. Exiting..."
    exit 1
fi

# Installing Regular Available Packages
echo "Installing regular 1st Party repo packages"
rpm_packages=$(cat ./1st-party.rpm-packages.list)
sudo dnf install -y $rpm_packages

# Installing Go Packages
echo "Installing Go Packages"
go_packages=$(cat ./go-packages.list)
go install $go_packages

# Enabling RPM Fusion Fedora Repositories
echo "Enabling RPM Fusion Repositories..."
sudo dnf install -y https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
rpm_fusion_packages=$(cat ./3rd-party.rpm-fusion-packages.list)
sudo dnf install -y $rpm_fusion_packages --allowerasing

# Installing Rust
echo "Installing Rust..."
rust_install_script_tmp=$(mktemp -t rust-install-script-XXXX.sh)
trap "rm -f $rust_install_script_tmp" EXIT
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs -o $rust_install_script_tmp
bash $rust_install_script_tmp -y --profile default

# Installing Packages from cargo
echo "Installing Packages from cargo..."
cargo_packages=$(cat ./cargo-packages.list)
cargo install $cargo_packages

# Installing Bun
echo "Installing Bun..."
bun_install_script_tmp=$(mktemp -t bun-install-script-XXXX.sh)
trap "rm -f $bun_install_script_tmp" EXIT
curl -fsSL https://bun.sh/install -o $bun_install_script_tmp
bash $bun_install_script_tmp 

# Installing from 3rd Party Repos
echo "Installing packages from 3rd Party Repos..."
# Add the Mullvad repository server to dnf
sudo dnf config-manager --add-repo https://repository.mullvad.net/rpm/stable/mullvad.repo
# Installing Mulvad VPN
sudo dnf install -y mullvad-vpn

# Installing from COPR
echo "Installing packages from COPR repos..."
sudo dnf copr enable -y atim/bandwhich
sudo dnf copr enable -y varlad/onefetch

copr_packages=$(cat ./3rd-party.copr-rpm-packages.list)
sudo dnf --refresh install -y $copr_packages

# Installing Flatpaks
echo "Installing Flatpaks from Flathub..."
flatpak_packages=$(cat ./flatpaks.flathub.list)
flatpak install -y --noninteractive flathub $flatpak_packages

# Installing downloaded rpms
# Installing AppImageLauncher
echo "Installing AppImageLauncher..."
appimagelauncher_tmp=$(mktemp -t appimagelauncher-XXXX.rpm)
trap "rm -f $appimagelauncher_tmp" EXIT
appimagelauncher_rpm_download_link=$(curl -sL https://api.github.com/repos/TheAssassin/AppImageLauncher/releases/latest | jq -r '.assets[] | select(.name | match(".*x86_64.*rpm")).browser_download_url')
curl -sL $appimagelauncher_rpm_download_link -o $appimagelauncher_tmp
sudo dnf install -y $appimagelauncher_tmp

# Installing Oh My Zsh
echo "Installing Oh My Zsh..."
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

# Installing App Images
echo "Installing AppImages..."
mkdir -p ~/Applications
appimage_static_urls=$(cat ./appimages-urls.static.list)
for appimage_url in $appimage_static_urls
do
    curl -sL $appimage_url -O -J
done
insomnia_latest_release_url=$(curl -sL https://api.github.com/repos/Kong/insomnia/releases/latest | jq -r '.assets[] | select(.name | match(".*AppImage")).browser_download_url')
curl -sL $insomnia_latest_release_url -O -J

logseq_latest_release_url=$(curl -sL https://api.github.com/repos/logseq/logseq/releases/latest | jq -r '.assets[] | select(.name | match(".*AppImage")).browser_download_url')
curl -sL $logseq_latest_release_url -O -J

mockoon_latest_release_url=$(curl -sL https://api.github.com/repos/mockoon/mockoon/releases/latest | jq -r '.assets[] | select(.name | match(".*x86_64.*AppImage")).browser_download_url')
curl -sL $mockoon_latest_release_url -O -J

trezor_suite_latest_release_url=$(curl -sL https://api.github.com/repos/trezor/trezor-suite/releases/latest | jq -r '.assets[] | select(.name | match(".*x86_64.*AppImage$")).browser_download_url')
curl -sL $trezor_suite_latest_release_url -O -J

rquickshare_latest_release_url=$(curl -sL https://api.github.com/repos/Martichou/rquickshare/releases/latest | jq -r '.assets[] | select(.name | match(".*amd64.*AppImage")).browser_download_url')
curl -sL $rquickshare_latest_release_url -O -J

wezterm_latest_release_url=$(curl -sL https://api.github.com/repos/wez/wezterm/releases/latest | jq -r '.assets[] | select(.name | match(".*AppImage$")).browser_download_url')
curl -sL $wezterm_latest_release_url -O -J
find . -name "*.AppImage" -exec chmod +x {}
mv *.AppImage ~/Applications

# Installing fonts
echo "Installing fonts..."
firacode_mono_nerdfont_zip_tmp=$(mktemp -t firacode-mono-nerdfont-XXXX.zip)
firacode_mono_nerdfont_dir_tmp=$(mktemp -d -t firacode-mono-nerdfont-XXXX)
trap "rm -f $firacode_mono_nerdfont_zip_tmp" EXIT
trap "rm -rf $firacode_mono_nerdfont_dir_tmp" EXIT
fira_code_zip_link=$(curl -sL https://api.github.com/repos/ryanoasis/nerd-fonts/releases/latest | jq -r '.assets[] | select(.name | match("FiraCode.zip")).browser_download_url')
curl -sL $fira_code_zip_link -o $firacode_mono_nerdfont_zip_tmp
unzip $firacode_mono_nerdfont_zip_tmp -d $firacode_mono_nerdfont_dir_tmp
mkdir -p $HOME/.local/share/fonts
cp $firacode_mono_nerdfont_dir_tmp/*.ttf $HOME/.local/share/fonts
#TODO: download Apple Color Emoji, configure firefox, zen, and fonts-config to use it
apple_color_emoji_ttf_link=$(curl -sL https://api.github.com/repos/samuelngs/apple-emoji-linux/releases/latest | jq -r '.assets[] | select(.name | match("AppleColorEmoji.ttf")).browser_download_url')
curl -sL $apple_color_emoji_ttf_link -o $HOME/.local/share/fonts/AppleColorEmoji.ttf
sudo cp ./configs/home/.config/fontconfig/fonts.conf $HOME/.config/fontconfig/fonts.conf
sudo cp ./configs/etc/fonts/conf.d/45-generic.conf /etc/fonts/conf.d/45-generic.conf
sudo cp ./configs/etc/fonts/conf.d/60-generic.conf /etc/fonts/conf.d/60-generic.conf
fc-cache -f -v

# Installing Zsh Plugins
echo "Installing Zsh Plugins..."
zsh -c "git clone --depth 1 -- https://github.com/marlonrichert/zsh-autocomplete.git $ZSH_CUSTOM/plugins/zsh-autocomplete"
zsh -c "git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting"
zsh -c "git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions"
zsh -c "git clone https://github.com/spaceship-prompt/spaceship-prompt.git \"$ZSH_CUSTOM/themes/spaceship-prompt\" --depth=1"
zsh -c "ln -s \"$ZSH_CUSTOM/themes/spaceship-prompt/spaceship.zsh-theme\" \"$ZSH_CUSTOM/themes/spaceship.zsh-theme\""
zsh -c "git clone https://github.com/spaceship-prompt/spaceship-vi-mode.git \"$ZSH_CUSTOM/plugins/spaceship-vi-mode\""
chsh -s $(which zsh)