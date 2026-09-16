#!/usr/bin/env bash
# Symlink every skill in this repo into ~/.config/devin/skills.
# Idempotent — run it after every `git pull` (and once on machine setup).
set -euo pipefail
REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
TARGET="$HOME/.config/devin/skills"
mkdir -p "$TARGET"
count=0
for skill_md in "$REPO_DIR"/skills/*/SKILL.md; do
  skill_dir="$(dirname "$skill_md")"
  ln -sfn "$skill_dir" "$TARGET/$(basename "$skill_dir")"
  count=$((count + 1))
done
echo "skills-Helcim: linked $count skill(s) into $TARGET"
