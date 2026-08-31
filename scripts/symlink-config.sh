#!/usr/bin/env bash
set -euo pipefail

DOTFILES_HOME="${DOTFILES_HOME:-"$HOME/.dotfiles/"}"

DIRS=(
  "$HOME/.config/glow"
)

# do the files exist?
for DIR in "${DIRS[@]}"; do
  if [ ! -d "$DIR" ]; then
    mkdir "$DIR"
    echo "Directory created: $DIR"
  else
    echo "$DIR exists -> proceeding to symlinking"
  fi
done

ln -sf "$DOTFILES_HOME/glow/config.yml" "$HOME/Library/Preferences/glow/glow.yml"
