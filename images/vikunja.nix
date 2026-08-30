# The container image for the Vikunja server.
{ pkgs, ... }:
let
  configFile = pkgs.writers.writeText "config.yaml" ''
    database:
      type: "postgres"
      user: "vikunja"
      host: "production-database-rw"
      password:
        file: /var/vikunja/secrets/database-password

    files:
      basepath: /mnt

    metrics:
      enabled: true

    service:
      publicurl: http://vikunja.bamilab.space
  '';

  # The script that is being ran for the duration of the container
  entrypointScript = pkgs.writers.writeBashBin "entrypoint.sh" ''
    set -ex
    echo $POSTGRES_PASSWORD > /var/vikunja/secrets/database-password
    ln -s ${configFile} /etc/vikunja/config.yaml
    ${pkgs.vikunja}/bin/vikunja web
  '';
in
pkgs.dockerTools.buildLayeredImage {
  name = "vikunja";

  fakeRootCommands = ''
    mkdir -p etc/vikunja
    mkdir -p var/vikunja/secrets
  '';

  config = {
    Cmd = [
      "${entrypointScript}/bin/entrypoint.sh"
    ];
    ExposedPorts = {
      "3456/tcp" = { };
    };
  };
}
