# --------------------------------------------------
#	.zshrc
# Purpose:
# 	- entry point for zsh configuration
# 	- loops through zsh fragements in /.zshrc.d and
# 		sources them
# --------------------------------------------------
[[ -n "${ZSH_VERSION:-}" ]] || return 0
emulate -LR zsh

for file in "$HOME/.zshrc.d/"*.zsh; do
	[ -f "$file" ] && source "$file"
done

eval "$(starship init zsh)"

# sourece custom env vars
source "$HOME/.zshenv"

# Options
setopt AUTO_PUSHD
setopt PUSHD_IGNORE_DUPS
setopt PUSHD_SILENT

### Rancher Desktop (if installed) START (DO NOT EDIT)
if [ -d "$HOME/.rd/bin" ]; then
	export PATH="$HOME/.rd/bin:$PATH"
fi
### Rancher Desktop END

### MANAGED BY RANCHER DESKTOP START (DO NOT EDIT)
export PATH="/Users/rohineshram/.rd/bin:$PATH"
### MANAGED BY RANCHER DESKTOP END (DO NOT EDIT)
