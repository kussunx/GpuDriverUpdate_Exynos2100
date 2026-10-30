#!/bin/sh
# Compare the two working Mali r38p1 blobs against the preserved baseline.
# Requires Git and a full checkout. Does not modify either binary.
set -eu

REPO_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$REPO_DIR"

check_blob() {
  path=$1
  expected=$2
  [ -f "$path" ] || { printf 'Missing: %s\n' "$path" >&2; return 1; }
  actual=$(git hash-object "$path")
  if [ "$actual" != "$expected" ]; then
    printf 'Unexpected Mali binary: %s\nExpected Git blob: %s\nActual Git blob:   %s\n' \
      "$path" "$expected" "$actual" >&2
    return 1
  fi
  printf 'Unchanged: %s (%s)\n' "$path" "$actual"
}

check_blob system/vendor/lib/egl/libGLES_mali.so \
  7c995c0071165fa0b5646af1301ce3d8046be2b0
check_blob system/vendor/lib64/egl/libGLES_mali.so \
  4b136a06e09aa170883e958ceaa616de88638aef
