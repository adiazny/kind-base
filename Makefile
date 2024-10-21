# Inspired by the work from https://garethr.dev/2019/05/ephemeral-kubernetes-clusters-with-kind-and-make/
# Other resources: https://earthly.dev/blog/makefile-variables/

SHELL_PATH := /bin/bash

APPLY = kubectl apply --filename
NAME = $$(echo $@ | cut -d "-" -f 2- | sed "s/%*$$//")

HOST_IP = $$(ifconfig -l | xargs -n1 ipconfig getifaddr)

KIND_NODE_VERSION := kindest/node:v1.31.0
CALICO_VERSION := v3.28.1
SINGLE_NODE_KIND_CONFIG := single-node-kind-config.yaml
MULTI_NODE_KIND_CONFIG :=  multi-node-kind-config.yaml

single-node-cluster:
	@kind create cluster --name dolo01 --image $(KIND_NODE_VERSION) --config $(SINGLE_NODE_KIND_CONFIG)
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
	@echo "\nInstall Ingress-Nginx from remote file"
	@$(APPLY) https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/static/provider/kind/deploy.yaml
	@kubectl wait --for=condition=Available --timeout=60s deployment/ingress-nginx-controller -n ingress-nginx

env-%:
	@kind get kubeconfig --name $(NAME)

clean:
	@kind get clusters | xargs -L1 -I% kind delete cluster --name %

list:
	@kind get clusters

.PHONY: single-node-cluster multi-node-cluster deploy-calico deploy-ingress-nginx create-% delete-% env-% clean list echo