---
title: 11. constructor and modifier
tags:
  - solidity
  - basic
  - wtfacademy
  - constructor
  - modifier
---

# WTF Solidity Tutorial: 11. Constructor & Modifier

Recently, I have been revisiting Solidity, consolidating the finer details, and writing "WTF Solidity" tutorials for newbies. 

Twitter: [@0xAA_Science](https://twitter.com/0xAA_Science) | [@WTFAcademy_](https://twitter.com/WTFAcademy_)

Community: [Discord](https://discord.wtf.academy)｜[Wechat](https://docs.google.com/forms/d/e/1FAIpQLSe4KGT8Sh6sJ7hedQRuIYirOoZK_85miz3dw7vA1-YjodgJ-A/viewform?usp=sf_link)｜[Website wtf.academy](https://wtf.academy)

Codes and tutorials are open source on GitHub: [github.com/AmazingAng/WTFSolidity](https://github.com/AmazingAng/WTFSolidity)

-----

In this section, we will introduce `constructor` and `modifier` in solidity with a control contract for access control（`Ownable`）.

## Constructor
`constructor` is a special and optional function, which will automatically run once during contract deployment. It can be used to initialize parameters of a contract. For example, it can initialize `owner` address in the below contract:

```solidity
   address owner; // define owner variable

   // constructor
   constructor() {
      owner = msg.sender; //  set owner to the address of deployer when contract is being deployed
   }
```

**Note**：The syntax of constructor in solidity is not consistent for different versions: Before `solidity 0.4.22`, constructors did not use the `constructor` keyword. Instead, the constructor function has the same name as the contract name. This old syntax is prone to mistakes: the developer may mistakenly name the contract as `Parents`, while the constructor as `parents`. So in `0.4.22` and later version, new syntax of `constructor` is used.

Example of constructor prior to `solidity 0.4.22`：
```solidity
pragma solidity =0.4.21;
contract Parents {
    // The function with the same name as the contract name(Parents) is constructor
    function Parents () public {
    }
}
```

## Modifier
`modifier` is similar to `decorator` in object-oriented programming, which is used to declare dedicated properties of functions and reduce code redundancy. It's like Iron Man Armor for functions: the function with it will have some magic properties. The popular use case of modiferie is to control the access for functions, which can only be called by dedicated address, such as contract owner.


![Iron Man's modifier](https://images.mirror-media.xyz/publication-images/nVwXsOVmrYu8rqvKKPMpg.jpg?height=630&width=1200)

Let's define a modifier called `onlyOwner`：
```solidity
   // define modifier
   modifier onlyOwner {
      require(msg.sender == owner); // check whether caller is address of owner
      _; // if true，continue to run the body of function；otherwise throw an error and revert transaction
   }
```

Functions with `onlyOwner` modifier can only be called by `owner` address：
```solidity
   function changeOwner(address _newOwner) external onlyOwner{
      owner = _newOwner; // only owner address can run this function and change owner
   }
```
We define a `changeOwner` function, which can change the `owner` of the contract. However, due to the `onlyOwner` modifier, only original contract `owner` can call it; errors will be thrown if others call it. This is the most common way to control smart contract privilege.

### OppenZepplin's implementation of Ownable：
`OppenZepplin` is an organization that maintains a standardized code base for `Solidity`, Their standard implementation of `Ownable` is as follows：
[https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol)

## Remix Demo example
Here, we take `Owner.sol` as an example.
1. compile and deploy the code in Remix.
2. click `owner` button to view current owner.
    ![](img/11-1_en.jpg)
3. The transaction succeeds when `changeOwner` function is called by the owner address user.
    ![](img/11-2_en.jpg)
4. The transaction fails when `changeOwner` function is called by other addresses.
    ![](img/11-3_en.jpg)


## Summary
In this lecture, we introduced constructor and modifier in `solidity`, and wrote an `Ownable` contract that controls contract privilege.
