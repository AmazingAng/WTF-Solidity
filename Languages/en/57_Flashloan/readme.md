---
title: 57. Flash loan
tags:
   - solidity
   - flashloan
   - Defi
   - uniswap
   - aave
---

# WTF Minimalist introduction to Solidity: 57. Flash loan

I'm recently re-learning solidity, consolidating the details, and writing a "WTF Solidity Minimalist Introduction" for novices (programming experts can find another tutorial), updating 1-3 lectures every week.

Twitter: [@0xAA_Science](https://twitter.com/0xAA_Science)

Community: [Discord](https://discord.gg/5akcruXrsk)｜[WeChat Group](https://docs.google.com/forms/d/e/1FAIpQLSe4KGT8Sh6sJ7hedQRuIYirOoZK_85miz3dw7vA1-YjodgJ-A/viewform?usp=sf_link) |[Official website wtf.academy](https://wtf.academy)

All codes and tutorials are open source on github: [github.com/AmazingAng/WTFSolidity](https://github.com/AmazingAng/WTFSolidity)

-----

You must have heard the term “flash loan attack”, but what is a flash loan? How to write a flash loan contract? In this lecture, we will introduce flash loans in the blockchain, implement flash loan contracts based on Uniswap V2, Uniswap V3, and AAVE V3, and use Foundry for testing.

## Flash Loan

The first time you heard about "flash loan" must be in Web3, because Web2 does not have this thing. Flashloan is a DeFi innovation that allows users to lend and quickly return funds in one transaction without providing any collateral.

Imagine that you suddenly find an arbitrage opportunity in the market, but you need to prepare 1 million U of funds to complete the arbitrage. In Web2, you go to the bank to apply for a loan, which requires approval, and you may miss the arbitrage opportunity. In addition, if the arbitrage fails, you not only have to pay interest, but also need to return the lost principal.

In Web3, you can obtain funds through flash loans on the DeFI platform (Uniswap, AAVE, Dodo). You can borrow 1 million u tokens without guarantee, perform on-chain arbitrage, and finally return the loan and interest. .

Flash loans take advantage of the atomicity of Ethereum transactions: a transaction (including all operations within it) is either fully executed or not executed at all. If a user attempts to use a flash loan and does not return the funds in the same transaction, the entire transaction will fail and be rolled back as if it never happened. Therefore, the DeFi platform does not need to worry about the borrower not being able to repay the loan, because if it is not repaid, it means that the money has not been loaned out; at the same time, the borrower does not need to worry about the arbitrage being unsuccessful, because if the arbitrage is unsuccessful, the repayment will not be repaid, and It means that the loan was unsuccessful.

![](./img/57-1.png)

## Flash loan in action

Below, we introduce how to implement flash loan contracts in Uniswap V2, Uniswap V3, and AAVE V3.

### 1. Uniswap V2 Flash Loan

[Uniswap V2 Pair](https://github.com/Uniswap/v2-core/blob/master/contracts/UniswapV2Pair.sol#L159) The `swap()` function of the contract supports flash loans. The code related to the flash loan business is as follows:

```solidity
function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external lock {
     // Other logic...

     // Optimistically send tokens to the to address
     if (amount0Out > 0) _safeTransfer(_token0, to, amount0Out);
     if (amount1Out > 0) _safeTransfer(_token1, to, amount1Out);

     //Call the callback function uniswapV2Call of the to address
     if (data.length > 0) IUniswapV2Callee(to).uniswapV2Call(msg.sender, amount0Out, amount1Out, data);

     // Other logic...

     // Use the k=x*y formula to check whether the flash loan is returned successfully
     require(balance0Adjusted.mul(balance1Adjusted) >= uint(_reserve0).mul(_reserve1).mul(1000**2), 'UniswapV2: K');
}
```

In the `swap()` function:

1. First transfer the tokens in the pool to the `to` address optimistically.
2. If the length of `data` passed in is greater than `0`, the callback function `uniswapV2Call` of the `to` address will be called to execute the flash loan logic.
3. Finally, check whether the flash loan is returned successfully through `k=x*y`. If not, roll back the transaction.

Next, we complete the flash loan contract `UniswapV2Flashloan.sol`. We let it inherit `IUniswapV2Callee` and write the core logic of flash loan in the callback function `uniswapV2Call`.

The overall logic is very simple. In the flash loan function `flashloan()`, we borrow `WETH` from the `WETH-DAI` pool of Uniswap V2. After the flash loan is triggered, the callback function `uniswapV2Call` will be called by the Pair contract. We do not perform arbitrage and only return the flash loan after calculating the interest. The interest rate of Uniswap V2 flash loan is `0.3%` per transaction.

**Note**: The callback function must have permission control to ensure that only Uniswap's Pair contract can be called. Otherwise, all the funds in the contract will be stolen by hackers.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./Lib.sol";

// Uniswap V2 flash loan callback interface
interface IUniswapV2Callee {
    function uniswapV2Call(address sender, uint amount0, uint amount1, bytes calldata data) external;
}

// // Uniswap V2 Flash Loan Contract
contract UniswapV2Flashloan is IUniswapV2Callee {
    address private constant UNISWAP_V2_FACTORY =
        0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;

    address private constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address private constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    IUniswapV2Factory private constant factory = IUniswapV2Factory(UNISWAP_V2_FACTORY);

    IERC20 private constant weth = IERC20(WETH);

    IUniswapV2Pair private immutable pair;

    constructor() {
        pair = IUniswapV2Pair(factory.getPair(DAI, WETH));
    }

// Flash loan function
     function flashloan(uint wethAmount) external {
         //The calldata length is greater than 1 to trigger the flash loan callback function
         bytes memory data = abi.encode(WETH, wethAmount);

         // amount0Out is the DAI to be borrowed, amount1Out is the WETH to be borrowed
         pair.swap(0, wethAmount, address(this), data);
     }

     // Flash loan callback function can only be called by the DAI/WETH pair contract
    function uniswapV2Call(
        address sender,
        uint amount0,
        uint amount1,
        bytes calldata data
    ) external {
// Confirm that the call is DAI/WETH pair contract
         address token0 = IUniswapV2Pair(msg.sender).token0(); // Get token0 address
         address token1 = IUniswapV2Pair(msg.sender).token1(); // Get token1 address
        assert(msg.sender == factory.getPair(token0, token1)); // ensure that msg.sender is a V2 pair

//Decode calldata
         (address tokenBorrow, uint256 wethAmount) = abi.decode(data, (address, uint256));

         // flashloan logic, omitted here
        require(tokenBorrow == WETH, "token borrow != WETH");

// Calculate flashloan fees
         // fee / (amount + fee) = 3/1000
         // Rounded up
         uint fee = (amount1 * 3) / 997 + 1;
         uint amountToRepay = amount1 + fee;

         //Repay flash loan
         weth.transfer(address(pair), amountToRepay);
     }
}

Foundry test contract `UniswapV2Flashloan.t.sol`:

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/UniswapV2Flashloan.sol";

address constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

contract UniswapV2FlashloanTest is Test {
    IWETH private weth = IWETH(WETH);

    UniswapV2Flashloan private flashloan;

    function setUp() public {
        flashloan = new UniswapV2Flashloan();
    }

function testFlashloan() public {
         //Exchange weth and transfer it to the flashloan contract to use it as handling fee
         weth.deposit{value: 1e18}();
         weth.transfer(address(flashloan), 1e18);
         // Flash loan loan amount
         uint amountToBorrow = 100 * 1e18;
         flashloan.flashloan(amountToBorrow);
     }

     // If the handling fee is insufficient, it will be reverted.
     function testFlashloanFail() public {
         //Exchange weth and transfer it to the flashloan contract to use it as handling fee
         weth.deposit{value: 1e18}();
         weth.transfer(address(flashloan), 3e17);
         // Flash loan loan amount
         uint amountToBorrow = 100 * 1e18;
         // Insufficient handling fee
         vm.expectRevert();
         flashloan.flashloan(amountToBorrow);
     }
}
```

In the test contract, we tested the cases of sufficient and insufficient handling fees respectively. You can use the following command line to test after installing Foundry (you can change the RPC to other Ethereum RPC):

```shell
FORK_URL=https://singapore.rpc.blxrbdn.com
forge test  --fork-url $FORK_URL --match-path test/UniswapV2Flashloan.t.sol -vv
```

### 2. Uniswap V3闪电贷

Unlike Uniswap V2 which indirectly supports flash loans in the `swap()` exchange function, Uniswap V3 supports flash loans in [Pool Pool Contract](https://github.com/Uniswap/v3-core/blob/main/contracts/UniswapV3Pool.sol #L791C1-L835C1) has added the `flash()` function to directly support flash loans. The core code is as follows:

```solidity
function flash(
    address recipient,
    uint256 amount0,
    uint256 amount1,
    bytes calldata data
) external override lock noDelegateCall {
    // 其他逻辑...

// Optimistically send tokens to the to address
     if (amount0 > 0) TransferHelper.safeTransfer(token0, recipient, amount0);
     if (amount1 > 0) TransferHelper.safeTransfer(token1, recipient, amount1);

     //Call the callback function uniswapV3FlashCallback of the to address
     IUniswapV3FlashCallback(msg.sender).uniswapV3FlashCallback(fee0, fee1, data);

     // Check whether the flash loan is returned successfully
    uint256 balance0After = balance0();
    uint256 balance1After = balance1();
    require(balance0Before.add(fee0) <= balance0After, 'F0');
    require(balance1Before.add(fee1) <= balance1After, 'F1');

    // sub is safe because we know balanceAfter is gt balanceBefore by at least fee
    uint256 paid0 = balance0After - balance0Before;
    uint256 paid1 = balance1After - balance1Before;

// Other logic...
}
```

Next, we complete the flash loan contract `UniswapV3Flashloan.sol`. We let it inherit `IUniswapV3FlashCallback` and write the core logic of flash loan in the callback function `uniswapV3FlashCallback`.

The overall logic is similar to that of V2. In the flash loan function `flashloan()`, we borrow `WETH` from the `WETH-DAI` pool of Uniswap V3. After the flash loan is triggered, the callback function `uniswapV3FlashCallback` will be called by the Pool contract. We do not perform arbitrage and only return the flash loan after calculating the interest. The handling fee for each flash loan in Uniswap V3 is consistent with the transaction fee.

**Note**: The callback function must have permission control to ensure that only Uniswap's Pair contract can be called. Otherwise, all the funds in the contract will be stolen by hackers.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./Lib.sol";

// UniswapV3 flash loan callback interface
//Need to implement and rewrite the uniswapV3FlashCallback() function
interface IUniswapV3FlashCallback {
     /// In the implementation, you must repay the pool for the tokens sent by flash and the calculated fee amount.
     /// The contract calling this method must be checked by the UniswapV3Pool deployed by the official UniswapV3Factory.
     /// @param fee0 The fee amount of token0 that should be paid to the pool when the flash loan ends
     /// @param fee1 The fee amount of token1 that should be paid to the pool when the flash loan ends
     /// @param data Any data passed by the caller is called via IUniswapV3PoolActions#flash
     function uniswapV3FlashCallback(
         uint256 fee0,
         uint256 fee1,
         bytes calldata data
     ) external;
}

// UniswapV3 flash loan contract
contract UniswapV3Flashloan is IUniswapV3FlashCallback {
    address private constant UNISWAP_V3_FACTORY = 0x1F98431c8aD98523631AE4a59f267346ea31F984;

    address private constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address private constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    uint24 private constant poolFee = 3000;

    IERC20 private constant weth = IERC20(WETH);
    IUniswapV3Pool private immutable pool;

    constructor() {
        pool = IUniswapV3Pool(getPool(DAI, WETH, poolFee));
    }

    function getPool(
        address _token0,
        address _token1,
        uint24 _fee
    ) public pure returns (address) {
        PoolAddress.PoolKey memory poolKey = PoolAddress.getPoolKey(
            _token0,
            _token1,
            _fee
        );
        return PoolAddress.computeAddress(UNISWAP_V3_FACTORY, poolKey);
    }

// Flash loan function
     function flashloan(uint wethAmount) external {
         bytes memory data = abi.encode(WETH, wethAmount);
         IUniswapV3Pool(pool).flash(address(this), 0, wethAmount, data);
     }

     // Flash loan callback function can only be called by the DAI/WETH pair contract
     function uniswapV3FlashCallback(
         uint fee0,
         uint fee1,
         bytes calldata data
     ) external {
         // Confirm that the call is DAI/WETH pair contract
         require(msg.sender == address(pool), "not authorized");
        
         //Decode calldata
        (address tokenBorrow, uint256 wethAmount) = abi.decode(data, (address, uint256));

        // flashloan logic, omitted here
        require(tokenBorrow == WETH, "token borrow != WETH");

        //Repay flash loan
        weth.transfer(address(pool), wethAmount + fee1);
    }
}
```

Foundry test contract `UniswapV3Flashloan.t.sol`:

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console2} from "forge-std/Test.sol";
import "../src/UniswapV3Flashloan.sol";

address constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

contract UniswapV2FlashloanTest is Test {
    IWETH private weth = IWETH(WETH);

    UniswapV3Flashloan private flashloan;

    function setUp() public {
        flashloan = new UniswapV3Flashloan();
    }

function testFlashloan() public {
         //Exchange weth and transfer it to the flashloan contract to use it as handling fee
         weth.deposit{value: 1e18}();
         weth.transfer(address(flashloan), 1e18);
                
         uint balBefore = weth.balanceOf(address(flashloan));
         console2.logUint(balBefore);
         // Flash loan loan amount
         uint amountToBorrow = 1 * 1e18;
         flashloan.flashloan(amountToBorrow);
    }

// If the handling fee is insufficient, it will be reverted.
     function testFlashloanFail() public {
         //Exchange weth and transfer it to the flashloan contract to use it as handling fee
         weth.deposit{value: 1e18}();
         weth.transfer(address(flashloan), 1e17);
         // Flash loan loan amount
         uint amountToBorrow = 100 * 1e18;
         // Insufficient handling fee
         vm.expectRevert();
         flashloan.flashloan(amountToBorrow);
     }
}
```

In the test contract, we tested the cases of sufficient and insufficient handling fees respectively. You can use the following command line to test after installing Foundry (you can change the RPC to other Ethereum RPC):

```shell
FORK_URL=https://singapore.rpc.blxrbdn.com
forge test  --fork-url $FORK_URL --match-path test/UniswapV3Flashloan.t.sol -vv
```

### 3. AAVE V3 Flash Loan

AAVE is a decentralized lending platform. Its [Pool contract](https://github.com/aave/aave-v3-core/blob/master/contracts/protocol/pool/Pool.sol#L424) passes `flashLoan The two functions ()` and `flashLoanSimple()` support single-asset and multi-asset flash loans. Here, we only use `flashLoan()` to implement flash loan of a single asset (`WETH`).

Next, we complete the flash loan contract `AaveV3Flashloan.sol`. We let it inherit `IFlashLoanSimpleReceiver` and write the core logic of flash loan in the callback function `executeOperation`.

The overall logic is similar to that of V2. In the flash loan function `flashloan()`, we borrow `WETH` from the `WETH` pool of AAVE V3. After the flash loan is triggered, the callback function `executeOperation` will be called by the Pool contract. We do not perform arbitrage and only return the flash loan after calculating the interest. The handling fee of AAVE V3 flash loan defaults to `0.05%` per transaction, which is lower than that of Uniswap.

**Note**: The callback function must have permission control to ensure that only AAVE's Pool contract can be called, and the initiator is this contract, otherwise the funds in the contract will be stolen by hackers.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./Lib.sol";

interface IFlashLoanSimpleReceiver {
     /**
     * @notice performs operations after receiving flash loan assets
     * @dev ensures that the contract can pay off the debt + additional fees, e.g. with
     * Sufficient funds to repay and Pool has been approved to withdraw the total amount
     * @param asset The address of the flash loan asset
     * @param amount The amount of flash loan assets
     * @param premium The fee for lightning borrowing assets
     * @param initiator The address where flash loans are initiated
     * @param params byte encoding parameters passed when initializing flash loan
     * @return True if the operation is executed successfully, False otherwise
     */
    function executeOperation(
        address asset,
        uint256 amount,
        uint256 premium,
        address initiator,
        bytes calldata params
    ) external returns (bool);
}

// AAVE V3 flash loan contract
contract AaveV3Flashloan {
    address private constant AAVE_V3_POOL =
        0x87870Bca3F3fD6335C3F4ce8392D69350B4fA4E2;

    address private constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    ILendingPool public aave;

    constructor() {
        aave = ILendingPool(AAVE_V3_POOL);
    }

// Flash loan function
     function flashloan(uint256 wethAmount) external {
         aave.flashLoanSimple(address(this), WETH, wethAmount, "", 0);
     }

     // Flash loan callback function can only be called by the pool contract
     function executeOperation(address asset, uint256 amount, uint256 premium, address initiator, bytes calldata)
        external
        returns (bool)
    {   
// Confirm that the call is DAI/WETH pair contract
         require(msg.sender == AAVE_V3_POOL, "not authorized");
         // Confirm that the initiator of the flash loan is this contract
         require(initiator == address(this), "invalid initiator");

         // flashloan logic, omitted here

         // Calculate flashloan fees
         // fee = 5/1000 * amount
         uint fee = (amount * 5) / 10000 + 1;
         uint amountToRepay = amount + fee;

         //Repay flash loan
         IERC20(WETH).approve(AAVE_V3_POOL, amountToRepay);

         return true;
    }
}
```

Foundry test contract `AaveV3Flashloan.t.sol`:

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/AaveV3Flashloan.sol";

address constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

contract UniswapV2FlashloanTest is Test {
    IWETH private weth = IWETH(WETH);

    AaveV3Flashloan private flashloan;

    function setUp() public {
        flashloan = new AaveV3Flashloan();
    }

function testFlashloan() public {
         //Exchange weth and transfer it to the flashloan contract to use it as handling fee
         weth.deposit{value: 1e18}();
         weth.transfer(address(flashloan), 1e18);
         // Flash loan loan amount
         uint amountToBorrow = 100 * 1e18;
         flashloan.flashloan(amountToBorrow);
     }

     // If the handling fee is insufficient, it will be reverted.
     function testFlashloanFail() public {
         //Exchange weth and transfer it to the flashloan contract to use it as handling fee
         weth.deposit{value: 1e18}();
         weth.transfer(address(flashloan), 4e16);
         // Flash loan loan amount
         uint amountToBorrow = 100 * 1e18;
         // Insufficient handling fee
         vm.expectRevert();
         flashloan.flashloan(amountToBorrow);
     }
}
```

In the test contract, we tested the cases of sufficient and insufficient handling fees respectively. You can use the following command line to test after installing Foundry (you can change the RPC to other Ethereum RPC):

```shell
FORK_URL=https://singapore.rpc.blxrbdn.com
forge test  --fork-url $FORK_URL --match-path test/AaveV3Flashloan.t.sol -vv
```

## Summary

In this lecture, we introduce flash loans, which allow users to lend and quickly return funds in one transaction without providing any collateral. Moreover, we have implemented Uniswap V2, Uniswap V3, and AAVE’s flash loan contracts respectively.

Through flash loans, we can leverage massive amounts of funds without collateral for risk-free arbitrage or vulnerability attacks. What are you going to do with flash loans?
