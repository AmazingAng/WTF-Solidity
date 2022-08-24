# Solidity Minimalist Tutorial: 4. Function output (return/returns)

Recently, I have been relearning Solidity, consolidating the finer details, and also writing a "Solidity Minimalist Tutorial" for newbies to learn. Lectures are updated 1~3 times weekly. 

Everyone is welcomed to follow my Twitter: [@0xAA_Science](https://twitter.com/0xAA_Science)

WTF Academy Discord: [Link](https://discord.gg/5akcruXrsk)

All codebase and tutorial notes are open source and available on GitHub (At 1024 repo stars, course certification is unlocked. At 2048 repo stars, community NFT is unlocked.): [github.com/AmazingAng/WTFSolidity](https://github.com/AmazingAng/WTFSolidity)

-----

In this chapter, we will introduce `Solidity` function output, including returning multiple values, named returns, and reading full and part of return values using destructuring assignments. 

## Return values (return and returns)
There are two keywords related to function output: `return` and `returns`:
- `returns` is added after the function name to declare variable type and variable name;
- `return` is used in the function body and returns desired variables.

```solidity
    // returning multiple variables
    function returnMultiple() public pure returns(uint256, bool, uint256[3] memory){
            return(1, true, [uint256(1),2,5]);
        }
```
In the above code, the `returnMultiple()` function has multiple outputs: `returns (uint256, bool, uint256[3] memory) `, and then we specify the return variables/values in the function body with `return (1, true, [uint256 (1), 2,5]) `.

## Named returns
We can indicate the name of the return variables in `returns`, so that `solidity` automatically initializes these variables, and automatically returns the values of these functions without adding the `return` keyword.

```solidity
    // named returns
    function returnNamed() public pure returns(uint256 _number, bool _bool, uint256[3] memory _array){
        _number = 2;
        _bool = false; 
        _array = [uint256(3),2,1];
    }
```
In the above code, we declare the return variable type and variable name with `returns (uint256 _number, bool _bool, uint256[3] memory _array) `. Thus, we only need to assign values to the variable ` _number`, ` _bool ` and ` _array `in the function body, and they will automatically return.

Of course, you can also return variables with `return` keyword in named returns:
```solidity
    // Named return, still support return
    function returnNamed2() public pure returns(uint256 _number, bool _bool, uint256[3] memory _array){
        return(1, true, [uint256(1),2,5]);
    }
```
## Destructuring assignments
`Solidity` internally allows tuple types, i.e. a list of objects of potentially different types whose number is a constant at compile-time. The tuples can be used to return multiple values at the same time.

- Variables declared with type and assigned from the returned tuple, not all elements have to be specified (but the number must match):
```solidity
        uint256 _number;
        bool _bool;
        uint256[3] memory _array;
        (_number, _bool, _array) = returnNamed();
```
- Assign part of return values: Components can be left out. In the following code, we only assign the return value ` _bool2 `, but not ` _ number` and ` _array `:
```solidity
        (, _bool2, ) = returnNamed();
```

## Verify on Remix
- Deploy the contract, and check the return values of the functions.

![](./img/4-1.png)


## Summary
In this section, we introduced function return values `return` and `returns`, including returning multiple variables, named returns, and reading full and part of return values using destructuring assignments. 





