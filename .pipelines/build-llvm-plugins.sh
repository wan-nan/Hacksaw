#!/bin/bash -e
# Copyright (c) 2023 Microsoft Corporation.
# Licensed under the MIT License.

set -x

BUILD_PREFIX="${HOME}/hacksaw-build"
LLVM_INSTALL="${BUILD_PREFIX}/llvm-install"

HWDB_BUILD="${BUILD_PREFIX}/hwdb"
mkdir -p ${HWDB_BUILD}
cmake -DLLVM_INCLUDE_PATH="${LLVM_INSTALL}/include" \
	-DLLVM_LIB_PATH="${LLVM_INSTALL}/lib" \
	-S hwdb/platform \
	-B ${HWDB_BUILD}

pushd ${HWDB_BUILD}
make -j$(nproc)
popd
