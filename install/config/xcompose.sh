# Set default XCompose that is triggered with CapsLock
tee ~/.XCompose >/dev/null <<EOF
# Run zanken-restart-xcompose to apply changes

# Include fast emoji access
include "%H/zanken/default/xcompose"

# Identification
<Multi_key> <space> <n> : "$ZANKEN_USER_NAME"
<Multi_key> <space> <e> : "$ZANKEN_USER_EMAIL"
EOF
