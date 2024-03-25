#!/bin/bash

echo 'Installing docker';
sudo apt-get update;
sudo apt-get remove docker docker-engine docker.io -y;
sudo apt install docker.io docker-compose -y;
sudo getent group docker >/dev/null || sudo groupadd docker;
sudo usermod -aG docker $USER;
newgrp docker;
docker run hello-world;
sudo systemctl enable docker;
sudo systemctl disable docker;
