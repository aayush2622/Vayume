{
  flake.nixosModules.Network =
    { pkgs, lib, config, ... }:
    let
      cfg = config.vayori.network;

      ipt = "${pkgs.iptables}/bin/iptables";
      ipt6 = "${pkgs.iptables}/bin/ip6tables";

      # Every resolver here is quoted with its DoT hostname, because
      # systemd-resolved needs one to validate the certificate - without
      # it, dnsovertls silently degrades to an unauthenticated tunnel.
      dnsProviders = {
        cloudflare = {
          hostname = "one.one.one.one";
          v4 = [ "1.1.1.1" "1.0.0.1" ];
          v6 = [ "2606:4700:4700::1111" "2606:4700:4700::1001" ];
        };
        quad9 = {
          hostname = "dns.quad9.net";
          v4 = [ "9.9.9.9" "149.112.112.112" ];
          v6 = [ "2620:fe::fe" "2620:fe::9" ];
        };
        mullvad = {
          hostname = "dns.mullvad.net";
          v4 = [ "194.242.2.2" ];
          v6 = [ "2a07:e340::2" ];
        };
        adguard = {
          hostname = "dns.adguard-dns.com";
          v4 = [ "94.140.14.14" "94.140.15.15" ];
          v6 = [ "2a10:50c0::ad1:ff" "2a10:50c0::ad2:ff" ];
        };
        google = {
          hostname = "dns.google";
          v4 = [ "8.8.8.8" "8.8.4.4" ];
          v6 = [ "2001:4860:4860::8888" "2001:4860:4860::8844" ];
        };
      };

      chosen = dnsProviders.${cfg.dns.provider};
      withHost = addrs: map (a: "${a}#${chosen.hostname}") addrs;
      resolvers = withHost (chosen.v4 ++ lib.optionals cfg.dns.ipv6 chosen.v6);

      # Traffic that must never be redirected into Tor: loopback (where
      # resolved and Tor's own ports live) and every private range, so
      # the LAN and container bridges keep working.
      directNets = [
        "127.0.0.0/8"
        "10.0.0.0/8"
        "172.16.0.0/12"
        "192.168.0.0/16"
        "169.254.0.0/16"
      ];

      returnDirect = table: chain:
        lib.concatMapStringsSep "\n"
          (net: "${ipt} -t ${table} -A ${chain} -d ${net} -j RETURN")
          directNets;

      # Container subnets, whose traffic is forwarded rather than locally
      # generated - so it never passes through OUTPUT and needs its own
      # PREROUTING redirect to be covered at all.
      containerNets = [ "172.16.0.0/12" "10.88.0.0/16" ];

      containerRedirect =
        lib.optionalString cfg.tor.includeContainers (
          lib.concatMapStringsSep "\n"
            (net: ''
              ${ipt} -t nat -A VAYORI_TOR_PRE -s ${net} -p udp --dport 53 -j REDIRECT --to-ports 9053
              ${ipt} -t nat -A VAYORI_TOR_PRE -s ${net} -p tcp -j REDIRECT --to-ports 9040
              ${ipt} -A VAYORI_TOR_FWD -s ${net} -p tcp -j RETURN
              ${ipt} -A VAYORI_TOR_FWD -s ${net} -p udp --dport 53 -j RETURN
              ${ipt} -A VAYORI_TOR_FWD -s ${net} -j REJECT --reject-with icmp-port-unreachable
            '')
            containerNets
        );

      torUp = pkgs.writeShellScript "vayori-tor-rules-up" ''
        set -eu

        # Locally generated traffic: all TCP into Tor's TransPort, all
        # DNS into its DNSPort. Tor's own uid is exempt or it redirects
        # into itself.
        ${ipt} -t nat -N VAYORI_TOR
        ${ipt} -t nat -A VAYORI_TOR -m owner --uid-owner tor -j RETURN
        ${returnDirect "nat" "VAYORI_TOR"}
        ${ipt} -t nat -A VAYORI_TOR -p udp --dport 53 -j REDIRECT --to-ports 9053
        ${ipt} -t nat -A VAYORI_TOR -p tcp -j REDIRECT --to-ports 9040
        ${ipt} -t nat -I OUTPUT 1 -j VAYORI_TOR

        # TCP and DNS are handled above; everything else leaving this box
        # (QUIC, WireGuard, NTP, ICMP) is rejected rather than allowed
        # out in the clear, because Tor cannot carry it.
        ${ipt} -N VAYORI_TORLEAK
        ${ipt} -A VAYORI_TORLEAK -m owner --uid-owner tor -j RETURN
        ${ipt} -A VAYORI_TORLEAK -o lo -j RETURN
        ${returnDirect "filter" "VAYORI_TORLEAK"}
        ${ipt} -A VAYORI_TORLEAK -p tcp -j RETURN
        ${ipt} -A VAYORI_TORLEAK -p udp --dport 53 -j RETURN
        ${ipt} -A VAYORI_TORLEAK -j REJECT --reject-with icmp-port-unreachable
        ${ipt} -I OUTPUT 1 -j VAYORI_TORLEAK

        # Container traffic is forwarded, not locally generated, so the
        # OUTPUT chains above never see it.
        ${ipt} -t nat -N VAYORI_TOR_PRE
        ${ipt} -N VAYORI_TOR_FWD
        ${containerRedirect}
        ${ipt} -t nat -I PREROUTING 1 -j VAYORI_TOR_PRE
        ${ipt} -I FORWARD 1 -j VAYORI_TOR_FWD

        # The TransPort is v4-only, so v6 has to be closed or it becomes
        # the leak path around all of the above.
        ${ipt6} -N VAYORI_TOR6
        ${ipt6} -A VAYORI_TOR6 -o lo -j RETURN
        ${ipt6} -A VAYORI_TOR6 -j REJECT --reject-with icmp6-port-unreachable
        ${ipt6} -I OUTPUT 1 -j VAYORI_TOR6
      '';

      torDown = pkgs.writeShellScript "vayori-tor-rules-down" ''
        # Deliberately no `set -e`: teardown must run to completion even
        # when a chain is already gone, or a half-removed ruleset strands
        # the machine with no working network.
        ${ipt} -t nat -D OUTPUT -j VAYORI_TOR 2>/dev/null || true
        ${ipt} -t nat -F VAYORI_TOR 2>/dev/null || true
        ${ipt} -t nat -X VAYORI_TOR 2>/dev/null || true

        ${ipt} -t nat -D PREROUTING -j VAYORI_TOR_PRE 2>/dev/null || true
        ${ipt} -t nat -F VAYORI_TOR_PRE 2>/dev/null || true
        ${ipt} -t nat -X VAYORI_TOR_PRE 2>/dev/null || true

        ${ipt} -D OUTPUT -j VAYORI_TORLEAK 2>/dev/null || true
        ${ipt} -F VAYORI_TORLEAK 2>/dev/null || true
        ${ipt} -X VAYORI_TORLEAK 2>/dev/null || true

        ${ipt} -D FORWARD -j VAYORI_TOR_FWD 2>/dev/null || true
        ${ipt} -F VAYORI_TOR_FWD 2>/dev/null || true
        ${ipt} -X VAYORI_TOR_FWD 2>/dev/null || true

        ${ipt6} -D OUTPUT -j VAYORI_TOR6 2>/dev/null || true
        ${ipt6} -F VAYORI_TOR6 2>/dev/null || true
        ${ipt6} -X VAYORI_TOR6 2>/dev/null || true
        exit 0
      '';

      torCtl = pkgs.writeShellScript "vayori-torctl" ''
        set -u

        case "''${1:-}" in
          start)
            ${torDown}
            ${pkgs.systemd}/bin/systemctl start tor.service || exit 1

            # Only redirect once Tor is actually listening - applying the
            # rules against a dead TransPort takes the machine offline
            # instead of routing it.
            for _ in $(seq 1 30); do
              if ${pkgs.iproute2}/bin/ss -ltn 'sport = :9040' | grep -q 9040; then
                exec ${torUp}
              fi
              sleep 0.5
            done

            echo "tor did not open its TransPort within 15s - traffic left untouched" >&2
            ${pkgs.systemd}/bin/systemctl stop tor.service || true
            exit 1
            ;;
          stop)
            # Rules first: a failed stop must not leave traffic pinned to
            # a service that is going away.
            ${torDown}
            exec ${pkgs.systemd}/bin/systemctl stop tor.service
            ;;
          newnym)
            # Fresh circuits. The control socket is root-owned, which is
            # why this arm lives on the privileged side rather than in
            # the user-facing wrapper.
            printf 'AUTHENTICATE\r\nSIGNAL NEWNYM\r\nQUIT\r\n' \
              | ${pkgs.socat}/bin/socat - UNIX-CONNECT:/run/tor/control \
              | ${pkgs.gnugrep}/bin/grep -q "^250" || {
                  echo "could not signal NEWNYM on /run/tor/control" >&2
                  exit 1
                }
            ;;
          *)
            echo "usage: vayori-torctl start|stop|newnym" >&2
            exit 2
            ;;
        esac
      '';

      torToggle = pkgs.writeShellScriptBin "vayori-tor" ''
        set -u
        case "''${1:-status}" in
          status) ${pkgs.systemd}/bin/systemctl is-active tor.service 2>/dev/null || true ;;
          start)  exec sudo -n ${torCtl} start ;;
          stop)   exec sudo -n ${torCtl} stop ;;
          newnym) exec sudo -n ${torCtl} newnym ;;
          *)      echo "usage: vayori-tor start|stop|status|newnym" >&2; exit 2 ;;
        esac
      '';
    in
    {
      options.vayori.network = {
        dns = {
          provider = lib.mkOption {
            type = lib.types.enum (builtins.attrNames dnsProviders);
            default = "cloudflare";
            description = ''
              Which upstream resolver the whole machine uses, via
              systemd-resolved. Each one is paired with its DoT hostname
              so `overTls` can actually verify the certificate.
            '';
          };

          overTls = lib.mkOption {
            type = lib.types.enum [ "false" "opportunistic" "true" ];
            default = "opportunistic";
            description = ''
              DNS-over-TLS mode. `opportunistic` encrypts where possible
              but still falls back to plaintext, which is what keeps
              captive portals working; `true` refuses to resolve at all
              rather than fall back, and will strand you behind one.
            '';
          };

          ipv6 = lib.mkOption {
            type = lib.types.bool;
            default = true;
            description = "Include the provider's IPv6 resolvers.";
          };
        };

        tor = {
          enable = lib.mkEnableOption "the Tor toggle and its control-center widget" // {
            default = true;
          };

          includeContainers = lib.mkOption {
            type = lib.types.bool;
            default = true;
            description = ''
              Also route Docker/Podman container traffic through Tor.
              Container traffic is forwarded rather than locally
              generated, so it bypasses the OUTPUT chains entirely and
              needs its own PREROUTING redirect - without this it keeps
              going out directly while everything else is routed.
            '';
          };
        };

        hardening.enable = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = ''
            Network-stack sysctls: ignore ICMP redirects and source
            routing, enable SYN cookies, and switch congestion control to
            BBR with a fair-queue qdisc.
          '';
        };

        randomizeMac = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = ''
            Randomise the Wi-Fi MAC address per connection, and while
            scanning. Off by default because it breaks networks that
            authenticate by MAC, and any captive portal that remembers
            you.
          '';
        };
      };

      config = lib.mkMerge [
        {
          networking.nameservers = resolvers;

          # These live under settings.Resolve now - the flat
          # dnssec/dnsovertls/fallbackDns options still work but are
          # renamed, and warn on every evaluation.
          services.resolved = {
            enable = true;
            settings.Resolve = {
              DNSSEC = "allow-downgrade";
              DNSOverTLS = cfg.dns.overTls;
              FallbackDNS = withHost chosen.v4;
            };
          };

          networking.networkmanager.dns = "systemd-resolved";
        }

        (lib.mkIf cfg.randomizeMac {
          networking.networkmanager.wifi = {
            macAddress = "random";
            scanRandMacAddress = true;
          };
        })

        (lib.mkIf cfg.hardening.enable {
          boot.kernel.sysctl = {
            "net.ipv4.conf.all.accept_redirects" = 0;
            "net.ipv4.conf.default.accept_redirects" = 0;
            "net.ipv4.conf.all.secure_redirects" = 0;
            "net.ipv6.conf.all.accept_redirects" = 0;
            "net.ipv6.conf.default.accept_redirects" = 0;
            "net.ipv4.conf.all.send_redirects" = 0;
            "net.ipv4.conf.all.accept_source_route" = 0;
            "net.ipv6.conf.all.accept_source_route" = 0;
            "net.ipv4.icmp_echo_ignore_broadcasts" = 1;
            "net.ipv4.tcp_syncookies" = 1;

            # Loose rather than strict reverse-path filtering: strict
            # drops the asymmetric routing that container bridges and
            # VPN split-tunnels rely on.
            "net.ipv4.conf.all.rp_filter" = 2;
            "net.ipv4.conf.default.rp_filter" = 2;

            "net.core.default_qdisc" = "fq";
            "net.ipv4.tcp_congestion_control" = "bbr";
          };
        })

        (lib.mkIf cfg.tor.enable {
          services.tor = {
            enable = true;
            openFirewall = false;
            client = {
              enable = true;
              transparentProxy.enable = true;
              dns.enable = true;
            };
            # Not `settings.ControlSocket` - a bare ControlSocket makes Tor
            # refuse to start because systemd's RuntimeDirectory gives /run/tor
            # mode 0710 (group `tor`), which Tor rejects as "too permissive".
            # This option emits `ControlPort unix:/run/tor/control GroupWritable
            # RelaxDirModeCheck`, which is the same socket without the check.
            controlSocket.enable = true;
          };

          # Installed but never started at boot - the widget owns when
          # it runs.
          systemd.services.tor.wantedBy = lib.mkForce [ ];

          # A firewall restart flushes every chain, including Tor's, and
          # would silently drop traffic back to direct while the daemon
          # is still up. Re-apply on each firewall (re)start if Tor is
          # running.
          networking.firewall.extraCommands = ''
            if ${pkgs.systemd}/bin/systemctl is-active --quiet tor.service; then
              ${torUp} || true
            fi
          '';

          security.sudo.extraRules = map (name: {
            users = [ name ];
            commands = [
              {
                command = "${torCtl}";
                options = [ "NOPASSWD" ];
              }
            ];
          }) (builtins.attrNames config.vayori.users);

          home-manager.users = lib.genAttrs (builtins.attrNames config.vayori.users) (name: {
            home.packages = [ torToggle ];

            # Install through the DMS plugin option, not a bare xdg.configFile
            # drop: DMS only loads a plugin whose id has `enabled: true` in
            # plugin_settings.json, and that file is generated solely from
            # `programs.dank-material-shell.plugins`. Dropping the files alone
            # leaves the widget on disk but never loaded, so `plugin_tor`
            # never appears in the control center.
            programs.dank-material-shell.plugins.tor = {
              enable = true;
              src = ./torWidget;
            };
          });
        })
      ];
    };
}
