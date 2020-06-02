#!/bin/bash
function booask() {
  while true; do
    read -p "$1 [y/n]: " yn
    case $yn in
    [Yy]*)
      echo 0
      break
      ;;
    [Nn]*)
      echo 1
      break
      ;;
    *) echo "Please answer y or n." ;;
    esac
  done
}
user=$USER

echo Welcome to the Ubuntu-20.04 INIT script by @Milano-Slesarik
echo I need you to answer a couple of questions.
echo --------------------------------------------------------

# LINUX USER VARS
create_user=$(booask 'Do you want to create a new linux user?')

if [ $create_user -eq 0 ]; then
  read -p "What's their name?: " user
  read -p "And password?: " -s userpwd
  echo
  user_is_sudo=$(booask 'Add to sudoers?')
  echo
fi
setup_ufw=$(booask 'Do you want to setup UFW?')

if [ $create_user -eq 0 ]; then
  echo "Creating user '$user'..."
  sudo adduser $user --gecos "First Last,RoomNumber,WorkPhone,HomePhone" --disabled-password
  sudo echo "$user:$userpwd" | sudo chpasswd

  if [ $user_is_sudo -eq 0 ]; then
    echo "Adding user to sudoers..."
    sudo usermod -aG sudo $user # add user to sudoers
  fi
fi

if [ $setup_ufw -eq 0 ]; then
  echo "Setting up UFW Firewall..."
  yes | sudo ufw allow OpenSSH
  yes | sudo ufw enable
  sudo ufw status
fi

echo "User '$user' has been created. You can now login as them using command 'su - $user'"