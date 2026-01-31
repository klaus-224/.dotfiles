# --------------------------------------------------
# 30-tools.zsh
# Purpose:
#   Sources everything in the ./tools/ folder
#
# --------------------------------------------------
for file in "$HOME/.zshrc.d/tools/"*.zsh; do
  [ -f "$file" ] && source "$file"
done
