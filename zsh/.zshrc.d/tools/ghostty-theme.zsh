# --------------------------------------------------
# ghostty-theme.zsh
# Purpose:
#   Pick and set a Ghostty theme from the terminal.
#
# Usage:
#   ghostty-theme --pick
#   ghostty-theme "Builtin Solarized Dark"
# --------------------------------------------------

_ghostty_theme_config_path() {
  printf '%s\n' "${GHOSTTY_CONFIG:-$HOME/.config/ghostty/config}"
}

_ghostty_theme_list() {
  if command -v ghostty >/dev/null 2>&1; then
    ghostty +list-themes 2>/dev/null | sed 's/ (resources)$//'
    return 0
  fi

  # Fallback when ghostty binary is unavailable.
  local cfg
  cfg="$(_ghostty_theme_config_path)"
  if [ -f "$cfg" ]; then
    awk -F'= ' '/^[[:space:]]*#?[[:space:]]*theme[[:space:]]*=/ {print $2}' "$cfg" | sed '/^$/d'
  fi
}

_ghostty_theme_write() {
  local theme="$1"
  local cfg tmp

  cfg="$(_ghostty_theme_config_path)"

  if [ ! -f "$cfg" ]; then
    echo "Ghostty config not found at: $cfg" >&2
    return 1
  fi

  tmp="$(mktemp "${TMPDIR:-/tmp}/ghostty-config.XXXXXX")" || return 1

  awk -v new_theme="$theme" '
    BEGIN { replaced = 0 }
    {
      if ($0 ~ /^[[:space:]]*#?[[:space:]]*theme[[:space:]]*=/ && replaced == 0) {
        print "theme = " new_theme
        replaced = 1
        next
      }
      print
    }
    END {
      if (replaced == 0) {
        print ""
        print "theme = " new_theme
      }
    }
  ' "$cfg" > "$tmp" || {
    rm -f "$tmp"
    return 1
  }

  mv "$tmp" "$cfg"
}

ghostty-theme() {
  local theme="$*"

  if [ "$1" = "-p" ] || [ "$1" = "--pick" ] || [ -z "$theme" ]; then
    if command -v fzf >/dev/null 2>&1; then
      theme="$(_ghostty_theme_list | fzf --height=70% --layout=reverse --prompt='Ghostty Theme> ' --header='Select a Ghostty theme')"
    else
      echo "fzf is required for interactive selection. Pass a theme name directly instead." >&2
      return 1
    fi
  fi

  if [ -z "$theme" ]; then
    echo "No theme selected." >&2
    return 1
  fi

  _ghostty_theme_write "$theme" || return 1

  if [ -n "$TMUX" ] && command -v tmux >/dev/null 2>&1; then
    tmux source-file "${TMUX_CONFIG:-$HOME/.tmux.conf}" 2>/dev/null || true
    tmux display-message "Ghostty theme set to: $theme" 2>/dev/null || true
  fi

  echo "Ghostty theme set to: $theme"
}
