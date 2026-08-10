# The container image for Prometheus.
{ pkgs, ... }:
let
  prometheusConfig = pkgs.writers.writeText "prometheus.yaml" ''
    global:
      scrape_interval: 60s
      evaluation_interval: 60s
      scrape_timeout: 15s

      external_labels:
        environment: production
        service: nextcloud

    scrape_configs:
      # Prometheus self-monitoring
      - job_name: "prometheus"
        static_configs:
          - targets: ["localhost:8080"]

      # Nextcloud application metrics
      - job_name: "nextcloud"
        scrape_interval: 60s
        scrape_timeout: 30s
        static_configs:
          - targets: ["service.nextcloud.svc.cluster.local:6399"]
            labels:
              instance: "nextcloud-production"

      # All node metrics
      - job_name: "node-old-laptop-msi"
        static_configs:
          - targets: ["192.168.0.123:9100"]
            labels:
              instance: "node-old-laptop-msi"
      - job_name: "node-old-laptop-asus"
        static_configs:
          - targets: ["192.168.0.134:9100"]
            labels:
              instance: "node-old-laptop-asus"
      - job_name: "node-thinkcentre"
        static_configs:
          - targets: ["192.168.0.148:9100"]
            labels:
              instance: "node-thinkcentre"
      # TODO: Configure the domain names in the nixos-config repo, and us them here somehow.
      #       Maybe it can be done by importing the flake, and then utilizing the options in config.nix
  '';

  entrypointScript = pkgs.writers.writeBashBin "entrypoint.sh" ''
    set -ex
    ${pkgs.prometheus}/bin/prometheus \
      --config.file=${prometheusConfig} \
      --storage.tsdb.path=/mnt \
      --storage.tsdb.retention.time=90d \
      --web.listen-address=:8080
  '';
in
pkgs.dockerTools.buildLayeredImage {
  name = "prometheus";

  config = {
    Cmd = [
      "${pkgs.flock}/bin/flock"
      "--verbose"
      "-n"
      "/mnt"
      "${entrypointScript}/bin/entrypoint.sh"
    ];
    ExposedPorts = {
      "8080/tcp" = { };
    };
  };
}
