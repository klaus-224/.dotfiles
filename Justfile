default:
  just --list

sync-brew:
  ./scripts/install-brew-packages.sh

sync-cargo:
  ./scripts/sync-cargo-packages.sh
