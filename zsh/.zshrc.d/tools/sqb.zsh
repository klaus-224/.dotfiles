# --------------------------------------------------
# mnemonic: [S][Q]L SCRATCH [B]UFFER
# Opens a temporary SQL buffer in Neovim with syntax highlighting and LSP
#
# Usage:
#   sql              			# Open empty SQL scratch buffer
#   pbpaste | sqlb    # Pipe SQL from clipboard
#   cat query.sql | sql
# --------------------------------------------------

function sqb() {
  # Ensure SQL language server is installed via Mason
  if ! [ -f "$HOME/.local/share/nvim/mason/bin/sql-language-server" ]; then
    echo "Installing SQL language server..."
    nvim --headless -c 'MasonInstall sqlls' -c 'qall' 2>/dev/null
  fi

  if [ -t 0 ]; then
    # No stdin, open empty buffer
    $EDITOR -c 'setfiletype sql' -c 'setlocal buftype=nofile bufhidden=wipe noswapfile'
  else
    # Has stdin, read it
    $EDITOR -c 'setfiletype sql' -c 'setlocal buftype=nofile bufhidden=wipe noswapfile' -
  fi
}
