{ config, pkgs, lib, ... }:

# The default package for the transmission service is pkgs.transmission, which
# comes without Qt and GTK3 by default.
# https://github.com/NixOS/nixpkgs/blob/master/pkgs/applications/networking/p2p/transmission/default.nix

# create the settings.json with the rpc password and your username
# {
#     "rpc-password": "{e6884270b235d215848637e9108851a45897e91200E/KarJ",
#     "rpc-username": "username"
# }

let
  peerPort = 50023;
in {
  services.transmission = {
    enable = true;
    openPeerPorts = true;
    openRPCPort = true;
    home = "/var/lib/transmission";
    # credentialsFile = "/var/lib/secrets/transmission/settings.json";
    # package = pkgs.transgui;
    settings = {
      /* directory settings */
      watch-dir-enabled = true;
      incomplete-dir-enabled = true;
      # watch-dir = "/var/lib/transmission/watch-dir";
      # download-dir = "/var/lib/transmission/downloads";
      # incomplete-dir = "/var/lib/transmission/.incomplete";

      /* web interface, accessible from local network */
      rpc-enabled = true;
      rpc-bind-address = "0.0.0.0";
      rpc-whitelist = "127.0.0.1";
      # rpc-host-whitelist = "void,192.168.*.*";
      # rpc-host-whitelist-enabled = true;

      port-forwarding-enabled = true;
      peer-port = peerPort;
      peer-port-random-on-start = false;

      encryption = 1;
      lpd-enabled = true; /* local peer discovery */
      dht-enabled = true; /* dht peer discovery in swarm */
      pex-enabled = true; /* peer exchange */

      /* ip blocklist */
      blocklist-enabled = true;
      blocklist-updates-enabled = true;
      blocklist-url = "https://github.com/sahsu/transmission-blocklist/releases/latest/download/blocklist.gz";
      # "blocklist-url" = "http://john.bitsurge.net/public/biglist.p2p.gz";
      /* taken from here: https://giuliomac.wordpress.com/2014/02/19/best-blocklist-for-transmission/ */

      /* download speed settings */
      speed-limit-down = 1200;
      speed-limit-down-enabled = false;
      speed-limit-up = 500;
      speed-limit-up-enabled = true;

      /* seeding limit */
      ratio-limit = 10;
      ratio-limit-enabled = true;
    };
  };
}
