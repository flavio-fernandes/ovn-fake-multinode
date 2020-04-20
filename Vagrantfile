# coding: utf-8
# -*- mode: ruby -*-
# vi: set ft=ruby :

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"
Vagrant.require_version ">=1.7.0"

$bootstrap_centos = <<SCRIPT
#dnf -y update ||:  ; # save your time. "vagrant box update" is your friend
dnf -y install time python3 tcpdump nmap
SCRIPT

$add_extras = <<SCRIPT
cd && python3 -m venv --copies .env
source ./.env/bin/activate
echo '[ -e "${HOME}/.env/bin/activate" ] && source ${HOME}/.env/bin/activate' >> .bashrc

pip install --upgrade pip
# https://scapy.readthedocs.io/en/latest/installation.html#installing-scapy-v2-x
pip install --pre scapy[basic]
SCRIPT

Vagrant.configure(2) do |config|

    vm_memory = ENV['VM_MEMORY'] || '4096'
    vm_cpus = ENV['VM_CPUS'] || '4'

    config.vm.hostname = "connvm"
    config.vm.box = "centos/8"
    config.vm.box_check_update = false

    # config.vm.synced_folder "#{ENV['PWD']}", "/vagrant", sshfs_opts_append: "-o nonempty", disabled: false, type: "sshfs"
    # Optional: Uncomment line above and comment out the line below if you have
    # the vagrant sshfs plugin and would like to mount the directory using sshfs.
    config.vm.synced_folder ".", "/vagrant", type: "rsync"

    config.vm.provision "bootstrap_centos", type: "shell", inline: $bootstrap_centos

    # Install and start ovs
    config.vm.provision :shell do |shell|
         shell.path = 'provisioning/install_ovs_in_underlay.sh'
    end

    config.vm.provision "add_extras", type: "shell", inline: $add_extras, privileged: false

    config.vm.provision :shell do |shell|
         shell.path = 'tutorial_setup.sh'
    end
    
    config.vm.provider 'libvirt' do |lb|
        lb.nested = true
        lb.memory = vm_memory
        lb.cpus = vm_cpus
        lb.suspend_mode = 'managedsave'
    end
    config.vm.provider "virtualbox" do |vb|
       vb.memory = vm_memory
       vb.cpus = vm_cpus
       vb.customize ["modifyvm", :id, "--nested-hw-virt", "on"]
       vb.customize ["modifyvm", :id, "--nictype1", "virtio"]
       vb.customize [
           "guestproperty", "set", :id,
           "/VirtualBox/GuestAdd/VBoxService/--timesync-set-threshold", 10000
          ]
    end
end
