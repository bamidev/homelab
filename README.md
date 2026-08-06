# My Kubernetes home-lab

This repository contains everything needed to set up my Kubernetes home-lab.
This includes all the manifest files to create the pods, services, database clusters, etc.
There are also some scripts to set the cluster up with the necessary systems, and only the `kubectl` command needs to be available (and configured to point to the cluster) to do that.

## Setup

To set up the cluster, run `./install.sh` first.
This will install all needed components.
This includes:
* CoreDNS, as the cluster's dns server.
* descheduler, to automatically rebalance pods among nodes.
* CNPG, to manage Postgres database clusters (e.g. a primary and standby/readonly servers).
* democratic-csi, to allow the Postgres databases to be stored on the disk of the node that runs it.

To load all the secrets from my password store into the cluster, use `./secrets.sh`.
This will take the secrets from my password-store and insert it into the cluster.

Then, each of the following services can be enabled by applying the corresponding folder, like so:
```
kubectl apply -f ./apps/grafana
kubectl apply -f ./apps/nextcloud
kubectl apply -f ./apps/owncast
kubectl apply -f ./apps/stonenet-site
```

At this point everything should already be set up and working.

## Images

All the images that are used by the pods are defined in my main [NixOS config](https://github.com/bamidev/nixos-config/tree/system/lab/images), and written in Nix.
In order build & deploy these images, the following command is available on any device that uses my NixOS config:
```
deploy-image nextcloud
```
This will build the nextcloud image, transfer it to all worker nodes, and then import it there into `containerd`.
From that point on, the pods should be able to load it up.

## Certificates

The CA certificate & key are stored in my password store, and my main NixOS config provides scripts for my devices to load these certificates from there, and then generate the necessary certificates for all the Kubernetes components.

Here is a usage example:
```
kubes-gen-control-certs thinkcentre 192.168.0.123
kubes-deploy-control-certs thinkcentre 192.168.0.123
kubes-gen-worker-certs thinkcentre 192.168.0.123
kubes-deploy-worker-certs thinkcentre 192.168.0.123
````
