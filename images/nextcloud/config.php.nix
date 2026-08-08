{ nextcloud }: ''
  <?php
  $CONFIG = [
    // General
    'instanceid' => 'ocweuq5tkc76',
    'passwordsalt' => 'PASSWORD_SALT',
    'secret' => 'NEXTCLOUD_SECRET',
    'trusted_domains' => [
      'service.nextcloud.svc.cluster.local',
      'nextcloud.kubes',
      '192.168.0.77',
      '172.0.0.11',
    ],
    'trusted_proxies' => [
      '10.0.0.0/8',
      '172.0.0.0/24',
    ],
    'overwrite.cli.url' => 'http://localhost',
    'datadirectory' => '/mnt/data',
    'version' => '${nextcloud.version}.1',

    // Database
    'dbtype' => 'pgsql',
    'dbhost' => 'production-database-rw',
    'dbname' => 'nextcloud',
    'dbuser' => 'nextcloud',
    'dbpassword' => 'POSTGRES_PASSWORD',
    'dbtableprefix' => 'oc_',
    'installed' => true,

    'default_language' => 'en',
    'default_timezone' => 'Europe/Amsterdam',
    'allow_user_to_change_display_name' => true,
    'skeletondirectory' => '/mnt/core/skeleton',

    'apps_paths' => [
      [
        'path' => '${nextcloud}/apps',
        'url' => '/coreapps',
        'writable' => false,
      ],
      [
        'path' => '/var/nextcloud/apps',
        'url' => '/apps',
        'writable' => false,
      ],
    ],

    'log_type' => 'file',
    'logfile' => '/dev/stderr',
    'loglevel' => 1,
    'loglevel_frontend' => 1,
    'loglevel_dirty_database_queries' => 0,
  ];
''
