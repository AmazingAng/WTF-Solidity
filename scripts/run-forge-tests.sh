#!/usr/bin/env bash
# 在仓库根目录运行: ./scripts/run-forge-tests.sh
# 对每个有 foundry.toml + test 的章节目录执行 forge test，并汇总结果。

set -e
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

# 主教程章节目录（与 src 下的符号链接一致，排除 18_Import 39_Random 因依赖 URL/Chainlink）
CHAPTERS=(
  01_HelloWeb3 02_ValueTypes 03_Function 04_Return 05_DataStorage
  06_ArrayAndStruct 07_Mapping 08_InitialValue 09_Constant 10_InsertionSort
  11_Modifier 12_Event 13_Inheritance 14_Interface 15_Errors 16_Overloading
  17_Library 19_Fallback 20_SendETH 21_CallContract 22_Call 23_Delegatecall
  24_Create 25_Create2 26_DeleteContract 27_ABIEncode 28_Hash 29_Selector
  30_TryCatch 31_ERC20 32_Faucet 33_Airdrop 34_ERC721 35_DutchAuction
  36_MerkleTree 37_Signature 38_NFTSwap 40_ERC1155 41_WETH 42_PaymentSplit
  43_TokenVesting 44_TokenLocker 45_Timelock 46_ProxyContract 47_Upgrade
  48_TransparentProxy 49_UUPS 50_MultisigWallet 51_ERC4626 52_EIP712
  53_ERC20Permit 54_CrossChainBridge 55_MultiCall 56_DEX 57_Flashloan 58_USDT
  S01_ReentrancyAttack S02_SelectorClash S03_Centralization S04_AccessControlExploit
  S05_Overflow S06_SignatureReplay S07_BadRandomness S08_ContractCheck S09_DoS
  S10_Honeypot S11_Frontrun S12_TxOrigin S13_UncheckedCall S14_TimeManipulation
  S15_OracleManipulation S16_NFTReentrancy S17_CrossReentrancy
)

PASSED=0
FAILED=0
SKIPPED=0

echo "===== 根目录 Forge 测试（仅 RootTest，不跑需 fork/env 的用例） ====="
if forge test --match-contract RootTest 2>&1; then
  echo "[OK] 根目录 forge test 通过"
  ((PASSED+=1))
else
  echo "[FAIL] 根目录 forge test 失败"
  ((FAILED+=1))
fi

echo ""
echo "===== 子项目 Forge 测试（各自 foundry.toml） ====="
for dir in Topics/Tools/TOOL07_Foundry/hello_wtf; do
  if [[ -d "$dir" ]] && [[ -f "$dir/foundry.toml" ]]; then
    echo "--- $dir ---"
    if (cd "$dir" && forge test --match-path "test/Counter.t.sol" 2>&1); then
      ((PASSED+=1))
    else
      ((FAILED+=1))
    fi
  fi
done

echo ""
echo "===== 汇总: 通过=$PASSED, 失败=$FAILED ====="
[[ $FAILED -gt 0 ]] && exit 1 || exit 0
