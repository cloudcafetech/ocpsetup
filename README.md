# ocpsetup
# Setup Openshift Container Platform 3.11
Opensource Openshift Container Platform with Monitoring, Logging & Backup ALL in single node

## Prepare ALL Servers for OCP (3.11)
OS ```CentOS 7``` to be ready before hand to start OCP

### Setup OCP

On Host host run following command

```curl -s https://raw.githubusercontent.com/cloudcafetech/kubesetup/master/host-setup.sh | KUBEMASTER=<MASTER-IP> bash -s master```

