#!/bin/bash
# Master and Slave VM configuration
master_ip="192.168.56.7"
cat > Vagrantfile <<EOF
Vagrant.configure("2") do |config|
  # Master Node Configuration
  config.vm.define "master" do |master|
    master.vm.box = "spox/ubuntu-arm"
    master.vm.box_version = "1.0.0"
    master.vm.network "private_network", ip: "$master_ip"
    master.vm.provider "vmware_desktop" do |vmware|
      vmware.vmx["memsize"] = "2048"
      vmware.vmx["numvcpus"] = "2"
      vmware.gui = true
      vmware.allowlist_verified = true
    end

    # LAMP Stack provisioning file
    master.vm.provision "file", source: "./lamp-stack-provision.sh", destination: "/home/vagrant/lamp-stack-provision.sh"
    master.vm.provision "shell", inline: "chmod +x /home/vagrant/lamp-stack-provision.sh"

    # Laravel configuration file provisioning
    master.vm.provision "file", source: "./laravel.conf", destination: "/tmp/laravel.conf"
    master.vm.provision "shell", inline: <<-SHELL
        sudo mkdir -p /etc/apache2/sites-available/
        sudo mv /tmp/laravel.conf /etc/apache2/sites-available/laravel.conf
    SHELL

    # Apache setup file provisioning
    master.vm.provision "file", source: "./apache-setup.sh", destination: "/home/vagrant/apache-setup.sh"
    master.vm.provision "shell", inline: <<-SHELL
        chmod +x /home/vagrant/apache-setup.sh
    SHELL
  end

  # Slave Node Configuration
  config.vm.define "slave" do |slave|
    slave.vm.box = "spox/ubuntu-arm"
    slave.vm.box_version = "1.0.0"
    slave.vm.network "private_network", ip: "192.168.56.17"
    slave.vm.provider "vmware_desktop" do |vmware|
      vmware.vmx["memsize"] = "2048"
      vmware.vmx["numvcpus"] = "2"
      vmware.gui = true
      vmware.allowlist_verified = true
    end

    # Ansible Playbook
    slave.vm.provision "file", source: "./master-execute.yml", destination: "/home/vagrant/master-execute.yml"

    # Ansible configuration file
    slave.vm.provision "file", source: "./hosts.ini.template", destination: "/home/vagrant/hosts.ini.template"
    slave.vm.provision "shell", inline: <<-SHELL
        sed -i "s/{{ master_ip }}/$master_ip/" /home/vagrant/hosts.ini.template
        mv /home/vagrant/hosts.ini.template /home/vagrant/hosts.ini
        
        # Disable host key checking
        export ANSIBLE_HOST_KEY_CHECKING=False

        # Install ansible
        sudo apt-add-repository ppa:ansible/ansible -y
        sudo apt update
        sudo apt install ansible -y

        # Check that master is up before executing playbook
        until ping -c1 $master_ip &>/dev/null; do
          echo "Waiting for master to be reachable..."
          sleep 5
        done

        # Run ansible playbook
        ansible-playbook -i /home/vagrant/hosts.ini /home/vagrant/master-execute.yml
SHELL
  end
end
EOF

vagrant up
