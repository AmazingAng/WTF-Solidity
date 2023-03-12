---
title: 51. ERC4626 Tokenization of Vault Standard
tags:
  - solidity
  - erc20
  - erc4626
  - defi
  - vault
  - openzepplin
---

# WTF Simplified Introduction to Solidity: 51. ERC4626 Tokenization of Vault Standard

I have recently been revising Solidity to consolidate the details, and am writing a "WTF Simplified Introduction to Solidity" for beginners to use (programming experts can find other tutorials), with weekly updates of 1-3 lectures.

Twitter: [@0xAA_Science](https://twitter.com/0xAA_Science)

Community: [Discord](https://discord.gg/5akcruXrsk)｜[WeChat group](https://docs.google.com/forms/d/e/1FAIpQLSe4KGT8Sh6sJ7hedQRuIYirOoZK_85miz3dw7vA1-YjodgJ-A/viewform?usp=sf_link)｜[Official website wtf.academy](https://wtf.academy)

All code and tutorials are open source on GitHub: [github.com/AmazingAng/WTFSolidity](https://github.com/AmazingAng/WTFSolidity)

-----

We often say that DeFi is like LEGO blocks, where you can create new protocols by combining multiple protocols. However, due to the lack of standards in DeFi, its composability is severely affected. ERC4626 extends the ERC20 token standard and aims to standardize yield vaults. In this talk, we will introduce the new generation DeFi standard - ERC4626 and write a simple vault contract. The teaching code reference comes from the ERC4626 contract in openzeppelin and solmate and is for educational purposes only.

## Vault

The vault contract is the foundation of DeFi LEGO blocks. It allows you to pledge basic assets (tokens) to the contract in exchange for certain returns, including the following applications:

- Yield farming: In Yearn Finance, you can pledge USDT to earn interest.
- Lending: In AAVE, you can loan ETH to earn deposit interest and loan interest.
- Staking: In Lido, you can stake ETH to participate in ETH 2.0 staking and obtain stETH that can be used to earn interest.

## ERC4626

![](./img/51-1.png)

Since the vault contract lacks standards, there are various ways of implementation. A yield aggregator needs to write many interfaces to connect with different DeFi projects. The ERC4626 Tokenized Vault Standard has emerged to enable easy expansion of DeFi with the following advantages:

1. Tokenization: ERC4626 inherits ERC20. When depositing to the vault, you will receive vault shares that are also compliant with the ERC20 standard. For example, when staking ETH, you will automatically get stETH as your share.

2. Better liquidity: Due to tokenization, you can use vault shares to do other things without withdrawing the underlying assets. For example, you can use Lido's stETH to provide liquidity or trade on Uniswap, without withdrawing any ETH.

3. Better composability: With the standard in place, a single set of interfaces can interact with all ERC4626 vaults, making it easier to develop applications, plugins, and tools based on vaults.

In summary, the importance of ERC4626 for DeFi is no less than that of ERC721 for NFTs.

### Key Points of ERC4626

The ERC4626 standard mainly implements the following logics:

1. ERC20: ERC4626 inherits ERC20, and the vault shares are represented by ERC20 tokens: users deposit specific ERC20 underlying assets (such as WETH) into the vault, and the contract mints a specific number of vault share tokens for them; When users withdraw underlying assets from the vault, the corresponding number of vault share tokens will be destroyed. The `asset()` function returns the token address of the vault's underlying asset.
2. Deposit logic: allows users to deposit underlying assets and mint corresponding number of vault shares. Related functions are `deposit()` and `mint()`. The `deposit(uint assets, address receiver)` function allows users to deposit `assets` units of assets and mint corresponding number of vault shares to `receiver` address. `mint(uint shares, address receiver)` is similar, except that it takes the minted vault shares as a parameter.
3. Withdrawal logic: allows users to destroy vault share tokens and withdraw corresponding number of underlying assets from the vault. Related functions are `withdraw()` and `redeem()`, the former taking the amount of underlying assets to be withdrawn as a parameter, and the latter taking the number of destroyed vault share tokens as a parameter.
4. Accounting and limit logic: other functions in the ERC4626 standard are for asset accounting in the vault, deposit and withdrawal limits, and the number of underlying assets and vault shares for deposit and withdrawal.

### IERC4626 Interface Contract

The IERC4626 interface contract includes a total of `2` events:
- `Deposit` event: triggered when depositing.
- `Withdraw` event: triggered when withdrawing.

The IERC4626 interface contract also includes `16` functions, which are classified into `4` categories according to their functionality: metadata functions, deposit/withdrawal logic functions, accounting logic functions, and deposit/withdrawal limit logic functions.

- Metadata
    - `asset()`: returns the address of the underlying asset token of the vault, which is used for deposit and withdrawal.
- Deposit/Withdrawal Logic
    - `deposit()`: a function that allows users to deposit `assets` units of the underlying asset into the vault, and the contract mints `shares` units of the vault's shares to the `receiver` address. It releases a `Deposit` event.
    - `mint()`: a minting function (also a deposit function) that allows users to deposit `assets` units of the underlying asset and the contract mints the corresponding amount of the vault's shares to the `receiver` address. It releases a `Deposit` event.
    - `withdraw()`: a function that allows the `owner` address to burn `share` units of the vault's shares, and the contract sends the corresponding amount of the underlying asset to the `receiver` address.
    - `redeem()`: a redemption function (also a withdrawal function) that allows the `owner` address to burn `share` units of the vault's shares and the contract sends the corresponding amount of the underlying asset to the `receiver` address.
- Accounting Logic
    - `totalAssets()`: returns the total amount of underlying asset tokens managed in the vault.
    - `convertToShares()`: returns the amount of vault shares that can be obtained by using a certain amount of the underlying asset.
    - `convertToAssets()`: returns the amount of underlying asset that can be obtained by using a certain amount of vault shares.
    - `previewDeposit()`: used by users to simulate the amount of vault shares they can obtain by depositing a certain amount of the underlying asset in the current on-chain environment.
    - `previewMint()`: used by users to simulate the amount of underlying asset needed to mint a certain amount of vault shares in the current on-chain environment.
    - `previewWithdraw()`: used by users to simulate the amount of vault shares they need to redeem to withdraw a certain amount of the underlying asset in the current on-chain environment.
    - `previewRedeem()`: used by on-chain and off-chain users to simulate the amount of underlying asset they can redeem by burning a certain amount of vault shares in the current on-chain environment.
- Deposit/Withdrawal Limit Logic
    - `maxDeposit()`: returns the maximum amount of the underlying asset that a certain user address can deposit in a single deposit.
    - `maxMint()`: returns the maximum amount of vault shares that a certain user address can mint in a single mint.
    - `maxWithdraw()`: returns the maximum amount of the underlying asset that a certain user address can withdraw in a single withdrawal.

- `maxRedeem()`: Returns the maximum vault quota that can be destroyed in a single redemption for a given user address.

```solidity
// SPDX-License-Identifier: MIT
// Author: 0xAA from WTF Academy

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

/**
 * @dev ERC4626 "代币化金库标准"的接口合约
 * https://eips.ethereum.org/EIPS/eip-4626[ERC-4626].
 */
interface IERC4626 is IERC20, IERC20Metadata {
    /*//////////////////////////////////////////////////////////////
                                 事件
    //////////////////////////////////////////////////////////////*/
    // 存款时触发
    event Deposit(address indexed sender, address indexed owner, uint256 assets, uint256 shares);

    // 取款时触发
    event Withdraw(
        address indexed sender,
        address indexed receiver,
        address indexed owner,
        uint256 assets,
        uint256 shares
    );

    /*//////////////////////////////////////////////////////////////
                            元数据
    //////////////////////////////////////////////////////////////*/
    /**
     * @dev 返回金库的基础资产代币地址 （用于存款，取款）
     * - 必须是 ERC20 代币合约地址.
     * - 不能revert
     */
    function asset() external view returns (address assetTokenAddress);

    /*//////////////////////////////////////////////////////////////
                        存款/提款逻辑
    //////////////////////////////////////////////////////////////*/
    /**
     * @dev 存款函数: 用户向金库存入 assets 单位的基础资产，然后合约铸造 shares 单位的金库额度给 receiver 地址
     *
     * - 必须释放 Deposit 事件.
     * - 如果资产不能存入，必须revert，比如存款数额大大于上限等。
     */
    function deposit(uint256 assets, address receiver) external returns (uint256 shares);

    /**
     * @dev 铸造函数: 用户需要存入 assets 单位的基础资产，然后合约给 receiver 地址铸造 share 数量的金库额度
     * - 必须释放 Deposit 事件.
     * - 如果全部金库额度不能铸造，必须revert，比如铸造数额大大于上限等。
     */
    function mint(uint256 shares, address receiver) external returns (uint256 assets);

    /**
     * @dev 提款函数: owner 地址销毁 share 单位的金库额度，然后合约将 assets 单位的基础资产发送给 receiver 地址
     * - 释放 Withdraw 事件
     * - 如果全部基础资产不能提取，将revert
     */
    function withdraw(uint256 assets, address receiver, address owner) external returns (uint256 shares);

    /**
     * @dev 赎回函数: owner 地址销毁 shares 数量的金库额度，然后合约将 assets 单位的基础资产发给 receiver 地址
     * - 释放 Withdraw 事件
     * - 如果金库额度不能全部销毁，则revert
     */
    function redeem(uint256 shares, address receiver, address owner) external returns (uint256 assets);

    /*//////////////////////////////////////////////////////////////
                            会计逻辑
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev 返回金库中管理的基础资产代币总额
     * - 要包含利息
     * - 要包含费用
     * - 不能revert
     */
    function totalAssets() external view returns (uint256 totalManagedAssets);

    /**
     * @dev 返回利用一定数额基础资产可以换取的金库额度
     * - 不要包含费用
     * - 不包含滑点
     * - 不能revert
     */
    function convertToShares(uint256 assets) external view returns (uint256 shares);

    /**
     * @dev 返回利用一定数额金库额度可以换取的基础资产
     * - 不要包含费用
     * - 不包含滑点
     * - 不能revert
     */
    function convertToAssets(uint256 shares) external view returns (uint256 assets);

    /**
     * @dev 用于链上和链下用户在当前链上环境模拟存款一定数额的基础资产能够获得的金库额度
     * - 返回值要接近且不大于在同一交易进行存款得到的金库额度
     * - 不要考虑 maxDeposit 等限制，假设用户的存款交易会成功
     * - 要考虑费用
     * - 不能revert
     * NOTE: 可以利用 convertToAssets 和 previewDeposit 返回值的差值来计算滑点
     */
    function previewDeposit(uint256 assets) external view returns (uint256 shares);

    /**
     * @dev 用于链上和链下用户在当前链上环境模拟铸造 shares 数额的金库额度需要存款的基础资产数量
     * - 返回值要接近且不小于在同一交易进行铸造一定数额金库额度所需的存款数量
     * - 不要考虑 maxMint 等限制，假设用户的存款交易会成功
     * - 要考虑费用
     * - 不能revert
     */
    function previewMint(uint256 shares) external view returns (uint256 assets);

    /**
     * @dev 用于链上和链下用户在当前链上环境模拟提款 assets 数额的基础资产需要赎回的金库份额
     * - 返回值要接近且不大于在同一交易进行提款一定数额基础资产所需赎回的金库份额
     * - 不要考虑 maxWithdraw 等限制，假设用户的提款交易会成功
     * - 要考虑费用
     * - 不能revert
     */
    function previewWithdraw(uint256 assets) external view returns (uint256 shares);

    /**
     * @dev 用于链上和链下用户在当前链上环境模拟销毁 shares 数额的金库额度能够赎回的基础资产数量
     * - 返回值要接近且不小于在同一交易进行销毁一定数额的金库额度所能赎回的基础资产数量
     * - 不要考虑 maxRedeem 等限制，假设用户的赎回交易会成功
     * - 要考虑费用
     * - 不能revert.
     */
    function previewRedeem(uint256 shares) external view returns (uint256 assets);

    /*//////////////////////////////////////////////////////////////
                     存款/提款限额逻辑
    //////////////////////////////////////////////////////////////*/
    /**
     * @dev 返回某个用户地址单次存款可存的最大基础资产数额。
     * - 如果有存款上限，那么返回值应该是个有限值
     * - 返回值不能超过 2 ** 256 - 1 
     * - 不能revert
     */
    function maxDeposit(address receiver) external view returns (uint256 maxAssets);

    /**
     * @dev 返回某个用户地址单次铸造可以铸造的最大金库额度
     * - 如果有铸造上限，那么返回值应该是个有限值
     * - 返回值不能超过 2 ** 256 - 1 
     * - 不能revert
     */
    function maxMint(address receiver) external view returns (uint256 maxShares);

    /**
     * @dev 返回某个用户地址单次取款可以提取的最大基础资产额度
     * - 返回值应该是个有限值
     * - 不能revert
     */
    function maxWithdraw(address owner) external view returns (uint256 maxAssets);

    /**
     * @dev 返回某个用户地址单次赎回可以销毁的最大金库额度
     * - 返回值应该是个有限值
     * - 如果没有其他限制，返回值应该是 balanceOf(owner)
     * - 不能revert
     */
    function maxRedeem(address owner) external view returns (uint256 maxShares);
}
```

### ERC4626 Contract

Here, we are implementing an extremely simple version of tokenized vault contract:
- The constructor initializes the address of the underlying asset contract, the name, and symbol of the vault shares token. Note that the name and symbol of the vault shares token should be associated with the underlying asset. For example, if the underlying asset is called `WTF`, the vault shares should be called `vWTF`.
- When a user deposits `x` units of the underlying asset into the vault, `x` units (equivalent) of vault shares will be minted.
- When a user withdraws `x` units of vault shares from the vault, `x` units (equivalent) of the underlying asset will be withdrawn as well.

**Note**: In actual use, special care should be taken to consider whether the accounting logic related functions should be rounded up or rounded down. You can refer to the implementations of [OpenZeppelin](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/extensions/ERC4626.sol) and [Solmate](https://github.com/transmissions11/solmate/blob/main/src/mixins/ERC4626.sol). However, this is not considered in the teaching example in this section.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {IERC4626} from "./IERC4626.sol";
import {ERC20, IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @dev ERC4626 "代币化金库标准"合约，仅供教学使用，不要用于生产
 */
contract ERC4626 is ERC20, IERC4626 {
    /*//////////////////////////////////////////////////////////////
                    状态变量
    //////////////////////////////////////////////////////////////*/
    ERC20 private immutable _asset; // 
    uint8 private immutable _decimals;

    constructor(
        ERC20 asset_,
        string memory name_,
        string memory symbol_
    ) ERC20(name_, symbol_) {
        _asset = asset_;
        _decimals = asset_.decimals();

    }

    /** @dev See {IERC4626-asset}. */
    function asset() public view virtual override returns (address) {
        return address(_asset);
    }

    /**
     * See {IERC20Metadata-decimals}.
     */
    function decimals() public view virtual override(IERC20Metadata, ERC20) returns (uint8) {
        return _decimals;
    }

    /*//////////////////////////////////////////////////////////////
                        存款/提款逻辑
    //////////////////////////////////////////////////////////////*/
    /** @dev See {IERC4626-deposit}. */
    function deposit(uint256 assets, address receiver) public virtual returns (uint256 shares) {
        // 利用 previewDeposit() 计算将获得的金库份额
        shares = previewDeposit(assets);

        // 先 transfer 后 mint，防止重入
        _asset.transferFrom(msg.sender, address(this), assets);
        _mint(receiver, shares);

        // 释放 Deposit 事件
        emit Deposit(msg.sender, receiver, assets, shares);
    }

    /** @dev See {IERC4626-mint}. */
    function mint(uint256 shares, address receiver) public virtual returns (uint256 assets) {
        // 利用 previewMint() 计算需要存款的基础资产数额
        assets = previewMint(shares);

        // 先 transfer 后 mint，防止重入
        _asset.transferFrom(msg.sender, address(this), assets);
        _mint(receiver, shares);

        // 释放 Deposit 事件
        emit Deposit(msg.sender, receiver, assets, shares);

    }

    /** @dev See {IERC4626-withdraw}. */
    function withdraw(
        uint256 assets,
        address receiver,
        address owner
    ) public virtual returns (uint256 shares) {
        // 利用 previewWithdraw() 计算将销毁的金库份额
        shares = previewWithdraw(assets);

        // 如果调用者不是 owner，则检查并更新授权
        if (msg.sender != owner) {
            _spendAllowance(owner, msg.sender, shares);
        }

        // 先销毁后 transfer，防止重入
        _burn(owner, shares);
        _asset.transfer(receiver, assets);

        // 释放 Withdraw 函数
        emit Withdraw(msg.sender, receiver, owner, assets, shares);
    }

    /** @dev See {IERC4626-redeem}. */
    function redeem(
        uint256 shares,
        address receiver,
        address owner
    ) public virtual returns (uint256 assets) {
        // 利用 previewRedeem() 计算能赎回的基础资产数额
        assets = previewRedeem(shares);

        // 如果调用者不是 owner，则检查并更新授权
        if (msg.sender != owner) {
            _spendAllowance(owner, msg.sender, shares);
        }

        // 先销毁后 transfer，防止重入
        _burn(owner, shares);
        _asset.transfer(receiver, assets);

        // 释放 Withdraw 函数        
        emit Withdraw(msg.sender, receiver, owner, assets, shares);
    }

    /*//////////////////////////////////////////////////////////////
                            会计逻辑
    //////////////////////////////////////////////////////////////*/
    /** @dev See {IERC4626-totalAssets}. */
    function totalAssets() public view virtual returns (uint256){
        // 返回合约中基础资产持仓
        return _asset.balanceOf(address(this));
    }

    /** @dev See {IERC4626-convertToShares}. */
    function convertToShares(uint256 assets) public view virtual returns (uint256) {
        uint256 supply = totalSupply();
        // 如果 supply 为 0，那么 1:1 铸造金库份额
        // 如果 supply 不为0，那么按比例铸造
        return supply == 0 ? assets : assets * supply / totalAssets();
    }

    /** @dev See {IERC4626-convertToAssets}. */
    function convertToAssets(uint256 shares) public view virtual returns (uint256) {
        uint256 supply = totalSupply();
        // 如果 supply 为 0，那么 1:1 赎回基础资产
        // 如果 supply 不为0，那么按比例赎回
        return supply == 0 ? shares : shares * totalAssets() / supply;
    }

    /** @dev See {IERC4626-previewDeposit}. */
    function previewDeposit(uint256 assets) public view virtual returns (uint256) {
        return convertToShares(assets);
    }

    /** @dev See {IERC4626-previewMint}. */
    function previewMint(uint256 shares) public view virtual returns (uint256) {
        return convertToAssets(shares);
    }

    /** @dev See {IERC4626-previewWithdraw}. */
    function previewWithdraw(uint256 assets) public view virtual returns (uint256) {
        return convertToShares(assets);
    }

    /** @dev See {IERC4626-previewRedeem}. */
    function previewRedeem(uint256 shares) public view virtual returns (uint256) {
        return convertToAssets(shares);
    }

    /*//////////////////////////////////////////////////////////////
                     DEPOSIT/WITHDRAWAL LIMIT LOGIC
    //////////////////////////////////////////////////////////////*/
    /** @dev See {IERC4626-maxDeposit}. */
    function maxDeposit(address) public view virtual returns (uint256) {
        return type(uint256).max;
    }

    /** @dev See {IERC4626-maxMint}. */
    function maxMint(address) public view virtual returns (uint256) {
        return type(uint256).max;
    }
    
    /** @dev See {IERC4626-maxWithdraw}. */
    function maxWithdraw(address owner) public view virtual returns (uint256) {
        return convertToAssets(balanceOf(owner));
    }
    
    /** @dev See {IERC4626-maxRedeem}. */
    function maxRedeem(address owner) public view virtual returns (uint256) {
        return balanceOf(owner);
    }
}
```

## `Remix` Demo

1. Deploy an `ERC20` token contract with the token name and symbol both set to `WTF`, and mint yourself `10000` tokens.

2. Deploy an `ERC4626` token contract with the underlying asset contract address set to the address of `WTF`, and set the name and symbol to `vWTF`.

3. Call the `approve()` function of the `ERC20` contract to authorize the `ERC4626` contract.

4. Call the `deposit()` function of the `ERC4626` contract to deposit `1000` tokens. Then call the `balanceOf()` function to check that your vault share has increased to `1000`.

5. Call the `mint()` function of the `ERC4626` contract to deposit another `1000` tokens. Then call `balanceOf()` function to check that your vault share has increased to `2000`.

6. Call the `withdraw()` function of the `ERC4626` contract to withdraw `1000` tokens. Then call the `balanceOf()` function to check that your vault share has decreased to `1000`.

7. Call the `redeem()` function of the `ERC4626` contract to withdraw `1000` tokens. Then call the `balanceOf()` function to check that your vault share has decreased to `0`.

## Summary

In this lesson, we introduced the ERC4626 tokenized vault standard and wrote a simple vault contract that converts underlying assets to 1:1 vault share tokens. The ERC4626 standard improves the liquidity and composability of DeFi and it will gradually become more popular in the future. What applications would you build with ERC4626?