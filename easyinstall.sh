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
    . test.sh
}

function _arch() {
    . arch.sh
}

function _debian() {
    . debian.sh
}

_help
