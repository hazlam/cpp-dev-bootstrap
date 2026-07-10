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
   `ninja`, `ccache`, `git`.
2. Clones and bootstraps [vcpkg](https://github.com/microsoft/vcpkg) to
   `~/vcpkg` (or `$VCPKG_ROOT` if already set).
3. Adds `VCPKG_ROOT`/`PATH` exports to `~/.bashrc` and `~/.zshrc` (whichever
   exist), skipping the file if it's already configured.

Only the `pacman` branch has been exercised end-to-end (this repo was built on
Arch); the `apt-get` and `brew` branches follow the same shape but should be
sanity-checked the first time you bootstrap a Debian/Ubuntu or macOS machine.

After bootstrapping, restart your shell (or `source ~/.bashrc`) so
`VCPKG_ROOT` takes effect.

## Platform notes (Arch / WSL2 / macOS — no native Windows)

- **Arch** (native or WSL2): primary platform, tested end-to-end.
- **WSL**: use WSL2 — sanitizers and ptrace-based debugging (lldb) are
  unreliable on WSL1. Keep projects on the Linux filesystem (`~/...`), not
  `/mnt/c/...`: builds are dramatically faster and tooling behaves.
- **Debian/Ubuntu** (incl. WSL2 Ubuntu): the distro's default toolchain may
  be too old for C++23. `std::println`/`<print>` (used in the template's
  hello world) needs libstdc++ from GCC 14+ or a recent libc++ — on Ubuntu
  24.04 that means installing a newer compiler (`gcc-14`, or clang from
  [apt.llvm.org](https://apt.llvm.org)) before `make build` succeeds, or
  temporarily swapping the hello world to `<iostream>`.
- **macOS**:
  - Homebrew's `llvm` is keg-only; bootstrap prints the exact `PATH` line to
    add so `clang++`/`clang-tidy` resolve to it.
  - `make run-msan` is **Linux-only** — MemorySanitizer does not support
    macOS. LeakSanitizer is also limited/off on macOS; ASan+UBSan
    (`make build`) and TSan (`make run-tsan`) work fine.
  - If Homebrew's `lldb` fails to attach (code-signing), use the system one:
    `/usr/bin/lldb` from `xcode-select --install`.
  - Apple ships GNU make 3.81 (2006). The template Makefile sticks to
    old-make features, but if a target ever misbehaves there,
    `brew install make` and run `gmake` instead.

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
