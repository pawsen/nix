let
  pawSSHKeys = [
    "ssh-ed25519
  AAAAC3NzaC1lZDI1NTE5AAAAIPpF6gB2Z8CImJc3EdMlu7xyB4hwMzUxo+inccPbuvHV paw@lion"
  ];
  tigerHostKey =
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILaNPaT6E+/26+O9FXE/r9NY733R2qih/HzOlybCuT6k";
  hetznerHostKey =
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGMGuXCcUtBZmwfNVX99zG01uqnaXJFndNwePt3uMGLi";
in {
  "tiger.tailscale.age".publicKeys = agSshKeys ++ [ palpatineHostKey ];
  "hetzner.tailscale.age".publicKeys = pawSSHKeys ++ [ hetznerHostKey ];
  "vader.restic-b2-password.age".publicKeys = agSshKeys;
  "palpatine.tailscale.age".publicKeys = agSshKeys ++ [ palpatineHostKey ];
  "hk47.tailscale.age".publicKeys = agSshKeys ++ [ hk47HostKey ];
  "hk47.vader-mac.age".publicKeys = agSshKeys ++ [ hk47HostKey r5d4HostKey ];
  "ag.npmrc.age".publicKeys = agSshKeys ++ [ mackeyHostKey palpatineHostKey ];
  "plausible.admin.password.age".publicKeys = agSshKeys
    ++ [ implausibleHostKey b1HostKey ];
  "plausible.keybase.age".publicKeys = agSshKeys
    ++ [ implausibleHostKey b1HostKey ];
  "webby.ghcr.age".publicKeys = agSshKeys ++ [ webbyHostKey b1HostKey ];
  "ghcr.age".publicKeys = agSshKeys ++ [ b1HostKey ];
  "attic.env.age".publicKeys = agSshKeys ++ [ b1HostKey ];
  "hetzner.tailscale.age".publicKeys = pawSSHKeys ++ [ hetznerHostKey ];
  "r5d4.tailscale.age".publicKeys = agSshKeys ++ [ r5d4HostKey ];
}
