#!/bin/bash
# Copyright 2018 Google LLC.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Usage:  ./nucleus/pip_package/build_pip_package.sh [optional_dir]
#
# If [optional_dir] is supplied, the created wheel file is placed there.
#
# Important:  You must run
#   source install.sh
# before running this script.

set -e

bazel build -c opt $COPT_FLAGS nucleus/pip_package:build_pip_package

function cp_external() {
  local src_dir=$1
  local dest_dir=$2
  for f in `find "$src_dir" -maxdepth 1 -mindepth 1 ! -name '*nucleus*'`; do
    cp -R "$f" "$dest_dir"
  done
}

TMPDIR=$(mktemp -d -t tmp.XXXXXXXXXXX)

RUNFILES=bazel-bin/nucleus/pip_package/build_pip_package.runfiles/nucleus

# $RUNFILES has four subdirectories, each of which gets treated a bit
# differently.

# Subdirectory #1:  Copy /nucleus to top level.
cp -R "${RUNFILES}/nucleus" "${TMPDIR}"

# Subdirectory #2:  Copy /external to /external, but leave out
# /external/nucleus.
mkdir "${TMPDIR}/external"
cp_external "${RUNFILES}" "${TMPDIR}/external"

# Subdirectory #3: Copy /_solib_k8 (or whatever the binary files directory
# is called) to top level.
so_lib_dir=$(ls "$RUNFILES" | grep solib)
if [ -n "${so_lib_dir}" ]; then
  cp -R "${RUNFILES}/${so_lib_dir}" "${TMPDIR}"
fi

# Subdirectory #4: Copy /third_party to /third_party.
mkdir "${TMPDIR}/third_party"
cp -R "${RUNFILES}"/third_party/* "${TMPDIR}/third_party"

cp LICENSE "${TMPDIR}"
cp README.md "${TMPDIR}"
cp nucleus/pip_package/MANIFEST.in "${TMPDIR}"
cp nucleus/pip_package/setup.py "${TMPDIR}"

pushd "${TMPDIR}"
rm -f MANIFEST
echo $(date) : "=== Building wheel in ${TMPDIR}"
python setup.py bdist_wheel
popd

if [ $# -gt 0 ]; then
  DEST=$1
  mkdir -p "${DEST}"
  cp "${TMPDIR}/dist"/* "${DEST}"
else
  DEST="${TMPDIR}/dist"
fi

echo "Output wheel is in ${DEST}"
