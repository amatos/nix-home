{ pkgs, ... }:
{
  # ── Nix ecosystem tools ─────────────────────────────────────────────────
  home.packages = with pkgs; [
    # ── Tier 1 — high daily value ──────────────────────────────────────────
    nix-search-tv # fzf-based search across nixpkgs, HM/NixOS/darwin options
    comma # run any program without installing (, ripgrep)
    nix-index # file→package database for comma
    nvd # diff package versions between NixOS generations
    nix-output-monitor # pretty build output (nom) — dependency tree, progress
    manix # fast Nix documentation/options search

    # ── Tier 2 — better workflow ───────────────────────────────────────────
    nix-inspect # TUI for exploring Nix config (ranger-like, fuzzy search)
    nurl # generate Nix fetcher expressions from repo URLs
    nix-init # generate full package expressions from URLs

    # ── Tier 3 — nice to have ─────────────────────────────────────────────
    nix-diff # debug why derivations differ
    nix-du # visualize store space by GC root
    nix-melt # browse flake.lock visually
    nix-health # one-time Nix install health check
    flake-checker # CI health check for stale flake inputs
  ];
  # (nixai was removed 2026-07: upstream olafkfreund/nix-ai-help was archived
  # read-only 2026-02 with a docs/manual.md vs docs/MANUAL.md case collision
  # that broke the input fetch on macOS, and no maintained fork exists.)

  # ── direnv + nix-direnv ────────────────────────────────────────────────
  # Fast flake dev shell auto-loading on cd.
  # Disabled: triggers "direnv: error .envrc is blocked" on every cd into
  # a directory tree with an .envrc. Uncomment when ready to use.
  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
    enableBashIntegration = true;
    enableFishIntegration = true;
  };
}
