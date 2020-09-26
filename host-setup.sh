#!/bin/bash
# OCP host setup script for CentOS

yum install -y yum-utils device-mapper-persistent-data lvm2 git curl wget bind-utils jq httpd-tools zip unzip nfs-utils nmap telnet dos2unix java-1.8.0-openjdk

curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh

mkdir /etc/docker /etc/containers

tee /etc/containers/registries.conf<<EOF
[registries.insecure]
registries = ['172.30.0.0/16']
EOF

tee /etc/docker/daemon.json<<EOF
{
   "insecure-registries": [
     "172.30.0.0/16"
   ]
}
EOF

echo "net.ipv4.ip_forward = 1" | tee -a /etc/sysctl.conf
sysctl -p

systemctl start docker; systemctl status docker; systemctl enable docker

DOCKER_BRIDGE=`docker network inspect -f "{{range .IPAM.Config }}{{ .Subnet }}{{end}}" bridge`
firewall-cmd --permanent --new-zone dockerc
firewall-cmd --permanent --zone dockerc --add-source $DOCKER_BRIDGE
firewall-cmd --permanent --zone dockerc --add-port={80,443,8443}/tcp
firewall-cmd --permanent --zone dockerc --add-port={53,8053}/udp
firewall-cmd --reload

wget https://github.com/openshift/origin/releases/download/v3.11.0/openshift-origin-client-tools-v3.11.0-0cbc58b-linux-64bit.tar.gz
tar xvf openshift-origin-client-tools*.tar.gz
cd openshift-origin-client*/
mv  oc kubectl  /usr/local/bin/
cd
rm -rf get-docker.sh openshift-origin-client-tools-* openshift-origin-client-tools*.tar.gz

public_ip=`ip -o -4 addr list eth0 | awk '{print $4}' | cut -d/ -f1`
oc cluster up --routing-suffix="${public_ip}.nip.io"

oc cluster status

# Deploying dynamic NFS based persistant storage
wget https://raw.githubusercontent.com/cloudcafetech/ocpsetup/master/nfsstorage-setup.sh
chmod +x ./nfsstorage-setup.sh
#./nfsstorage-setup.sh

# Kafka setup
wget https://raw.githubusercontent.com/cloudcafetech/kafka-on-container/master/kafka-setup.sh
chmod +x ./kafka-setup.sh
#./kafka-setup.sh

