# Place Zanken's desktop skill in each supported assistant's global skill directory.
mkdir -p ~/.agents/skills ~/.claude/skills ~/.codex/skills ~/.pi/agent/skills
ln -sfn "$ZANKEN_PATH/default/zanken-skill" ~/.agents/skills/zanken
ln -sfn "$ZANKEN_PATH/default/zanken-skill" ~/.claude/skills/zanken
ln -sfn "$ZANKEN_PATH/default/zanken-skill" ~/.codex/skills/zanken
ln -sfn "$ZANKEN_PATH/default/zanken-skill" ~/.pi/agent/skills/zanken
