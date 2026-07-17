NIRI_CONFIG="${NIRI_CONFIG:-$HOME/.config/niri/config.kdl}"
NVIDIA_CONFIG_BEGIN="// Zanken NVIDIA environment"
NVIDIA_CONFIG_END="// End Zanken NVIDIA environment"

configure_niri_environment() {
  local temporary_config=""

  if [[ ! -f $NIRI_CONFIG ]]; then
    echo "Niri configuration is missing: $NIRI_CONFIG" >&2
    return 1
  fi

  temporary_config=$(mktemp "${NIRI_CONFIG}.XXXXXX")
  cp "$NIRI_CONFIG" "$temporary_config"
  sed -i "/^$NVIDIA_CONFIG_BEGIN$/,/^$NVIDIA_CONFIG_END$/d" "$temporary_config"

  if [[ $GPU_ARCH == "turing_plus" ]]; then
    cat >>"$temporary_config" <<EOF

$NVIDIA_CONFIG_BEGIN
environment {
  NVD_BACKEND "direct"
  LIBVA_DRIVER_NAME "nvidia"
  __GLX_VENDOR_LIBRARY_NAME "nvidia"
}
$NVIDIA_CONFIG_END
EOF
  else
    cat >>"$temporary_config" <<EOF

$NVIDIA_CONFIG_BEGIN
environment {
  NVD_BACKEND "egl"
  __GLX_VENDOR_LIBRARY_NAME "nvidia"
}
$NVIDIA_CONFIG_END
EOF
  fi

  if ! niri validate --config "$temporary_config" >/dev/null; then
    rm -f "$temporary_config"
    echo "Generated NVIDIA settings are not valid Niri configuration" >&2
    return 1
  fi

  mv "$temporary_config" "$NIRI_CONFIG"
}

if lspci | grep -qi 'nvidia'; then
  # Check which kernel is installed and set appropriate headers package
  KERNEL_HEADERS="$(pacman -Qqs '^linux(-zen|-lts|-hardened)?$' | head -1)-headers"

  if omarchy-hw-nvidia-gsp; then
    PACKAGES=(nvidia-open-dkms nvidia-utils lib32-nvidia-utils libva-nvidia-driver)
    GPU_ARCH="turing_plus"
  elif omarchy-hw-nvidia-without-gsp; then
    PACKAGES=(nvidia-580xx-dkms nvidia-580xx-utils lib32-nvidia-580xx-utils)
    GPU_ARCH="maxwell_pascal_volta"
  fi
  # Bail if no supported GPU
  if [[ -z ${PACKAGES+x} ]]; then
    echo "No compatible driver for your NVIDIA GPU. See: https://wiki.archlinux.org/title/NVIDIA"
    exit 0
  fi

  omarchy-pkg-add "$KERNEL_HEADERS" "${PACKAGES[@]}"

  # Configure modprobe for early KMS
  sudo tee /etc/modprobe.d/nvidia.conf <<EOF >/dev/null
options nvidia_drm modeset=1
EOF

  # Configure mkinitcpio for early loading
  sudo tee /etc/mkinitcpio.conf.d/nvidia.conf <<EOF >/dev/null
MODULES+=(nvidia nvidia_modeset nvidia_uvm nvidia_drm)
EOF

  configure_niri_environment
fi
