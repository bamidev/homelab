# The container image for Grafana.
{ pkgs, ... }:
let
  grafanaConfig = pkgs.writers.writeText "grafana.ini" ''
    instance_name = grafana

    # Enable anonymous authentication to allow for externally shared dashboards
    [auth.anonymous]
    enabled = true
    hide_version = true
    org_name = Anonymous
    org_role = Viewer

    [security]
    admin_user = admin

    [paths]
    logs = /dev/stderr

    [server]
    domain = 172.0.0.11:30002
    http_port = 8080
    root_url = http://%(domain)s/

    [database]
    type = postgres
    host = database-rw
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
