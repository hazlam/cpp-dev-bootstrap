#!/usr/bin/env bash
# Scaffold a new C++ project from the template and git-init it.
#
# Usage: ./new-project.sh <path-to-new-project>
#   e.g. ./new-project.sh ~/Projects/cpp/01-unit-converter

set -euo pipefail

if [ $# -ne 1 ]; then
  echo "Usage: $0 <path-to-new-project>" >&2
  exit 1
fi

dest="$1"
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ -e "$dest" ]; then
  echo "Error: $dest already exists." >&2
  exit 1
fi

cp -r "$here/template" "$dest"
cd "$dest"
git init

echo "Created $dest (git initialized). Next: cd $dest && make run"
