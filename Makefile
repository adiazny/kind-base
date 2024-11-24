# Inspired by the work from https://garethr.dev/2019/05/ephemeral-kubernetes-clusters-with-kind-and-make/
# Other resources: https://earthly.dev/blog/makefile-variables/

SHELL_PATH := /bin/bash

APPLY = kubectl apply --filename
NAME = $$(echo $@ | cut -d "-" -f 2- | sed "s/%*$$//")
WAIT := 200s

HOST_IP = $$(ifconfig -l | xargs -n1 ipconfig getifaddr)

KIND_NODE_VERSION := kindest/node:v1.31.0
CALICO_VERSION := v3.28.1
NGINX_CONTROLLER_VERSION := v1.11.3
SINGLE_NODE_KIND_CONFIG := single-node-kind-config.yaml
MULTI_NODE_KIND_CONFIG :=  multi-node-kind-config.yaml

single-node-cluster:
	@kind create cluster --name dolo01 --image $(KIND_NODE_VERSION) --config $(SINGLE_NODE_KIND_CONFIG)
	@kubectl label node dolo01-control-plane node.kubernetes.io/exclude-from-external-load-balancers-
	@$(MAKE) deploy-dependencies

multi-node-cluster:
	@kind create cluster --name multi01 --image $(KIND_NODE_VERSION) --config $(MULTI_NODE_KIND_CONFIG)
	@$(MAKE) deploy-dependencies

deploy-dependencies: deploy-calico deploy-ingress-nginx

create-%:
	@kind create cluster --name $(NAME) --wait $(WAIT)
	
delete-%:
	@kind delete cluster --name $(NAME)

deploy-calico:
	@echo "\nInstall Calico from remote file"
	@$(APPLY) https://raw.githubusercontent.com/projectcalico/calico/${CALICO_VERSION}/manifests/calico.yaml 
	@kubectl wait --for=condition=Available --timeout=60s deployment/calico-kube-controllers -n kube-system

# This nginx manifest has been created for KinD, you do not need to edit or patch the deployment for any reason, it comes preconfigured to integrate with KinD by default.
deploy-ingress-nginx:
	@echo "\nInstall Ingress Nginx Controller from remote file"
	@$(APPLY) https://raw.githubusercontent.com/kubernetes/ingress-nginx/refs/tags/controller-$(NGINX_CONTROLLER_VERSION)/deploy/static/provider/kind/deploy.yaml
	@kubectl apply -f ingress-nginx-controller-service.yaml
	@kubectl wait --for=condition=Available --timeout=60s deployment/ingress-nginx-controller -n ingress-nginx

env-%:
	@kind get kubeconfig --name $(NAME)

clean:
	@kind get clusters | xargs -L1 -I% kind delete cluster --name %

list:
	@kind get clusters

host-ip:
	@echo $(HOST_IP)

cloud-provider-kind:
	@sudo cloud-provider-kind

.PHONY: single-node-cluster multi-node-cluster deploy-calico deploy-ingress-nginx create-% delete-% env-% clean list host-ip cloud-provider-kind