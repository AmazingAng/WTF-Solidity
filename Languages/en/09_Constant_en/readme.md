# Solidity Minimalist Tutorial: 9. Constant and Immutable

Recently, I have been relearning the Solidity, consolidating the finer details, and also writing a "Solidity Minimalist Tutorial" for newbies to learn. Lectures are updated 1~3 times weekly. 

Everyone is welcomed to follow my Twitter: [@0xAA_Science](https://twitter.com/0xAA_Science)

WTF Solidity Discord: [Link](https://discord.gg/5akcruXrsk)

All codebase and tutorial notes are open source and available on GitHub (At 1024 repo stars, course certification is unlocked. At 2048 repo stars, community NFT is unlocked.): [github.com/AmazingAng/WTFSolidity](https://github.com/AmazingAng/WTFSolidity)

-----
In this section, we will introduce two keywords in `solidity`, `constant` and `immutable`. After the state variable declares these two keywords, you cannot change the values after the contract and it will help to save ` gas `. In addition, only the numeric variables can declare them as `constant` and `immutable`; the `string` and ` bytes ` can be declared as `constant`, but not as `immutable`.

## constant and immutable
### constant
The `constant` variable must be initialized when declared and cannot be changed after that. Code cannot compile if try to change it.
``` solidity
    // The constant variable must be initialized when declared and cannot be changed after that
    uint256 constant CONSTANT_NUM = 10;
    string constant CONSTANT_STRING = "0xAA";
    bytes constant CONSTANT_BYTES = "WTF";
    address constant CONSTANT_ADDRESS = 0x0000000000000000000000000000000000000000;
```
### immutable
The `immutable` variable can be initialized at declaration or in the constructor, so it is more flexible.
``` solidity
    // The immutable variable can be initialized in the constructor and cannot be changed later
    uint256 public immutable IMMUTABLE_NUM = 9999999999;
    address public immutable IMMUTABLE_ADDRESS;
    uint256 public immutable IMMUTABLE_BLOCK;
    uint256 public immutable IMMUTABLE_TEST;
```
You can initialize the `immutable` variable using a global variable such as `address(this)`,`block.number`, or a custom function. In the following example, we use the ` test ()` function to initialize the `IMMUTABLE_TEST ` to the ` 9 `:
``` solidity
    // The immutable variables are initialized with constructor, so that could use
    constructor(){
        IMMUTABLE_ADDRESS = address(this);
        IMMUTABLE_BLOCK = block.number;
        IMMUTABLE_TEST = test();
    }

    function test() public pure returns(uint256){
        uint256 what = 9;
        return(what);
    }
```

## Verify on Remix
1. After the contract deployed, initialized values of the `constant` and `immutable` variables can be obtained through the `getter` function on the remix. 

   ![9-1.png](./img/9-1.png)   
   
2. After the `constant` variable initialized, code cannot compile if try to change its value and the compiler will issue an error of `TypeError: Cannot assign to a constant variable. `.

   ![9-2.png](./img/9-2.png)   
   
3. After the `immutable` variable initialized, code cannot compile if try to change its value and the compiler will issue an error of `TypeError: Immutable state variable already initialized. `.

   ![9-3.png](./img/9-3.png)

## Tutorial summary
In this section, we introduced two keywords in `solidity`, `constant` and `immutable`, to keep the variables that should not be changed. It will help to save ` gas ` while improving contract security.


