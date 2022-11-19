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
小明编写了一个合约，合约功能主要是用来看谁运气好，其中合约钱包有10个以太坊，只要有人在调用合约的同时，当前的`block.timestamp`取余7为0的话，那么
`msg.sender`即可拿走合约钱包中的所有钱。合约内容如下：
```solidity
 contract Roulette {
     uint public pastBlockTime;
     constructor() payable {} 

    // call spin and send 1 ether to play
     function spin() external payable {     
        require(msg.value == 1 ether);
        require(block.timestamp != pastBlockTime);    
        pastBlockTime = block.timestamp;     
    // if the block.timestamp is divisible by 7 you win the Ether in the contract
        if(block.timestamp % 7 == 0) {         
          (bool sent, ) = msg.sender.call{value: address(this).balance}("");         
          require(sent, "Failed to send Ether");     
        } 
     }
 }
```
### 合约漏洞
在合约运行了好久之后,都没有人能够成功的拿走奖励,这时就有人动歪脑筋了.他只要可以操纵`block.timestamp`,让 timestamp % 7 == 0 那么奖励即可到手。

### 使用Hardhat复现

* 关键点  
这个漏洞的关键点主要是修改时间戳，如果可以修改区块上的时间戳使得时间戳可以取余7，那么即可拿走合约中的所有钱。

#### 使用hardhat在本地构建网络
在控制台输入`npx hardhat node`,输出如下所示
```shell
Started HTTP and WebSocket JSON-RPC server at http://127.0.0.1:8545/

Accounts
========
Account #0: 0xf39fd6e51aad88f6f4ce6ab8827279cfffb92266 (10000 ETH)
Private Key: 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
```
#### 将合约部署在本地网络上
在控制台输入`npx hardhat run scripts/deploy.ts --network localhost`
#### 修改本地网络上区块时间戳,然后与合约进行交互
在控制台输入`npx ./scripts/get.js`,其中关键代码如下
```javascript
//修改区块时间戳
while (blockInfo.timestamp % 7 !== 0) {
  await provider.send('evm_increaseTime', [70000]);
  await provider.send('evm_mine');
  blockInfo = await provider.getBlock("latest")
  console.log("timestamp-->"+ blockInfo.timestamp);
  console.log("number-->" + blockInfo.number);
}
```
