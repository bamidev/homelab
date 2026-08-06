# This file installs everything I need on my Kubernetes cluster.
set -ex

# Helm repos
helm repo add coredns https://coredns.github.io/helm
helm repo add democratic-csi https://democratic-csi.github.io/charts/
helm repo add descheduler https://kubernetes-sigs.github.io/descheduler/
helm repo add traefik https://traefik.github.io/charts
helm repo update

# CoreDNS
helm upgrade --install coredns coredns/coredns --version 1.14.6 --namespace=kube-system -f values/coredns.yaml

# The Kubernetes Descheduler
helm upgrade --install descheduler --namespace kube-system descheduler/descheduler

# Traefik
helm upgrade --install traefik traefik/traefik --version 41.1.1 -f traefik/values.yaml --wait

# democratic-csi to give Kubernetes some storage abilities
helm upgrade --install --namespace kube-system --create-namespace snapshot-controller democratic-csi/snapshot-controller
helm upgrade --install local-zfs-dataset democratic-csi/democratic-csi --version 0.15.1 --create-namespace --namespace democratic-csi -f values/democratic-csi.yaml

# CNPG (CloudNativePostGres)
kubectl apply --server-side -f https://raw.githubusercontent.com/cloudnative-pg/cloudnative-pg/release-1.30/releases/cnpg-1.30.0.yaml
# TODO: Install CNPG with helm as well
