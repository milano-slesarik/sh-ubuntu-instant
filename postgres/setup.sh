#!/bin/bash
[ "$UID" -eq 0 ] || {
  echo "This script must be run as root."
  exit 1
}
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

install=$(booask "Do you wan't to install postgres?")

if [ $install -eq 0 ]; then
  sudo apt install postgresql postgresql-contrib
fi

create_user=$(booask "Do you wan't to create a postgres user?")


if [ $create_user -eq 0 ]
  then
    read -p "Postgres new user username? [$SUDO_USER]: " pg_user_username
    pg_user_username=${pg_user_username:-$SUDO_USER}
    read -p "And password?: " -s pg_user_pwd
  else
    read -p "Postgres existing user username? [$SUDO_USER]: " pg_user_username
    pg_user_username=${pg_user_username:-$SUDO_USER}
fi

sudo -u postgres psql -c "CREATE USER $pg_user_username WITH PASSWORD '$pg_user_pwd';"
sudo -u postgres psql -c "ALTER ROLE $pg_user_username SET client_encoding TO 'utf8';"
sudo -u postgres psql -c "ALTER ROLE $pg_user_username SET default_transaction_isolation TO 'read committed';"
sudo -u postgres psql -c "ALTER ROLE $pg_user_username SET timezone TO 'UTC';"


create_db=$(booask "Do you wan't to create a database?")

if [ $create_db -eq 0 ]; then
  read -p "Postgres database name?: " pg_db_name
  sudo -u postgres psql -c "CREATE DATABASE $pg_db_name;"
  sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE $pg_db_name TO $pg_user_username;"
fi






