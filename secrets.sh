#!/usr/bin/env bash

sudo -E kubectl create secret -n nextcloud generic credentials --from-literal=secret="$(pass homelab/nextcloud/secret)" --from-literal=password-salt="$(pass homelab/nextcloud/password-salt)" --from-literal=admin-password="$(pass homelab/nextcloud/admin)" --from-literal=monitoring-password="$(pass homelab/nextcloud/monitoring)"
sudo -E kubectl create secret -n owncast generic credentials --from-literal=admin-password="$(pass homelab/owncast/admin)"
sudo -E kubectl create secret -n hiddenite generic credentials --from-literal=webdav-password="$(pass homelab/hiddenite/webdav)"

sudo -E kubectl create secret -n distribution tls certificate --cert=/tmp/cert.pem --key=/tmp/key.pem
