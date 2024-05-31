#!/bin/bash

# MIT License - github.com/imlayered/writea-installer/

echo "You are about to install Writea (writea.prpl.wtf) onto your server, please click enter to proceed; CTRL+C to cancel."
echo "Install script by Auri (auri.lol), Writea by Ivy (prpl.wtf)"
read -r

# This kinda works... sometimes...
read -p "Would you like to see detailed output? (y/n, default is n): " show_output
show_output=${show_output:-n}

read -p "Would you like to use Nginx or Apache for your webserver? (default is nginx): " webserver
webserver=${webserver:-nginx}

read -p "What is your email (Used for SSL registering through Certbot): " email

read -p "What domain would you like to use Writea on: " domain

read -p "What is your site name: " site_name

read -p "What is your site description: " site_description

run_command() {
    if [ "$show_output" == "y" ]; then
        "$@"
    else
        "$@" > /dev/null 2>&1
    fi
}

run_command sudo apt update && sudo apt upgrade -y

install_nginx() {
    run_command sudo apt install -y nginx
    sudo tee /etc/nginx/sites-available/writea <<EOL
server {
    listen 80;
    server_name $domain;

    root /var/www/writea;
    index index.html index.htm;

    location / {
        try_files \$uri \$uri/ =404;
    }
}
EOL
    run_command sudo ln -s /etc/nginx/sites-available/writea /etc/nginx/sites-enabled/
    run_command sudo systemctl restart nginx
}

install_apache() {
    run_command sudo apt install -y apache2
    sudo tee /etc/apache2/sites-available/writea.conf <<EOL
<VirtualHost *:80>
    ServerAdmin $email
    ServerName $domain
    DocumentRoot /var/www/writea

    <Directory /var/www/writea>
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>

    ErrorLog \${APACHE_LOG_DIR}/error.log
    CustomLog \${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
EOL
    run_command sudo a2ensite writea.conf
    run_command sudo systemctl restart apache2
}

if [ "$webserver" == "nginx" ]; then
    install_nginx
else
    install_apache
fi

run_command sudo mkdir -p /var/www/writea
run_command sudo git clone https://github.com/prplwtf/writea.git /var/www/writea

run_command sudo cp /var/www/writea/configuration/Configuration.example.yml /var/www/writea/configuration/Configuration.yml
sudo sed -i "s/Title:.*/Title: $site_name/" /var/www/writea/configuration/Configuration.yml
sudo sed -i "s/Description:.*/Description: $site_description/" /var/www/writea/configuration/Configuration.yml
sudo sed -i "s|Link:.*|Link: http://$domain|" /var/www/writea/configuration/Configuration.yml

if [ "$webserver" == "nginx" ]; then
    run_command sudo apt install -y certbot python3-certbot-nginx
    run_command sudo certbot --nginx -m $email -d $domain --agree-tos --non-interactive
else
    run_command sudo apt install -y certbot python3-certbot-apache
    run_command sudo certbot --apache -m $email -d $domain --agree-tos --non-interactive
fi

echo "Writea has been installed and is running on http://$domain"
echo "Writea install script by Auri (auri.lol / github.com/imlayered/writea-install)"
echo "If you find any errors, please contact me on Discord at @layered"
echo -e " 
     (
       )
    .------.
   |        |
  |          |
  |          |
   \        /
    --------
 "
# MIT License - github.com/imlayered/writea-installer/
