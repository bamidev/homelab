# My Kubernetes home-lab

This repository contains everything needed to set up my Kubernetes home-lab.
This includes all the manifest files to create the pods, services, database clusters, etc.
There are also some scripts to set the cluster up with the necessary systems, and only the `kubectl` command needs to be available (and configured to point to the cluster) to do that.

## Setup

To set up the cluster, run:
```
sudo -E helmfile apply
```
That should do it.

It will install all the components and my apps.

## Images

All the app images are defined in Nix using `pkgs.dockerTools`, and are available as a 'package' in the flake.
For example, here is how you can build an image:
```
nix build -o nextcloud-image.tar.gz .#nextcloud
```

To deploy these images, the following command is available on any device that uses [my NixOS config](https://github.com/bamidev/nixos-config), assuming your working directory is in this repo:
```
deploy-image nextcloud
```
This will build the nextcloud image, transfer it to all worker nodes, and then import it there into `containerd`.
From that point on, the pods should be able to load it up at any time.

## Certificates

The CA certificate & key are stored in my password store, and my main NixOS config provides scripts for my devices to load these certificates from there, and then generate the necessary certificates for all the Kubernetes components.

Here is a usage example:
```
kubes-gen-control-certs thinkcentre 192.168.0.123
kubes-deploy-control-certs thinkcentre 192.168.0.123
kubes-gen-worker-certs thinkcentre 192.168.0.123
kubes-deploy-worker-certs thinkcentre 192.168.0.123
```
