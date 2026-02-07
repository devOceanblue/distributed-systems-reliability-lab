#!/usr/bin/env sh
set -e

if ! command -v gradle >/dev/null 2>&1; then
  echo "gradle command not found. Install Gradle to use this lightweight wrapper." >&2
  exit 1
fi

exec gradle "$@"
