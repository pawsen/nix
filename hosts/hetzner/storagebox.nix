{ config, lib, pkgs, ... }:

# check status
# systemctl status mnt-share.mount
with lib;
let cfg = config.modules.storagebox;

in {
  options.modules.storagebox = {
    enable = mkEnableOption "Mount hetzner storagebox";
    mount_dir = mkOption {
      description = "Where to locally mount the storagebox";
      type = types.str;
      default = "/mnt/share";
    };
    user = mkOption {
      description = "username for device, ie //user.your-storagebox.de/backup";
      type = types.str;
    };
    auth_file = mkOption {
      description = "Path to the file containing the authentication key";
      type = types.str;
    };
  };

  config = mkIf cfg.enable {
    # For mount.cifs, required unless domain name resolution is not needed.
    environment.systemPackages = [ pkgs.cifs-utils ];
    fileSystems."${cfg.mount_dir}" = {
      device = "//${cfg.user}.your-storagebox.de/backup";
      fsType = "cifs";
      options = let
        # noauto: don't mount automatically at boot or with mount -a
        # x-systemd.automount: only mount upon access,
        # x-systemd.automount,noauto,
        automount_opts =
          "rw";
          # "x-systemd.idle-timeout=60,x-systemd.device-timeout=5s,x-systemd.mount-timeout=5s";
        # set dir and file-mode so all users can create files on the share.
        # Otherwise only the uid,gid(if not set, as here, defaults to root), can
        # write and create folders at runtime
        # This of cource
        sharing_opts = "iocharset=utf8,file_mode=0777,dir_mode=0777,noperm";
      in [
        # seal for encrypted traffic. Requires at least SMB 3.0
        "${automount_opts},${sharing_opts},seal,credentials=${cfg.auth_file}"
      ];
    };
  };
}
