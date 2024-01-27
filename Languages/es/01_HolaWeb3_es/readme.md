# WTF Solidity Tutorial: 1. Hola Web3 (Solidity in 3 lines)

Recently, I have been revisiting Solidity, consolidating the finer details, and writing "WTF Solidity" tutorials for newbies. 

Twitter: [@0xAA_Science](https://twitter.com/0xAA_Science) | [@WTFAcademy_](https://twitter.com/WTFAcademy_)

Community: [Discord](https://discord.gg/5akcruXrsk)｜[Wechat](https://docs.google.com/forms/d/e/1FAIpQLSe4KGT8Sh6sJ7hedQRuIYirOoZK_85miz3dw7vA1-YjodgJ-A/viewform?usp=sf_link)｜[Website wtf.academy](https://wtf.academy)

Codes and tutorials are open source on GitHub: [github.com/AmazingAng/WTFSolidity](https://github.com/AmazingAng/WTFSolidity)

-----

## WTF is Solidity?

`Solidity` is a programming language used for creating smart contracts on the Ethereum Virtual Machine (EVM). It's a necessary skill for working on blockchain projects. Moreover, as many of them are open-source, understanding the code can help in avoiding money-losing projects.


`Solidity` has two characteristics:

1. Object-oriented: After learning it, you can use it to make money by finding the right projects.
2. Advanced: If you can write smart contract in Solidity, you are the first class citizen of Ethereum.

## Development tool: Remix

In this tutorial, we will be using `Remix` to run `solidity` contracts. `Remix` is an smart contract development IDE (Integrated Development Environment) recommended by Ethereum official. It is suitable for beginners, allows for quick deployment and testing of smart contracts in the browser, without needing to install any programs on your local machine.

Website: [remix.ethereum.org](https://remix.ethereum.org)

Upon entering `Remix`, you can see that the menu on the left-hand side has three buttons, corresponding to the file (where you write the code), compile (where you run the code), and deploy (where you deploy to the chain). By clicking the "Create New File" button, you can create a blank `solidity` contract.

Within Remix, we can see that there are four buttons on the leftmost vertical menu, corresponding to FILE EXPLORER (where to write code), SEARCH IN FILES (find and replace files), SOLIDITY COMPILER (to run code), and DEPLOY & RUN TRANSACTIONS (on-chain deployment). We can create a blank Solidity contract by clicking the `Create New File` button.

![Remix Menu](./img/1-1.png)

## The first Solidity program

This one is easy, the program only contains 1 line of comment and 3 lines of code:

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
contract HelloWeb3{
    string public _string = "Hello Web3!";}
```

Now, we will breakdown and analyze the source code in detail, understanding the basic structure: 

1. The first line is a comment, which denotes the software license (license identifier) used by the program. We are using the MIT license. If you do not indicate the license used, the program can compile successfully but will report an warning during compilation. Solidity's comments are denoted with "//", followed by the content of the comment (which will not be run by the program).

```solidity
// SPDX-License-Identifier: MIT
```

2. The second line declares the Solidity version used by the source file, because the syntax of different versions is different. This line of code means that the source file will not allow compilation by compilers version lower than v0.8.4 and not higher than v0.9.0 (the second condition is provided by `^`).

```solidity
pragma solidity ^0.8.4;
```
    
3. Lines 3 and 4 are the main body of the smart contract. Line 3 creates a contract with the name `HelloWeb3`. Line 4 is the content of the contract. Here, we created a string variable called `_string` and assign "Hello Web3!" as value to it.

```solidity
contract HelloWeb3{
    string public _string = "Hello Web3!";}
```
We will introduce the different variables in Solidity later.

## Code compilation and deployment

In the code editor, pressing CTRL+S to compile the code.

After compilation, click the `Deploy` button on the left menu to enter the deployment page.

   ![](./img/1-2.png)

By default, Remix uses the JavaScript virtual machine to simulate the Ethereum chain and run smart contracts, similar to running a testnet on the browser. Remix will allocate several test accounts to you, each with 100 ETH (test tokens). You can click `Deploy` (yellow button) to deploy the contract.

   ![](./img/1-3.png)

After a successful deployment, you will see a contract named `HelloWeb3` below. By clicking on the variable `_string`, it will print its value: `"Hello Web3!"`.

## Summary

In this tutorial, we briefly introduced `Solidity`, `Remix` IDE, and completed our first Solidity program - `HelloWeb3`. Going forward, we will continue our Solidity journey.

### Recommended materials on Solidity：

1. [Solidity Documentation](https://docs.soliditylang.org/en/latest/)
2. [Solidity Tutorial by freeCodeCamp](https://www.youtube.com/watch?v=ipwxYa-F1uY)
