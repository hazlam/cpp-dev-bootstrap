# Thin CLI wrapper around CMake + Ninja. CMake describes the build (see
# CMakeLists.txt); this Makefile just standardizes the commands you run.
#
# Sanitizer sets are mutually incompatible at runtime, so each gets its own
# build directory and target: `build` (ASan+UBSan, default), `debug-tsan`,
# `debug-msan`, `release` (none). See CMakeLists.txt for details.

# NOTE: plain `:=`, not `?=` -- GNU Make has a built-in default value for CXX
# (g++) at "default" origin, so `?=` (which only fires when a variable is
# fully undefined) would never override it. Command-line overrides (e.g.
# `make CXX=g++ build`) still win over this, since command-line origin beats
# a plain in-file assignment. (Project is CXX-only, no C sources, so there's
# no CC to set.)
CXX := clang++

BUILD_DIR   := build
DEBUG_DIR   := build-debug
TSAN_DIR    := build-tsan
MSAN_DIR    := build-msan
RELEASE_DIR := build-release

ifdef VCPKG_ROOT
VCPKG_TOOLCHAIN := -DCMAKE_TOOLCHAIN_FILE=$(VCPKG_ROOT)/scripts/buildsystems/vcpkg.cmake
endif

# Recursively expanded so target-specific $(CXX) overrides (e.g. debug-msan)
# are picked up correctly.
CMAKE_COMMON = -G Ninja -DCMAKE_CXX_COMPILER=$(CXX) $(VCPKG_TOOLCHAIN)

# Clearer sanitizer crash reports.
UBSAN_OPTIONS ?= print_stacktrace=1
ASAN_OPTIONS  ?= abort_on_error=1
export UBSAN_OPTIONS ASAN_OPTIONS

.PHONY: build run debug-tsan debug-msan release test format tidy debug debug-san clean

## Default debug build: ASan + UBSan (+ LeakSanitizer).
build:
	cmake -S . -B $(BUILD_DIR) $(CMAKE_COMMON) -DCMAKE_BUILD_TYPE=Debug -DSANITIZE=address,undefined
	cmake --build $(BUILD_DIR)

run: build
	./$(BUILD_DIR)/app

## ThreadSanitizer, separate build dir (incompatible with ASan).
debug-tsan:
	cmake -S . -B $(TSAN_DIR) $(CMAKE_COMMON) -DCMAKE_BUILD_TYPE=Debug -DSANITIZE=thread
	cmake --build $(TSAN_DIR)
	./$(TSAN_DIR)/app

## MemorySanitizer, Clang-only, separate build dir. Best-effort: can be
## noisy without an MSan-instrumented standard library. `override` forces
## clang++ here even if the caller passed `make CXX=g++`, since MSan is a
## Clang-only feature -- command-line variables normally beat target-specific
## ones, so a plain `:=` here would silently be ignored under that call.
debug-msan: override CXX := clang++
debug-msan:
	cmake -S . -B $(MSAN_DIR) $(CMAKE_COMMON) -DCMAKE_BUILD_TYPE=Debug -DSANITIZE=memory
	cmake --build $(MSAN_DIR)
	./$(MSAN_DIR)/app

## Optimized build, no sanitizers.
release:
	cmake -S . -B $(RELEASE_DIR) $(CMAKE_COMMON) -DCMAKE_BUILD_TYPE=Release -DSANITIZE=none
	cmake --build $(RELEASE_DIR)

test: build
	ctest --test-dir $(BUILD_DIR) --output-on-failure

format:
	clang-format -i src/*.cpp src/*.h 2>/dev/null || true

tidy: build
	clang-tidy -p $(BUILD_DIR) src/*.cpp

## Plain debug build: no sanitizers, unoptimized, full symbols. Own build
## dir so it never gets stale sanitizer instrumentation left over from
## `build`. Use this for ordinary logic bugs -- no redzones, no sanitizer
## aborts interrupting your step-through.
debug:
	cmake -S . -B $(DEBUG_DIR) $(CMAKE_COMMON) -DCMAKE_BUILD_TYPE=Debug -DSANITIZE=none
	cmake --build $(DEBUG_DIR)
	lldb ./$(DEBUG_DIR)/app

## Debug the ASan+UBSan build interactively, e.g. to catch a sanitizer abort
## and inspect state right at the point of failure. LeakSanitizer (bundled
## with ASan) scans for leaks at exit via ptrace, which conflicts with lldb
## also ptracing the process -- causes a fatal LSan error ("LeakSanitizer has
## encountered a fatal error") the moment the program runs under the
## debugger. ASan/UBSan's own checks still work fine under lldb; only the
## exit-time leak scan needs disabling here. Note: `debug-tsan`/`debug-msan`
## builds can't be folded in here too -- they're mutually incompatible with
## ASan/UBSan and with each other, which is why they're separate build dirs
## to begin with.
debug-san: export ASAN_OPTIONS := $(ASAN_OPTIONS):detect_leaks=0
debug-san: build
	lldb ./$(BUILD_DIR)/app

clean:
	rm -rf $(BUILD_DIR) $(DEBUG_DIR) $(TSAN_DIR) $(MSAN_DIR) $(RELEASE_DIR)
