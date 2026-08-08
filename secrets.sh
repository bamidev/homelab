#!/usr/bin/env bash

sudo -E kubectl create secret -n nextcloud generic credentials --from-literal=secret="$(pass kubernetes/nextcloud/secret)" --from-literal=password-salt="$(pass kubernetes/nextcloud/password-salt)" --from-literal=admin-password="$(pass kubernetes/nextcloud/admin)" --from-literal=monitoring-password="$(pass kubernetes/nextcloud/monitoring)"
sudo -E kubectl create secret -n owncast generic credentials --from-literal=admin-password="$(pass kubernetes/owncast/admin)"
