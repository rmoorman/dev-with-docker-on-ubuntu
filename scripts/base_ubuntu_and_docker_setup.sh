#!/bin/bash

update-locale LANG="en_US.UTF-8" LC_COLLATE="en_US.UTF-8" \
  LC_CTYPE="en_US.UTF-8" LC_MESSAGES="en_US.UTF-8" \
  LC_MONETARY="en_US.UTF-8" LC_NUMERIC="en_US.UTF-8" LC_TIME="en_US.UTF-8"

echo 'GRUB_CMDLINE_LINUX="cgroup_enable=memory swapaccount=1"' >> /etc/default/grub

echo 'deb https://apt.dockerproject.org/repo ubuntu-xenial main' > /etc/apt/sources.list.d/docker.list
apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D
apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D

apt-get update -y
apt-get install -y ntp git vim curl sqlite debconf-utils \
  network-manager dnsmasq nfs-kernel-server \
  apt-transport-https ca-certificates

apt-get install -y

apt-get purge lxc-docker
apt-cache policy docker-engine

apt-get install -y linux-image-extra-$(uname -r) linux-image-extra-virtual
apt-get install -y docker-engine

curl -L https://github.com/docker/compose/releases/download/1.8.0/docker-compose-`uname -s`-`uname -m` > /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

echo "** Linking /Users -> /home in the guest. Supports volume mounting in docker-compose"
[[ ! -L /Users ]] && ln -s /home /Users

echo "creating docker group and user"
groupadd -f docker
usermod -aG docker vagrant

echo "** Adding ubuntu user to admin group"
groupadd -f admin
usermod -aG admin vagrant

echo "\n\n*** Setting up systemd drop-in config for docker daemon\n"
echo "*** This is CRITICAL for routing, iptables, and docker working in harmony\n\n"
mkdir /etc/systemd/system/docker.service.d
[[ -f /tmp/dev-on-docker.confg ]] && mv /tmp/dev-on-docker.confg /etc/systemd/system/docker.service.d/

echo "** Modifying NetworkManager and dnsmasq to support routing to docker containers from host"
sed -e 's/.*bind-interfaces/# bind-interfaces/' -i /etc/dnsmasq.d/network-manager
sed -e 's/.*dns=dnsmasq/# dns=dnsmasq/' -i /etc/NetworkManager/NetworkManager.conf
[[ -f /tmp/dnsmasq-docker ]] && mv /tmp/dnsmasq-docker /etc/dnsmasq.d/

systemctl daemon-reload
service ntp restart
service nfs-kernel-server start
service network-manager restart
service docker start
service dnsmasq restart

