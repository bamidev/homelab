# Nextcloud

## Installation

The Nextcloud image provides some scripts to install Nextcloud, and to install Nextcloud apps.

To install Nextcloud, keep in mind that the `/var/nextcloud/config/config.php` file that has been
put into place by default, sets property `installed` to `true`.
Set it `false` manually by entering the pod and editing the file.
Only when it is set to `false`, you can start the installation.

To run the installation, simply run `nextcloud-install` in the pod, or:
```
sudo -E kubectl -n nextcloud exec deploy/production -- nextcloud-install
```
This will set up Nextcloud with a few basic apps, but no actual users other than the admin.
You can find the password with: `pass kubernetes/nextcloud/admin`

## Apps

To enable other Nextcloud apps, simply run the following inside the pod:
```
nextcloud-occ app:enable my-app
```
