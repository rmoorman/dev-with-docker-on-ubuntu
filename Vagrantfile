# -*- mode: ruby -*-
# vi: set ft=ruby :

# VM_IP specifies the port the VM will run on, and the routes
VM_IP = "192.168.90.10"

# VM_GATEWAY_IP specifies the NFS export access. Corresponds to the host's IP
# in the vboxnet
VM_GATEWAY_IP = "192.168.90.1"

# This value should match the port that maps to consul 8600 in the docker-compose
DOCKER_DNS_PORT = 8600

DOCKER_BRIDGE_IP = "171.17.0.1"
DOCKER_BRIDGE_IP_MASK = "32"
DOCKER_BRIDGE_SUBNET = "171.17.0.0"
DOCKER_BRIDGE_SUBNET_MASK = "16"

# This var will be used to configure the user created in the vagrant, and
# should match the user running the vagrant box
USERNAME = ENV.fetch('USER')
SHELL = ENV.fetch('SHELL')
HOME = ENV.fetch('HOME')

require "lib/plugin/setup_docker_routing"

Vagrant.configure("2") do |config|
  config.vm.box = "bento/ubuntu-16.04"
  config.vm.box_version = "= 2.3.0"
  config.vm.box_check_update = true

  # Create a forwarded port mapping which allows access to a specific port
  # within the machine from a port on the host machine. In the example below,
  # accessing "localhost:8080" will access port 80 on the guest machine.
  # config.vm.network "forwarded_port", guest: 80, host: 8080

  # Create a private network, which allows host-only access to the machine
  # using a specific IP.
  config.vm.network "private_network", ip: VM_IP

  # Create a public network, which generally matched to bridged network.
  # Bridged networks make the machine appear as another physical device on
  # your network.
  # config.vm.network "public_network"

  # Share an additional folder to the guest VM. The first argument is
  # the path on the host to the actual folder. The second argument is
  # the path on the guest to mount the folder. And the optional third
  # argument is a set of non-required options.
  # config.vm.synced_folder "../data", "/vagrant_data"
  #config.vm.synced_folder ".", "/vagrant", disabled: true

  config.vm.provider "virtualbox" do |vb|
    vb.name = "dev-on-ub"
    # Customize the amount of memory on the VM:
    vb.memory = "4096"
    vb.cpus = 4
    # Display the VirtualBox GUI when booting the machine
    # vb.gui = true
  end

  provisioning_files = [
    { s: "~#{USERNAME}/.ssh/id_rsa", d: "/tmp/id_rsa" },
    { s: "~#{USERNAME}/.ssh/id_rsa.pub", d: "/tmp/id_rsa.pub" },
    { s: "~#{USERNAME}/.ssh/config", d: "/tmp/ssh_config" },
    { s: "./extras.sh", d: "/tmp/extras.sh" },
    { s: "./localextras.sh", d: "/tmp/localextras.sh" },
    { s: "./consul-registrator-setup/consul.json", d: "/tmp/consul.json" },
    { s: "./consul-registrator-setup/docker-compose.yml", d: "/tmp/docker-compose.yml" },
  ]

  puts "*** Generating Scripts based on user config"
  Dir[File.join(%w{templates *.erb})].each do |template|
    script_name = File.basename(template.sub(/\.erb$/, ""))
    erb_result = ERB.new(File.read(template)).result
    output_file = File.join("generated_scripts", script_name)

    File.open(output_file, "w") {|f| f.puts erb_result }

    provisioning_files << { s: output_file, d: "/tmp/#{script_name}" }
  end
  
  provisioning_files.each do |x|
    config.vm.provision "file", source: x[:s], destination: x[:d]
  end

  config.vm.provision "shell", file: "scripts/base_ubuntu_and_docker_setup.sh"
  config.vm.provision "shell", file: "generated_scripts/user_setup.sh"

  config.vm.provision "shell", inline: <<-SHELL
    echo "/home/#{USERNAME}/vagrant_projects #{VM_GATEWAY_IP}(rw,sync,no_subtree_check,insecure,anonuid=$(id -u #{USERNAME}),anongid=$(id -g #{USERNAME}),all_squash)" >> /etc/exports
    exportfs -a

    sudo -u #{USERNAME} -i bash extras.sh

    echo "** Cleaning up old packaged with 'apt autoremove' ... "
    apt autoremove -y

    echo "** Run 'export DOCKER_HOST="tcp://#{VM_IP}:2375"' on this host to interact with docker in the vagrant guest"
    echo "** Note that some things may not work."
  SHELL
end

