#!/bin/bash

# Setup apache server to host laravel
sudo a2dissite 000-default.conf
sudo a2ensite laravel.conf

sudo a2enmod rewrite
sudo systemctl restart apache2

sudo chown -R www-data:www-data /home/vagrant/laravel/storage
sudo chown -R www-data:www-data /home/vagrant/laravel/bootstrap/cache

sudo apt-get install libapache2-mod-php8.1
sudo a2enmod php8.1
sudo systemctl restart apache2
