---
title: S12. 操纵block timestamp
tags:
- solidity
- security
- timestamp
---

# WTF Solidity 合约安全:S12. 操纵block timestamp
我最近在重新学solidity，巩固一下细节，也写一个“WTF Solidity极简入门”，供小白们使用（编程大佬可以另找教程），每周更新1-3讲。

推特：[@0xAA_Science](https://twitter.com/0xAA_Science)｜[@WTFAcademy_](https://twitter.com/WTFAcademy_)

社区：[Discord](https://discord.wtf.academy)｜[微信群](https://docs.google.com/forms/d/e/1FAIpQLSe4KGT8Sh6sJ7hedQRuIYirOoZK_85miz3dw7vA1-YjodgJ-A/viewform?usp=sf_link)｜[官网 wtf.academy](https://wtf.academy)

所有代码和教程开源在github: [github.com/AmazingAng/WTFSolidity](https://github.com/AmazingAng/WTFSolidity)

-----

这一讲，我们将介绍智能合约的`timestamp`修改时间攻击和预防方法。

## `timestamp` 操纵区块时间攻击
### 区块结构
<div align="center"><img src="img/区块头.png"></div>

一个区块由区块头和区块体组成，其中区块头由以下组成：
* `parentHash`
  是一个哈希值，记录此区块直接引用的父区块哈希值。通过此记录，才能完整的将区块有序组织，形成一条区块链。并且可以防止父区块内容被修改，因为数据修改，
区块哈希必然发生变化，因此一个区块直接或间接的强化了所有父辈区块，通过加密算法保证历史区块不可能被修改。
* `sha3Uncles`
  是一个哈希值，表示区块引用的多个叔辈区块。在区块体中也包含了多个叔辈的区块头信息，而sha3Uncles则是叔块集的 RLPHASH 哈希值。在比特币中只有成功
挖出区块并被其他节点接受时才能获得奖励，是所有矿工在争取记账权和连带的奖励。而以太坊稍有不同，不能成为主链一部分的孤儿区块，如果有幸被后来的区块收
留进区块链就变成了叔块。收留了孤块的区块有额外的奖励。孤块一旦成为叔块，该区块统一可获得奖励。通过叔块奖励机制，来降低以太坊软分叉和平衡网速慢的矿工利益
* `miner`
  是一个地址，表示区块是此账户的矿工挖出，挖矿奖励将下发到此账户。
* `stateRoot`
  是一个哈希值，表示执行完此区块中的所有交易后以太坊状态快照ID。因为以太坊描述为一个状态机系统，因此快照ID称之为状态哈希值。又因为状态哈希是由所有
账户状态按默克尔前缀树算法生成，因此称为状态默克尔树根值。
* `transactionsRoot`
  是一个哈希值，表示该区块中所有交易生成一颗默克尔树根节点哈希值。是一个密码学保证交易集合摘要。通过此Root可以直接校验某交易是否包含在此区块中。
* `receiptRoot`
  是一个哈希值，同样是默克尔树根节点哈希值。由区块交易在执行完成后生成的交易回执信息集合生成。
* `logsBloom`
  是一个256长度Byte数组。提取自receipt，用于快速定位查找交易回执中的智能合约事件信息。
* `difficulty`
  是 big.Int 值，表示此区块能被挖出的难度系数。
* `number`
  是 big.Int 值，表示此区块高度。用于对区块标注序号，在一条区块链上，区块高度必须是连续递增。
* `gasLimit`
  是 uint64 值，表示此区块所允许消耗的Gas燃料量。此数值根据父区块进行动态调整，调整的目的是调整区块所能包含的交易数量。
* `gasUsed`
  是 uint64 值，表示此区块所有交易执行所实际消耗的Gas燃料量。
* `timestamp`
  **是 uint64 值，表示此区块创建的UTC时间戳，单位秒。因为以太坊平均14.5s出一个区块(白皮书中研究是 12秒)，因此区块时间戳可以充当时间戳服务，
但不能完全信任**。
* `extraData`
  是一个长度不固定的Byte数组，最长32位。完全由矿工自定义，矿工一般会写一些公开推广类内容或者作为投票使用。
* `mixHash`
  是一个哈希值。用于校验区块是否正确挖出。实际上是区块头数据不包含nonce时的一个哈希值。
* `nonce`
  是一个8长度的Byte，实际是一个 uint64 值。用于校验区块是否正确挖出，mixHash 只有用一个正确的 nonce 才能进行PoW工作量证明。

### 操纵时间攻击例子
此例子用[WTF Solidity极简入门: 32. 代币水龙头](https://github.com/AmazingAng/WTF-Solidity/tree/main/32_Faucet)来做为测试用例，主要在mint()函数加入条件,只有 当前的`block.timestamp`取余7为0的话，那么
`msg.sender`才可以mint我们的WTF代币：
```solidity
// @dev 铸造代币，从 `0` 地址转账给 调用者地址
  function mint(uint256 amount) external {
    require(block.timestamp != pastBlockTime);
    pastBlockTime = block.timestamp;
    // if the block.timestamp is divisible by 7 you win the Ether in the contract
    if (block.timestamp % 7 == 0) {
      balanceOf[msg.sender] += amount;
      totalSupply += amount;
      emit Transfer(address(0), msg.sender, amount);
    }
  }
```
### 合约漏洞
在合约运行了好久之后,都没有人能够成功的mint到WTF代币,这时就有人动歪脑筋了.他只要可以操纵`block.timestamp`,让 timestamp % 7 == 0 那么奖励即可到手。

### 使用Foundry复现

* 关键点  
这个漏洞的关键点主要是修改时间戳，如果可以修改区块上的时间戳使得时间戳可以取余7，那么即可拿走合约中的所有钱。

#### 使用Foundry写测试用例
其中关键代码如下,主要使用Foundry中的Cheatcodes来修改时间戳
```solidity
    function testMint() public {
  //在这里修改block.timestamp
  vm.warp(6);
  console.log("block.timestamp % 7 != 0");
  //启动测试
  vm.startPrank(alice);
  console.log("token name: %s", wtf.name());
  console.log("alice balance after: %s", wtf.balanceOf(alice));
  wtf.mint(10000);
  console.log("alice balance after: %s", wtf.balanceOf(alice));
  // Resets subsequent calls' msg.sender to be `address(this)`

  console.log("block.timestamp % 7 == 0");
  //在这里修改block.timestamp
  vm.warp(7);
  console.log("token name: %s", wtf.name());
  console.log("alice balance after: %s", wtf.balanceOf(alice));
  wtf.mint(10000);
  console.log("alice balance after: %s", wtf.balanceOf(alice));
  //结束测试
  vm.stopPrank();
}
```
#### 使用Foundry启动测试用例
```shell
forge test -vv --match-test testMint
```
#### 输出如下
```shell
[⠰] Compiling...
[⠘] Compiling 1 files with 0.8.17
[⠃] Solc 0.8.17 finished in 1.35s
Compiler run successful

Running 1 test for test/Faucet.t.sol:FaucetTest
[PASS] testMint() (gas: 100479)
Logs:
  block.timestamp % 7 != 0
  token name: WTF
  alice balance after: 0
  alice balance after: 0
  block.timestamp % 7 == 0
  token name: WTF
  alice balance after: 0
  alice balance after: 10000

Test result: ok. 1 passed; 0 failed; finished in 15.64ms
```