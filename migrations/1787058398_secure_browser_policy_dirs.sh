echo "Restrict Chromium-family managed policy directories to root (revoke world-writable a+rw)"

for dir in \
  /etc/chromium/policies/managed \
  /etc/opt/chrome/policies/managed \
  /etc/opt/edge/policies/managed \
  /etc/brave/policies/managed; do
  if [[ -d $dir ]]; then
    sudo chmod 0755 "$dir"
  fi
done