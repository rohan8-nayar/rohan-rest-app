# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  # Base box configuration - ARM64 box for Apple Silicon Macs
  config.vm.box = "bento/ubuntu-22.04-arm64"  # Ubuntu 22.04 LTS for ARM
  config.vm.box_check_update = false

  # VM configuration
  config.vm.define "rohan-rest-app" do |app|
    app.vm.hostname = "rohan-rest-app"
    
    # Network configuration
    app.vm.network "private_network", ip: "192.168.56.10"
    app.vm.network "forwarded_port", guest: 8080, host: 8080, host_ip: "127.0.0.1"
    app.vm.network "forwarded_port", guest: 5432, host: 5432, host_ip: "127.0.0.1"
    
    # Provider-specific configuration for VMware Fusion (Apple Silicon)
    app.vm.provider "vmware_desktop" do |vmware|
      vmware.vmx["displayname"] = "rohan-rest-app"
      vmware.vmx["memsize"] = "2048"
      vmware.vmx["numvcpus"] = "2"
      vmware.gui = false
    end
    
    # Fallback to VirtualBox for Intel Macs (will fail on ARM)
    app.vm.provider "virtualbox" do |vb|
      vb.name = "rohan-rest-app"
      vb.memory = "2048"
      vb.cpus = 2
      vb.gui = false
      vb.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
      vb.customize ["modifyvm", :id, "--natdnsproxy1", "on"]
    end
    
    # Sync folders - use rsync for better cross-platform compatibility
    app.vm.synced_folder ".", "/vagrant", type: "rsync", 
      rsync__exclude: ['.git/', 'venv/', '__pycache__/', '*.pyc', '.DS_Store']
    
    # Provisioning script
    app.vm.provision "shell", path: "scripts/setup.sh", privileged: false
    
    # Optional: Run deployment after provisioning
    app.vm.provision "shell", inline: <<-SHELL
      echo "🚀 Starting application deployment..."
      make start-api
    SHELL
  end
end