#!/usr/bin/env bash

./scripts/clear-upgradeable.sh

set -euo pipefail -x

npm run compile

build_info=($(jq -r '.input.sources | keys | if any(test("^contracts/mocks/.*\\bunreachable\\b")) then empty else input_filename end' artifacts/build-info/*))
build_info_num=${#build_info[@]}

if [ $build_info_num -ne 1 ]; then
  echo "found $build_info_num relevant build info files but expected just 1"
  exit 1
fi

# -D: delete original and excluded files
# -b: use this build info file
# -i: use included Initializable
# -x: exclude all proxy contracts except Clones library
# -p: emit public initializer
#  -i contracts/openzeppelin/proxy/utils/Initializable.sol \
npx @openzeppelin/upgrade-safe-transpiler@latest \
  -b "$build_info" \
  -x 'contracts/mocks/ERC721ReceiverMock.sol' \
  -x 'contracts/mocks/ERC3525ReceiverMock.sol'

rm -rf @openzeppelin
rm -f contracts/Initializable.sol

node ./scripts/migrate-imports.js
sed 's/\.\.\/\.\.\/@openzeppelin\/contracts/@openzeppelin\/contracts-upgradeable/g' contracts/mocks/WithInit.sol > contracts/mocks/ERC3525BaseMockUpgradeableWithInit.sol
rm -f contracts/mocks/WithInit.sol