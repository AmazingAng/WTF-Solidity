---
title: 15. Errors
tags:
  - solidity
  - advanced
  - wtfacademy
  - error
  - revert/assert/require
---

# WTF Solidity Tutorial: 15. Errors

Recently, I have been relearning Solidity, consolidating the finer details, and also writing a "WTF Solidity Tutorial" for newbies to learn. Lectures are updated 1~3 times weekly. 

Everyone is welcomed to follow my Twitter: [@0xAA_Science](https://twitter.com/0xAA_Science)

WTF Academy Discord, where you can find the way to join WeChat group: [Link](https://discord.gg/5akcruXrsk)

All codebase and tutorial notes are open source and available on GitHub (At 1024 repo stars, course certification is unlocked. At 2048 repo stars, community NFT is unlocked.): [github.com/AmazingAng/WTFSolidity](https://github.com/AmazingAng/WTFSolidity)

-----

In this section, we introduce three `solidity` methods of throwing exceptions: `error`, `require` and `assert`, and compare the `gas` consumption of the three methods.

## Errors
`bugs` always occur when writing smart contracts, and the Error commands in `solidity` help us `debug`.

### Error

`error` is a new addition to `solidity version 0.8`, which is convenient and efficient (saving `gas`) to explain to the user why the operation failed. 
Errors can be defined outside of `contract`. Below, we define a `TransferNotOwner` exception, which will throw an error when the user is not the token `owner` when trying to transfer:

```solidity
error TransferNotOwner(); // custom error
```
During execution, `error` must be used with the `revert` command.
```solidity
    function transferOwner1(uint256 tokenId, address newOwner) public {
        if(_owners[tokenId] != msg.sender){
            revert TransferNotOwner();
        }
        _owners[tokenId] = newOwner;
    }
```
We define a `transferOwner1()` function, which will check if the `owner` of the token is the originator, if not, it will throw a `TransferNotOwner` exception; 
if so, The transfer can be completed successfully.

### Require
`Require` command was a common method for throwing exceptions before `solidity version 0.8`, and it is still used by many mainstream contracts. 
It's a convenient method, and the only downside is that `gas` is higher than  `error` command as the length of the string described the exception increases. 
Instructions of `require`: `require(condition to be checked, "description of exception")`, an exception is thrown when the condition is not established.

Now, let's rewrite the above `transferOwner` function with the `require` command:
```solidity
    function transferOwner2(uint256 tokenId, address newOwner) public {
        require(_owners[tokenId] == msg.sender, "Transfer Not Owner");
        _owners[tokenId] = newOwner;
    }
```

### Assert
The `assert` command is generally used by programmers for `debugging`, because it does not explain why the exception was thrown (Has no string compared with `require`).
Usage: `assert (condition to be checked)`, when the check condition does not hold, an exception will be thrown.

Let's rewrite the above `transferOwner` function with the `assert` command:
```solidity
    function transferOwner3(uint256 tokenId, address newOwner) public {
        assert(_owners[tokenId] == msg.sender);
        _owners[tokenId] = newOwner;
    }
```

## Remix Demo
   
1. Enter any `uint256` number and non-zero address, call `transferOwner1`, which is the `error` method, 
and the console will throw an exception and displays the customed `TransferNotOwner`.

![15 1.png](./img/15-1.png)
   
2. Enter any `uint256` number and a non-zero address, call `transferOwner2`, which is the `require` method, 
the console throws an exception and prints the string in `require`.

![15 2.png](./img/15-2.png)
   
3. Enter any `uint256` number and non-zero address, call `transferOwner3`, which is the `assert` method, the console only throws an exception.

![15 3.png](./img/15-3.png)
   

## Gas comparison of three methods
Let's compare the `gas` consumption of the three exceptions. Through the Debug button of the remix console, 
you can find the `gas` consumption of each function call as follows:

1. **`gas` of `error`**：24445
2. **`gas` of `require`**：24743
3. **`gas` of `assert`**：24446

We can see that the `error` method consumes the least `gas`, followed by the `assert` method, and the `require` method consumes the most `gas`!
Therefore, `error` can not only inform the user of the reason for throwing an exception, but also save `gas`, 
so we should use it more! (Note that the gas consumption of each function will vary due to differences in deployment test times, 
but the comparison result will be consistent.)

## 总结
In this section, we introduce three methods of `solidity` throwing exceptions: `error`, `require` and `assert`, and compare the `gas` consumption of the three methods. 
Conclusion: `error` can not only tell the user why the exception was thrown, but also save `gas`.

