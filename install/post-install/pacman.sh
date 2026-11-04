# Configure pacman
# A release mode selects Zanken source, not package infrastructure. Preserve
# the official repository/mirror configuration prepared during preflight.

if lspci -nn | grep -q "106b:180[12]"; then
  # The arch-mact2 mirror ships signed databases (arch-mact2.db.sig), but the
  # maintainer's key is not in the default keyring, so hard `Required` would
  # break T2 installs. Best-effort verification:
  #   SigLevel = Optional DatabaseOptional
  # For full verification, import and trust the maintainer's key first, e.g.:
  #   sudo pacman-key --recv-keys <maintainer-fingerprint> && sudo pacman-key --lsign-key <maintainer-fingerprint>
  cat <<EOF | sudo tee -a /etc/pacman.conf >/dev/null

[arch-mact2]
Server = https://github.com/NoaHimesaka1873/arch-mact2-mirror/releases/download/release
SigLevel = Optional DatabaseOptional
EOF
fi
