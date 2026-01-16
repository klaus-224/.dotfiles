# --------------------------------------------------
#	.zshrc
# Purpose:
# 	- entry point for zsh configuration
# 	- loops through zsh fragements in /.zshrc.d and
# 		sources them
# --------------------------------------------------

for file in "$HOME/.zshrc.d/"*.zsh; do
  [ -f "$file" ] && source "$file"
done
