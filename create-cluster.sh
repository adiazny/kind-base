#!/usr/bin/env bash
clear

# TODO: Add check and install logic for following tools:
# kubectl, helm, jq

#Create KIND Cluster called cluster01 using config.
echo -e "\n \n*******************************************************************************************************************"
echo -e "Create Multi-Node KinD Cluster"
echo -e "*******************************************************************************************************************"
kind create cluster --name cluster01 --config multi-node-kind-config.yaml

echo -e "\n \n*******************************************************************************************************************"
echo -e "Adding node label for Ingress Controller to worker nodes"
echo -e "*******************************************************************************************************************"
tput setaf 3
kubectl label node cluster01-worker ingress-ready=true

#Install Calico
echo -e "\n \n*******************************************************************************************************************"
echo -e "Install Calico from remote file"
echo -e "*******************************************************************************************************************"

CALICO_VERSION=v3.28.1
kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/${CALICO_VERSION}/manifests/calico.yaml 

# Wait for Calico to be ready
kubectl wait --for=condition=Available --timeout=60s deployment/calico-kube-controllers -n kube-system

# Deploy NGINX
echo -e "\n \n*******************************************************************************************************************"
echo -e "Install NGINX Ingress Controller"
echo -e "*******************************************************************************************************************"

# This manifest has been created for KinD, you do not need to edit or patch the deployment for any reason, it comes preconfigured to integrate with KinD by default.
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/static/provider/kind/deploy.yaml

# Find IP address of Docker Host

hostip=$(ifconfig -l | xargs -n1 ipconfig getifaddr)

echo -e "\n \n*******************************************************************************************************************"
echo -e "Cluster Creation Complete.  Please see the summary below for key information"
echo -e "*******************************************************************************************************************"

echo -e "\n \n*******************************************************************************************************************"
echo -e "Your Kind Cluster Information: \n"
echo -e "Ingress Domain: $hostip.nip.io \n"
echo -e "Ingress rules will need to use the IP address of your Linux Host in the Domain name \n"
echo -e "Example:  You have a web server you want to expose using a host called ordering."
echo -e "          Your ingress rule would use the hostname: ordering.$hostip.nip.io"
echo -e "******************************************************************************************************************* \n"