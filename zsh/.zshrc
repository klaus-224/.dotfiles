ZSHRC_DIR="$HOME/.zshrc.d"

for file in "$ZSHRC_DIR"/*.zsh; do
  source "$file"
done

