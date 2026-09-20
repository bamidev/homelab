# The container image for the Hiddenite music player server
{ pkgs, ... }:
let
  configFile = pkgs.writers.writeText "config.yaml" ''
    database:
      path: /mnt/.library.sqlite

    library:
      paths:
        - /mnt

    server:
      port: 8080
      baseUrls:
        - http://192.168.0.77:30008
        - http://hiddenite.bamilab.space
        - http://hiddenite.local.bamilab.space
  '';

  # The script that is being ran for the duration of the container
  entrypointScript = pkgs.writers.writeBashBin "entrypoint.sh" (with pkgs; ''
    set -ex
    ${git}/bin/git clone https://github.com/bamidev/hiddenite /tmp/hiddenite
    ${nix}/bin/nix --extra-experimental-features 'nix-command flakes' develop /tmp/hiddenite -c npm --prefix /tmp/hiddenite/common install
    ${nix}/bin/nix --extra-experimental-features 'nix-command flakes' develop /tmp/hiddenite -c npm --prefix /tmp/hiddenite/common run build
    ${nix}/bin/nix --extra-experimental-features 'nix-command flakes' develop /tmp/hiddenite -c npm --prefix /tmp/hiddenite/server install
    ${nix}/bin/nix --extra-experimental-features 'nix-command flakes' develop /tmp/hiddenite -c npm --prefix /tmp/hiddenite/server run start
  '');
in
pkgs.dockerTools.buildLayeredImage {
  name = "hiddenite";

  fakeRootCommands = ''
    mkdir -p usr/bin
    ln -s ${pkgs.coreutils}/bin/env usr/bin/env
  '';

  config = {
    Cmd = [
      "${entrypointScript}/bin/entrypoint.sh"
    ];
    ExposedPorts = {
      "8080/tcp" = { };
    };
    Env = [
      "SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
      "GIT_SSL_CAINFO=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
      "HOME=/root"
      "NIX_CONFIG=build-users-group ="
    ];
  };

  contents = with pkgs; [
    cacert
  ];
}
