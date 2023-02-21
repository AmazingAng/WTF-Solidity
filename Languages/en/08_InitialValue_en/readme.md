# WTF Solidity Tutorial: 8. Initial Value

Recently, I have been revisiting Solidity, consolidating the finer details, and writing "WTF Solidity" tutorials for newbies. 

Twitter: [@0xAA_Science](https://twitter.com/0xAA_Science) | [@WTFAcademy_](https://twitter.com/WTFAcademy_)

Community: [Discord](https://discord.wtf.academy)｜[Wechat](https://docs.google.com/forms/d/e/1FAIpQLSe4KGT8Sh6sJ7hedQRuIYirOoZK_85miz3dw7vA1-YjodgJ-A/viewform?usp=sf_link)｜[Website wtf.academy](https://wtf.academy)

Codes and tutorials are open source on GitHub: [github.com/AmazingAng/WTFSolidity](https://github.com/AmazingAng/WTFSolidity)


-----

## Initial values of variables

In Solidity, variables declared but not assigned have their initial/default values. In this tutorial, we will introduce the initial values of common variable types.

### Initial values of value types

- `boolean`: `false`
- `string`: `""`
- `int`: `0`
- `uint`: `0`
- `enum`: first element in enumeration 
- `address`: `0x0000000000000000000000000000000000000000` (or `address(0)`)
- `function`
    - `internal`: blank function
    - `external`: blank function

You can use `getter` function of `public` variables to confirm the above initial values:

```solidity
    bool public _bool; // false
    string public _string; // ""
    int public _int; // 0
    uint public _uint; // 0
    address public _address; // 0x0000000000000000000000000000000000000000

    enum ActionSet {Buy, Hold, Sell}
    ActionSet public _enum; // first element 0

    function fi() internal{} // internal blank function
    function fe() external{} // external blank function
```

### Initial values of reference types

- `mapping`: a `mapping` which all members set to their default values
- `struct`: a `struct` which all members set to their default values

- `array`
    - dynamic array: `[]`
    - static array（fixed-length): a static array where all members set to their default values.

You can use `getter` function of `public` variables to confirm initial values:

```solidity
    // reference types
    uint[8] public _staticArray; // a static array which all members set to their default values[0,0,0,0,0,0,0,0]
    uint[] public _dynamicArray; // `[]`
    mapping(uint => address) public _mapping; // a mapping which all members set to their default values
    // a struct which all members set to their default values 0, 0
    struct Student{
        uint256 id;
        uint256 score; 
    }
    Student public student;
```

### `delete` operator

`delete a` will change the value of variable `a` to its initial value.

```solidity
    // delete operator
    bool public _bool2 = true; 
    function d() external {
        delete _bool2; // delete will make _bool2 change to default(false)
    }
```

## Verify on Remix

- Deploy `InitialValue.sol` and check the initial values of the different types.

    ![](./img/8-1_en.jpg)

- After using the `delete` operator, the value of the variables are reset to their initial values.

    ![](./img/8-2_en.jpg)

## Summary

In this section, we introduced the initial values of variables in Solidity. When a variable is declared but not assigned, its value defaults to the initial value, which is equivalent as `0` represented in its type. The `delete` operator can reset the value of the variable to the initial value.
