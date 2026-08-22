# The container image for Grafana.
{ pkgs, ... }:
let
  openldapConfig = pkgs.writers.writeText "slapd.ldif" ''
    # 1. First, establish the configuration root
    dn: cn=config
    objectClass: olcGlobal
    cn: config

    # 2. Define the configuration database itself
    dn: olcDatabase=config,cn=config
    objectClass: olcDatabaseConfig
    olcDatabase: config

    dn: olcDatabase=mdb,cn=config
    objectClass: olcDatabaseConfig
    objectClass: olcMdbConfig
    olcDatabase: mdb
    OlcDbMaxSize: 1073741824
    olcSuffix: dc=service,dc=openldap,dc=svc,dc=cluster,dc=local
    olcRootDN: cn=Manager,dc=service,dc=openldap,dc=svc,dc=cluster,dc=local
    olcRootPW: secret
    olcDbDirectory: /mnt
    olcDbIndex: objectClass eq
  '';

  entrypointScript = pkgs.writers.writeBashBin "entrypoint.sh" ''
    set -ex
    DB_PATH=/usr/local/etc/slap.d

    ${pkgs.openldap}/bin/slapadd -n 0 -F "$DB_PATH" -l ${openldapConfig}
    ${pkgs.openldap}/libexec/slapd -d conns,filter,config,ACL,stats,shell,sync -F "$DB_PATH"
  '';
in
pkgs.dockerTools.buildLayeredImage {
  name = "openldap";

  fakeRootCommands = ''
    mkdir -p mnt usr/local/etc/slap.d
  '';

  config = {
    Cmd = [
      "${entrypointScript}/bin/entrypoint.sh"
    ];
    ExposedPorts = {
      "8080/tcp" = { };
    };
  };
}
