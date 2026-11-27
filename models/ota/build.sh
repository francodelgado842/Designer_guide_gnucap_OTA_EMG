#!/usr/bin/env bash
set -euo pipefail
cd -- "$(dirname -- "${BASH_SOURCE[0]}")"

include_dir=${GNUGCAP_INC:-$(gnucap-conf --includedir)}
modelgen=${GNUGCAP_VAMS:-gnucap-mg-vams}
compiler=${CXX:-g++}
work=$(mktemp -d)
trap 'rm -rf -- "$work"' EXIT

"$modelgen" -I "$include_dir" --cc ota.vams > "$work/ota.cc"
"$compiler" -I "$include_dir" -DNDEBUG -O2 -fPIC -shared "$work/ota.cc" -o "$work/ota.so"
mv -- "$work/ota.so" ota.so
echo 'Compilado: ota.so'
