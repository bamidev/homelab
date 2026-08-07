# The Nextcloud container is running with Apache and PHP-FPM.
# Apache is used because Nextcloud uses an .htaccess file.
{ pkgs, ... }:
let
  nextcloud = pkgs.nextcloud34;
  php = pkgs.php85;
  ncApps = nextcloud.packages.apps;

  apacheConfig = pkgs.writeText "httpd.conf" (
    with pkgs;
    ''
      ServerName 0.0.0.0
      ServerRoot /var/lib/httpd
      Listen 8080

      User httpd
      Group httpd

      SetEnv NEXTCLOUD_CONFIG_DIR /var/nextcloud/config

      LoadModule alias_module ${apacheHttpd}/modules/mod_alias.so
      LoadModule authn_core_module ${apacheHttpd}/modules/mod_authn_core.so
      LoadModule authz_core_module ${apacheHttpd}/modules/mod_authz_core.so
      LoadModule dir_module ${apacheHttpd}/modules/mod_dir.so
      LoadModule env_module ${apacheHttpd}/modules/mod_env.so
      LoadModule log_config_module ${apacheHttpd}/modules/mod_log_config.so
      LoadModule mime_module ${apacheHttpd}/modules/mod_mime.so
      LoadModule mpm_event_module ${apacheHttpd}/modules/mod_mpm_event.so
      LoadModule unixd_module ${apacheHttpd}/modules/mod_unixd.so
      LoadModule proxy_module ${apacheHttpd}/modules/mod_proxy.so
      LoadModule proxy_fcgi_module ${apacheHttpd}/modules/mod_proxy_fcgi.so
      LoadModule rewrite_module ${apacheHttpd}/modules/mod_rewrite.so

      <FilesMatch \.php$>
          SetHandler "proxy:unix:/var/run/php-fpm.sock|fcgi://localhost/"
      </FilesMatch>

      <Directory "${nextcloud}">
          Options Indexes FollowSymLinks
          AllowOverride All
          Require all granted
      </Directory>
      DocumentRoot "${nextcloud}"

      ErrorLog "/dev/stderr"
      TransferLog "/dev/stdout"
      TypesConfig ${pkgs.apacheHttpd}/conf/mime.types

      # Apache needs to know where to find the apps folders
      Alias /apps "/var/nextcloud/apps/"
      Alias /coreapps "${nextcloud}/apps/"
    ''
  );

  nextcloudConfig = import ./nextcloud/config.php.nix { inherit nextcloud; };

  phpFpmConfig = pkgs.writeText "php-fpm.conf" ''
    [global]
    error_log = /dev/stderr
    include = ${phpPoolConfig}
  '';

  phpPoolConfig = pkgs.writeText "www.conf" ''
    [www]
    user = httpd
    group = httpd

    listen = /var/run/php-fpm.sock

    listen.owner = httpd
    listen.group = httpd
    listen.mode = 0660

    pm = ondemand

    pm.max_children = 5

    pm.process_idle_timeout = 10s

    catch_workers_output = yes
    decorate_workers_output = no

    php_admin_value[short_open_tag] = On
    php_admin_value[memory_limit] = 512M
  '';

  entryPointScript = pkgs.writers.writeBashBin "entrypoint" ''
    set -ex
    trap "kill 0" EXIT

    # Write the secrets into config.php
    sed -i "s/POSTGRES_PASSWORD/$POSTGRES_PASSWORD/g" /var/nextcloud/config/config.php
    sed -i "s/NEXTCLOUD_SECRET/$NEXTCLOUD_SECRET/g" /var/nextcloud/config/config.php
    sed -i "s/PASSWORD_SALT/$PASSWORD_SALT/g" /var/nextcloud/config/config.php

    chown -R httpd:httpd /mnt
    chmod -R 777 /tmp

    ${php}/bin/php-fpm -F -O --fpm-config ${phpFpmConfig} &
    ${pkgs.apacheHttpd}/bin/httpd -D FOREGROUND -f ${apacheConfig} &
    wait -n
  '';

  installScript = pkgs.writers.writeBashBin "nextcloud-install" ''
    set -ex

    # Create data dirs
    mkdir -p /mnt/core/skeleton
    mkdir -p /mnt/data
    mkdir -p /mnt/apps
    chown -R httpd:httpd /mnt

    # Remove existing admin user files, because it will block the installation
    rm -rf /mnt/data/admin

    # Run installation command from within a writable directory
    # This is needed because the `occ` script uses __DIR__ to find the config file,
    # and nextcloud complains if __DIR__/config is not writable.
    mkdir -p /tmp/nextcloud
    cp -r ${nextcloud}/* /tmp/nextcloud
    chown -R httpd:httpd /tmp/nextcloud
    chmod -R +w /tmp/nextcloud/config
    su - httpd -c "${php}/bin/php /tmp/nextcloud/occ maintenance:install --database=pgsql --database-name=nextcloud --database-host=\"production-database-rw\" --database-user=nextcloud --database-pass=\"$POSTGRES_PASSWORD\" --data-dir=/mnt/data --password-salt=\"$PASSWORD_SALT\" --server-secret=\"$NEXTCLOUD_SECRET\""

    # Cleanup
    rm -r /tmp/nextcloud
  '';

  occScript = pkgs.writers.writeBashBin "nextcloud-occ" ''
    set -e
    sudo httpd ${php}/bin/php ${nextcloud}/occ $@
  '';
in
pkgs.dockerTools.buildImage {
  name = "nextcloud";

  runAsRoot = with pkgs; ''
    ${dockerTools.shadowSetup}
    groupadd -r httpd
    useradd -r httpd -g httpd -d /var/lib/httpd
    mkdir -p /var/lib/httpd/logs
    chown -R httpd:httpd /var/lib/httpd

    mkdir -p /var/run
    mkdir -p /var/nextcloud/apps
    mkdir -p /var/nextcloud/config

    cp -r ${ncApps.bookmarks} /var/nextcloud/apps/bookmarks
    cp -r ${ncApps.calendar} /var/nextcloud/apps/calendar
    cp -r ${ncApps.contacts} /var/nextcloud/apps/contacts

    chown -R httpd:httpd /var/nextcloud
    chmod -R 0750 /var/nextcloud/
    chmod 0640 /var/nextcloud/config/config.php
  '';

  contents = with pkgs; [
    gnused
    php
    su
    sudo

    (writeTextDir "var/nextcloud/config/config.php" nextcloudConfig)

    installScript
    occScript
  ];

  config = {
    Cmd = [
      # Make sure to exclusively lock the mounted NFS folder, so that no second Nextcloud pod can
      # mount it, and we won't get data corruption if Nextcloud doesn't lock its files very well.
      "${pkgs.flock}/bin/flock"
      "--verbose"
      "-n"
      "/mnt"
      "${entryPointScript}/bin/entrypoint"
    ];
    Env = [
      "NEXTCLOUD_CONFIG_DIR=/var/nextcloud/config"
    ];
    ExposedPorts = {
      "8080/tcp" = { };
    };
  };
}
