#!/usr/bin/env bash
set -euo pipefail

profile="${1:-work}"
if [[ "$profile" != "work" && "$profile" != "personal" ]]; then
  echo "Usage: $0 [work|personal] [opencode arguments...]" >&2
  exit 2
fi
shift || true

DOTFILES_HOME="${DOTFILES_HOME:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
config_dir="$DOTFILES_HOME/opencode"
source_config="$config_dir/opencode.$profile.jsonc"
temporary_config="$(mktemp "$config_dir/.opencode.slim.$profile.XXXXXX")"
trap 'rm -f "$temporary_config"' EXIT

node - "$source_config" "$temporary_config" <<'NODE'
const { readFileSync, writeFileSync } = require("node:fs");
const { parse } = require(process.argv[2].replace(/opencode\.[^.]+\.jsonc$/, "node_modules/jsonc-parser"));

const config = parse(readFileSync(process.argv[2], "utf8"));
config.plugin = config.plugin.map((entry) =>
  typeof entry === "string" && entry.startsWith("oh-my-openagent@")
    ? "oh-my-opencode-slim@2.2.18"
    : entry,
);
writeFileSync(process.argv[3], `${JSON.stringify(config, null, 2)}\n`);
NODE

export OPENCODE_CONFIG_DIR="$config_dir"
export OPENCODE_CONFIG="$temporary_config"
export OH_MY_OPENCODE_SLIM_PRESET="$profile"
unset OMO_PROFILE

opencode "$@"
