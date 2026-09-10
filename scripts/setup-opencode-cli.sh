#!/usr/bin/env bash
set -euo pipefail

DOTFILES_HOME="${DOTFILES_HOME:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
OPENCODE_CONFIG_DIR="${OPENCODE_CONFIG_DIR:-$DOTFILES_HOME/opencode}"

export DOTFILES_HOME
export OPENCODE_CONFIG_DIR

if [[ ! -d "$OPENCODE_CONFIG_DIR" ]]; then
  echo "Error: missing OpenCode configuration directory: $OPENCODE_CONFIG_DIR" >&2
  exit 1
fi

for required in \
  opencode.work.jsonc \
  opencode.personal.jsonc \
  omo.jsonc \
  package.json; do
  if [[ ! -f "$OPENCODE_CONFIG_DIR/$required" ]]; then
    echo "Error: missing $OPENCODE_CONFIG_DIR/$required" >&2
    exit 1
  fi
done

if [[ "$OPENCODE_CONFIG_DIR" != "$DOTFILES_HOME/opencode" ]]; then
  echo "Error: refusing to configure an unrelated OpenCode directory: $OPENCODE_CONFIG_DIR" >&2
  exit 1
fi

if ! command -v brew >/dev/null 2>&1; then
  echo "Error: Homebrew is required to install OpenCode." >&2
  exit 1
fi

if ! command -v opencode >/dev/null 2>&1; then
  echo "Installing OpenCode..."
  brew install opencode
fi

required_opencode_version="1.4.0"
installed_opencode_version="$(opencode --version)"
if ! node -e '
  const parse = (value) => value.match(/\d+/g)?.slice(0, 3).map(Number) ?? [];
  const current = parse(process.argv[1]);
  const required = parse(process.argv[2]);
  for (let index = 0; index < 3; index += 1) {
    if ((current[index] ?? 0) === (required[index] ?? 0)) continue;
    process.exit((current[index] ?? 0) < (required[index] ?? 0) ? 1 : 0);
  }
' "$installed_opencode_version" "$required_opencode_version"; then
  echo "Error: OpenCode $required_opencode_version or newer is required; found $installed_opencode_version." >&2
  exit 1
fi

omo_dir="${OMO_CONFIG_DIR:-$HOME/.omo}"
omo_config="$omo_dir/omo.jsonc"
repo_omo_config="$OPENCODE_CONFIG_DIR/omo.jsonc"
if [[ ! -e "$omo_dir" ]]; then
  mkdir -p "$omo_dir"
fi
if [[ -L "$omo_config" ]]; then
  linked_omo_config="$(readlink "$omo_config")"
  if [[ "$linked_omo_config" != "$repo_omo_config" ]]; then
    echo "Error: refusing to replace unrelated OMO config symlink: $omo_config -> $linked_omo_config" >&2
    exit 1
  fi
elif [[ -e "$omo_config" ]]; then
  echo "Error: refusing to overwrite unrelated OMO config: $omo_config" >&2
  exit 1
else
  ln -s "$repo_omo_config" "$omo_config"
fi

echo "Installing local OpenCode tool dependencies..."
npm ci --prefix "$OPENCODE_CONFIG_DIR" --ignore-scripts

echo "Validating OpenCode and OMO configuration..."
npm test --prefix "$OPENCODE_CONFIG_DIR"
for profile in work personal; do
  OMO_PROFILE="$profile" \
  OMO_DISABLE_POSTHOG=1 \
  OPENCODE_CONFIG="$OPENCODE_CONFIG_DIR/opencode.$profile.jsonc" \
    opencode debug config >/dev/null
done

echo "OpenCode setup ready:"
echo "  DOTFILES_HOME=$DOTFILES_HOME"
echo "  OPENCODE_CONFIG_DIR=$OPENCODE_CONFIG_DIR"
echo "  Work profile: $OPENCODE_CONFIG_DIR/opencode.work.jsonc"
echo "  Personal profile: $OPENCODE_CONFIG_DIR/opencode.personal.jsonc"
echo "  OMO config: $omo_config -> $repo_omo_config"
echo "Source $DOTFILES_HOME/zsh/.zshenv before launching OpenCode."
