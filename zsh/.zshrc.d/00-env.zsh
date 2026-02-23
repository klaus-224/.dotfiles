# --------------------------------------------------
# 00-env.zsh
# Purpose:
# 	Sets the default OS as well as env variables for 
# 	mac and linux
# --------------------------------------------------

case "$(uname -s)" in
  Darwin)
    export OS_TYPE="macos"
    ;;
  Linux)
    export OS_TYPE="linux"
    ;;
esac

export PAGER="nvim +Man!"

