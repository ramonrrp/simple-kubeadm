#!/bin/bash
####################################################################################
# Heavly inspired in "Descomplicando o Kubernetes" from https://www.linuxtips.io/ ##
# Configuring kubeadm|kubectl|kubelet + deps in a ubuntu 20.04 vm###################
################################################################Author: Ramon Perez#
################################################################               2021#
####################################################################################

#Pratical docker installation method
which docker || curl -fsSL https://get.docker.com | bash

# Configuring docker to use systemd as cgroup driver
[[ -d /etc/docker ]] || mkdir /etc/docker
[[ -f /etc/docker/daemon.json ]] || touch /etc/docker/daemon.json
echo '{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2"
}' > /etc/docker/daemon.json

[[ -d /etc/systemd/system/docker.service.d ]] || mkdir -p /etc/systemd/system/docker.service.d
systemctl enable docker
systemctl daemon-reload
systemctl restart docker

#turning swap off
sed -e '/swap/s/^/#/g' -i /etc/fstab
swapoff -a

#installing deps | kubeadm | kubectl | kubelet
apt update
apt install -y apt-transport-https ca-certificates curl
curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg
echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | tee /etc/apt/sources.list.d/kubernetes.list
apt-get update
apt-get install -y kubelet kubeadm kubectl
apt-mark hold kubelet kubeadm kubectl

#iniciallizing cluster
kubeadm init 
mkdir -p $HOME/.kube
cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
chown $(id -u):$(id -g) $HOME/.kube/config

# getting weave-net
kubectl apply -f "https://cloud.weave.works/k8s/net?k8s-version=$(kubectl version | base64 | tr -d '\n')"
kubectl get pods --all-namespaces
