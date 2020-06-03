#!/bin/bash
nginx_conf_tmpl_url="https://raw.githubusercontent.com/milano-slesarik/ubuntu-django-gunicorn-nginx-bash/master/templates/nginx/nginx_base.tmpl"


[ "$UID" -eq 0 ] || {
  echo "This script must be run as root."
  exit 1
}


render_template() {
  tmpl=$(wget -O- -q $1)
  user=$SUDO_USER
  eval "echo \"$tmpl\"" > $2

}
read -p '/etc/nginx/sites-available/<NAME OF THE PROJECT>' project

nginx_sites_available=/etc/nginx/sites-available/$project

yes | apt install nginx
render_template $nginx_conf_tmpl_url $nginx_sites_available
ln -s $nginx_sites_available /etc/nginx/sites-enabled
nginx -t
systemctl restart nginx
ufw allow 'Nginx Full'

