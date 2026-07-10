# app

Starter template: CMake + Ninja + Clang, driven by a thin `Makefile`.

## Usage

```sh
make build     # Debug build with ASan + UBSan (default)
make run       # build + run ./build/app
make test      # ctest
make debug     # plain debug build (no sanitizers) + open in lldb
make debug-san # ASan+UBSan build + open in lldb (see caveat below)
make format    # clang-format src/
make tidy      # clang-tidy src/
make release   # optimized build, no sanitizers -> build-release/app
make debug-tsan # ThreadSanitizer build (own dir) -> build-tsan/app
make debug-msan # MemorySanitizer build (own dir, clang-only, best-effort)
make clean     # remove all build dirs
```

Compare against GCC any time with `make CXX=g++ CC=gcc build`.

## Sanitizers

`build`, `debug-tsan`, and `debug-msan` each configure into their own build
directory (`build/`, `build-tsan/`, `build-msan/`) because these sanitizer
sets cannot be linked together:

- **ASan + UBSan** (+ LeakSanitizer, bundled with ASan) — default `make build`.
  Catches out-of-bounds access, use-after-free, leaks, signed overflow,
  misaligned access, etc. Good default for most learning projects.
- **TSan** (`make debug-tsan`) — data races across threads. Use for the
  concurrency projects.
- **MSan** (`make debug-msan`) — reads of uninitialized memory. Clang-only. Can
  produce false positives if code links against a non-MSan-instrumented
  standard library; treat findings as a lead to investigate, not gospel.

There's no combined "every sanitizer at once" build — TSan and MSan are each
incompatible with ASan/UBSan and with each other, so they can never share a
binary. That's also why debugging is split in two: `make debug` (plain, no
sanitizers — best for ordinary logic bugs, no instrumentation noise) vs.
`make debug-san` (the ASan+UBSan build under lldb, e.g. to catch a sanitizer
abort and inspect state at the point of failure). `debug-san` disables
LeakSanitizer's exit-time scan, since LSan's own use of ptrace conflicts with
lldb ptracing the same process. `debug-tsan`/`debug-msan` run their binary
directly (no lldb attached) and print a report on failure, same as before.

Note: `make tidy`'s `clang-analyzer-*` checks trace into standard-library headers
(e.g. `<print>`/`<format>`) when your code calls into them, which is slow and prints a
lot of "suppressed warnings in non-user code" noise. That's expected — it still
finishes and only surfaces findings for your own code.

## Adding a dependency (vcpkg)

1. Add the port name to `vcpkg.json`'s `"dependencies"` array, e.g. `"fmt"`.
2. In `CMakeLists.txt`:
   ```cmake
   find_package(fmt CONFIG REQUIRED)
   target_link_libraries(app PRIVATE fmt::fmt)
   ```
3. `make build` — vcpkg fetches and builds it automatically via the
   toolchain file (requires `VCPKG_ROOT` to be set in your shell).

## Starting a new project from this template

```sh
~/Projects/cpp/cpp-starter/new-project.sh ~/Projects/cpp/<project-name>
```

Or by hand:

```sh
cp -r ~/Projects/cpp/cpp-starter/template ~/Projects/cpp/<project-name>
cd ~/Projects/cpp/<project-name>
git init
```
