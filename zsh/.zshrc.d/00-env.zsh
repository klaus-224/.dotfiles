# --------------------------------------------------
# 00-env.zsh
# Purpose:
#   Detect the operating system once and expose it
#   as an environment variable for later branching.
#
# Sets:
#   OS_TYPE = macos | linux
#
# Rules:
#   - No PATH changes
#   - No tool loading
#   - Pure environment detection only
# --------------------------------------------------

case "$(uname -s)" in
  Darwin)
    export OS_TYPE="macos"
    ;;
  Linux)
    export OS_TYPE="linux"
    ;;
esac
