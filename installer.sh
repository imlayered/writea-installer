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
server_tokens off;

server {
    listen 80;
    listen [::]:80;
    server_name $domain;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name $domain;

    access_log /var/log/nginx/writea.app-access.log;
    error_log  /var/log/nginx/writea.app-error.log error;

    root /var/www/writea;
    index index.html index.htm;

    ssl_certificate /etc/letsencrypt/live/$domain/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$domain/privkey.pem;
    ssl_session_cache shared:SSL:10m;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers "ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384";
    ssl_prefer_server_ciphers on;

    location / {
        try_files $uri $uri/ =404;
    }
}
EOL
    run_command sudo ln -s /etc/nginx/sites-available/writea /etc/nginx/sites-enabled/
    run_command sudo systemctl restart nginx
}

install_apache() {
    run_command sudo apt install -y apache2
    sudo tee /etc/apache2/sites-available/writea.conf <<EOL
ServerTokens Prod

<VirtualHost *:80>
    ServerName $domain

    Redirect permanent / https://$domain/
</VirtualHost>

<VirtualHost *:443>
    ServerName $domain

    DocumentRoot /var/www/writea
    DirectoryIndex index.html index.htm

    SSLEngine on
    SSLCertificateFile /etc/letsencrypt/live/$domain/fullchain.pem
    SSLCertificateKeyFile /etc/letsencrypt/live/$domain/privkey.pem

    SSLProtocol TLSv1.2 TLSv1.3
    SSLCipherSuite ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384
    SSLHonorCipherOrder on
    SSLSessionCache shmcb:/var/run/ssl_scache(512000)

    CustomLog /var/log/apache2/writea.app-access.log combined
    ErrorLog /var/log/apache2/writea.app-error.log

    <Directory /var/www/writea>
        Options -Indexes +FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>

    <Location />
        RewriteEngine On
        RewriteCond %{REQUEST_FILENAME} !-f
        RewriteCond %{REQUEST_FILENAME} !-d
        RewriteRule ^(.*)$ /index.html [L]
    </Location>
</VirtualHost>
EOL
    run_command sudo a2ensite writea.conf
    run_command sudo a2enmod rewrite
    run_command sudo a2enmod ssl
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
