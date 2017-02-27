
apt-get install -y zsh
adduser --force-badname --uid 9999 --shell=/bin/$(basename DEVWDOC_SHELL) --disabled-password --gecos "DEVWDOC_USERNAME" DEVWDOC_USERNAME
usermod -G docker,admin,sudo,staff DEVWDOC_USERNAME
echo "DEVWDOC_USERNAME ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/DEVWDOC_USERNAME

mkdir /home/DEVWDOC_USERNAME/.ssh
chmod 0700 /home/DEVWDOC_USERNAME/.ssh
mv /tmp/id_rsa* /home/DEVWDOC_USERNAME/.ssh/
mv /tmp/ssh_config /home/DEVWDOC_USERNAME/.ssh/config

mkdir /home/DEVWDOC_USERNAME/vagrant_projects
echo "File from dev-on-ub" > /home/DEVWDOC_USERNAME/vagrant_projects/README.txt

mv /tmp/extras.sh /tmp/localextras.sh /home/DEVWDOC_USERNAME/

mkdir /home/DEVWDOC_USERNAME/consul-registrator-setup/
mv /tmp/consul.json /tmp/docker-compose.yml /home/DEVWDOC_USERNAME/consul-registrator-setup/

chown -R DEVWDOC_USERNAME: /home/DEVWDOC_USERNAME

sudo -u DEVWDOC_USERNAME -i bash extras.sh

echo "/home/DEVWDOC_USERNAME/vagrant_projects DEVWDOC_VM_GATEWAY_IP(rw,sync,no_subtree_check,insecure,anonuid=$(id -u DEVWDOC_USERNAME),anongid=$(id -g DEVWDOC_USERNAME),all_squash)" >> /etc/exports
exportfs -a

echo "** Cleaning up old packaged with 'apt autoremove' ... "
apt autoremove -y

echo "** Linking /Users -> /home in the guest. Supports volume mounting in docker-compose"
[[ ! -L /Users ]] && ln -s /home /Users

echo "** Run 'export DOCKER_HOST="tcp://DEVWDOC_VM_IP:2375"' on this host to interact with docker in the vagrant guest"
echo "** Note that some things may not work."

