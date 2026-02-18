# --------------------------------------------------
# ghostty-transparency.zsh
# Purpose:
#   Toggle or set Ghostty background transparency from the shell.
# Usage:
#   ghostty-transparency          # toggle between opaque and transparent presets
#   ghostty-transparency on 0.9 8 # enable with opacity and blur
#   ghostty-transparency off      # disable transparency (opacity 1)
# Environment:
#   GHOSTTY_TRANSPARENT_OPACITY - default opacity when enabling (default: 0.9)
#   GHOSTTY_TRANSPARENT_BLUR    - default blur radius when enabling (default: 12)
# --------------------------------------------------

_ghostty_transparency_config_path() {
  printf '%s\n' "${GHOSTTY_CONFIG:-$HOME/.config/ghostty/config}"
}

_ghostty_transparency_current_opacity() {
  local cfg
  cfg="$(_ghostty_transparency_config_path)"
  [ -f "$cfg" ] || return 1
  awk -F'= *' '
    /^[[:space:]]*#?[[:space:]]*background-opacity[[:space:]]*=/ {
      val=$2; gsub(/^[[:space:]]+|[[:space:]]+$/, "", val); print val; exit
    }
  ' "$cfg"
}

_ghostty_transparency_write() {
  local opacity="$1" blur="$2" cfg tmp
  cfg="$(_ghostty_transparency_config_path)"

  if [ ! -f "$cfg" ]; then
    echo "Ghostty config not found at: $cfg" >&2
    return 1
  fi

  tmp="$(mktemp "${TMPDIR:-/tmp}/ghostty-config.XXXXXX")" || return 1

  awk -v opacity="$opacity" -v blur="$blur" '
    BEGIN {rop=0; rbl=0}
    {
      if ($0 ~ /^[[:space:]]*#?[[:space:]]*background-opacity[[:space:]]*=/ && rop==0) {
        print "background-opacity = " opacity
        rop=1; next
      }
      if ($0 ~ /^[[:space:]]*#?[[:space:]]*background-blur-radius[[:space:]]*=/ && rbl==0) {
        if (blur != "") { print "background-blur-radius = " blur } else { next }
        rbl=1; next
      }
      print
    }
    END {
      if (rop==0) print "background-opacity = " opacity
      if (blur != "" && rbl==0) print "background-blur-radius = " blur
    }
  ' "$cfg" > "$tmp" && mv "$tmp" "$cfg"
}

ghostty-transparency() {
  local action="$1" op blur msg current
  shift || true

  local default_opacity="${GHOSTTY_TRANSPARENT_OPACITY:-0.8}"
  local default_blur="${GHOSTTY_TRANSPARENT_BLUR:-10}"

  current="$(_ghostty_transparency_current_opacity)"
  [ -z "$current" ] && current=1

  case "$action" in
    ""|toggle)
      if awk "BEGIN{exit !($current < 1)}"; then
        _ghostty_transparency_write 1 "" || return 1
        msg="Ghostty transparency disabled (opacity 1)"
      else
        _ghostty_transparency_write "$default_opacity" "$default_blur" || return 1
        msg="Ghostty transparency enabled (opacity $default_opacity, blur $default_blur)"
      fi
      ;;
    on)
      op="${1:-$default_opacity}"
      blur="${2:-$default_blur}"
      _ghostty_transparency_write "$op" "$blur" || return 1
      msg="Ghostty transparency enabled (opacity $op, blur $blur)"
      ;;
    off)
      _ghostty_transparency_write 1 "" || return 1
      msg="Ghostty transparency disabled (opacity 1)"
      ;;
    *)
      echo "Usage: ghostty-transparency [on [opacity [blur]]] | off | toggle" >&2
      return 1
      ;;
  esac

  echo "$msg"
}
