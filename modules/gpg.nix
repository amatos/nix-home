{ pkgs, lib,... }:
let
  gpgSigningKey = "5FC8FE1141FA769594E91E48F41BDBF6171A3BB4";
  email = "alberth@matos.cc";
in
{
  programs.gpg = {
    enable = true;
    # home-manager's programs.gpg module already mkDefaults most of the old
    # gpg.conf (drduh/YubiKey-Guide) — personal-*-preferences, cert/s2k algos,
    # no-comments, no-emit-version, keyid-format, list/verify-options,
    # with-fingerprint, require-cross-certification, no-symkey-cache. Only
    # the settings below are additional or diverge from those defaults.
    settings = {
      charset = "utf-8";
      no-greeting = true;
      require-secmem = true;
      armor = true;
      use-agent = true;
      auto-key-locate = "clear,local,wkd,dane";
      auto-key-retrieve = true;
      default-key = "${gpgSigningKey}";
      trusted-key = "${gpgSigningKey}";
    };
    publicKeys = [
      {
        source = pkgs.fetchurl {
          url = "https://keys.openpgp.org/vks/v1/by-fingerprint/${gpgSigningKey}";
          hash = "sha256-BdHZRXJw27vnOXetqj+wANTYf7L58yRTgAiz6dKBD64=";
        };
        trust = "ultimate";
      }
    ];
  };

  # Import GPG public key on first activation.
  # Tries WKD (domain-hosted) first; falls back to keys.openpgp.org.
  # Skipped if the key is already in the keyring (idempotent).
  home.activation.importGpgKey = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    _gpgBin="${pkgs.gnupg}/bin/gpg"
    _key="${gpgSigningKey}"
    _email="${email}"

    if ! "$_gpgBin" --list-keys "$_key" > /dev/null 2>&1; then
      echo "GPG: importing key $_key for $_email..."
      "$_gpgBin" --auto-key-locate wkd --locate-key "$_email" 2>/dev/null \
        || "$_gpgBin" --keyserver hkps://keys.openpgp.org --recv-keys "$_key" \
        || echo "GPG: warning — could not import key $_key (no network?)"
    fi

    # Ensure ultimate trust is set (safe to run every time)
    echo "$_key:6:" | "$_gpgBin" --import-ownertrust 2>/dev/null || true
  '';
}
