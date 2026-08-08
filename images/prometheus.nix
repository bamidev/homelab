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
          - targets: ["localhost:9090"]

      # Nextcloud application metrics
      - job_name: "nextcloud"
        scrape_interval: 60s         # Nextcloud API can be slow; use longer interval
        scrape_timeout: 30s
        static_configs:
          - targets: ["localhost:6398"]
            labels:
              instance: "nextcloud-production"
  '';
in
pkgs.dockerTools.buildLayeredImage {
  name = "prometheus";

  config = {
    Cmd = [
      "${pkgs.prometheus}/bin/prometheus"
      "--config.file=${prometheusConfig}"
    ];
    ExposedPorts = {
      "8080/tcp" = { };
    };
  };
}
