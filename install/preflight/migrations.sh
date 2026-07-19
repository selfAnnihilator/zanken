ZANKEN_MIGRATIONS_STATE_PATH=~/.local/state/zanken/migrations
ZANKEN_MIGRATION_BASELINE=1780164860
mkdir -p $ZANKEN_MIGRATIONS_STATE_PATH

for file in "$ZANKEN_PATH"/migrations/*.sh; do
  filename=$(basename "$file")
  if [[ ! $filename =~ ^([0-9]+)(_.+)?\.sh$ ]]; then
    echo "Skipping migration with an invalid filename: $filename" >&2
    continue
  fi
  migration_id=${BASH_REMATCH[1]}

  (( migration_id < ZANKEN_MIGRATION_BASELINE )) && continue
  touch "$ZANKEN_MIGRATIONS_STATE_PATH/$filename"
done
