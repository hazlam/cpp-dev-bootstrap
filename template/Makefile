# Thin CLI wrapper around CMake + Ninja. CMake describes the build (see
# CMakeLists.txt); this Makefile just standardizes the commands you run.
#
# Sanitizer sets are mutually incompatible at runtime, so each gets its own
# build directory and target: `build` (ASan+UBSan, default), `run-tsan`,
# `run-msan`, `release` (none). `debug` is the only target that opens lldb.
# See CMakeLists.txt for details.

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

# Recursively expanded so target-specific $(CXX) overrides (e.g. run-msan)
# are picked up correctly.
CMAKE_COMMON = -G Ninja -DCMAKE_CXX_COMPILER=$(CXX) $(VCPKG_TOOLCHAIN)

# Clearer sanitizer crash reports.
UBSAN_OPTIONS ?= print_stacktrace=1
ASAN_OPTIONS  ?= abort_on_error=1
export UBSAN_OPTIONS ASAN_OPTIONS

.PHONY: build run run-tsan run-msan release test format tidy debug clean

## Default debug build: ASan + UBSan (+ LeakSanitizer).
build:
	cmake -S . -B $(BUILD_DIR) $(CMAKE_COMMON) -DCMAKE_BUILD_TYPE=Debug -DSANITIZE=address,undefined
	cmake --build $(BUILD_DIR)

run: build
	./$(BUILD_DIR)/app

## ThreadSanitizer build + run, separate build dir (incompatible with ASan).
run-tsan:
	cmake -S . -B $(TSAN_DIR) $(CMAKE_COMMON) -DCMAKE_BUILD_TYPE=Debug -DSANITIZE=thread
	cmake --build $(TSAN_DIR)
	./$(TSAN_DIR)/app

## MemorySanitizer build + run, Clang-only (and Linux-only), separate build
## dir. Best-effort: can be noisy without an MSan-instrumented standard
## library. `override` forces clang++ here even if the caller passed
## `make CXX=g++`, since MSan is a Clang-only feature -- command-line
## variables normally beat target-specific ones, so a plain `:=` here would
## silently be ignored under that call.
run-msan: override CXX := clang++
run-msan:
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

## The lldb target: plain debug build, no sanitizers, unoptimized, full
## symbols. Own build dir so it never picks up sanitizer instrumentation
## from `build` -- no redzones, no sanitizer aborts interrupting your
## step-through. To debug the sanitized binary instead, run lldb by hand
## with LeakSanitizer's exit-time scan disabled (LSan's ptrace use conflicts
## fatally with lldb also ptracing the process; ASan/UBSan's own checks
## work fine under lldb):
##   ASAN_OPTIONS=detect_leaks=0 lldb ./build/app
debug:
	cmake -S . -B $(DEBUG_DIR) $(CMAKE_COMMON) -DCMAKE_BUILD_TYPE=Debug -DSANITIZE=none
	cmake --build $(DEBUG_DIR)
	lldb ./$(DEBUG_DIR)/app

clean:
	rm -rf $(BUILD_DIR) $(DEBUG_DIR) $(TSAN_DIR) $(MSAN_DIR) $(RELEASE_DIR)
