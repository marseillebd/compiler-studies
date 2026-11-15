#!/usr/bin/env bash
set -eu
cd "$(dirname "$0")"

cflags=(-g -O0)

src=.
build=.quick-test

(
set -x
mkdir -p "$build"
cabal build
cabal run compiler-studies quick-test.bpp > "$build/quick-test.c"
cc ${cflags[@]} -c "$build/quick-test.c" \
                -o "$build/quick-test.o"
cc ${cflags[@]} -o "$build/quick-test" \
  "$build/quick-test.o" data/bpprt-libc.c
)

set +e
echo >&2 '===================================='
"$build/quick-test"
ec=$?
echo >&2 '===================================='
echo >&2 "exit code: $ec"

