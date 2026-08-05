# This file installs everything I need on my Kubernetes cluster.
set -ex

# Helm repos
helm repo add democratic-csi https://democratic-csi.github.io/charts/
helm repo add traefik https://traefik.github.io/charts
helm repo update

# The Kubernetes Descheduler
kubectl apply -f descheduler/kubernetes/base/rbac.yaml
kubectl apply -f descheduler/kubernetes/base/configmap.yaml
kubectl apply -f descheduler/kubernetes/deployment/deployment.yaml

# Traefik
helm upgrade --install traefik traefik/traefik --version 41.1.1 -f traefik/values.yaml --wait

# local-path-provisioner so that the CNPG databases can store everything on the disk of the node they are running on.
kubectl apply -f https://raw.githubusercontent.com/rancher/local-path-provisioner/v0.0.36/deploy/local-path-storage.yaml

# democratic-csi allows Kubernetes to make snapshots
helm upgrade --install local-zfs democratic-csi/democratic-csi --version 0.15.1 --create-namespace --namespace democratic-csi -f democratic-csi.yaml

# CNPG (CloudNativePostGres)
kubectl apply --server-side -f https://raw.githubusercontent.com/cloudnative-pg/cloudnative-pg/release-1.30/releases/cnpg-1.30.0.yaml
