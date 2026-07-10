# app

Starter template: CMake + Ninja + Clang, driven by a thin `Makefile`.

## Usage

```sh
make build     # Debug build with ASan + UBSan (default)
make run       # build + run ./build/app
make test      # ctest
make debug     # plain debug build (no sanitizers) + open in lldb
make run-tsan  # ThreadSanitizer build + run (own dir) -> build-tsan/app
make run-msan  # MemorySanitizer build + run (own dir, clang-only, Linux-only)
make release   # optimized build, no sanitizers -> build-release/app
make format    # clang-format src/
make tidy      # clang-tidy src/
make clean     # remove all build dirs
```

Compare against GCC any time with `make CXX=g++ build`.

C++23 `<print>`/`std::println` needs a recent stdlib, so with Clang the build
links `libc++` (`-stdlib=libc++`, `USE_LIBCXX` in `CMakeLists.txt`) instead of
whatever libstdc++ the distro ships — `bootstrap.sh` installs both a modern
clang and libc++ together for this reason. Pass `-DUSE_LIBCXX=OFF` (e.g.
`cmake -B build -DUSE_LIBCXX=OFF`) if your system libstdc++ is GCC 14+ and
you'd rather use that. With `make CXX=g++`, GCC always uses its own libstdc++
regardless of this flag — you'll need GCC 14+ for `<print>` to exist.

## Sanitizers

`build`, `run-tsan`, and `run-msan` each configure into their own build
directory (`build/`, `build-tsan/`, `build-msan/`) because these sanitizer
sets cannot be linked together:

- **ASan + UBSan** (+ LeakSanitizer, bundled with ASan) — default `make build`
  and `make run`. Catches out-of-bounds access, use-after-free, leaks, signed
  overflow, misaligned access, etc. Good default for most learning projects.
- **TSan** (`make run-tsan`) — data races across threads. Use for the
  concurrency projects.
- **MSan** (`make run-msan`) — reads of uninitialized memory. Clang-only and
  **Linux-only** (MemorySanitizer doesn't support macOS). Can produce false
  positives if code links against a non-MSan-instrumented standard library;
  treat findings as a lead to investigate, not gospel. On macOS, LeakSanitizer
  is also limited/off — ASan+UBSan and TSan work fine there.

There's no combined "every sanitizer at once" build — TSan and MSan are each
incompatible with ASan/UBSan and with each other, so they can never share a
binary.

`make debug` is the only target that opens lldb, and it uses a plain,
sanitizer-free build (`build-debug/`) so nothing interrupts your
step-through. If you specifically want lldb on the sanitized binary (e.g. to
inspect state right where ASan aborts), run it by hand with LeakSanitizer's
exit-time scan disabled — LSan's ptrace use conflicts fatally with lldb
ptracing the same process:

```sh
ASAN_OPTIONS=detect_leaks=0 lldb ./build/app
```

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
~/Projects/cpp/cpp-dev-bootstrap/new-project.sh ~/Projects/cpp/<project-name>
```

Or by hand:

```sh
cp -r ~/Projects/cpp/cpp-dev-bootstrap/template ~/Projects/cpp/<project-name>
cd ~/Projects/cpp/<project-name>
git init
```
