#!/usr/bin/env bash

[ "$UID" -eq 0 ] || {
  echo "This script must be run as root."
  exit 1
}
if ! tty -s; then
  echo "This script must be run in an interactive terminal."
  exit 1
fi

booask()
{
  while :; do
    read -rp "$1 [y/n]: " yn
    case "$yn" in
      [Yy]*)
        return
        ;;
      [Nn]*)
        return 1
        ;;
      *)
        echo "Please answer y or n."
        ;;
    esac
  done
}

if booask 'Do you want to install postgres?'; then
  apt install postgresql postgresql-contrib
fi

if booask 'Do you want to create a postgres user?'; then
  read -rp "Postgres new user username? [$SUDO_USER]: " pg_user_username
  pg_user_username="${pg_user_username:-$SUDO_USER}"
  read -rp "And password?: " -s pg_user_pwd
else
  read -rp "Postgres existing user username? [$SUDO_USER]: " pg_user_username
  pg_user_username="${pg_user_username:-$SUDO_USER}"
fi

postgres psql <<SQL
CREATE USER '$pg_user_username' WITH PASSWORD '$pg_user_pwd';
ALTER ROLE '$pg_user_username' SET client_encoding TO 'utf8';
ALTER ROLE '$pg_user_username' SET default_transaction_isolation TO 'read committed';
ALTER ROLE '$pg_user_username' SET timezone TO 'UTC';
SQL

if booask 'Do you want to create a database?'; then
  read -rp 'Postgres database name: ' pg_db_name
  postgres psql <<SQL
CREATE DATABASE '$pg_db_name';
GRANT ALL PRIVILEGES ON DATABASE '$pg_db_name' TO '$pg_user_username';
SQL
fi
