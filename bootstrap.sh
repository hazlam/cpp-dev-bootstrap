#!/usr/bin/env bash
# Bootstrap a C++ dev environment: Clang/LLVM toolchain, CMake/Ninja, lldb,
# ccache, and vcpkg (manifest mode). Safe to re-run — every step is
# idempotent, so running this again on an already-provisioned machine should
# be a no-op (aside from re-confirming package versions with your package
# manager).
#
# Usage: ./bootstrap.sh

set -euo pipefail

VCPKG_DIR="${VCPKG_ROOT:-$HOME/vcpkg}"

log() { printf '\n==> %s\n' "$1"; }

# --- 1. System packages -----------------------------------------------------
install_packages() {
  if command -v pacman >/dev/null 2>&1; then
    log "Installing packages via pacman"
    # curl/zip/unzip/tar/pkgconf are vcpkg's own prerequisites for
    # fetching and building ports.
    sudo pacman -S --needed clang llvm lldb lld cmake ninja ccache git \
      curl zip unzip tar pkgconf

  elif command -v apt-get >/dev/null 2>&1; then
    log "Installing packages via apt-get"
    sudo apt-get update
    # Debian/Ubuntu names ninja's package "ninja-build", not "ninja".
    # curl/zip/unzip/tar/pkg-config are vcpkg's prerequisites -- absent on
    # minimal Ubuntu/WSL images, and vcpkg fails without them.
    sudo apt-get install -y clang llvm lldb lld cmake ninja-build ccache git \
      curl zip unzip tar pkg-config

  elif command -v brew >/dev/null 2>&1; then
    log "Installing packages via Homebrew"
    # Homebrew's llvm bundles clang, lldb, lld, clang-format, clang-tidy.
    brew install llvm cmake ninja ccache git
    local llvm_prefix
    llvm_prefix="$(brew --prefix llvm)"
    echo
    echo "NOTE: Homebrew's llvm is keg-only (macOS ships its own old clang)."
    echo "Add this to your shell rc so 'clang++'/'clang-tidy' resolve to Homebrew's:"
    echo "  export PATH=\"$llvm_prefix/bin:\$PATH\""
    echo "For debugging, prefer the system lldb (/usr/bin/lldb, from"
    echo "'xcode-select --install') -- Homebrew's lldb often can't attach"
    echo "due to macOS code-signing restrictions."

  else
    echo "No supported package manager found (looked for pacman, apt-get, brew)." >&2
    echo "Install these manually, then re-run this script to finish vcpkg setup:" >&2
    echo "  clang, llvm, lldb, lld, cmake, ninja, ccache, git" >&2
    exit 1
  fi
}

# --- 2. vcpkg ----------------------------------------------------------------
install_vcpkg() {
  if [ ! -d "$VCPKG_DIR/.git" ]; then
    log "Cloning vcpkg into $VCPKG_DIR"
    git clone --depth 1 https://github.com/microsoft/vcpkg "$VCPKG_DIR"
  else
    log "vcpkg already cloned at $VCPKG_DIR"
  fi

  log "Bootstrapping vcpkg (safe to re-run)"
  "$VCPKG_DIR/bootstrap-vcpkg.sh" -disableMetrics
}

# --- 3. Shell environment ----------------------------------------------------
add_env_block() {
  local rc="$1"
  [ -f "$rc" ] || return 0

  if grep -q "VCPKG_ROOT" "$rc" 2>/dev/null; then
    log "VCPKG_ROOT already configured in $rc"
    return 0
  fi

  log "Adding VCPKG_ROOT to $rc"
  {
    echo ""
    echo "# vcpkg (C++ dependency manager)"
    echo "export VCPKG_ROOT=\"$VCPKG_DIR\""
    echo "export PATH=\"\$VCPKG_ROOT:\$PATH\""
  } >> "$rc"
}

configure_shell() {
  # Create the login shell's rc file if it doesn't exist yet. A fresh macOS
  # account has no ~/.zshrc at all, and add_env_block skips missing files --
  # without this, bootstrap would install everything but never set
  # VCPKG_ROOT, and the failure would only surface later (vcpkg deps
  # silently not resolving at CMake configure time).
  local login_rc=""
  case "$(basename "${SHELL:-}")" in
    bash) login_rc="$HOME/.bashrc" ;;
    zsh)  login_rc="$HOME/.zshrc" ;;
  esac
  if [ -n "$login_rc" ] && [ ! -f "$login_rc" ]; then
    log "Creating $login_rc (login shell rc did not exist)"
    touch "$login_rc"
  fi

  add_env_block "$HOME/.bashrc"
  add_env_block "$HOME/.zshrc"
}

main() {
  install_packages
  install_vcpkg
  configure_shell

  # Quick sanity summary -- on a fresh machine this immediately shows
  # whether anything is missing or resolving to an unexpected version
  # (e.g. Apple clang instead of Homebrew's before the PATH fix).
  log "Installed tool versions"
  local t
  for t in clang++ cmake ninja lldb ccache git; do
    printf '  %-8s %s\n' "$t" \
      "$("$t" --version 2>/dev/null | head -n 1 || echo 'NOT FOUND on PATH')"
  done

  log "Done"
  echo "Restart your shell (or 'source ~/.bashrc') to pick up VCPKG_ROOT."
  echo "Then: cp -r template ~/Projects/cpp/<project-name> && cd ~/Projects/cpp/<project-name> && git init && make run"
}

main "$@"
