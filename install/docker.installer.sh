#!/bin/bash

# https://docs.docker.com/engine/install/ubuntu/

echo 'Uninstalling old versions';
for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do sudo apt-get remove -y $pkg; done

echo 'Setting up Docker's apt repository';
# Add Docker's official GPG key:
sudo apt-get update;
sudo apt-get install -y ca-certificates curl;
sudo install -m 0755 -d /etc/apt/keyrings;
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc;
sudo chmod a+r /etc/apt/keyrings/docker.asc;

# Add the Docker repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null;
sudo apt-get update;

echo 'Installing the latest Docker version';
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin;

echo 'Creating docker group and adding user to the group';
sudo getent group docker >/dev/null || sudo groupadd docker;
sudo usermod -aG docker $USER;
newgrp docker;

echo 'Docker installation completed successfully';
