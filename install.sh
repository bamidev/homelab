# This file installs everything I need on my Kubernetes cluster.
set -ex

# The Kubernetes Descheduler
kubectl apply -f descheduler/kubernetes/base/rbac.yaml
kubectl apply -f descheduler/kubernetes/base/configmap.yaml
kubectl apply -f descheduler/kubernetes/deployment/deployment.yaml

# local-path-provisioner so that the CNPG databases can store everything on the disk of the node they are running on.
kubectl apply -f https://raw.githubusercontent.com/rancher/local-path-provisioner/v0.0.36/deploy/local-path-storage.yaml

# CNPG (CloudNativePostGres)
kubectl apply --server-side -f https://raw.githubusercontent.com/cloudnative-pg/cloudnative-pg/release-1.30/releases/cnpg-1.30.0.yaml

# The Nginx ingress controller
#kubectl apply -f ingress-nginx/deployments/common/ns-and-sa.yaml
#kubectl apply -f ingress-nginx/deployments/rbac/rbac.yaml
#kubectl apply -f ingress-nginx/deployments/rbac/crds.yaml
#kubectl apply -f ingress-nginx/deployments/deployment/nginx-ingress.yaml
#kubectl apply -f ingress-nginx/deployments/service/loadbalancer.yaml

# Longhorn
#kubectl apply -f https://raw.githubusercontent.com/longhorn/longhorn/v1.12.0/deploy/longhorn.yaml
