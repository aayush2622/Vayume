{ ... }:
{
  flake.nixosModules.Performance =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.vayume.performance;
      bootReport = pkgs.writeShellScript "vayume-boot-time" ''
        ${pkgs.systemd}/bin/systemd-analyze
        echo
        echo "Slowest units (parallel ones are not necessarily on the critical path):"
        ${pkgs.systemd}/bin/systemd-analyze blame | ${pkgs.gnugrep}/bin/grep -vE '\.(device|mount|slice|socket|path)' | ${pkgs.coreutils}/bin/head -12
        echo
        echo "Critical chain to the login screen:"
        ${pkgs.systemd}/bin/systemd-analyze critical-chain display-manager.service --no-pager
      '';
      d = lib.mkOverride 900;
    in
    {
      options.vayume.performance = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Apply the system-level tuning described in docs/system-performance.md. Every value is a default that `_config.nix` or Host.nix can override.";
        };
        gaming = lib.mkOption {
          type = lib.types.bool;
          default = config.vayume.apps.Gaming.enable or false;
          defaultText = lib.literalExpression "config.vayume.apps.Gaming.enable";
          description = "Gaming-only tuning: split-lock mitigation off, a smaller CFS bandwidth slice, gamemode renice and gamescope.";
        };
        kernel = lib.mkOption {
          type = lib.types.nullOr (
            lib.types.enum [
              "lts"
              "latest"
              "zen"
            ]
          );
          default = null;
          description = "Kernel package set. null keeps the NixOS default.";
        };
      };

      config = lib.mkIf cfg.enable (
        lib.mkMerge [
          {
            zramSwap = {
              algorithm = d "zstd";
              memoryPercent = d 50;
              priority = d 100;
            };

            boot = {
              kernel.sysctl = {
                "vm.swappiness" = d 180;
                "vm.page-cluster" = d 0;
                "vm.watermark_boost_factor" = d 0;
                "vm.watermark_scale_factor" = d 125;
                "vm.vfs_cache_pressure" = d 50;
                "vm.dirty_bytes" = d 268435456;
                "vm.dirty_background_bytes" = d 67108864;
                "vm.max_map_count" = d 2147483642;
                "kernel.nmi_watchdog" = d 0;
                "net.core.default_qdisc" = d "fq";
                "net.ipv4.tcp_congestion_control" = d "bbr";
                "net.ipv4.tcp_fastopen" = d 3;
                "net.ipv4.tcp_slow_start_after_idle" = d 0;
                "net.ipv4.tcp_mtu_probing" = d 1;
                "net.ipv4.tcp_fin_timeout" = d 5;
                "net.core.netdev_max_backlog" = d 16384;
                "net.core.somaxconn" = d 8192;
              };
              kernelModules = [ "tcp_bbr" ];
              kernelParams = [
                "nowatchdog"
                "quiet"
              ];
              blacklistedKernelModules = [
                "iTCO_wdt"
                "sp5100_tco"
              ];
              tmp.cleanOnBoot = d true;
              loader.grub.configurationLimit = d 10;
              loader.timeout = d 2;
            };

            services.fstrim.enable = d true;

            virtualisation.docker.enableOnBoot = d false;

            vayume.commands.boot-time = {
              command = "${bootReport}";
              description = "How long the last boot took, and which units were slowest";
              panel = {
                label = "Boot time report";
                icon = "timer";
              };
            };

            services.udev.extraRules = ''
              ACTION=="add|change", KERNEL=="nvme[0-9]*n[0-9]*", ATTR{queue/scheduler}="none"
              ACTION=="add|change", KERNEL=="sd[a-z]|mmcblk[0-9]*", ATTR{queue/rotational}=="0", ATTR{queue/scheduler}="mq-deadline"
              ACTION=="add|change", KERNEL=="sd[a-z]", ATTR{queue/rotational}=="1", ATTR{queue/scheduler}="bfq"
            '';

            systemd = {
              settings.Manager = {
                DefaultTimeoutStopSec = d "15s";
                DefaultLimitNOFILE = d "1024:1048576";
              };
              user.settings.Manager.DefaultTimeoutStopSec = d "10s";
              oomd = {
                enable = d true;
                enableRootSlice = d true;
                enableUserSlices = d true;
              };
            };

            services.journald.settings.Journal = {
              SystemMaxUse = d "500M";
              MaxRetentionSec = d "1month";
            };

            nix = {
              daemonCPUSchedPolicy = d "batch";
              daemonIOSchedClass = d "idle";
              daemonIOSchedPriority = d 7;
              settings = {
                download-buffer-size = d 268435456;
                connect-timeout = d 5;
                log-lines = d 25;
                min-free = d 5368709120;
                max-free = d 21474836480;
              };
            };

            documentation.man.cache.enable = d false;
          }

          (lib.mkIf cfg.gaming {
            boot.kernel.sysctl = {
              "kernel.split_lock_mitigate" = d 0;
              "kernel.sched_cfs_bandwidth_slice_us" = d 3000;
            };
            programs.gamemode.settings.general.renice = d 10;
            programs.gamescope = {
              enable = d true;
              capSysNice = d true;
            };
            programs.steam.gamescopeSession.enable = d true;
          })

          (lib.mkIf (cfg.kernel != null) {
            boot.kernelPackages = d (
              {
                lts = pkgs.linuxPackages;
                latest = pkgs.linuxPackages_latest;
                zen = pkgs.linuxPackages_zen;
              }
              .${cfg.kernel}
            );
          })
        ]
      );
    };
}
