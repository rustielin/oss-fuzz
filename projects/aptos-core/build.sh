#!/bin/bash -eu
# Copyright 2023 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
################################################################################

# This script must run in the `aptos-core` repo root directory

set -e

export ROOTDIR="$(pwd)"
export OUT="${OUT:-${ROOTDIR}/out}"
export ARG="${1:-all}"
export RUSTBACKTRACE="full"

# reset oss-fuzz compile flags
export CFLAGS="-O1 -fno-omit-frame-pointer -gline-tables-only -DFUZZING_BUILD_MODE_UNSAFE_FOR_PRODUCTION -fsanitize=address -fsanitize-address-use-after-scope"
export CXXFLAGS_EXTRA="-stdlib=libc++"
export CXXFLAGS="$CFLAGS $CXXFLAGS_EXTRA"

cd testsuite/aptos-fuzzer/

unset RUSTFLAGS

# from aptos-core
export RUSTFLAGS="--cfg tokio_unstable -C force-frame-pointers=yes -C force-unwind-tables=yes -C link-arg=-fuse-ld=lld -C target-feature=+sse4.2"

# addl
# export RUSTFLAGS="${RUSTFLAGS} -C link-arg=-l/usr/lib/libFuzzingEngine.a -Clink-arg=-lc++"
# fuzzers=$(cargo +nightly run --bin aptos-fuzzer list --no-desc)
fuzzers="ValueTarget"

# https://github.com/rust-lang/rust/issues/110682
# export RUSTFLAGS="${RUSTFLAGS} --cfg fuzzing -Zsanitizer=address -Cdebug-assertions -Cdebuginfo=1 -Cforce-frame-pointers -Zinline-mir-threshold=10000 -Zinline-mir-hint-threshold=10000 -Zmir-opt-level=3"

cd fuzz
for fuzzer_name in $fuzzers; do
    SINGLE_FUZZ_TARGET=$fuzzer_name cargo +nightly fuzz build -O -a
    cp -r $ROOTDIR/target/x86_64-unknown-linux-gnu/release/fuzz_builder $OUT/$fuzzer_name
    rm $ROOTDIR/target/x86_64-unknown-linux-gnu/release/fuzz_builder
done

