# --------------------------------------------------
# 00-env.zsh
# Purpose:
# 	Sets the default OS as well as env variables for 
# 	mac and linux
# --------------------------------------------------
unalias -- '-h' '--help' '-help' 'help' 2>/dev/null;

case "$(uname -s)" in
  Darwin)
    export OS_TYPE="macos"
    ;;
  Linux)
    export OS_TYPE="linux"
    ;;
esac

export PAGER="nvim +Man!"
