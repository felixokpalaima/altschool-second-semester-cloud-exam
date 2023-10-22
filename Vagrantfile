master_ip = "192.168.56.18"
Vagrant.configure("2") do |config|
  # Master Node Configuration
  config.vm.define "master" do |master|
    master.vm.box = "spox/ubuntu-arm"
    master.vm.box_version = "1.0.0"
    master.vm.network "private_network", ip: master_ip
    master.vm.provider "vmware_desktop" do |vmware|
      vmware.vmx["memsize"] = "2048"
      vmware.vmx["numvcpus"] = "2"
      vmware.gui = true
      vmware.allowlist_verified = true
    end
    master.vm.provision "shell", inline: <<-SHELL

cat > /home/vagrant/script.sh <<EOF
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

# Start and enale apache and mysql servers
sudo systemctl start apache2
sudo systemctl enable apache2

sudo systemctl start mysql
sudo systemctl enable mysql

sudo php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
sudo php -r "if (hash_file('sha384', 'composer-setup.php') === 'e21205b207c3ff031906575712edab6f13eb0b361f2085f1f1237b7126d785e826a450292b6cfd1d64d92e6563bbde02') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;"
sudo php composer-setup.php
sudo php -r "unlink('composer-setup.php');"
sudo mv composer.phar /usr/local/bin/composer
sudo service apache2 restart
sudo chown -R vagrant:vagrant /home/vagrant/laravel
sudo systemctl restart apache2
composer install
cp .env.example .env
php artisan key:generate
sudo systemctl reload apache2
# php artisan serve --host=0.0.0.0
EOF
chmod +x /home/vagrant/script.sh
sudo mkdir -p /etc/apache2/sites-available/
cat > /etc/apache2/sites-available/laravel.conf <<EOF
<VirtualHost *:80>
ServerAdmin webmaster@localhost
DocumentRoot /home/vagrant/laravel/public

<Directory /home/vagrant/laravel/public>
  AllowOverride All
  Order allow,deny
  Allow from all
  Require all granted
</Directory>

ErrorLog ${APACHE_LOG_DIR}/error.log
CustomLog ${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
EOF

cat > /home/vagrant/commands.sh <<EOF
#!/bin/bash

sudo a2dissite 000-default.conf
sudo a2ensite laravel.conf

sudo a2enmod rewrite
sudo systemctl restart apache2

sudo chown -R www-data:www-data /home/vagrant/laravel/storage
sudo chown -R www-data:www-data /home/vagrant/laravel/bootstrap/cache

sudo apt-get install libapache2-mod-php8.1
sudo a2enmod php8.1
sudo systemctl restart apache2
EOF
sudo chmod +x /home/vagrant/commands.sh
SHELL
  end

  # Slave Node Configuration
  config.vm.define "slave" do |slave|
    slave.vm.box = "spox/ubuntu-arm"
    slave.vm.box_version = "1.0.0"
    slave.vm.network "private_network", ip: "192.168.56.7"
    slave.vm.provider "vmware_desktop" do |vmware|
      vmware.vmx["memsize"] = "2048"
      vmware.vmx["numvcpus"] = "1"
      vmware.gui = true
      vmware.allowlist_verified = true
    end 
    slave.vm.provision "shell", inline: <<-SHELL
    export ANSIBLE_HOST_KEY_CHECKING=False
    sudo apt-add-repository ppa:ansible/ansible -y
    sudo apt update
    sudo apt install ansible apache2 -y
    sudo systemctl start apache2
    sudo systemctl enable apache2
    cat > /home/vagrant/master-execute.yml <<EOF
---
- hosts: master
  tasks:
    - name: Execute bash script on Master
      command: /home/vagrant/script.sh

    - name: Execute commands on Master
      command: /home/vagrant/commands.sh

    - name: Setup a cron job to check server's uptime every 12 am
      cron:
        name: "Check uptime"
        minute: "0"
        hour: "0"
        job: "/usr/bin/uptime >> /home/vagrant/uptime.log"
EOF
cat > /home/vagrant/hosts.ini <<EOF
[master]
master ansible_ssh_host=#{master_ip} ansible_ssh_user=vagrant ansible_ssh_private_key_file=/vagrant/.vagrant/machines/master/vmware_desktop/private_key
EOF
until ping -c1 #{master_ip} &>/dev/null; do
  echo "Waiting for master to be reachable..."
  sleep 5
done

ansible-playbook -i /home/vagrant/hosts.ini /home/vagrant/master-execute.yml
SHELL
  end
end
