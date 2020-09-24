#!/bin/bash
# NFS based persistant storage setup script for OCP
# Deploying dynamic NFS based persistant storage

NFSRV=10.128.0.24
NFSMOUNT=/root/nfs/kubedata

mkdir nfsstorage
cd nfsstorage

oc login -u system:admin
oc new-project kubenfs

wget https://raw.githubusercontent.com/cloudcafetech/kubesetup/master/nfs-storage/nfs-rbac.yaml
wget https://raw.githubusercontent.com/cloudcafetech/kubesetup/master/nfs-storage/nfs-deployment.yaml
wget https://raw.githubusercontent.com/cloudcafetech/kubesetup/master/nfs-storage/kubenfs-storage-class.yaml

sed -i "s/10.128.0.9/$NFSRV/g" nfs-deployment.yaml
sed -i "s|/root/nfs/kubedata|$NFSMOUNT|g" nfs-deployment.yaml

oc create -f nfs-rbac.yaml -n kubenfs
oc adm policy add-scc-to-user hostmount-anyuid -z kubenfs
oc adm policy add-scc-to-user hostmount-anyuid -z nfs-client-provisioner
oc adm policy add-scc-to-user hostmount-anyuid -z kubenfs
oc create -f nfs-deployment.yaml -f kubenfs-storage-class.yaml -n kubenfs
