---
title: 55. Multiple calls
tags:
   - solidity
   - erc20
---

# WTF Minimalist introduction to Solidity: 55. Multiple calls

I'm recently re-learning solidity, consolidating the details, and writing a "WTF Solidity Minimalist Introduction" for novices (programming experts can find another tutorial), updating 1-3 lectures every week.

Twitter: [@0xAA_Science](https://twitter.com/0xAA_Science)

Community: [Discord](https://discord.gg/5akcruXrsk)｜[WeChat Group](https://docs.google.com/forms/d/e/1FAIpQLSe4KGT8Sh6sJ7hedQRuIYirOoZK_85miz3dw7vA1-YjodgJ-A/viewform?usp=sf_link) |[Official website wtf.academy](https://wtf.academy)

All codes and tutorials are open source on github: [github.com/AmazingAng/WTFSolidity](https://github.com/AmazingAng/WTFSolidity)

-----

In this lecture, we will introduce the MultiCall multi-call contract, which is designed to execute multiple function calls in one transaction, which can significantly reduce transaction fees and improve efficiency.

## MultiCall

In Solidity, the MultiCall (multiple call) contract is designed to allow us to execute multiple function calls in one transaction. Its advantages are as follows:

1. Convenience: MultiCall allows you to call different functions of different contracts in one transaction, and these calls can also use different parameters. For example, you can query the ERC20 token balances of multiple addresses at one time.

2. Save gas: MultiCall can combine multiple transactions into multiple calls in one transaction, thereby saving gas.

3. Atomicity: MultiCall allows users to perform all operations in one transaction, ensuring that all operations either succeed or fail, thus maintaining atomicity. For example, you can conduct a series of token transactions in a specific order.

## MultiCall Contract

Next, let’s study the MultiCall contract, which is simplified from MakerDAO’s [MultiCall](https://github.com/mds1/multicall/blob/main/src/Multicall3.sol).

The MultiCall contract defines two structures:

- `Call`: This is a call structure that contains the target contract `target` to be called, a flag `allowFailure` indicating whether the call failure is allowed, and the bytecode `call data` to be called.

- `Result`: This is a result structure that contains the flag `success` that indicates whether the call was successful and the bytecode returned by the call `return data`.

The contract contains only one function, which is used to perform multiple calls:

- `multicall()`: The parameter of this function is an array composed of Call structures. This can ensure that the length of the target and data passed in are consistent. The function performs multiple calls through a loop and rolls back the transaction if the call fails.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract Multicall {
     // Call structure, including target contract target, whether to allow call failure allowFailure, and call data
     struct Call {
         address target;
         bool allowFailure;
         bytes callData;
     }

     // Result structure, including whether the call is successful and return data
     struct Result {
         bool success;
         bytes returnData;
    }

/// @notice merges multiple calls (supporting different contracts/different methods/different parameters) into one call
     /// @param calls Array composed of Call structure
     /// @return returnData An array composed of Result structure
     function multicall(Call[] calldata calls) public returns (Result[] memory returnData) {
         uint256 length = calls.length;
         returnData = new Result[](length);
         Call calldata calli;
        
         // Called sequentially in the loop
         for (uint256 i = 0; i < length; i++) {
             Result memory result = returnData[i];
             calli = calls[i];
             (result.success, result.returnData) = calli.target.call(calli.callData);
             // If calli.allowFailure and result.success are both false, revert
             if (!(calli.allowFailure || result.success)){
                 revert("Multicall: call failed");
            }
        }
    }
}
```

## Remix Reappearance

1. We first deploy a very simple ERC20 token contract `MCERC20` and record the contract address.

    ```solidity
    // SPDX-License-Identifier: MIT
    pragma solidity ^0.8.19;
    import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

    contract MCERC20 is ERC20{
        constructor(string memory name_, string memory symbol_) ERC20(name_, symbol_){}

        function mint(address to, uint amount) external {
            _mint(to, amount);
        }
    }
    ```

2. Deploy the `MultiCall` contract.

3. Get the `calldata` to be called. We will mint 50 and 100 units of tokens respectively for 2 addresses. You can fill in the parameters of `mint()` on the remix call page, and then click the **Calldata** button to copy the encoded calldata. Come down. example:

    ```solidity
    to: 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4
    amount: 50
    calldata: 0x40c10f190000000000000000000000005b38da6a701c568545dcfcb03fcb875f56beddc40000000000000000000000000000000000000000000000000000000000000032
    ```

    .[](./img/55-1.png)

If you don’t understand `calldata`, you can read WTF Solidity [Lecture 29].

4. Use the `multicall()` function of `MultiCall` to call the `mint()` function of the ERC20 token contract to mint 50 and 100 units of tokens respectively to the two addresses. example:
    ```solidity
    calls: [["0x0fC5025C764cE34df352757e82f7B5c4Df39A836", true, "0x40c10f190000000000000000000000005b38da6a701c568545dcfcb03fcb875f56beddc40000000000000000000000000000000000000000000000000000000000000032"], ["0x0fC5025C764cE34df352757e82f7B5c4Df39A836", false, "0x40c10f19000000000000000000000000ab8483f64d9c6d1ecf9b849ae677dd3315835cb20000000000000000000000000000000000000000000000000000000000000064"]]
    ```

5. Use the `multicall()` function of `MultiCall` to call the `balanceOf()` function of the ERC20 token contract to query the balance of the two addresses just minted. The selector of the `balanceOf()` function is `0x70a08231`. example:

    ```solidity
    [["0x0fC5025C764cE34df352757e82f7B5c4Df39A836", true, "0x70a082310000000000000000000000005b38da6a701c568545dcfcb03fcb875f56beddc4"], ["0x0fC5025C764cE34df352757e82f7B5c4Df39A836", false, "0x70a08231000000000000000000000000ab8483f64d9c6d1ecf9b849ae677dd3315835cb2"]]
    ```

   The return value of the call can be viewed in `decoded output`. The balances of the two addresses are `0x0000000000000000000000000000000000000000000000000000000000000000032` and `0x00000000000000000000000000000 00000000000000000000000000000000000064`, that is, 50 and 100, the call was successful!
     .[](./img/55-2.png)

## Summary

In this lecture, we introduced the MultiCall multi-call contract, which allows you to execute multiple function calls in one transaction. It should be noted that different MultiCall contracts have some differences in parameters and execution logic. Please read the source code carefully when using them.
