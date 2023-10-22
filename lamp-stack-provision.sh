#!/bin/bash

# Clone Laravel Github repo
repository_url="https://github.com/laravel/laravel.git"
git clone "https://github.com/laravel/laravel.git"
cd laravel
echo "Successfully cloned laravel repo"

# Install and  configure LAMP stack
sudo add-apt-repository ppa:ondrej/php -y
sudo apt-get update
sudo apt install php8.1 php8.1-cli php8.1-fpm php8.1-mysql php8.1-common php8.1-opcache php8.1-mbstring php8.1-xml php8.1-zip php8.1-gd php8.1-curl unzip -y
sudo apt-get install apache2 mysql-server=8.0.34-0ubuntu0.20.04.1 -y

# Start and enable apache and mysql servers
sudo systemctl start apache2
sudo systemctl enable apache2
sudo systemctl start mysql
sudo systemctl enable mysql

# Install and verify composer with its dependencies
sudo php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
sudo php -r "if (hash_file('sha384', 'composer-setup.php') === 'e21205b207c3ff031906575712edab6f13eb0b361f2085f1f1237b7126d785e826a450292b6cfd1d64d92e6563bbde02') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;"
sudo php composer-setup.php
sudo php -r "unlink('composer-setup.php');"
sudo mv composer.phar /usr/local/bin/composer
sudo service apache2 restart

# Give vagrant user ownership of laravel 
sudo chown -R vagrant:vagrant /home/vagrant/laravel
sudo systemctl restart apache2

# Install laravel app dependencies
composer install

# Create env file for app access keys
cp .env.example .env

# Generate laravel app key in the .env
php artisan key:generate

# Reload apache service
sudo systemctl reload apache2
