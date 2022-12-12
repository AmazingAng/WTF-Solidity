---
title: 31. ERC20
tags:
  - solidity
  - application
  - wtfacademy
  - ERC20
  - OpenZeppelin
---

# Solidity Minimalist Tutorial: 31. ERC20

Recently, I have been revisiting Solidity, consolidating the finer details, and writing "WTF Solidity" tutorials for newbies. 

Twitter: [@0xAA_Science](https://twitter.com/0xAA_Science) | [@WTFAcademy_](https://twitter.com/WTFAcademy_)

Community: [Discord](https://discord.wtf.academy)｜[Wechat](https://docs.google.com/forms/d/e/1FAIpQLSe4KGT8Sh6sJ7hedQRuIYirOoZK_85miz3dw7vA1-YjodgJ-A/viewform?usp=sf_link)｜[Website wtf.academy](https://wtf.academy)

Codes and tutorials are open source on GitHub: [github.com/AmazingAng/WTFSolidity](https://github.com/AmazingAng/WTFSolidity)

-----

In this chanpter, we gona learn `ERC20` - Ethereum's token statndard, and create your own test token.

## ERC20

`ERC20` is the token standard on Ethereum, which comes from [`EIP20`](https://eips.ethereum.org/EIPS/eip-20) in November 2015 with the participation of Vitalik, It realizes the basic logic of token transfer:

- account balance
- transfer
- transfer approve
- token's total supply
- token's info(optional): name, symbol, decimal

## IERC20
`IERC20` is the interface contract of `ERC20` token standard, which specifies the functions and events to be implemented by `ERC20` token. 

The reason why the interface needs to be defined is that with the specification, all `ERC20` tokens have common function names, input parameters and output parameters.

In the interface function, you only need to define the function name, input parameters and output parameters, and you don't care about how the function is implemented internally.

Thus, the function can be divided into two parts: internal and external. One is the implementation, and the other is the external interface, which specifies common data.

That's why two files `ERC20.sol` and `ierc20.sol` are needed to realize a contract.

### Event
`IERC20` defines `2` events: `Transfer` event and `Approval` event, which emit in transfering and approving

```solidity
    /**
     * @dev emit when: `value` of token transfer from account(`from`) to other account(`to`)
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev emit when: `value` of token approve from account(`from`) to other account(`to`)
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
```

### function
`IERC 20` defines `6` functions, provides the basic function of transferring tokens, and allows tokens to be approved for use by third parties in other chains.

- `totalSupply()` return the total supply of token
```solidity
    /**
     * @dev return the total supply of token
     */
    function totalSupply() external view returns (uint256);
```

- `balanceOf()` return account's balance
```solidity
    /**
     * @dev return the number of token held by `account`
     */
    function balanceOf(address account) external view returns (uint256);
```

- `transfer()` transfering token
```solidity
    /**
     * @dev transfer `amount` token, from caller's account to other account(`to`)
     *
     * return `true` if success
     *
     * emit {Transfer} event
     */
    function transfer(address to, uint256 amount) external returns (bool);
```

- `allowance()` return amount of approved
```solidity
    /**
     * @dev return the amount of approved from `owner` to `spender`, default is 0
     *
     * when {approve} or {transferFrom} be invoked, `allowance` will be change
     */
    function allowance(address owner, address spender) external view returns (uint256);
```

- `approve()` Approval
```solidity
    /**
     * @dev caller's account approve `amount` of token to `spender`
     *
     * return `true` if success
     *
     * emit {Approval} event
     */
    function approve(address spender, uint256 amount) external returns (bool);
```

- `transferFrom()` Approve transfer
```solidity
    /**
     * @dev through the principle of approve, transfer `amount` of token from `from` to `to`. Part of token will be deducted from caller's `allowance`
     *
     * return `true` if success
     *
     * emit {Transfer} event
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
```

## ERC20 implementation

Now, we gona write a `ERC20`, which implement simply functions which defined in `IERC20`.

### State Varaible
We need state variables to record account balance, approve amount and token information. Where `balanceOf`, `allowance` and `Total Supply` are the type of `public`, a `getter` function with the same name will be automatically generated to realize `balanceof()`, `allowance()` and `totalSupply()` specified in `IERC20`. And `name`, `symbol`, `decimals` correspond to the name, symbol and decimal of tokens.

**Caution**: Modifying the `public` variable with `override` will override the`getter` function with the same name as the variable inherited from the parent contract, such as the `balanceOf()` function in `IERC20`.

```solidity
    mapping(address => uint256) public override balanceOf;

    mapping(address => mapping(address => uint256)) public override allowance;

    uint256 public override totalSupply;   // token's total supply

    string public name;   // token's name
    string public symbol;  // token's symbol
    
    uint8 public decimals = 18; // token's decimal
```

### function
- constructor: init token's name, symbol
```solidity
    constructor(string memory name_, string memory symbol_){
        name = name_;
        symbol = symbol_;
    }
```
- `transfer()` function: implement the `transfer` function in `IERC20`, the token's transfer logic. The caller deducts amount tokens, and the receiver adds corresponding tokens. The dog coin will magic change this function, adding the logic of taxation, dividends, lottery and so on.
```solidity
    function transfer(address recipient, uint amount) external override returns (bool) {
        balanceOf[msg.sender] -= amount;
        balanceOf[recipient] += amount;
        emit Transfer(msg.sender, recipient, amount);
        return true;
    }
```

- `approve()` function: implement the `approve` function in `IERC20`, the token's authorization logic. The authorized party' spender' can control the authorized party's `amount` of tokens. `spender` can be an EOA account or a contract account: when you trade tokens with `uniswap`, you need to authorize the tokens to the `uniswap` contract at first.

```solidity
    function approve(address spender, uint amount) external override returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }
```
- `transferFrom()` function: Implement the `transferFrom` function in ` IERC20`, the token's approve logic. The authorized party transfers the `amount` tokens of the authorized party `sender` to the receiver `recipient`.
```solidity
    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external override returns (bool) {
        allowance[sender][msg.sender] -= amount;
        balanceOf[sender] -= amount;
        balanceOf[recipient] += amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }
```

- `mint()` function: function of mint token, which is not in the `IERC20` standard. For the convenience of the tutorial here, anyone can mint any number of tokens. In practical application, permission management will be added, and only `owner` can mint tokens:
```solidity
    function mint(uint amount) external {
        balanceOf[msg.sender] += amount;
        totalSupply += amount;
        emit Transfer(address(0), msg.sender, amount);
    }
```

- `burn()` function: function of burn tokens, which is not in the `IERC20` standard.
```solidity
    function burn(uint amount) external {
        balanceOf[msg.sender] -= amount;
        totalSupply -= amount;
        emit Transfer(msg.sender, address(0), amount);
    }
```

## Create `ERC20` token

With the `ERC20` standard, it is very simple to create tokens on the `ETH` chain. Now, let's create our first token.

Compile the `ERC20` contract on `Remix`, enter the parameters of the constructor in the deployment column, both `name_` and `symbol_` are set to `WTF`, and then click the `transact` key to deploy.

![Deploy Contract](./img/31-1.png)

In this way, we've created the `WTF` token. We need to run the `mint()` function to mint some tokens for ourselves. Click the `ERC20` contract in `Deployed Contract`, enter `100` in the `mint` function column and click the `mint` button to cast `100` `WTF` tokens for yourself.

You can click the Debug button on the right to see the logs below.

It contains four key messages：
- event `Transfer`
- Mint address `0x0000000000000000000000000000000000000000`
- Receive address `0x5B38Da6a701c568545dCfcB03FcB875f56beddC4`
- token amount `100`

![Mint Token](./img/31-2.png)

We use the `balanceOf()` function to query the account balance. Input our account address, we can see the balance becomes `100`, and the mint is success.

Account information is shown on the left side of the figure, and the right side is marked with the specific information of function execution.

![Query Balance](./img/31-3.png)


## Summarize

In this chapter, we learned the `ERC20` standard on Ethereum and its implementation, and created our own test tokens. The `ERC20` token standard proposed at the end of 2015 has greatly lowered the threshold for issuing tokens in Ethereum, and opened the `ICO` era. When investing, carefully reading the token contract of the project can effectively avoid the temptation and increase the success rate of investment.
