{ config, lib, pkgs, ... }:

{
  # if storagebox is enabled, do a bind mount to where data is stored
  fileSystems."/var/lib/syncthing" = lib.mkIf config.modules.storagebox.enable {
    device = "/mnt/share/syncthing";
    options = [ "bind" ];
  };

  services.syncthing = {
    enable = true;
    openDefaultPorts = true;
    # dataDir = "/var/lib/syncthing/var/";
    # configDir = "/var/lib/syncthing/.config/";
    # dataDir = "${config.users.users.syncthing.home}/var/";
    # configDir = "${config.users.users.syncthing.home}/.config/";

    # use the nginx user instead of the default syncthing. This allows nginx to
    # index the files, like a poor mans ftp.
    # XXX this is not needed when data is stored on the storagebox. It's mounted
    # as a CIFS/samba and there are no real access control. Thus all folders are
    # created as 0777 and files 0666.
    # user = "nginx";
    # group = "nginx";
    guiAddress = "0.0.0.0:8384";
  };

}
