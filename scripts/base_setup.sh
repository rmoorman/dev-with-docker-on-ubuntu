
update-locale LANG="en_US.UTF-8" LC_COLLATE="en_US.UTF-8" \
  LC_CTYPE="en_US.UTF-8" LC_MESSAGES="en_US.UTF-8" \
  LC_MONETARY="en_US.UTF-8" LC_NUMERIC="en_US.UTF-8" LC_TIME="en_US.UTF-8"

echo 'deb https://apt.dockerproject.org/repo ubuntu-xenial main' > /etc/apt/sources.list.d/docker.list
apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D
apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D

apt-get update -y
apt-get install -y ntp git vim curl debconf-utils sqlite \
  nfs-kernel-server network-manager dnsmasq \
  apt-transport-https ca-certificates

apt-get purge lxc-docker
apt-cache policy docker-engine
apt-get install -y linux-image-extra-$(uname -r) linux-image-extra-virtual
apt-get install -y docker-engine

curl -L https://github.com/docker/compose/releases/download/DEVWDOC_DOCKER_COMPOSE_VERSION/docker-compose-`uname -s`-`uname -m` > /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

echo 'GRUB_CMDLINE_LINUX="cgroup_enable=memory swapaccount=1"' >> /etc/default/grub

echo "creating docker group and user"
groupadd -f docker
usermod -aG docker vagrant

echo "** Adding ubuntu user to admin group"
groupadd -f admin
usermod -aG admin vagrant

echo "** Setting up systemd dropin config for docker daemon"
mkdir /etc/systemd/system/docker.service.d

cat > /etc/systemd/system/docker.service.d/dev-on-docker.conf <<EOF-docker.conf
[Unit]
Before=dnsmasq.service

[Service]
ExecStart=
ExecStart=/usr/bin/docker daemon -H fd:// -H tcp://DEVWDOC_VM_IP:2375
ExecStartPost=/sbin/iptables -P FORWARD ACCEPT
EOF-docker.conf

echo "** Modifying NetworkManager and dnsmasq to support routing to service.docker"
sed -e 's/.*bind-interfaces/# bind-interfaces/' -i /etc/dnsmasq.d/network-manager
sed -e 's/.*dns=dnsmasq/# dns=dnsmasq/' -i /etc/NetworkManager/NetworkManager.conf

cat > /etc/dnsmasq.d/10-docker <<EOF-dnsmasq.conf
listen-address=127.0.0.1
listen-address=172.17.0.1
listen-address=DEVWDOC_VM_IP
server=/.service.docker/127.0.0.1#8600
EOF-dnsmasq.conf

systemctl daemon-reload

service ntp restart
service dnsmasq restart
service network-manager restart
service nfs-kernel-server start
service docker start

