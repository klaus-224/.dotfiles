# --------------------------------------------------
# aws-utils.zsh
# Purpose:
#   AWS CLI helpers.
# --------------------------------------------------

function _aws_cli_auth(){
	aws login
}

function _aws_require_cli() {
  if command -v aws >/dev/null 2>&1; then
    return 0
  fi

  echo "aws CLI not found. Install it and configure credentials first." >&2
  return 1
}

function _aws_s3_normalize_uri() {
  local s3_path="$1"

  if [[ "$s3_path" == s3://* ]]; then
    echo "${s3_path%/}"
    return 0
  fi

  echo "s3://${s3_path#/}"
}

function aws_s3_download_all() {
  local s3_path destination
  local -a extra_args

  if (( $# < 1 )); then
    cat <<'EOF' >&2
Usage:
  aws_s3_download_all <s3://bucket/prefix> [destination] [aws s3 sync args...]

Examples:
  aws_s3_download_all s3://my-bucket/path ./downloads
  aws_s3_download_all my-bucket/path ./downloads --profile prod --dryrun
EOF
    return 1
  fi

  _aws_require_cli || return 1
	_aws_cli_auth

  s3_path="$(_aws_s3_normalize_uri "$1")"
  shift

  destination="${1:-.}"
  if (( $# > 0 )); then
    shift
  fi

  extra_args=("$@")

  echo "Downloading ${s3_path} -> ${destination}" >&2
  aws s3 sync "$s3_path" "$destination" "${extra_args[@]}"
}
