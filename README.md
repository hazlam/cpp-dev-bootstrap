# cpp-starter

A portable C++ dev environment: Clang/LLVM toolchain + CMake/Ninja + vcpkg + a
project template with sanitizer-backed debug builds. `git clone` this repo and
run one script to get the same setup on any machine.

## Bootstrap a new machine

```sh
git clone <this-repo-url> ~/Projects/cpp/cpp-starter
cd ~/Projects/cpp/cpp-starter
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
macOS's Homebrew `llvm` is keg-only — the script prints the exact `PATH` line
you need to add manually.

After bootstrapping, restart your shell (or `source ~/.bashrc`) so
`VCPKG_ROOT` takes effect.

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
