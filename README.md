# KIND Base Configuration

This repository provides a base configuration for deploying single and multi-node KIND (Kubernetes-in-Docker) clusters using Make and Shell scripts. 

This configuration assumes that you have Docker and KIND installed on your system. If you don't have these tools installed, you'll need to install them before using this repository. Future iterations will incorporate automating the installing of required tools.

## Overview

The repository includes a Makefile that defines targets for creating and managing KIND clusters. The Makefile uses Shell scripts to perform tasks such as creating clusters, labeling nodes, and deploying dependencies.

## Targets

The Makefile defines the following targets:

* `single-node-cluster`: Creates a single-node KIND cluster with the specified node version and configuration.
* `multi-node-cluster`: Creates a multi-node KIND cluster with the specified node version and configuration.
* `deploy-dependencies`: Deploys dependencies such as Calico and Ingress-Nginx to the cluster.
* `create-<cluster-name>`: Creates a KIND cluster with the specified name and configuration.
* `delete-<cluster-name>`: Deletes a KIND cluster with the specified name.

## Usage

To use this repository, simply clone it and run the desired Make target. For example, to create a single-node cluster, run the following command:
```bash
make single-node-cluster
```
This will create a single-node KIND cluster with the specified node version and configuration.