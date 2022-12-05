# WTF Solidity Tutorial: 2. Value Types

Recently, I have been revisiting Solidity, consolidating the finer details, and writing "WTF Solidity" tutorials for newbies. 

Twitter: [@0xAA_Science](https://twitter.com/0xAA_Science) | [@WTFAcademy_](https://twitter.com/WTFAcademy_)

Community: [Discord](https://discord.wtf.academy)｜[Wechat](https://docs.google.com/forms/d/e/1FAIpQLSe4KGT8Sh6sJ7hedQRuIYirOoZK_85miz3dw7vA1-YjodgJ-A/viewform?usp=sf_link)｜[Website wtf.academy](https://wtf.academy)

Codes and tutorials are open source on GitHub: [github.com/AmazingAng/WTFSolidity](https://github.com/AmazingAng/WTFSolidity)


-----

### Variable Types in Solidity

1. **Value Type**：This include boolean, integer, etc. Varialbes of these types will always be passed by value (i.e. always create a new copy when used as function arguments or in assignments).

2. **Reference Type**：This includes arrays and structs. Variables of these types take up a large amount of storage, will be passed by pointers during assignment, and can be modified through multiple variable names. 

3. **Mapping Type**: These are similar to hash tables for Solidity.

4. **Function Type**：The Solidity documentation classifies functions into value types, but I think they are very different. So I will classify them separately. 

Only the most common types will be introduced here. In this chapter, we will introduce value types.

## Value types

### 1. Boolean

The value of a Boolean is binary, either `true` or `false`.

```solidity
    // Boolean
    bool public _bool = true;
```

Operators for Boolean type include:

- `!`   (logical NOT)
- `&&`  (logical AND)
- `||`  (logical OR)
- `==`  (equality)
- `!=`  (inequality)

Code：

```solidity
    // Boolean operators
    bool public _bool1 = !_bool; // logical NOT
    bool public _bool2 = _bool && _bool1; // logical AND
    bool public _bool3 = _bool || _bool1; // logical OR
    bool public _bool4 = _bool == _bool1; // equality
    bool public _bool5 = _bool != _bool1; // inequality
```

From the above source code：the value of the variable `_bool` is `true`；so `_bool1` is not`_bool`，which yields `false`；`_bool && _bool1``s value is `false`；`_bool || _bool1``s value is `true`；`_bool == _bool1``s value is `false`；and `_bool != _bool1``s value is `true`.

**Important note：** The `&&` and `||` operator follows a short-circuit evaluation rule. This means that for an expression such as `f(x) || g(y)`，if `f(x)` is `true`，then `g(y)` will not be computed; even if its result is the opposite of `f(x)`.

### 2. Integers

Integers are the whole numbers in Solidity，most frequently used examples include:

```solidity
    // Integer
    int public _int = -1; // integers including negative numbers
    uint public _uint = 1; // positive numbers
    uint256 public _number = 20220330; // 256-bit positive integers
```
Some commonly used integer operators include:

- Inequality operator (which returns a Boolean)： `<=`， `<`， `==`， `!=`， `>=`， `>` 
- Arithmetic operator： `+`， `-`， unary operators `-`， `+`， `*`， `/`， `%` (modulo)，`**` (exponent)

Code：

```solidity
    // Integer operators
    uint256 public _number1 = _number + 1; // +，-，*，/
    uint256 public _number2 = 2**2; // Exponent
    uint256 public _number3 = 7 % 2; // Modulo (Modulus)
    bool public _numberbool = _number2 > _number3; // Great than
```

You can run the above code and check the values of the variables.

### 3. Addresses

Address type stores a 20-bit value, the same as the size of an Ethereum address. Address types also have member variables and functions. There are two types of address: plain addresses and `payable` addresses. The `payable` address has two members, `balance()` and `transfer()`, making it easy to check `ETH` balances and transfer funds. You are not supposed to send `ETH` to plain addresses.

Code:

```solidity
    // Address
    address public _address = 0x7A58c0Be72BE218B41C608b7Fe7C5bB630736C71;
    address payable public _address1 = payable(_address); // payable address (can transfer fund and check balance)
    // Members of address
    uint256 public balance = _address1.balance; // balance of address
```

### 4. Fixed-size byte arrays

There are two types of byte arrays (`bytes`): fixe-sized (`byte`, `bytes8`, `bytes32`) and dynamically-sized (`bytes`, `string`). The fixe-sized byte arrays belong to value type, and the dynamically-sized belong to reference type. The fixe-sized byte arrays can store data, and consumes less `gas`.

Code：

```solidity
    // Fixed-size byte arrays
    bytes32 public _byte32 = "MiniSolidity"; 
    bytes1 public _byte = _byte32[0]; 
```

We assign value `MiniSolidity` to the variable `_byte32`, or in `hexadecimal`: `0x4d696e69536f6c69646974790000000000000000000000000000000000000000`

On the other hand, the `_byte` variable stores the first byte of the `_byte32` variable, which is `0x4d`.

### 5. Enumeration

Enumeration (`enum`) is a user-defined data type within Solidity. It is mainly used to assign names to `uint`, which keeps the program easy to read.

Code:

```solidity
    // Let uint 0， 1， 2 represent Buy, Hold, Sell
    enum ActionSet { Buy, Hold, Sell }
    // Create an enum variable called action
    ActionSet action = ActionSet.Buy;
```

It can be converted to `uint` easily:

```solidity
    // Enum can be converted into uint
    function enumToUint() external view returns(uint){
        return uint(action);
    }
```

`enum` is a less popular type in Solidity. 

## Example with Remix

- After deploying the contract, you can cehck the values of each variable:

   ![2-1.png](./img/2-1.png)
  
- Conversion between enum and uint:

   ![2-2.png](./img/2-2.png)

   ![2-3.png](./img/2-3.png)

## Summary 

In this chapter, we introduced the variable types in Solidity and explained the boolean, integer, address, fixed-length byte array, and enumeration in value types. We will cover several other types in the subsequent tutorials.
