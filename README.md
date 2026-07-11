# cpp-dev-bootstrap

A portable C++ dev environment: Clang/LLVM toolchain + CMake/Ninja + vcpkg + a
project template with sanitizer-backed debug builds. `git clone` this repo and
run one script to get the same setup on any machine.

## Bootstrap a new machine

```sh
git clone git@github.com:hazlam/cpp-dev-bootstrap.git ~/Projects/cpp/cpp-dev-bootstrap
cd ~/Projects/cpp/cpp-dev-bootstrap
./bootstrap.sh
```

`bootstrap.sh` is safe to re-run — every step is idempotent. It:

1. Installs the toolchain via whichever package manager it finds
   (`pacman`, `apt-get`, or `brew`): `clang`, `llvm`, `lldb`, `lld`, `cmake`,
   `ninja`, `ccache`, `git`. The kit standardizes on **Clang + libc++**: on
   `apt-get` systems it pulls a pinned modern LLVM from
   [apt.llvm.org](https://apt.llvm.org) (default major version 22, override
   with `LLVM_VERSION=20 ./bootstrap.sh`) rather than the distro's own
   `clang` package, since Ubuntu's default is years behind and too old for
   C++23 `<print>`/`std::println`. `update-alternatives` then points
   unversioned `clang`/`clang++`/`clang-tidy`/`clang-format`/`lldb` at it, so
   the template's `Makefile` (`CXX := clang++`) needs no changes per distro.
2. Clones and bootstraps [vcpkg](https://github.com/microsoft/vcpkg) to
   `~/vcpkg` (or `$VCPKG_ROOT` if already set).
3. Adds `VCPKG_ROOT`/`PATH` exports to `~/.bashrc` and `~/.zshrc` (whichever
   exist), skipping the file if it's already configured.

The `pacman` branch (Arch) is the primary platform. The `apt-get`
(Debian/Ubuntu, see #1/#2) and `brew` (macOS, see #3) branches have since been
exercised end-to-end on real machines — each has a workflow under
`.github/workflows/` that re-runs the real `bootstrap.sh` plus a fresh
`new-project.sh` scaffold build on every push, so all three paths stay covered.

After bootstrapping, restart your shell (or `source ~/.bashrc` on bash /
`source ~/.zshrc` on zsh, e.g. macOS) so `VCPKG_ROOT` takes effect.

## Platform notes (Arch / WSL2 / macOS — no native Windows)

- **Arch** (native or WSL2): primary platform, tested end-to-end.
- **WSL**: use WSL2 — sanitizers and ptrace-based debugging (lldb) are
  unreliable on WSL1. Keep projects on the Linux filesystem (`~/...`), not
  `/mnt/c/...`: builds are dramatically faster and tooling behaves.
- **Debian/Ubuntu** (incl. WSL2 Ubuntu): `bootstrap.sh` handles the toolchain
  gap automatically now (see above) — it installs a pinned modern
  clang + libc++ from apt.llvm.org and wires up `update-alternatives`, so
  `make build`/`make run` work with C++23 `<print>`/`std::println` out of the
  box. The template's `CMakeLists.txt` passes `-stdlib=libc++` to Clang for
  the same reason (`-DUSE_LIBCXX=OFF` to fall back to system libstdc++ if
  it's GCC 14+ and new enough).
- **macOS** (Apple Silicon, tested end-to-end on macOS 26 / Homebrew LLVM 22):
  - Homebrew's `llvm` is keg-only; bootstrap prints the exact `PATH` line to
    add so `clang++`/`clang-tidy` resolve to it.
  - `make run-msan` is **Linux-only** — MemorySanitizer does not support
    macOS (it fails at compile time with a clear "unsupported option" error).
    LeakSanitizer is also limited/off on macOS; ASan+UBSan (`make build`) and
    TSan (`make run-tsan`) work fine.
  - Homebrew's `lldb` attached and ran fine in testing (`make debug`). If it
    ever fails to attach on your machine (code-signing/SIP), fall back to the
    system one: `/usr/bin/lldb` from `xcode-select --install`.
  - Apple ships GNU make 3.81 (2006); the template Makefile is verified against
    it, so the default `/usr/bin/make` works — no `brew install make` / `gmake`
    needed.

## Start a new project

```sh
./new-project.sh ~/Projects/cpp/01-unit-converter
cd ~/Projects/cpp/01-unit-converter
make run
```

Or do it by hand:

```sh
cp -r template ~/Projects/cpp/<project-name>
cd ~/Projects/cpp/<project-name>
git init
```

Each project is its own repo, seeded from `template/` — see
[`template/README.md`](template/README.md) for the full `make` command
reference (build/run/test/debug/sanitizers/vcpkg deps).
