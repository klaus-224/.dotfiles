#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="${DOTFILES_HOME:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
BREW_DIR="$DOTFILES_DIR/packages"
COMMON="$BREW_DIR/Brewfile.common"
VERSIONS_DIR="$BREW_DIR/installed-versions"

case "$(uname -s)" in
Darwin)
  OS_BREWFILE="$BREW_DIR/Brewfile.macos"
  ;;
Linux)
  OS_BREWFILE="$BREW_DIR/Brewfile.linux"
  ;;
*)
  echo "Error: Unsupported OS for brew bundle: $(uname -s)" >&2
  exit 1
  ;;
esac

if ! command -v brew >/dev/null 2>&1; then
  echo "Error: Homebrew is required before running install-brew-packages.sh" >&2
  exit 1
fi

if [[ ! -f "$COMMON" ]]; then
  echo "Error: missing Brewfile: $COMMON" >&2
  exit 1
fi

if [[ ! -f "$OS_BREWFILE" ]]; then
  echo "Error: missing Brewfile: $OS_BREWFILE" >&2
  exit 1
fi

TMP_BREWFILE="$(mktemp)"
trap 'rm -f "$TMP_BREWFILE"' EXIT

awk '!seen[$0]++' "$COMMON" "$OS_BREWFILE" >"$TMP_BREWFILE"
echo "Installing Homebrew packages using unified Brewfile: $OS_BREWFILE"
brew bundle --file "$TMP_BREWFILE"

mkdir -p "$VERSIONS_DIR"
TIMESTAMP="$(date -u +"%Y%m%dT%H%M%SZ")"
SNAPSHOT_FILE="$VERSIONS_DIR/brew-versions-${TIMESTAMP}.txt"
LATEST_FILE="$VERSIONS_DIR/brew-versions-latest.txt"

{
  echo "# generated_at_utc=${TIMESTAMP}"
  echo "# os=$(uname -s)"
  echo
  echo "## formulae"
  brew list --formula --versions | sort
  echo
  echo "## casks"
  if [[ "$(uname -s)" == "Darwin" ]]; then
    brew list --cask --versions | sort
  else
    echo "(not applicable on Linux)"
  fi
} >"$SNAPSHOT_FILE"

cp "$SNAPSHOT_FILE" "$LATEST_FILE"
echo "Saved brew version snapshots:"
echo "  - $SNAPSHOT_FILE"
echo "  - $LATEST_FILE"
