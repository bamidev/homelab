{ pkgs }:
let
  # All the packages that will be added to all container images to be able to inspect and manipulate
  # the containers.
  devpkgs = with pkgs; [
    bash
    coreutils
    gnugrep
    nano
    ps
    su
  ];
  extendImage = (
    baseImage:
    baseImage.override (oldArgs: {
      contents = (oldArgs.contents or [ ]) ++ devpkgs;
    })
  );

  # All the available images
  images = [
    "grafana"
    "nextcloud"
    "owncast"
    "stonenet-site"
  ];
in
builtins.listToAttrs (
  map (name: {
    name = name;
    value = extendImage (
      import ./images/${name}.nix {
        inherit pkgs;
      }
    );
  }) images
)
