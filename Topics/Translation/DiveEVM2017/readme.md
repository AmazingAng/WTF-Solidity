# 深入以太坊虚拟机系列

**原文**：
- [Diving Into The Ethereum Virtual Machine](https://medium.com/@hayeah/diving-into-the-ethereum-vm-6e8d5d2f3c30)
- [Diving Into The Ethereum VM Part 2 — How I Learned To Start Worrying And Count The Storage Cost](https://medium.com/@hayeah/diving-into-the-ethereum-vm-part-2-storage-layout-bc5349cb11b7)
- [Diving Into The Ethereum VM Part 3 — The Hidden Costs of Arrays](https://medium.com/@hayeah/diving-into-the-ethereum-vm-the-hidden-costs-of-arrays-28e119f04a9b)
- [Diving Into The Ethereum VM Part 4 — How To Decipher A Smart Contract Method Call](https://medium.com/@hayeah/how-to-decipher-a-smart-contract-method-call-8ee980311603)
- [Diving Into The Ethereum VM Part 5 — The Smart Contract Creation Process](https://medium.com/@hayeah/diving-into-the-ethereum-vm-part-5-the-smart-contract-creation-process-cb7b6133b855)
- [Diving Into The Ethereum VM Part 6 — How Solidity Events Are Implemented](https://blog.qtum.org/how-solidity-events-are-implemented-diving-into-the-ethereum-vm-part-6-30e07b3037b9)

**原文作者**：[Howard](https://twitter.com/hayeah)

**翻译**：[alphafitz](https://twitter.com/alphafitz01)

> 写在前面：这是作者 [Howard](https://twitter.com/hayeah) 在 2017 年开始写的一系列文章，当时使用的编译器版本还是 0.4.x，但是其描述的以太坊虚拟机(EVM)的基本工作原理仍然适用并且十分值得学习，帮助我更好地理解了 EVM，故在此将其翻译为中文版。
> 
> 本文中给出的源代码及汇编代码仍然沿用原文内容，涉及到的版本不一致的问题请自行查阅学习。本人尽最大可能保证翻译通顺准确，但大家如果发现错误可以直接提交 pr。
>
>By alphafitz

## 译文

**[深入以太坊虚拟机 Part1 — 汇编与字节码](https://github.com/AmazingAng/WTFSolidity/blob/main/Topics/Translation/DiveEVM2017/DiveEVM2017-Part1.md)**

**[深入以太坊虚拟机 Part2 — 固定长度数据类型的表示 ](https://github.com/AmazingAng/WTFSolidity/blob/main/Topics/Translation/DiveEVM2017/DiveEVM2017-Part2.md)**

**[深入以太坊虚拟机 Part3 — 动态数据类型的表示](https://github.com/AmazingAng/WTFSolidity/blob/main/Topics/Translation/DiveEVM2017/DiveEVM2017-Part3.md)**

**[深入以太坊虚拟机 Part4 — 智能合约外部方法调用](https://github.com/AmazingAng/WTFSolidity/blob/main/Topics/Translation/DiveEVM2017/DiveEVM2017-Part4.md)**

**[深入以太坊虚拟机 Part5 — 智能合约创建过程](https://github.com/AmazingAng/WTFSolidity/blob/main/Topics/Translation/DiveEVM2017/DiveEVM2017-Part5.md)**

**[深入以太坊虚拟机 Part6 — Solidity 事件实现](https://github.com/AmazingAng/WTFSolidity/blob/main/Topics/Translation/DiveEVM2017/DiveEVM2017-Part6.md)**