---
title: 25. Create2
tags:
  - solidity
  - advanced
  - wtfacademy
  - create contract
  - create2
---

# Solidity Minimalist Tutorial: 25. Create2

Recently, I have been relearning Solidity, consolidating the finer details, and also writing a "Solidity Minimalist Tutorial" for newbies to learn. Lectures are updated 1~3 times weekly. 

Everyone is welcomed to follow my Twitter: [@0xAA_Science](https://twitter.com/0xAA_Science)

WTF Academy Discord,  where you can find the way to join WeChat group:  [Link](https://discord.gg/5akcruXrsk)

All codebase and tutorial notes are open source and available on GitHub (At 1024 repo stars, course certification is unlocked. At 2048 repo stars, community NFT is unlocked.): [github.com/AmazingAng/WTFSolidity](https://github.com/AmazingAng/WTFSolidity)

-----

`CREATE2` opcode helps us to predict the address of smart contract before it is deployed on Ethereum network, and `Uniswap` created `Pair` contract with `CREATE2` instead of `CREATE`.

In this chapter, I will introduce the use of `CREATE2`.

## How does `CREATE` calculate address
Smart contracts can be created by other contracts and regular accounts using the `CREATE` opcode. 

In both cases, the address of new contract is calculated in the same way: the hash of creator's address (usually wallet address which will deploy or contract address) and the nonce(the total number of transactions sent from this address or, for contract account, the total number of contracts created. Every time a contract is created, the nonce will plus one).
```
new address = hash(creator's address, nonce)
```
creator's address won't change, but the nonce may change over time, so it's
difficult to predict the address of contract created with CREATE.

## How does `CREATE2` calculate address
The purpose of `CREATE2` is to make contract address independent of future events. No matter what happens on blockchain in the future, you can deploy the contract to a pre-calculated address.

The address of contract created with `CREATE2` is determined by four parts:
- `0xFF`: a constant to avoid conflict with `CREATE`
- creator's address
- salt: a value given by creator
- The bytecode of contract to be deployed

```
new address = hash("0xFF", creator's address, salt, bytecode)
```
`CREATE2` ensures that if creator deploys a given contract bytecode with `CREATE2` and given `salt`, it will be stored at `new address`.

## How to use `CREATE2`
`CREATE2` is used in the same way as `Create`. It also `new` a new contract and passes in parameters which is needed for the new contract constructor, except with an extra `salt` parameter.
```
Contract x = new Contract{salt: _salt, value: _value}(params)
```
`Contract` is the name of contract to be created, `x` is the contract object (address), and `_salt` is the specified salt; If the constructor is `payable`, a number of(`_value`) `ETH` can be transferred to the contract at creation, and `params` is the parameter of new contract constructor.

## Minimalist Uniswap2

Similar to [the previous chapter](https://github.com/AmazingAng/WTF-Solidity/tree/main/Languages/en/24_Create_en), we use `Create2` to implement a minimalist `Uniswap`.

### `Pair`
```solidity
contract Pair{
    address public factory; // factory contract address
    address public token0; // token1
    address public token1; // token2

    constructor() payable {
        factory = msg.sender;
    }

    // called once by the factory at time of deployment
    function initialize(address _token0, address _token1) external {
        require(msg.sender == factory, 'UniswapV2: FORBIDDEN'); // sufficient check
        token0 = _token0;
        token1 = _token1;
    }
}
```
`Pair` contract is simple and contains three state variables: `factory`, `token0` and `token1`.

Constructor assigns the `factory` to factory contract address at deployment time. `initialize` function is called once by factory contract when the `Pair` contract is created, updating `token0` and `token1` to the addresses of two tokens in the token pair.

### `PairFactory2`
```solidity
contract PairFactory2{
        mapping(address => mapping(address => address)) public getPair; // Find the Pair address by two token addresses
        address[] public allPairs; // Save all Pair addresses

        function createPair2(address tokenA, address tokenB) external returns (address pairAddr) {
            require(tokenA != tokenB, 'IDENTICAL_ADDRESSES'); //Avoid conflicts when tokenA and tokenB are the same
            // Calculate salt with tokenA and tokenB addresses
            (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA); //Sort tokenA and tokenB by size
            bytes32 salt = keccak256(abi.encodePacked(token0, token1));
            //Deploy new contract with create2
            Pair pair = new Pair{salt: salt}(); 
            // call initialize function of the new contract
            pair.initialize(tokenA, tokenB);
            // Update address map
            pairAddr = address(pair);
            allPairs.push(pairAddr);
            getPair[tokenA][tokenB] = pairAddr;
            getPair[tokenB][tokenA] = pairAddr;
        }
```
Factory contract(`PairFactory2`) has two state variables. `getPair` is a map of two token addresses to the token pair address. It is convenient to find the token pair address according to tokens. `allPairs` is an array of token pair address, storing all token pair addresses.

`PairFactory2` contract has only one `createPair2` function, which uses `CREATE2` to create a new `Pair` contract based on the two token addresses `tokenA` and `tokenB` entered. Inside
```solidity
    Pair pair = new Pair{salt: salt}(); 
```
It's the above code that uses `CREATE2` to create contract, which is very simple, and `salt` is the hash of `token1` and `token2`.
```solidity
    bytes32 salt = keccak256(abi.encodePacked(token0, token1));
```

### Calculate `Pair` address beforehand
```solidity
        // Calculate Pair contract address beforehand
        function calculateAddr(address tokenA, address tokenB) public view returns(address predictedAddress){
            require(tokenA != tokenB, 'IDENTICAL_ADDRESSES'); //Avoid conflicts when tokenA and tokenB are the same
            // Calculate salt with tokenA and tokenB addresses
            (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA); //Sort tokenA and tokenB by size
            bytes32 salt = keccak256(abi.encodePacked(token0, token1));
            // Calculate contract address
            predictedAddress = address(uint160(uint(keccak256(abi.encodePacked(
                bytes1(0xff),
                address(this),
                salt,
                keccak256(type(Pair).creationCode)
            )))));
        }
```
We write a `calculateAddr` function to precompute the address of `Pair` that `tokenA` and `tokenB` will generate. With it, we can verify whether the address we calculated in advance is the same as actual address.

You can deploy `PairFactory2` contract and call `createPair2` with the following two addresses as parameters to see what is the address of token pair created and whether it is the same as the precomputed address.

```
WBNB address: 0x2c44b726ADF1963cA47Af88B284C06f30380fC78
PEOPLE address on BSC:
0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c
```

#### If there are parameters in deployment contract constructor

For example, when `create2` contract:
> Pair pair = new Pair{salt: salt}(address(this)); 

When calculating, you need to package parameters and bytecode together:

> ~~keccak256(type(Pair).creationCode)~~
> => keccak256(abi.encodePacked(type(Pair).creationCode, abi.encode(address(this))))
```solidity
predictedAddress = address(uint160(uint(keccak256(abi.encodePacked(
                bytes1(0xff),
                address(this),
                salt,
                keccak256(abi.encodePacked(type(Pair).creationCode, abi.encode(address(this))))
            )))));
```

### Verify on remix
1. First, the address hash of `WBNB` and `PEOPLE` is used as `salt` to calculate the address of `Pair` contract
2. Calling `PairFactory2.createPair2` and the address of `WBNB` and `PEOPLE` are passed in as parameters to get the address of `pair` contract created.
3. Compare contract address.

![create2_remix_test.png](./img/25-1_en.jpg)

## Application scenario of `CREATE2`
1. The exchange reserves addresses for new users to create wallet contracts.
2. `Factory` contract driven by `CREATE2`. The creation of trading pairs in `UniswapV2` is done by calling `create2` in `Factory`. The advantage is: It can get a certain `pair` address, so that the Router can calculate `pair` address through `(tokenA, tokenB)`, no longer need to perform a `Factory.getPair(tokenA, tokenB)` cross-contract call.

## Summary
In this chapter, we introduced the principle of `CREATE2` opcode and how to use it. Besides, we used it to create a minimalist version of `Uniswap` and calculate token pair contract address in advance. `CREATE2` helps us to determine contract address before deploying the contract, which is basis for some `layer2` projects.
