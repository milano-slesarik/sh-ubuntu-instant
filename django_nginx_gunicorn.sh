#!/bin/bash
[ "$UID" -eq 0 ] || {
  echo "This script must be run as root."
  exit 1
}



user_home_dir=$(eval echo ~${SUDO_USER})
gunicorn_service_path=/etc/systemd/system/gunicorn.service
gunicorn_socket_path=/etc/systemd/system/gunicorn.socket
gunicorn_service_tmpl_url="https://raw.githubusercontent.com/milano-slesarik/ubuntu-django-gunicorn-nginx-bash/master/templates/gunicorn/gunicorn_service.tmpl"
gunicorn_socket_tmpl_url="https://raw.githubusercontent.com/milano-slesarik/ubuntu-django-gunicorn-nginx-bash/master/templates/gunicorn/gunicorn_socket.tmpl"
nginx_conf_tmpl_url="https://raw.githubusercontent.com/milano-slesarik/ubuntu-django-gunicorn-nginx-bash/master/templates/nginx/nginx_base.tmpl"

# functions
function join_by() {
  local IFS="$1"
  shift
  echo "$*"
}

function setup_postgres() {
  pg_db_name=$1
  pg_user_username=$2
  pg_user_pwd=$3
  apt install postgresql postgresql-contrib
  -u postgres psql -c "CREATE DATABASE $pg_db_name;"
  -u postgres psql -c "CREATE USER $pg_user_username WITH PASSWORD '$pg_user_pwd';"
  -u postgres psql -c "ALTER ROLE $pg_user_username SET client_encoding TO 'utf8';"
  -u postgres psql -c "ALTER ROLE $pg_user_username SET default_transaction_isolation TO 'read committed';"
  -u postgres psql -c "ALTER ROLE $pg_user_username SET timezone TO 'UTC';"
  -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE $pg_db_name TO $pg_user_username;"
}

render_template() {
  tmpl=$(wget -O- -q $1)
  user=$SUDO_USER
  eval "echo \"$tmpl\"" > $2

}

setup_gunicorn() {
  render_template $gunicorn_socket_tmpl_url $gunicorn_socket_path
  render_template $gunicorn_service_tmpl_url $gunicorn_service_path
  systemctl start gunicorn.socket
  systemctl enable gunicorn.socket
}

echo_section() {
  echo
  echo ----------------------------------- $1 -----------------------------------------
  echo
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

# /functions

# VARIABLES
# shellcheck disable=SC2034

echo Welcome to the Ubuntu-20.04/Django/Gunicorn/Nginx/Postgres automatic configuration script by @Milano-Slesarik
echo I need you to answer a couple of questions.
echo --------------------------------------------------------

# LINUX CONF VARS

read -p 'Name of your Django project: ' project
use_postgres=$(booask 'Do you want to setup postgres?')
use_gunicorn=$(booask 'Do you want to setup gunicorn?')
use_nginx=$(booask 'Do you want to setup nginx?')

if [ $use_postgres -eq 0 ]; then
  read -p "Postgres user username? [$SUDO_USER]: " pg_user_username
  pg_user_username=${pg_user_username:-$SUDO_USER}
  read -p "And password?: " -s pg_user_pwd
fi
if [ $use_postgres -eq 0 ]; then
  read -p "Postgres database name? [$project]: " pg_db_name
  pg_db_name=${pg_db_name:-$project}
fi

DJANGO_PROJECT_DIR=~/$project

read -p 'Type domains separated by comma (eg. "mysite.com,www.mysite.com"): ' domains_input
read -p 'Type here the URL of GIT repository: ' git_repo
read -p 'Type GIT repository password: ' -s git_repo_pwd

venvs_dir=~/.virtualenvs/
venv_path=venvs_dir$project

nginx_sites_available=/etc/nginx/sites-available/$project
IFS=',' read -r -a domains <<<"$domains_input"
nginx_domains=$(
  IFS=$' '
  echo "${domains[*]}"
)

# RUN

echo ">>> apt update"
yes | apt update
echo ">>> install python3-pip python3-dev libpq-dev nginx curl git"
yes | apt install python3-pip python3-dev libpq-dev nginx curl git

yes | pip3 install --upgrade pip
yes | pip3 install virtualenv

mkdir -p $user_home_dir/.virtualenvs/
virtualenv $user_home_dir/.virtualenvs/$project

if [ $use_postgres -eq 0 ]; then
  setup_postgres $pg_db_name $pg_user_username $pg_user_pwd
fi

GIT_PASSWORD=$git_repo_pwd git clone $git_repo $user_home_dir/$project

# GUNICORN

setup_gunicorn

# NGINX

render_template $nginx_conf_tmpl_url $nginx_sites_available
ln -s $nginx_sites_available /etc/nginx/sites-enabled
nginx -t
systemctl restart nginx
ufw allow 'Nginx Full'
