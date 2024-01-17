---
title: S02. Selector Clash
tags:
  - solidity
  - security
  - selector
  - abi encode
---

# WTF Solidity S02. Selector Clash

Recently, I have been revisiting Solidity, consolidating the finer details, and writing "WTF Solidity" tutorials for newbies.

Twitter: [@0xAA_Science](https://twitter.com/0xAA_Science) | [@WTFAcademy\_](https://twitter.com/WTFAcademy_)

Community: [Discord](https://discord.gg/5akcruXrsk)｜[Wechat](https://docs.google.com/forms/d/e/1FAIpQLSe4KGT8Sh6sJ7hedQRuIYirOoZK_85miz3dw7vA1-YjodgJ-A/viewform?usp=sf_link)｜[Website wtf.academy](https://wtf.academy)

Codes and tutorials are open source on GitHub: [github.com/AmazingAng/WTF-Solidity](https://github.com/AmazingAng/WTF-Solidity)

English translations by: [@to_22X](https://twitter.com/to_22X)

---

In this lesson, we will introduce the selector clash attack, which is one of the reasons behind the hack of the cross-chain bridge Poly Network. In August 2021, the cross-chain bridge contracts of Poly Network on ETH, BSC, and Polygon were hacked, resulting in a loss of up to $611 million ([summary](https://rekt.news/zh/polynetwork-rekt/)). This is the largest blockchain hack of 2021 and the second-largest in history, second only to the Ronin bridge hack.

## Selector Clash

In Ethereum smart contracts, the function selector is the first 4 bytes (8 hexadecimal digits) of the hash value of the function signature `"<function name>(<function input types>)"`. When a user calls a function in a contract, the first 4 bytes of the `calldata` represent the selector of the target function, determining which function to call. If you are not familiar with it, you can read the [WTF Solidity 29: Function Selectors](https://github.com/AmazingAng/WTF-Solidity/blob/main/Languages/en/29_Selector_en/readme.md).

Due to the limited length of the function selector (4 bytes), it is very easy to collide: that is, we can easily find two different functions that have the same function selector. For example, `transferFrom(address,address,uint256)` and `gasprice_bit_ether(int128)` have the same selector: `0x23b872dd`. Of course, you can also write a script to brute force it.

![](./img/S02-1.png)

You can use the following websites to find different functions corresponding to the same selector:

1. [https://www.4byte.directory/](https://www.4byte.directory/)
2. [https://sig.eth.samczsun.com/](https://sig.eth.samczsun.com/)

You can also use the "Power Clash" tool below for brute forcing:

1. PowerClash: https://github.com/AmazingAng/power-clash

In contrast, the public key of a wallet is `64` bytes long and the probability of collision is almost `0`, making it very secure.

## `0xAA` Solves the Sphinx Riddle

The people of Ethereum have angered the gods, and the gods are furious. In order to punish the people of Ethereum, the goddess Hera sends down a Sphinx, a creature with the head of a human and the body of a lion, to the cliffs of Ethereum. The Sphinx presents a riddle to every Ethereum user who passes by the cliff: "What walks on four legs in the morning, two legs at noon, and three legs in the evening? It is the only creature that walks on different numbers of legs throughout its life. When it has the most legs, it is at its slowest and weakest." Those who solve this enigmatic riddle will be spared, while those who fail to solve it will be devoured. The Sphinx uses the selector `0x10cd2dc7` to verify the correct answer.

One morning, Oedipus passes by and encounters the Sphinx. He solves the mysterious riddle and says, "It is `function man()`. In the morning of life, he is a child who crawls on two legs and two hands. At noon, he becomes an adult who walks on two legs. In the evening, he grows old and weak, and needs a cane to walk, hence he is called three-legged." After guessing the riddle correctly, Oedipus is allowed to live.

Later that afternoon, `0xAA` passes by and encounters the Sphinx. He also solves the mysterious riddle and says, "It is `function peopleLduohW(uint256)`. In the morning of life, he is a child who crawls on two legs and two hands. At noon, he becomes an adult who walks on two legs. In the evening, he grows old and weak, and needs a cane to walk, hence he is called three-legged." Once again, the riddle is guessed correctly, and the Sphinx becomes furious. In a fit of anger, the Sphinx slips and falls from the towering cliff to its death.

![](./img/S02-2.png)

## Vulnerable Contract Example

### Vulnerable Contract

Let's take a look at an example of a vulnerable contract. The `SelectorClash` contract has one state variable `solved`, initialized as `false`, which the attacker needs to change to `true`. The contract has `2` main functions, named after the Poly Network vulnerable contract.

1. `putCurEpochConPubKeyBytes()`: After calling this function, the attacker can change `solved` to `true` and complete the attack. However, this function checks `msg.sender == address(this)`, so the caller must be the contract itself. We need to look at other functions.

2. `executeCrossChainTx()`: This function allows calling functions within the contract, but the function parameters are slightly different from the target function: the target function takes `(bytes)` as parameters, while this function takes `(bytes, bytes, uint64)`.

```solidity
contract SelectorClash {
    bool public solved; // Whether the attack is successful

    // The attacker needs to call this function, but the caller msg.sender must be this contract.
    function putCurEpochConPubKeyBytes(bytes memory _bytes) public {
        require(msg.sender == address(this), "Not Owner");
        solved = true;
    }

    // Vulnerable, the attacker can collide function selectors by changing the _method variable, call the target function, and complete the attack.
    function executeCrossChainTx(bytes memory _method, bytes memory _bytes, bytes memory _bytes1, uint64 _num) public returns(bool success){
        (success, ) = address(this).call(abi.encodePacked(bytes4(keccak256(abi.encodePacked(_method, "(bytes,bytes,uint64)"))), abi.encode(_bytes, _bytes1, _num)));
    }
}
```

### How to Attack

Our goal is to use the `executeCrossChainTx()` function to call the `putCurEpochConPubKeyBytes()` function in the contract. The selector of the target function is `0x41973cd9`. We observe that the `executeCrossChainTx()` function calculates the selector using the `_method` parameter and `"(bytes,bytes,uint64)"` as the function signature. Therefore, we just need to choose the appropriate `_method` so that the calculated selector matches `0x41973cd9`, allowing us to call the target function through selector collision.

In the Poly Network hack, the hacker collided the `_method` as `f1121318093`, which means the first `4` bytes of the hash of `f1121318093(bytes,bytes,uint64)` is also `0x41973cd9`, successfully calling the function. Next, we need to convert `f1121318093` to the `bytes` type: `0x6631313231333138303933`, and pass it as a parameter to `executeCrossChainTx()`. The other `3` parameters of `executeCrossChainTx()` are not important, so we can fill them with `0x`, `0x`, and `0`.

## Reproduce on `Remix`

1. Deploy the `SelectorClash` contract.
2. Call `executeCrossChainTx()` with the parameters `0x6631313231333138303933`, `0x`, `0x`, `0`, to initiate the attack.
3. Check the value of the `solved` variable, which should be modified to `true`, indicating a successful attack.

## Summary

In this lesson, we introduced the selector clash attack, which is one of the reasons behind the $611 million hack of the Poly Network cross-chain bridge. This attack teaches us:

1. Function selectors are easily collided, even when changing parameter types, it is still possible to construct functions with the same selector.

2. Manage the permissions of contract functions properly to ensure that functions of contracts with special privileges cannot be called by users.
