# The container image for the NFS server Ganesha.
{ pkgs, ... }:
let
  configFile = pkgs.writers.writeText "ganesha.conf" ''
    NFS_CORE_PARAM {
      Protocols = 4,9P;
    }

    EXPORT
    {
      Export_Id = 1;
      Path = /mnt/bamilab;
      Pseudo = /;
      Access_Type = RW;
      Squash = root_squash;
      Sectype = krb5p;
      FSAL {
        Name = VFS;
      }
    }
    
    EXPORT
    {
      Export_Id = 1;
      Path = /mnt/shared;
      Pseudo = /;
      Access_Type = RW;
      Squash = root_squash;
      Sectype = krb5p;
      FSAL {
        Name = VFS;
      }
    }

    LOG {
      Default_Log_Level = INFO;

      Components {
        ALL {
          Destination = STDERR;
        }
      }
    }
  '';

  # The script that is being ran for the duration of the container
  entrypointScript = pkgs.writers.writeBashBin "entrypoint.sh" ''
    set -ex
    ${pkgs.nfs-ganesha}/bin/ganesha.nfsd -L /dev/stderr -x -F -f ${configFile}
  '';
in
pkgs.dockerTools.buildLayeredImage {
  name = "ganesha";
  
  fakeRootCommands = ''
    mkdir -p var/run/ganesha
  '';

  config = {
    Cmd = [
      "${entrypointScript}/bin/entrypoint.sh"
    ];
    ExposedPorts = {
      "2049/tcp" = { };
    };
  };
}
