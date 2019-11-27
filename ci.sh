#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" > /dev/null && pwd )"
DUB_BUILD_TYPE="${DUB_BUILD_TYPE:-unittest}"
DC="${DC:-dmd}"

echo "dub build type: $DUB_BUILD_TYPE"
echo "DC: $DC"

dub test -q --build="$DUB_BUILD_TYPE" --compiler="$DC"
cd "$SCRIPT_DIR"/example/basic
dub build -q
