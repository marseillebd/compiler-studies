#!/usr/bin/env bash
set -eu
cd "$(dirname "$0")"

cabal build
cabal run compiler-studies quick-test.bpp > quick-test.c
cc -g -O0 quick-test.c -o quick-test
set +e
echo >&2 '===================================='
./quick-test
ec=$?
echo >&2 '===================================='
echo >&2 "exit code: $ec"

