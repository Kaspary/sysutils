#!/bin/bash

echo 'Installing Tilix';
sudo apt install tilix -y

echo 'Settings tilix as default';
sudo update-alternatives --set x-terminal-emulator $(which tilix)
