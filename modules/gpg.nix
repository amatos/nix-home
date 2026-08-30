{
  pkgs,
  lib,
  nix-secrets,
  ...
}:
let
  user = import "${nix-secrets}/users/alberth.nix";
  gpgSigningKey = user.gpgSigningKey;
  email = user.email;
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
    # GnuPG smartcard glue — make scdaemon defer to pcscd.
    #
    # Root cause this fixes: there is exactly one smartcard reader (a built-in
    # Realtek CCID reader, or a USB YubiKey acting as its own reader). By default
    # GnuPG's scdaemon uses its *internal* CCID driver and opens that reader
    # directly via libusb, which locks out pcscd — pcscd then logs
    # `OpenUSBByName() Can't claim interface … LIBUSB_ERROR_BUSY` and every other
    # PC/SC consumer (OpenSC PKCS#11, `ssh-add -s`, yubioath) is starved. Whichever
    # daemon grabs the reader first wins, so the smartcard "works" only
    # intermittently depending on boot/login race order.
    #
    # `disable-ccid` makes scdaemon talk to the reader through pcscd instead of its
    # own driver (modules/nixos/smartcard already runs pcscd with the ccid plugin),
    # and `pcsc-shared` lets the card be opened by several PC/SC clients at once.
    # Net effect: gpg (via scdaemon → pcscd), OpenSC, ssh PKCS#11 and yubioath all
    # share the single reader instead of fighting over it.
    scdaemonSettings = {
      disable-ccid = true; # route through pcscd, don't grab the reader directly
      pcsc-shared = true; # allow concurrent PC/SC access to the card
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
