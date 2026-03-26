export NVM_DIR="$HOME/.nvm"

if command -v brew >/dev/null 2>&1; then
	NVM_SH="$(brew --prefix)/opt/nvm/nvm.sh"
	if [[ -s "$NVM_SH" ]]; then
		source "$NVM_SH"
	fi
fi
