# The container image for Grafana.
{ pkgs, ... }:
let
  grafanaConfig = pkgs.writers.writeText "grafana.ini" ''
    instance_name = grafana

    [security]
    admin_user = admin

    [paths]
    logs = /dev/stderr

    [server]
    http_port = 8080

    [database]
    type = postgres
    host = production-database-rw
    name = grafana
    user = grafana
    password = ''${POSTGRES_PASSWORD}
  '';
in
pkgs.dockerTools.buildLayeredImage {
  name = "grafana";

  config = {
    Cmd = [
      "${pkgs.grafana}/bin/grafana"
      "server"
      "--config"
      "${grafanaConfig}"
      "--homepath"
      "${pkgs.grafana}/share/grafana"
    ];
    ExposedPorts = {
      "8080/tcp" = { };
    };
  };
}
