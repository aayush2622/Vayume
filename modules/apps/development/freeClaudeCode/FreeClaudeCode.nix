{ self, lib, ... }:
let
  freeClaudeCodeSpec = {
    baseUrl = "http://localhost:8082";
    authToken = "freecc";
    clientEnv = {
      ANTHROPIC_BASE_URL = "http://localhost:8082";
      ANTHROPIC_AUTH_TOKEN = "freecc";
      CLAUDE_CODE_ENABLE_GATEWAY_MODEL_DISCOVERY = "1";
      CLAUDE_CODE_AUTO_COMPACT_WINDOW = "190000";
      DISABLE_AUTOUPDATER = "1";
      DISABLE_FEEDBACK_COMMAND = "1";
      DISABLE_ERROR_REPORTING = "1";
    };
  };
in {
  options.flake.freeClaudeCode = lib.mkOption {
    type = lib.types.lazyAttrsOf lib.types.unspecified;
    default = { };
    description = ''
      Free Claude Code's proxy connection info (base URL, auth token, the
      client env vars that point a Claude Code integration at it), shared
      so apps that optionally wire into it (VS Code, Android Studio)
      don't each hardcode their own copy - see
      modules/apps/freeClaudeCode/FreeClaudeCode.nix.
    '';
  };

  config.flake.freeClaudeCode = freeClaudeCodeSpec;

  config.flake.homeModules.apps.FreeClaudeCode = { pkgs, lib, config, vayoriSecrets, ... }:
    let
      fccDir = "${config.home.homeDirectory}/.local/share/free-claude-code";
      fccConfigDir = "${config.home.homeDirectory}/.fcc";
      jetbrainsAcpFile = "${config.home.homeDirectory}/.jetbrains/acp.json";
      claudeJsonFile = "${config.home.homeDirectory}/.claude.json";

      fccSeedEnv = {
        MODEL = "nvidia_nim/nvidia/nemotron-3-super-120b-a12b";
        PROXY_AUTH_ENABLED = "false";
        ANTHROPIC_AUTH_TOKEN = self.freeClaudeCode.authToken;
        FCC_OPEN_BROWSER = "false";
      };

      fccSeedEnvFile = pkgs.writeText "fcc-seed.env" (
        lib.concatStringsSep "\n" (lib.mapAttrsToList (n: v: "${n}=${v}") fccSeedEnv) + "\n"
      );
      claudeAcpEnv = self.freeClaudeCode.clientEnv;

      realProviders = lib.filterAttrs (n: v: v != "REPLACE_ME") (vayoriSecrets.PROVIDERS or { });

      providersEnvFile = pkgs.writeText "fcc-providers.env" (
        lib.concatStringsSep "\n" (lib.mapAttrsToList (n: v: "${n}=${v}") realProviders) + "\n"
      );

      # mktemp, run jq with the given args/filter against `file` (a shell
      # variable reference, e.g. "$CLAUDE_JSON"), cp the result back over it
      # on success, clean up the tmpfile either way. Callers run sequentially
      # in the same script, so reusing one $JQ_TMP name between calls is fine.
      jqPatchInPlace = file: jqArgs: filter: ''
        JQ_TMP="$(mktemp)"
        ${pkgs.jq}/bin/jq ${jqArgs} '${filter}' "${file}" > "$JQ_TMP" \
          && run cp "$JQ_TMP" "${file}"
        rm -f "$JQ_TMP"
      '';

      fccBootstrapScript = pkgs.writeShellScript "free-claude-code-bootstrap" ''
        set -e
        FCC_DIR=${lib.escapeShellArg fccDir}

        if [ ! -d "$FCC_DIR/.git" ]; then
          ${pkgs.git}/bin/git clone https://github.com/Alishahryar1/free-claude-code.git "$FCC_DIR"
        else
          ${pkgs.git}/bin/git -C "$FCC_DIR" pull --ff-only
        fi

        cd "$FCC_DIR"
        ${pkgs.uv}/bin/uv sync --python '${pkgs.python314}/bin/python3.14'
      '';
    in
    {
      home.packages = [
        pkgs.uv
        pkgs.python314
      ];

      home.activation.freeClaudeCodeSetup = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        FCC_CONFIG_DIR=${lib.escapeShellArg fccConfigDir}

        run mkdir -p "$FCC_CONFIG_DIR"
        run chown -R "$(id -u):$(id -g)" "$FCC_CONFIG_DIR"
        if [ ! -f "$FCC_CONFIG_DIR/.env" ]; then
          run sh -c "cat ${fccSeedEnvFile} > '$FCC_CONFIG_DIR/.env'"
        fi

        ENV_TMP="$(mktemp)"
        cp "$FCC_CONFIG_DIR/.env" "$ENV_TMP"

        while IFS='=' read -r providerKey providerValue; do
          [ -z "$providerKey" ] && continue
          grep -v "^''${providerKey}=" "$ENV_TMP" > "$ENV_TMP.next" || true
          mv "$ENV_TMP.next" "$ENV_TMP"
          printf '%s=%s\n' "$providerKey" "$providerValue" >> "$ENV_TMP"
        done < ${providersEnvFile}

        run cp "$ENV_TMP" "$FCC_CONFIG_DIR/.env"
        rm -f "$ENV_TMP"

        CLAUDE_JSON=${lib.escapeShellArg claudeJsonFile}

        if [ ! -f "$CLAUDE_JSON" ]; then
          run sh -c "printf '{}' > '$CLAUDE_JSON'"
        fi

        ${jqPatchInPlace "$CLAUDE_JSON" "" ". + {hasCompletedOnboarding: true}"}

        ACP_JSON=${lib.escapeShellArg jetbrainsAcpFile}

        run mkdir -p "$(dirname "$ACP_JSON")"

        if [ ! -f "$ACP_JSON" ]; then
          run sh -c "printf '{}' > '$ACP_JSON'"
        fi

        ${jqPatchInPlace "$ACP_JSON" "--argjson env ${lib.escapeShellArg (builtins.toJSON claudeAcpEnv)}" ''
          .acp.registry."claude-acp".env =
            ((.acp.registry."claude-acp".env // {}) + $env)
        ''}

        run ${pkgs.systemd}/bin/systemctl --user --no-block restart free-claude-code.service || true
      '';

      systemd.user.services.free-claude-code-bootstrap = {
        Unit = {
          Description = "Clone/update Free Claude Code and sync its Python environment";
          After = [ "network-online.target" ];
        };
        Service = {
          Type = "oneshot";
          ExecStart = "${fccBootstrapScript}";
        };
      };

      systemd.user.services.free-claude-code = {
        Unit = {
          Description = "Free Claude Code local proxy server";
          After = [ "network-online.target" "free-claude-code-bootstrap.service" ];
          Wants = [ "free-claude-code-bootstrap.service" ];
        };
        Service = {
          WorkingDirectory = fccDir;
          ExecStart = "${fccDir}/.venv/bin/fcc-server";
          Restart = "on-failure";
          RestartSec = 10;
        };
        Install.WantedBy = [ "default.target" ];
      };
    };
}
