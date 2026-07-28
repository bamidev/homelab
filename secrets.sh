#!/usr/bin/env bash
kubectl create secret generic nextcloud --from-literal=secret=$(pass kubernetes/nextcloud/secret) --from-literal=password-salt=$(pass kubernetes/nextcloud/password-salt)
kubectl create secret generic owncast --from-literal=secret=$(pass kubernetes/owncast/admin)
