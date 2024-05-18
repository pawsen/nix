{ config, lib, pkgs, ... }:

with lib;
let
  # redirectFile = "${config.users.users.www.home}/public/_redirects.map";

  # https://nixos.org/manual/nixpkgs/stable/#trivial-builder-writeText
  nginxWebRoot = pkgs.writeTextDir "index.html" ''
    <html><body><h1>Hello from NGINX</h1></body></html>
  '';

  cfg = config.modules.nginx;
in {
  options.modules.nginx = {
    enable = mkEnableOption "Enable nginx";
    enableCloudflareSupport = mkOption {
      type = types.bool;
      default = false;
    };
    domain = mkOption {
      type = types.str;
      default = "127.0.0.1";
    };
  };

  config = mkIf cfg.enable (mkMerge [
    {
      security.acme = {
        acceptTerms = true;
        defaults.email = "pawsen+lecerts@gmail.com";
      };
      networking.firewall.allowedTCPPorts = [ 80 443 ];
      services.nginx = {
        enable = true;

        recommendedOptimisation = true;
        recommendedBrotliSettings = true;
        recommendedGzipSettings = true;
        recommendedZstdSettings = true;
        recommendedProxySettings = true;

        # Reduce the permitted size of client requests, to reduce the likelihood
        # of buffer overflow attacks. This can be tweaked on a per-vhost basis,
        # as needed.
        clientMaxBodySize = "256k"; # default 10m
        # Significantly speed up regex matchers
        appendConfig = "pcre_jit on;";
        commonHttpConfig = ''
          client_body_buffer_size  4k;       # default: 8k
          large_client_header_buffers 2 4k;  # default: 4 8k

          map $sent_http_content_type $expires {
              default                    off;
              text/html                  10m;
              text/css                   max;
              application/javascript     max;
              application/pdf            max;
              ~image/                    max;
          }

          log_format main '$remote_addr - $remote_user [$time_iso8601] '
                          '"$host" "$request" $status $body_bytes_sent $request_time '
                          '"$http_referer" "$http_user_agent"';
          access_log /var/log/nginx/access.log main;
        '';

        virtualHosts = {
          ${cfg.domain} = {

            # basicAuth = { test = "password"; };
            root = "${nginxWebRoot}";
            # root = "${config.users.users.www.home}/public";
            # root = "/var/lib/www/public";
            locations."= /" = {
              # extraConfig = ''
              #   if ($redirectedUri) {
              #     return 301 $redirectedUri;
              #   }
              # '';
              #
            };
          };
          "calibre.${cfg.domain}" = {
            addSSL = true;
            enableACME = true;
            basicAuth = { "paw" = "velkommen"; };
            locations."/" = {
              proxyPass = "http://127.0.0.1:8585";
              extraConfig = ''
                # for uploading large books
                client_max_body_size 20M;
              '';
            };
          };
          # transmission
          # "get.${cfg.domain}" = {
          #   addSSL = true;
          #   enableACME = true;
          #   # basicAuthFile = config.age.secrets.nginx-auth.path;
          #   basicAuth = { "paw" = "velkommen"; };

          #   locations."/" = {
          #     proxyPass = "http://127.0.0.1:9091";
          #     proxyWebsockets = true;
          #   };
          # };
          "get2.${cfg.domain}" = {
            addSSL = true;
            enableACME = true;
            basicAuthFile = config.age.secrets.nginx-auth2.path;

            locations."/" = {
              proxyPass = "http://127.0.0.1:9091";
              proxyWebsockets = true;
            };
          };
          "copy.${cfg.domain}" = {
            addSSL = true;
            enableACME = true;
            # basicAuthFile = config.age.secrets.nginx-auth.path;
            basicAuth = { "paw" = "velkommen"; };
            root = "/var/lib/syncthing/var";
            locations."/".extraConfig = "autoindex on;";
          };

          "copy2.${cfg.domain}" = {
            # addSSL = true;
            # enableACME = true;
            # basicAuthFile = config.age.secrets.nginx-auth.path;
            basicAuth = { "paw" = "velkommen"; };
            root = "/var/lib/test2/var";
            locations."/".extraConfig = "autoindex on;";
          };
          # https://docs.syncthing.net/users/reverseproxy.html#nginx
          "syncthing.${cfg.domain}" = {
            addSSL = true;
            enableACME = true;
            basicAuth = { "paw" = "velkommen"; };
            locations."/" = { proxyPass = "http://127.0.0.1:8384"; };
          };

          # "me.pawsen.net" = {
          #   locations."/" = {

          #     # proxyWebsockets = true;
          #     proxyPass = "http://127.0.0.1:80"; };
          # };

          # "pawsen.me" = {
          #   locations."/" = {
          #     return = "307 https://www.alexghr.me$request_uri";
          #   };
          # };
          # "plausible.pawsen.me" = {
          #   locations."/" = {
          #     proxyPass = "http://127.0.0.1:8000";
          #   };
          # };
          # "www.pawsen.me" = {
          #   locations."/" = {
          #     proxyPass = "http://127.0.0.1:8001";
          #   };
          # };
          # "attic.pawsen.me" = {
          #   locations."/" = {
          #     proxyPass = "http://127.0.0.1:8002";
          #     extraConfig = ''
          #       client_max_body_size 100M;
          #       proxy_set_header Host $host;
          #     '';
          #   };
          # };
        };
      };
    }

    (lib.mkIf cfg.enableCloudflareSupport {
      services.nginx.commonHttpConfig = ''
        ${concatMapStrings (ip: ''
          set_real_ip_from ${ip};
        '') (filter (line: line != "") (splitString "\n" ''
          ${readFile (fetchurl "https://www.cloudflare.com/ips-v4/")}
          ${readFile (fetchurl "https://www.cloudflare.com/ips-v6/")}
        ''))}
        real_ip_header CF-Connecting-IP;
      '';
    })

  ]);
}
