#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="${DOTFILES_HOME:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
CARGO_PKG_FILE="${CARGO_PKG_FILE:-$DOTFILES_DIR/packages/cargo.txt}"
ACTION="${1:-sync}"

usage() {
  cat <<'EOF'
Usage: sync-cargo-packages.sh [sync|reinstall|list]

  sync       Install/update crates listed in packages/cargo.txt (default)
  reinstall  Force reinstall every listed crate
  list       Print configured crates
EOF
}

if [[ ! -f "$CARGO_PKG_FILE" ]]; then
  echo "Error: cargo package list not found at $CARGO_PKG_FILE" >&2
  exit 1
fi

if ! command -v cargo >/dev/null 2>&1; then
  echo "Error: cargo is required. Install rustup first." >&2
  exit 1
fi

read_packages() {
  # Strip comments and empty lines.
  sed -e 's/[[:space:]]*#.*$//' -e '/^[[:space:]]*$/d' "$CARGO_PKG_FILE"
}

case "$ACTION" in
  list)
    read_packages
    exit 0
    ;;
  sync|reinstall)
    ;;
  -h|--help|help)
    usage
    exit 0
    ;;
  *)
    usage >&2
    exit 1
    ;;
esac

echo "Syncing cargo packages from $CARGO_PKG_FILE"
while IFS= read -r crate; do
  [[ -z "$crate" ]] && continue
  echo "-> $crate"
  if [[ "$ACTION" == "reinstall" ]]; then
    cargo install --locked --force "$crate"
  else
    cargo install --locked "$crate"
  fi
done < <(read_packages)

echo "Cargo package sync complete."
