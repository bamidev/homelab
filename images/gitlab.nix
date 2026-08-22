# The container image for Gitlab.
# 
{ pkgs, ... }:
let
  gitlabBundix = pkgs.stdenv.mkDerivation {
    name = "gitlab-bundix";
    src = pkgs.gitlab;

    nativeBuildInputs = with pkgs; [
      bundix
    ];

    buildPhase = ''
      export HOME="$TMPDIR/home"
      (
        cd $src/share/gitlab
        bundix
      ) 
    '';
  };

  gitlabGems = pkgs.bundlerEnv {
    name = "gitlab-gems";
    ruby = pkgs.ruby;
    gemdir = ./gitlab/.;
  };

  gitlab = pkgs.stdenv.mkDerivation rec {
    pname = "gitlab";
    version = src.version;

    src = pkgs.gitlab;

    nativeBuildInputs = [
      gitlabGems
    ];

    buildPhase = ''
      export HOME="$TMPDIR/home"
      #bundle config set --local path "$out/share/gitlab/vendor/bundle"
      #bundle config set --local deployment true

      (
        cd $src/share/gitlab
        bundle check --verbose
      )
    '';
  };

  # The script that is being ran for the duration of the container
  entrypointScript = pkgs.writers.writeBashBin "entrypoint.sh" ''
    set -ex
    ${gitlab}/bin/gitlab
  '';
in
pkgs.dockerTools.buildImage {
  name = "gitlab";

    #diskSize = 8192;

    #runAsRoot = with pkgs; ''
    #  cp -r ${gitlab}/share/gitlab /tmp
    #  cd /tmp/gitlab
    #  ${bundler}/bin/bundle install
    #'';

  config = {
    Cmd = [
      "${entrypointScript}/bin/entrypoint.sh"
    ];
    ExposedPorts = {
      "8080/tcp" = { };
    };
  };
}
