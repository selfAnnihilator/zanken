#!/bin/bash

# Set install mode to online since boot.sh is used for curl installations
export ZANKEN_ONLINE_INSTALL=true

ansi_art='                 ▄▄▄
 ▄█████▄    ▄███████████▄    ▄███████   ▄███████   ▄███████   ▄█   █▄    ▄█   █▄
███   ███  ███   ███   ███  ███   ███  ███   ███  ███   ███  ███   ███  ███   ███
███   ███  ███   ███   ███  ███   ███  ███   ███  ███   █▀   ███   ███  ███   ███
███   ███  ███   ███   ███ ▄███▄▄▄███ ▄███▄▄▄██▀  ███       ▄███▄▄▄███▄ ███▄▄▄███
███   ███  ███   ███   ███ ▀███▀▀▀███ ▀███▀▀▀▀    ███      ▀▀███▀▀▀███  ▀▀▀▀▀▀███
███   ███  ███   ███   ███  ███   ███ ██████████  ███   █▄   ███   ███  ▄██   ███
███   ███  ███   ███   ███  ███   ███  ███   ███  ███   ███  ███   ███  ███   ███
 ▀█████▀    ▀█   ███   █▀   ███   █▀   ███   ███  ███████▀   ███   █▀    ▀█████▀
                                       ███   █▀                                  '

clear
echo -e "\n$ansi_art\n"

# Use custom branch if instructed, otherwise install the supported release branch.
ZANKEN_REF="${ZANKEN_REF:-main}"

# Set mirror based on branch
if [[ $ZANKEN_REF == "dev" ]]; then
  export ZANKEN_MIRROR=edge
  echo 'Server = https://geo.mirror.pkgbuild.com/$repo/os/$arch' | sudo tee /etc/pacman.d/mirrorlist >/dev/null
elif [[ $ZANKEN_REF == "rc" ]]; then
  export ZANKEN_MIRROR=rc
  echo 'Server = https://mirror.rackspace.com/archlinux/$repo/os/$arch' | sudo tee /etc/pacman.d/mirrorlist >/dev/null
else
  export ZANKEN_MIRROR=stable
  echo 'Server = https://mirrors.kernel.org/archlinux/$repo/os/$arch' | sudo tee /etc/pacman.d/mirrorlist >/dev/null
fi

sudo pacman -Syu --noconfirm --needed git

# Use custom repo if specified, otherwise default to selfAnnihilator/zanken
ZANKEN_REPO="${ZANKEN_REPO:-selfAnnihilator/zanken}"

echo -e "\nCloning Zanken from: https://github.com/${ZANKEN_REPO}.git"
rm -rf ~/zanken/
git clone "https://github.com/${ZANKEN_REPO}.git" ~/zanken >/dev/null

echo -e "\e[32mUsing branch: $ZANKEN_REF\e[0m"
cd ~/zanken
git fetch origin "${ZANKEN_REF}" && git checkout "${ZANKEN_REF}"
cd -

echo -e "\nInstallation starting..."
source ~/zanken/install.sh "$@"
