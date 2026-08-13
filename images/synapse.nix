# The container image for Synapse, the matrix server of Element.
{ pkgs, ... }:
let
  configFile = pkgs.writers.writeText "homeserver.yaml" ''
    database:
      name: psycopg2
      args:
        user: synapse
        password: POSTGRES_PASSWORD
        dbname: synapse
        host: production-database-rw
        port: 5432

    enable_metrics: true
      
    listeners:
      - port: 8080
        type: http
        tls: false
        resources:
          - names: [client, federation]
      - port: 9100
        type: metrics
        tls: false

    media_store_path: /mnt/media

    report_stats: false

    server_name: matrix.bamilab.space

    signing_key_path: /mnt/key/matrix.bamilab.space.signing.key
  '';

  # The script that is being ran for the duration of the container
  entrypointScript = pkgs.writers.writeBashBin "entrypoint.sh" ''
    set -ex
    mkdir -p /mnt/{data,keys}

    # Set up the config file by rewriting the secrets into it
    cp "${configFile}" /etc/homeserver.yaml
    sed -i "s/POSTGRES_PASSWORD/$POSTGRES_PASSWORD/g" /etc/homeserver.yaml

    ${pkgs.matrix-synapse}/bin/synapse_homeserver \
      -c ${configFile} \
      -c /etc/homeserver.yaml
  '';
in
pkgs.dockerTools.buildLayeredImage {
  name = "synapse";

  fakeRootCommands = ''
    mkdir -p mnt/{media,key}
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
