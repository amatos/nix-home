{
  lib,
  pkgs,
  config,
  ...
}:
let
  # Absolute store paths — home-manager activation scripts run with a minimal
  # PATH (bash/coreutils/diffutils/findutils/gettext/gnugrep/gnused/jq/ncurses/
  # nix only) that excludes the user package profile, so a bare `mise` would
  # silently no-op even though it works in an interactive shell. Via
  # `config.programs.mise.package` (not a bare `pkgs.mise`) so this follows
  # home/shared/tools/mise.nix's darwin Homebrew shim rather than still
  # building the crashing nixpkgs mise there.
  miseBin = "${config.programs.mise.package}/bin/mise";
  # mise's npm backend shells out to `npm`/`node` — neither is reachable from
  # the minimal activation PATH. Prefix nodejs + git store paths plus the
  # per-user profile bins (NixOS/darwin HM-module: /etc/profiles/per-user;
  # standalone HM: ~/.nix-profile).
  bootstrapPath = "${pkgs.nodejs}/bin:${pkgs.git}/bin:/etc/profiles/per-user/$USER/bin:$HOME/.nix-profile/bin:$PATH";
in
{
  # getcaveman.dev (JuliusBrussee) — the Caveman token-compression stack
  # ("why use many token when few token do trick"). One aiAgentHelpers token,
  # two pieces, neither in nixpkgs nor Homebrew:
  #
  #  1. caveman-code — the standalone provider-agnostic terminal coding agent,
  #     npm @juliusbrussee/caveman-code (binary `caveman`). Installed via
  #     mise's npm backend (mise deliberately owns a WRITABLE global
  #     config.toml — see home/shared/tools/mise.nix), the same mechanism as
  #     oh-my-pi.nix but cross-platform: unlike omp there is no Homebrew
  #     formula, so darwin uses this same bootstrap (no `lib.mkIf isLinux`).
  #  2. the caveman agent skill (github:JuliusBrussee/caveman) — compressed
  #     "caveman-speak" replies, ~65% fewer output tokens, code/commands kept
  #     byte-exact. Deliberately NOT automated anymore (manual, once per
  #     agent — same stance as agentmemory's `connect` and
  #     codebase-memory-mcp's `install`): its unified installer drives each
  #     agent's own CLI, and those prompt on a TTY with no non-interactive
  #     escape hatch — `gemini extensions install` asks for workspace trust
  #     (hung gtr5's activation to the systemd start timeout twice,
  #     2026-07-08), and `claude plugin marketplace add` trips first-run
  #     onboarding on any machine where Claude Code has never been launched
  #     (hung brutus's first activation, 2026-07-09; the timeout/stdin
  #     hardening below proved insufficient — the CLI grandchild survives
  #     `timeout`'s SIGTERM to npx and keeps the TTY). Install from a real
  #     terminal after each agent is onboarded:
  #       npx -y github:JuliusBrussee/caveman
  #
  # Fail-soft (`|| echo`) so a network hiccup never breaks `nixos-rebuild
  # switch` / `darwin-rebuild switch`. Upgrades are NOT automatic — rerun:
  #   mise use -g npm:@juliusbrussee/caveman-code
  home.activation.cavemanCodeBootstrap = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if [ -x ${miseBin} ]; then
      if ! ${miseBin} ls -g 2>/dev/null | grep -qi 'caveman-code'; then
        echo "→ Bootstrapping caveman-code via mise (npm backend) ..."
        $DRY_RUN_CMD env PATH="${bootstrapPath}" ${miseBin} use -g 'npm:@juliusbrussee/caveman-code' </dev/null 2>&1 || \
          echo "  (mise install failed — non-fatal; rerun manually with: mise use -g npm:@juliusbrussee/caveman-code)"
      fi
    fi
  '';

  # ── Retired: automatic skill bootstrap (kept for future reuse) ────────────
  # Removed 2026-07-09 after hanging brutus's first activation (see above).
  # Re-enabling needs two things fixed first: (a) only target agents that are
  # already onboarded (e.g. gate the claude id on ~/.claude.json existing) and
  # (b) kill the whole process TREE on timeout (`timeout` only signals npx;
  # use `timeout -k` on a `setsid` child or equivalent). Also restore
  # `config, settings` to the lambda args — the bindings below use both.
  #
  # npxBin = "${pkgs.nodejs}/bin/npx";
  # stampFile = "${config.xdg.stateHome}/the-one-nix/caveman-skill-installed";
  # timeoutBin = "${pkgs.coreutils}/bin/timeout";
  # skillOnlyIds = { "claude-code" = "claude"; "codex" = "codex"; "opencode" = "opencode"; };
  # skillAgents = lib.concatMap
  #   (t: lib.optional (skillOnlyIds ? ${t}) skillOnlyIds.${t})
  #   (settings.aiCodeTools or [ ]);
  # skillOnlyFlags = lib.concatMapStringsSep " " (id: "--only ${id}") skillAgents;
  #
  # home.activation.cavemanSkillBootstrap = lib.mkIf (skillAgents != [ ])
  #   (lib.hm.dag.entryAfter [ "writeBoundary" ] ''
  #     if [ ! -e "${stampFile}" ]; then
  #       echo "→ Installing the caveman agent skill for: ${lib.concatStringsSep ", " skillAgents} ..."
  #       $DRY_RUN_CMD env PATH="${bootstrapPath}" ${timeoutBin} 240 ${npxBin} -y github:JuliusBrussee/caveman --non-interactive ${skillOnlyFlags} </dev/null 2>&1 || \
  #         echo "  (caveman skill install incomplete — non-fatal; rerun manually with: npx -y github:JuliusBrussee/caveman)"
  #       $DRY_RUN_CMD mkdir -p "$(dirname "${stampFile}")"
  #       $DRY_RUN_CMD touch "${stampFile}"
  #     fi
  #   '');
}
