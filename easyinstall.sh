#!/bin/bash

VER=0.1.0
PROJECT_NAME="easyinstall"
PROJECT="https://github.com/Maninder-mike/$PROJECT_NAME"

Node_name=$(uname -n)
echo $Node_name

function _help() {
    # echo "this is EasyInstall for single command install essential app for your system: "
    # echo $PROJECT_NAME
    # echo $VER
    # echo $PROJECT
    # _arch
    # _debian
    _fedora
}

function _arch() {

    sudo pacman -Syyuu && \

    sudo -S pacman -S neovim vifm pulseaudio pamixer htop \
    tlp tlp-rdw numlockx base-devel xscreensaver firefox cups \
    git go nodejs npm nautilus evince nomacs system-config-printer \
    vlc sqlite sqlitebrowser networkmanager 
}

function _debian() {
    sudo -S apt install fish terminator sqlite3 sqlitebrowser \
    python3 python3-pip git nodejs npm tlp tlp-rdw gnome-tweak-tool \
    ubuntu-restricted-extras neovim vifm 
}


function _fedora() {
    sudo dnf update && \
    sudo dnf install git nodejs npm fish vlc sqlite sqlitebrowser && \
    sudo npm i yarn -g && \
    sudo chsh -s /usr/bin/fish && \
    sudo dnf autoremove
}

_help
