# nix run github:numtide/nixos-anywhere -- --flake .#hetzner root@<ip>
# Additional info about the machine can be found at
# https://wiki.gentoo.org/wiki/Hetzner_Cloud_(ARM64)
#
# if source is not able to build derivations for target, use --build-on-remote
# nix run github:nix-community/nixos-anywhere -- --debug --flake .#hetzner root@65.21.53.22
# nixos-rebuild switch --flake .#hetzner --build-host root@65.21.53.22  --target-host root@65.21.53.22
# or without nixos-rebuild
# nix build .#nixosConfigurations.test.config.system.build.vm
# nixos-rebuild build-vm  --flake .#hetzner
{ config, pkgs, lib, modulesPath, ... }: {
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    (modulesPath + "/profiles/qemu-guest.nix")
    ./nginx.nix
    ./transmission.nix
  ];

  system.stateVersion = "23.11";

  disko.devices = import ./disk-configuration.nix { inherit lib; };

  services.btrfs.autoScrub = {
    enable = true;
    fileSystems = [ "/" ];
    interval = "weekly";
  };

  swapDevices = [{
    device = "/swap/swapfile";
    size = 2048;
  }];

  boot = {
    supportedFilesystems = [ "btrfs" ];

    # Hetzner cloud supports UEFI / atleast for arm64
    loader.grub = {
      # no need to set devices, disko will add all devices that have a EF02 partition to the list
      # devices = [ ];
      efiSupport = true;
      efiInstallAsRemovable = true;
    };
    # https://nixos.wiki/wiki/Install_NixOS_on_Hetzner_Cloud#AArch64_.28CAX_instance_type.29_specifics
    initrd.kernelModules = [ "virtio_gpu" ];
    kernelParams = [ "console=tty" ];
  };

  networking = {
    hostName = "hetzner";
    firewall = {
      enable = true;
      allowedTCPPorts = [ 80 ];
    };
  };

  nix = {
    package = pkgs.nixVersions.nix_2_16;
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
  };

  environment.systemPackages = with pkgs; [ git vim ];

  users = {
    # groups.plausible = {};
    users = {
      root.openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPpF6gB2Z8CImJc3EdMlu7xyB4hwMzUxo+inccPbuvHV"
      ];
    };
  };

  age.secrets = {
    # attic-env.file = ../../secrets/attic.env.age;
    tailscale.file = ../../secrets/hetzner.tailscale.age;
  };

  # virtualisation = {
  #   oci-containers = {
  #     backend = "podman";
  #     containers = {
  #       alexghr = {
  #         image = "ghcr.io/alexghr/www";
  #         login = {
  #           username = "alexghr";
  #           passwordFile = config.age.secrets.ghcr.path;
  #           registry = "ghcr.io";
  #         };
  #         ports = [
  #           "8001:80"
  #         ];
  #       };
  #       yaacc = {
  #         image = "ghcr.io/alexghr/yaacc";
  #         login = {
  #           username = "alexghr";
  #           passwordFile = config.age.secrets.ghcr.path;
  #           registry = "ghcr.io";
  #         };
  #         ports = [
  #           "8003:3000"
  #         ];
  #       };
  #     };
  #   };
  # };

  services = {
    openssh = {
      enable = true;
      settings = {
        PermitRootLogin = "yes";
        PasswordAuthentication = false;
      };
    };

    # this comes with SSH jail by default
    fail2ban.enable = true;

    # postgresql = {
    #   enable = true;
    #   package = pkgs.postgresql_16;
    #   enableTCPIP = false;
    # };

    # atticd = {
    #   enable = true;

    #   credentialsFile = config.age.secrets.attic-env.path;

    #   settings = {
    #     listen = "[::]:8002";
    #     allowed-hosts = [
    #       "attic.pawsen.me"
    #     ];
    #     api-endpoint = "https://attic.pawsen.me/";

    #     database.url = "postgresql:///atticd?host=/run/postgresql&user=atticd";

    #     storage = {
    #       type = "local";
    #       path = "/var/lib/atticd/storage";
    #     };

    #     # basic chunking
    #     # taken from official docs
    #     # https://docs.attic.rs/admin-guide/deployment/nixos.html#configuration
    #     chunking = {
    #       nar-size-threshold = 64 * 1024; # 64 KiB
    #       min-size = 16 * 1024; # 16 KiB
    #       avg-size = 64 * 1024; # 64 KiB
    #       max-size = 256 * 1024; # 256 KiB
    #     };
    #   };
    # };
  };

  # systemd.services = {
  #   atticd-postgres = {
  #     after = [ "postgresql.service" ];
  #     partOf = [ "atticd.service" ];
  #     serviceConfig = {
  #       Type = "oneshot";
  #       User = config.services.postgresql.superUser;
  #       RemainAfterExit = true;
  #     };
  #     script = ''
  #       PSQL() {
  #         ${config.services.postgresql.package}/bin/psql --port=5432 "$@"
  #       }
  #       # check if the database already exists
  #       if ! PSQL -lqt | ${pkgs.coreutils}/bin/cut -d \| -f 1 | ${pkgs.gnugrep}/bin/grep -qw atticd ; then
  #         PSQL -tAc "CREATE ROLE atticd WITH LOGIN;"
  #         PSQL -tAc "CREATE DATABASE atticd WITH OWNER atticd;"
  #       fi
  #     '';
  #     };

  #     atticd.after = [ "atticd-postgres.service" ];
  # };

  alexghr.tailscale = {
    enable = true;
    authKeyFile = config.age.secrets.tailscale.path;
    exitNode = true;
  };
}
