#!/bin/bash
[ "$UID" -eq 0 ] || {
  echo "This script must be run as root."
  exit 1
}

sudo apt update -y  && sudo apt upgrade -y
sudo apt install software-properties-common apt-transport-https
sudo wget -q http://www.webmin.com/jcameron-key.asc -O- | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] http://download.webmin.com/download/repository sarge contrib"
sudo apt install webmin
sudo ufw allow 10000/tcp