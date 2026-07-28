kubectl apply -f https://raw.githubusercontent.com/rancher/local-path-provisioner/v0.0.36/deploy/local-path-storage.yaml

kubectl apply -f https://raw.githubusercontent.com/cloudnative-pg/cloudnative-pg/release-1.30/releases/cnpg-1.30.0.yaml

kubectl apply -f ingress-nginx/deployments/common/ns-and-sa.yaml
kubectl apply -f ingress-nginx/deployments/rbac/rbac.yaml
kubectl apply -f ingress-nginx/deployments/rbac/crds.yaml
kubectl apply -f ingress-nginx/deployments/deployment/nginx-ingress.yaml
kubectl apply -f ingress-nginx/deployments/service/loadbalancer.yaml
