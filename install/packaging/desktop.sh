mapfile -t packages < <(grep -vE '^[[:space:]]*(#|$)' "$ZANKEN_PATH/install/zanken-desktop.packages")
mapfile -t workflow_packages < <(grep -vE '^[[:space:]]*(#|$)' "$ZANKEN_PATH/install/zanken-workflow.packages")
packages+=("${workflow_packages[@]}")
zanken-pkg-add "${packages[@]}"
python3 -B "$ZANKEN_PATH/lib/zanken/workflow.py" validate "$ZANKEN_PATH"
