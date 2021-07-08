# Deployment Guide

Follow these steps to deploy Oona v1 on a Ubuntu 18.04 (Bionic Beaver) or newer Linux system running Microk8s.

## Microk8s Installation

Make sure your system is up-to-date and then install Microk8s:

```bash
# Retrieve the latest package versions across all repositories
sudo apt update

# MicroK8s will install a minimal, lightweight Kubernetes you can run 
# and use on practically any machine. It can be installed with a snap
sudo snap install microk8s --classic --channel=1.21

```

After installation run the following commands:

```bash
# Set an alias to shorten microk8s.kubectl command to kubectl
echo '# alias for kubectl (kubernetes)' >> ~/.bashrc
echo 'alias kubectl=microk8s.kubectl' >> ~/.bashrc

# Run .bashrc file to ensure changes take place
. ~/.bashrc

# To enable Ingress for the microk8s infrastructure
microk8s enable ingress

```

## Install Oona v1

First make changes to the `/etc/hosts` file and add an entry for `localhostke.com` pointing to your IP address

```bash
HOST_IP=`ifconfig enp3s0 | awk '/inet / {print $2}'`
echo $HOST_IP   localhostke.com | sudo tee -a /etc/hosts

```

Next deploy Oona v1 using the yaml files, run: 

```bash
kubectl apply -f jitsi-web.yaml -f jitsi-prosody.yaml -f jitsi-jvb.yaml -f jitsi-jicofo.yaml -f jitsi-ingress.yaml

```
The deployment will take a few minutes and then can be accessed at `localhostke.com` on the browser
