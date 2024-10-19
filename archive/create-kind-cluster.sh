#!/usr/bin/env bash

# Simple script to provision a Kubernetes cluster using KIND: https://kind.sigs.k8s.io/

# Override with a different name if you want
CLUSTER_NAME=${CLUSTER_NAME:-kind-cluster}

# This sets the errexit and nounset options. 
# The errexit option causes the script to exit immediately if any command exits with a non-zero status. 
# The nounset option causes the script to exit if any variable is referenced without being set.
set -eu

if [[ "${INSTALL_KIND:-no}" == "yes" ]]; then
    rm -f ./kind
    curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.11.1/kind-linux-amd64
    chmod a+x ./kind
    sudo mv ./kind /usr/local/bin/kind
fi

# Delete the old cluster (if it exists)
kind delete cluster --name="${CLUSTER_NAME}"

echo -e "Creating KinD Cluster with name: ${CLUSTER_NAME}"
#kind create cluster --name cluster01 --config cluster01-kind.yml
# Create KIND cluster with 3 worker nodes, control node can support ingress too if required
kind create cluster --name="${CLUSTER_NAME}" --config - <<EOF
---
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
networking:
  apiServerAddress: "0.0.0.0"
  disableDefaultCNI: true
  apiServerPort: 6443
kubeadmConfigPatches:
- |
  apiVersion: kubeadm.k8s.io/v1beta2
  kind: ClusterConfiguration
  metadata:
    name: config
  networking:
    serviceSubnet: "10.96.0.1/12"
    podSubnet: "10.240.0.0/16"
nodes:
- role: control-plane
  extraMounts:
  - hostPath: /var/run/docker.sock
    containerPath: /var/run/docker.sock
- role: worker
  extraPortMappings:
  - containerPort: 80
    hostPort: 80
  - containerPort: 443
    hostPort: 443
  - containerPort: 2222
    hostPort: 2222
  extraMounts:
  - hostPath: /var/run/docker.sock
    containerPath: /var/run/docker.sock
EOF

echo -e "Adding node label for Ingress Controller to worker node"
kubectl label node kind-cluster-worker ingress-ready=true

#Install Calico
echo -e "Install Calico from local file, using 10.240.0.0/16 as the pod CIDR"
CALICO_VERSION=v3.28.0 
kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/${CALICO_VERSION}/manifests/calico.yaml 

# Wait for Calico to be ready
kubectl wait --for=condition=Available --timeout=60s deployment/calico-kube-controllers -n kube-system

#Deploy NGINX
echo -e "Install NGINX Ingress Controller"
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml

# Wait for NGINX Ingress Controller to be ready
kubectl wait --for=condition=Available --timeout=60s deployment.apps/ingress-nginx-controller -n ingress-nginx

# Fix issue where script would exit with an error if kubectl was not installed.
# This is done by adding a try/catch around the kubectl commands.
set +e # disable immediate exit on error
trap 'echo -e "Error occurred while running kubectl command: $BASH_COMMAND: ${BASH_LINENO}: ${BASH_COMMAND##*/}: exit status $?.  This is not fatal, but may indicate issues with your cluster." >&2' ERR

#Find IP address of host
hostip=$(ifconfig -l | xargs -n1 ipconfig getifaddr)

echo -e "Your Kind Cluster Information: \n"
echo -e "Ingress Domain: $hostip.nip.io \n"
echo -e "Ingress rules will need to use the IP address of your Linux Host in the Domain name \n"
echo -e "Example:  You have a web server you want to expose using a host called ordering."
echo -e "          Your ingress rule would use the hostname: ordering.$hostip.nip.io"

echo "Cluster created successfully"
echo "Use 'kind load docker-image <image tag>' to push images into the nodes, otherwise they will be pulled"