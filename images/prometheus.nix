# The container image for Prometheus.
{ pkgs, ... }:
let
  prometheusConfig = pkgs.writers.writeText "prometheus.yaml" ''
    global:
      scrape_interval: 60s          # How often to scrape targets
      evaluation_interval: 60s      # How often to evaluate alerting rules
      scrape_timeout: 15s           # Timeout for each scrape request

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
        scrape_interval: 60s         # Nextcloud API can be slow; use longer interval
        scrape_timeout: 30s
        static_configs:
          - targets: ["service.nextcloud.svc.cluster.local:6399"]
            labels:
              instance: "nextcloud-production"

      # Node Exporter for OS-level metrics
      - job_name: "node"
        static_configs:
          - targets: ["127.0.0.1:9100"]
            labels:
              instance: "local-node"
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
