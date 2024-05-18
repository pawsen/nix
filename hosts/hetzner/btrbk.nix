{ config, lib, pkgs, ... }:

with lib;

let cfg = config.modules.btrbk-host;
in {
  options.modules.btrbk-host = {
    enable = mkEnableOption "Enable btrbk host for btrfs backups";
  };

  config = mkIf cfg.enable {

    # https://nixos.wiki/wiki/Btrbk
    users.users."btrbk" = {
      # for ssh login, it seems the user needs to be a normal user.
      # Not sure that's correct, though.
      # isSystemUser = true;
      isNormalUser = true;
      group = "btrbk";
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPpF6gB2Z8CImJc3EdMlu7xyB4hwMzUxo+inccPbuvHV"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIItf4/8x62RgH7esL8cE6u7dGA2/v5veVJqXKjpF02Er backup@pawsen.net"
      ];
    };
    # same as nogroup
    users.groups.btrbk = { };

    security.sudo = {
      enable = true;
      extraRules = [{
        commands = [
          {
            command = "${pkgs.coreutils-full}/bin/test";
            options = [ "NOPASSWD" ];
          }
          {
            command = "${pkgs.coreutils-full}/bin/readlink";
            options = [ "NOPASSWD" ];
          }
          {
            command = "${pkgs.btrfs-progs}/bin/btrfs";
            options = [ "NOPASSWD" ];
          }
        ];
        users = [ "btrbk" ];
      }];
      extraConfig = with pkgs; ''
        Defaults:picloud secure_path="${
          lib.makeBinPath [ btrfs-progs coreutils-full ]
        }:/nix/var/nix/profiles/default/bin:/run/current-system/sw/bin"
      '';
    };

    # Note: Before the release of NixOS 24.05 you'll have to add the corresponding compression tool manually
    environment.systemPackages = [ pkgs.lz4 ];
  };
}
