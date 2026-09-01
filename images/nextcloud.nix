# The Nextcloud container is running with Apache and PHP-FPM.
# Apache is used because Nextcloud uses an .htaccess file to handle some of the URL rewriting.
{ pkgs, ... }:
let
  ### Packages ###
  nextcloud = pkgs.nextcloud34;
  php = pkgs.php85;
  ncApps = nextcloud.packages.apps;

  ### Parameters ###
  nextcloudConfigPath = "/var/nextcloud/config";
  user = "httpd";
  group = user;

  ### Config files ###
  apacheConfig = pkgs.writeText "httpd.conf" (
    with pkgs;
    ''
      ServerName 0.0.0.0
      ServerRoot /var/lib/httpd
      Listen 8080

      User ${user}
      Group ${group}

      SetEnv NEXTCLOUD_CONFIG_DIR ${nextcloudConfigPath}

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
    user = ${user}
    group = ${group}

    listen = /var/run/php-fpm.sock

    listen.owner = ${user}
    listen.group = ${group}
    listen.mode = 0660

    pm = ondemand

    pm.max_children = 5

    pm.process_idle_timeout = 10s

    catch_workers_output = yes
    decorate_workers_output = no

    php_admin_value[short_open_tag] = On
    php_admin_value[memory_limit] = 512M
  '';

  entryPointScript = pkgs.writers.writeBashBin "entrypoint.sh" ''
    set -ex
    trap "kill 0" EXIT

    # Write the secrets into config.php
    sed -i "s/POSTGRES_PASSWORD/$POSTGRES_PASSWORD/g" /var/nextcloud/config/config.php
    sed -i "s/NEXTCLOUD_SECRET/$NEXTCLOUD_SECRET/g" /var/nextcloud/config/config.php
    sed -i "s/PASSWORD_SALT/$PASSWORD_SALT/g" /var/nextcloud/config/config.php

    chown -R httpd:httpd /mnt
    chmod -R 777 /tmp

    # Spawn php-fpm, apache and the nextcloud-exporter
    ${php}/bin/php-fpm -F -O --fpm-config ${phpFpmConfig} &
    ${pkgs.apacheHttpd}/bin/httpd -D FOREGROUND -f ${apacheConfig} &
    ${pkgs.prometheus-nextcloud-exporter}/bin/nextcloud-exporter --server http://127.0.0.1:8080 \
      --username monitoring --password "$MONITORING_PASSWORD" &

    # Wait until one of the processes stops, then 
    JOBS=$(jobs -p)
    wait -n
    kill $JOBS
    wait $JOBS
  '';

  installScript = pkgs.writers.writeBashBin "nextcloud-install" ''
    set -ex

    # Create data dirs
    mkdir -p /mnt/core/skeleton
    mkdir -p /mnt/data
    mkdir -p /mnt/apps
    chown -R ${user}:${group} /mnt

    # Remove existing admin user files, because it will block the installation
    rm -rf /mnt/data/admin

    # Run installation command from within a writable directory
    # This is needed because the `occ` script uses __DIR__ to find the config file,
    # and nextcloud complains if __DIR__/config is not writable.
    mkdir -p /tmp/nextcloud
    cp -r ${nextcloud}/* /tmp/nextcloud
    chown -R httpd:httpd /tmp/nextcloud
    chmod -R +w /tmp/nextcloud/config
    ${pkgs.util-linux}/bin/runuser -u httpd -- ${php}/bin/php /tmp/nextcloud/occ maintenance:install --database=pgsql --database-name=nextcloud --database-host=production-database-rw --database-user=nextcloud --database-pass="$POSTGRES_PASSWORD" --data-dir=/mnt/data --password-salt="$PASSWORD_SALT" --server-secret="$NEXTCLOUD_SECRET" --admin-pass="$ADMIN_PASSWORD"

    # Cleanup
    rm -r /tmp/nextcloud

    # Install my preferred apps
    ${occScript}/bin/nextcloud-occ app:enable bookmarks
    ${occScript}/bin/nextcloud-occ app:enable calendar
    ${occScript}/bin/nextcloud-occ app:enable contacts
    ${occScript}/bin/nextcloud-occ app:enable music
    ${occScript}/bin/nextcloud-occ app:enable server-info # Should already be enabled


    NC_PASS="$MONITORING_PASSWORD" ${occScript}/bin/nextcloud-occ user:add --group=admin --password-from-env monitoring # Should already be enabled

    # config.php has been overwritten, reverse that
    cp ${nextcloudConfig} /var/nextcloud/config/config.php
  '';

  occScript = pkgs.writers.writeBashBin "nextcloud-occ" ''
    set -e
    ${pkgs.util-linux}/bin/runuser -u ${user} -- ${php}/bin/php ${nextcloud}/occ $@
  '';
in
pkgs.dockerTools.buildImage {
  name = "nextcloud";

  runAsRoot = with pkgs; ''
    ${dockerTools.shadowSetup}
    groupadd -r ${group}
    useradd -r ${user} -g ${group} -d /var/lib/httpd
    mkdir -p /var/lib/httpd/logs
    chown -R ${user}:${group} /var/lib/httpd

    mkdir -p /var/run
    mkdir -p /var/nextcloud/apps
    mkdir -p ${nextcloudConfigPath}

    cp -r ${ncApps.bookmarks} /var/nextcloud/apps/bookmarks
    cp -r ${ncApps.calendar} /var/nextcloud/apps/calendar
    cp -r ${ncApps.contacts} /var/nextcloud/apps/contacts
    cp -r ${ncApps.music} /var/nextcloud/apps/music

    chown -R httpd:httpd /var/nextcloud
    chmod -R 0750 /var/nextcloud/
    chmod 0640 ${nextcloudConfigPath}/config.php
  '';

  contents = with pkgs; [

    (writeTextDir "var/nextcloud/config/config.php" nextcloudConfig)

    installScript
    occScript
  ];

  config = {
    Cmd = [
      "${entryPointScript}/bin/entrypoint.sh"
    ];
    Env = [
      "NEXTCLOUD_CONFIG_DIR=${nextcloudConfigPath}"
    ];
    ExposedPorts = {
      "8080/tcp" = { };
    };
  };
}
