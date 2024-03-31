# https://github.com/nix-community/disko/blob/master/example/btrfs-subvolumes.nix

{ disks ? [ "/dev/sda" ], ... }: {
  disk = {
    main = {
      device = builtins.elemAt disks 0;
      # device = lib.mkDefault "/dev/sda";
      # device = "/dev/sda";
      type = "disk";
      content = {
        type = "gpt";
        partitions = {
          boot = {
            name = "boot";
            size = "1M";
            type = "EF02"; # for grub MBR
          };
          esp = {
            name = "ESP";
            # start = "1M";
            size = "128M";
            type = "EF00";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
            };
          };
          root = {
            name = "root";
            size = "100%";
            content = {
              type = "btrfs";
              extraArgs = [ "-f" ]; # Override existing partition
              # Subvolumes must set a mountpoint in order to be mounted,
              # unless their parent is mounted
              subvolumes =
                let mountOptions = [ "compress=zstd" "noatime" "autodefrag" ];
                in {
                  # Subvolume name is different from mountpoint
                  "/root" = {
                    inherit mountOptions;
                    mountpoint = "/";
                  };
                  # Subvolume name is the same as the mountpoint
                  "/home" = {
                    inherit mountOptions;
                    mountpoint = "/home";
                  };
                  # Parent is not mounted so the mountpoint must be set
                  "/nix" = {
                    inherit mountOptions;
                    mountpoint = "/nix";
                  };
                  # Subvolume for the swapfile
                  "/swap" = {
                    mountOptions = [ "noatime" "nodatacow" ];
                    mountpoint = "/swap";
                  };
                };
              mountpoint = "/partition-root";
            };
          };
        };
      };
    };
  };
}
