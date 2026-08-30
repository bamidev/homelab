{ pkgs }:
let
  # Generate a new gemset.nix file for gitlab
  gitlabGenerateGemsetScript = pkgs.writers.writeBashBin "gitlab-generate-gemset" ''
    ${pkgs.bundix}/bin/bundix --gemfile=${pkgs.gitlab}/share/gitlab/Gemfile --lockfile=${pkgs.gitlab}/share/gitlab/Gemfile.lock
    echo gemset.nix file created in current directory.
  '';
in
pkgs.mkShell {
  packages = [ gitlabGenerateGemsetScript ];
}
