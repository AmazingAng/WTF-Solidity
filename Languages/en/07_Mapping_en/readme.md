# Solidity Minimalist Primer: 7. Mapping

Recently, I have been relearning the Solidity, consolidating the finer details, and also writing a "Solidity Minimalist Primer" for newbies to learn and use from (advanced programmers can find another tutorial). Lectures are updated 1~3 times weekly. 

Everyone is welcomed to follow my Twitter: [@0xAA_Science](https://twitter.com/0xAA_Science)

WTF Solidity Discord: [Link](https://discord.gg/5akcruXrsk)

All codebase and tutorial notes are open source and available on GitHub (At 1024 repo stars, course certification is unlocked. At 2048 repo stars, community NFT is unlocked.): [github.com/AmazingAng/WTFSolidity](https://github.com/AmazingAng/WTFSolidity)

-----

In this section, we will introduce the hash table in Solidity: `Mapping` type.

## Mapping
In the mapping, people can query the corresponding `Value` by the `Key`. For example, a person's wallet address can be queried by his `id`.

The format of declaring the mapping is `mapping(_KeyType => _ValueType)`, where `_KeyType` and `_ValueType` are the variable types of `Key` and `Value` respectively. Example:
```solidity
    mapping(uint => address) public idToAddress; // id maps to address
    mapping(address => address) public swapPair; // Mapping of token pairs, from address to address
```

## Rules of mapping
- **Rule 1**: The `_KeyType` should be selected among default types in `solidity` such as ` uint `, `address`, etc. No custom struct can be used. However, `_ValueType` can be any custom types. The following example will throw an error, because `_KeyType` uses a custom struct:
```solidity
      //Define a struct
      struct Student{
          uint256 id;
          uint256 score;
      }
      mapping(Student => uint) public testVar;
```
- **Rule 2**: The storage location of the mapping must be `storage`: it can serve as the state variable or the `storage` variable inside function. But it can't be used in arguments or return results of `public` function.

- **Rule 3**: If the mapping is declared as `public` then `solidity` will automatically create a `getter` function for you to query for the `Value` by the `Key`.

- **Rule 4**：The syntax of adding a key-value pair to a mapping is `_Var[_Key] = _Value`, where '_Var' is the name of the mapping variable, and '_Key' and '_Value' correspond to the new key-value pair. Example:
```solidity
    function writeMap (uint _Key, address _Value) public {
        idToAddress[_Key] = _Value;
      }
```
## Principle of mapping
- **principle 1**: The mapping does not store any `key` information or length information.

- **principle 2**: Mapping use `keccak256(key)` as offset to access value.

- **principle 3**: Since Ethereum defines all unused space as 0, all `key` that are not assigned a `Value` will have an initial Value of 0.

## Verify on Remix (use `Mapping.sol` as example)
- Example of mapping 1 deploy

    ![7-1_en](./img/7-1_en.png)

- Example of mapping 2 initial value

    ![7-2_en](./img/7-2_en.png)

- Example of mapping 3 key-value pair

    ![7-3_en](./img/7-3_en.png)



## Tutorial summary
In this section，we introduced the `Mapping` type in `solidity`. So far, we've learned all kinds of common variables, and then we'll learn control flow such as `if-else`, `while` in the coming tutorials.
