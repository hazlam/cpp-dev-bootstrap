cmake_minimum_required(VERSION 3.25)
project(app LANGUAGES CXX)

# --- Language standard -------------------------------------------------
set(CMAKE_CXX_STANDARD 23)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

# Needed by clangd / editor tooling for accurate diagnostics.
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

if(NOT CMAKE_BUILD_TYPE)
  set(CMAKE_BUILD_TYPE Debug)
endif()

# --- Executable ----------------------------------------------------------
add_executable(app src/main.cpp)

target_compile_options(app PRIVATE
  -Wall -Wextra -Wpedantic -Wshadow -Wconversion
)

# --- Standard library ------------------------------------------------------
# C++23 <print>/std::println needs a recent stdlib. With Clang we standardize
# on libc++ (opt in explicitly; Clang otherwise defaults to the system
# libstdc++, which is too old on Debian/Ubuntu). GCC uses its own libstdc++
# (needs >= 14). Toggle with -DUSE_LIBCXX=OFF if you have a new-enough libstdc++.
option(USE_LIBCXX "Compile/link against libc++ (Clang only)" ON)
if(USE_LIBCXX AND CMAKE_CXX_COMPILER_ID MATCHES "Clang")
  target_compile_options(app PRIVATE -stdlib=libc++)
  target_link_options(app PRIVATE -stdlib=libc++)
endif()

# --- Sanitizers ------------------------------------------------------------
# Selectable via -DSANITIZE=<set>. The Makefile picks the right value and a
# dedicated build directory per target, since these sets are mutually
# incompatible at link/runtime and must never be mixed in one build:
#   address,undefined  -- ASan + UBSan (+ LeakSanitizer, bundled with ASan).
#                          Default for `make build`. Good all-rounder for the
#                          pointer/memory/move-semantics chapters.
#   thread              -- ThreadSanitizer. Incompatible with ASan. Own build
#                          dir via `make run-tsan`, for the threading
#                          projects.
#   memory              -- MemorySanitizer (uninitialized reads). Clang-only,
#                          incompatible with ASan/TSan. Own build dir via
#                          `make run-msan`. Best-effort: can be noisy unless
#                          the whole standard library is also MSan-instrumented.
#   none                -- no sanitizers (used by `make release`).
set(SANITIZE "address,undefined" CACHE STRING
    "Sanitizer set: address,undefined | thread | memory | none")

if(NOT SANITIZE STREQUAL "none")
  target_compile_options(app PRIVATE -fsanitize=${SANITIZE} -fno-omit-frame-pointer -g)
  target_link_options(app PRIVATE -fsanitize=${SANITIZE})
endif()

# --- Dependencies (vcpkg) ---------------------------------------------
# Add packages to vcpkg.json, then e.g.:
#   find_package(fmt CONFIG REQUIRED)
#   target_link_libraries(app PRIVATE fmt::fmt)

# --- Tests -----------------------------------------------------------------
enable_testing()
# Add tests as you reach the testing chapter, e.g.:
#   add_test(NAME app_smoke COMMAND app)
