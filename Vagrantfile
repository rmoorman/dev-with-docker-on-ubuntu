# -*- mode: ruby -*-
# vi: set ft=ruby :

# VM_IP specifies the port the VM will run on, and the routes
VM_IP = "192.168.90.10"

# VM_GATEWAY_IP specifies the NFS export access. Corresponds to the host's IP
# in the vboxnet
VM_GATEWAY_IP = "192.168.90.1"

# This value should match the port that maps to consul 8600 in the docker-compose
DOCKER_DNS_PORT = 8600

DOCKER_COMPOSE_VERSION = "1.11.2"

# This var will be used to configure the user created in the vagrant, and
# should match the user running the vagrant box
USERNAME = ENV.fetch('USER')
SHELL = File.basename(ENV.fetch('SHELL'))

require 'open3'
def syscall(log, cmd)
  print "#{log} ... "
  status = nil
  Open3.popen2e(cmd) do |input, output, thr|
    output.each {|line| puts line }
    status = thr.value
  end
  if status.success?
    puts "done"
  else
    exit(1)
  end
end

class SetupDockerRouting < Vagrant.plugin('2')
  name 'setup_docker_routing'

  class Action
    def initialize(app, env)
      @app = app
    end

    def call(env)
      @app.call(env)

      syscall("** Setting up routing to .docker domain", <<-EOF
          echo "** Adding resolver directory if it does not exist"
          [[ ! -d /etc/resolver ]] && sudo mkdir -p /etc/resolver

          echo "** Adding/Replacing *.docker resolver (replacing to ensure OSX sees the change)"
          [[ -f /etc/resolver/docker ]] && sudo rm -f /etc/resolver/docker
          sudo bash -c "printf '%s\n%s\n' 'nameserver #{VM_IP}' 'port #{DOCKER_DNS_PORT}' > /etc/resolver/docker"

          echo "** Adding routes"
          sudo route -n delete 172.17.0.0/16 #{VM_IP}
          sudo route -n add 172.17.0.0/16 #{VM_IP}
          sudo route -n delete 172.17.0.1/32 #{VM_IP}
          sudo route -n add 172.17.0.1/32 #{VM_IP}

          echo "** Mounting ubuntu NFS /home/#{USERNAME}/vagrant_projects to ~/vagrant_projects"
          [[ ! -d #{ENV.fetch('HOME')}/vagrant_projects ]] && mkdir #{ENV.fetch('HOME')}/vagrant_projects
          echo "#!/bin/bash" > ./mount_nfs_share
          echo "" >> ./mount_nfs_share
          echo "sudo mount -t nfs -o rw,bg,hard,nolocks,intr,sync #{VM_IP}:/home/#{USERNAME}/vagrant_projects #{ENV.fetch('HOME')}/vagrant_projects" >> ./mount_nfs_share
          chmod +x ./mount_nfs_share
          ./mount_nfs_share
        EOF
      )
    end
  end

  action_hook(:setup_docker_routing, :machine_action_up) do |hook|
    hook.prepend(SetupDockerRouting::Action)
  end
end

Vagrant.configure("2") do |config|
  config.vm.box = "bento/ubuntu-16.04"
  config.vm.box_version = "= 2.3.0"
  config.vm.box_check_update = true

  # Make sure you have XQuartz running on the host
  config.ssh.forward_x11 = true

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

    # Set the timesync threshold to 10 seconds, instead of the default 20 minutes.
  end

  [
    { s: "./scripts/base_setup.sh", d: "/tmp/base_setup.sh" },
    { s: "./scripts/user_setup.sh", d: "/tmp/user_setup.sh" },
    { s: "~#{USERNAME}/.ssh/id_rsa", d: "/tmp/id_rsa" },
    { s: "~#{USERNAME}/.ssh/id_rsa.pub", d: "/tmp/id_rsa.pub" },
    { s: "~#{USERNAME}/.ssh/config", d: "/tmp/ssh_config" },
    { s: "./extras.sh", d: "/tmp/extras.sh" },
    { s: "./localextras.sh", d: "/tmp/localextras.sh" },
    { s: "./consul-registrator-setup/consul.json", d: "/tmp/consul.json" },
    { s: "./consul-registrator-setup/docker-compose.yml", d: "/tmp/docker-compose.yml" },
  ].each do |x|
    config.vm.provision "file", source: x[:s], destination: x[:d]
  end

  config.vm.provision "shell", inline: <<-SHELL
    sed -e 's/DEVWDOC_USERNAME/#{USERNAME}/' \
        -e 's/DEVWDOC_VM_IP/#{VM_IP}/' \
        -e 's/DEVWDOC_VM_GATEWAY_IP/#{VM_GATEWAY_IP}/' \
        -e 's/DEVWDOC_DOCKER_COMPOSE_VERSION/#{DOCKER_COMPOSE_VERSION}/' \
        -e 's/DEVWDOC_SHELL/#{SHELL}/' \
        -i /tmp/base_setup.sh /tmp/user_setup.sh
    bash /tmp/base_setup.sh
    bash /tmp/user_setup.sh
  SHELL
end

