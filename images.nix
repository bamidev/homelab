{ pkgs }:
let
  # All the packages that will be added to all container images to be able to inspect and manipulate
  # the containers.
  devpkgs = with pkgs; [
    bash
    coreutils
    gnugrep
    gnused
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
  images = pkgs.lib.attrsets.mapAttrsToList (name: _: name) (
    pkgs.lib.attrsets.filterAttrs (_: value: value == "directory") (builtins.readDir ./apps)
  );
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
