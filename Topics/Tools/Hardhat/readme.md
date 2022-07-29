## Hardhat 测试test
```shell
yarn install
npx hardhat compile
npx hardhat test
# report gas used for each test
REPORT_GAS=true npx hardhat test test/31_ERC20.spec.ts
```