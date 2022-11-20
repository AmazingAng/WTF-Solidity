---
title: 16. Overloading
tags:
  - solidity
  - advanced
  - wtfacademy
  - overloading
---
# WTF Solidity Tutorial: 16. Overloading

Recently, I have been revisiting Solidity, consolidating the finer details, and writing "WTF Solidity" tutorials for newbies. 

Twitter: [@0xAA_Science](https://twitter.com/0xAA_Science) | [@WTFAcademy_](https://twitter.com/WTFAcademy_)

Community: [Discord](https://discord.wtf.academy)｜[Wechat](https://docs.google.com/forms/d/e/1FAIpQLSe4KGT8Sh6sJ7hedQRuIYirOoZK_85miz3dw7vA1-YjodgJ-A/viewform?usp=sf_link)｜[Website wtf.academy](https://wtf.academy)

Codes and tutorials are open source on GitHub: [github.com/AmazingAng/WTFSolidity](https://github.com/AmazingAng/WTFSolidity)

-----

## Overloading
`solidity` allows functions to be overloaded（`overloading`）.That is, functions with the same name but different input parameter types 
can exist at the same time, and they are regarded as different functions.
Note that `solidity` does not allow modifier (`modifier`) to be overloaded.

### Function Overloading
For example, we could define two functions both called `saySomething()`:
one without any arguments and outputting `"Nothing"`, the other taking a `string` argument and outputting a `string`.

```solidity
function saySomething() public pure returns(string memory){
    return("Nothing");
}

function saySomething(string memory something) public pure returns(string memory){
    return(something);
}
```

After compiling, all overloading functions become different function selectors due to different parameter types. 
For the specific content of the function selector, please refer to [WTF Solidity Tutorial: 29. Function Selector](https://github.com/AmazingAng/WTFSolidity/tree/main/29_Selector).

Taking the `Overloading.sol` contract as an example, after compiling and deploying on Remix.
After calling the overloading functions `saySomething()` and `saySomething(string memory something)` respectively, 
we can see different results, for the functions are regarded as different ones.
![](./img/16-1.jpeg)

### Argument Matching

When the overloading function is called, the variable type will be matched between input parameter and function parameters.
An error will be reported if there are multiple matching overloading functions,
The following example has two functions called `f()`, one have `uint8` parameter and the other get `uint256`:

```solidity
    function f(uint8 _in) public pure returns (uint8 out) {
        out = _in;
    }

    function f(uint256 _in) public pure returns (uint256 out) {
        out = _in;
    }
```
For `50` can be converted to `uint8` as well as `uint256`, so it will report an error if we call `f(50)`.

## Summary

In this lecture, we introduce the basic usage of overloading function in `solidity`: 
functions with the same name but different input parameter types can exist at the same time, 
which are treated as different functions.


