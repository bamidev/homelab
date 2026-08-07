# The container image for Owncast.
{ pkgs, ... }:
let
  # The script that is being ran for the duration of the container
  entrypointScript = pkgs.writers.writeBashBin "entrypoint" ''
    set -ex
    ${pkgs.owncast}/bin/owncast -webserverport 8080 -adminpassword $ADMIN_PASSWORD
  '';
in
pkgs.dockerTools.buildLayeredImage {
  name = "owncast";

  config = {
    Cmd = [
      "${entrypointScript}/bin/entrypoint"
    ];
    ExposedPorts = {
      "8080/tcp" = { };
    };
  };
}
