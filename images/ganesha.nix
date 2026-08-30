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
      Pseudo = /bamilab;
      Access_Type = RW;
      Squash = root_squash;
      SecType = sys;
      # TODO: Sectype = krb5p;
      FSAL {
        Name = VFS;
      }
    }
    
    EXPORT
    {
      Export_Id = 2;
      Path = /mnt/shared;
      Pseudo = /shared;
      Access_Type = RW;
      Squash = root_squash;
      SecType = sys;
      # TODO: Sectype = krb5p;
      FSAL {
        Name = VFS;
      }
    }

    LOG {
      Default_Log_Level = INFO;
    }
  '';

  # The script that is being ran for the duration of the container
  entrypointScript = pkgs.writers.writeBashBin "entrypoint.sh" ''
    set -x

    # Create folders if they don't exist yet
    mkdir -p /mnt/bamilab
    mkdir -p /mnt/shared

    ${pkgs.nfs-ganesha}/bin/ganesha.nfsd -L /dev/stderr -x -F -f ${configFile}

    sleep 3600
  '';
in
pkgs.dockerTools.buildLayeredImage {
  name = "ganesha";

  fakeRootCommands = ''
    mkdir -p etc tmp var/run/ganesha var/lib/nfs/ganesha
    ln -s /proc/mounts etc/mtab
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
