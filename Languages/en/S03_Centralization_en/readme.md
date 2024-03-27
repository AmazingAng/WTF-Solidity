---
title: S03. Centralization Risks
tags:
  - solidity
  - security
  - multisig
---

# WTF Solidity S03. Centralization Risks

Recently, I have been revisiting Solidity, consolidating the finer details, and writing "WTF Solidity" tutorials for newbies.

Twitter: [@0xAA_Science](https://twitter.com/0xAA_Science) | [@WTFAcademy\_](https://twitter.com/WTFAcademy_)

Community: [Discord](https://discord.gg/5akcruXrsk)｜[Wechat](https://docs.google.com/forms/d/e/1FAIpQLSe4KGT8Sh6sJ7hedQRuIYirOoZK_85miz3dw7vA1-YjodgJ-A/viewform?usp=sf_link)｜[Website wtf.academy](https://wtf.academy)

Codes and tutorials are open source on GitHub: [github.com/AmazingAng/WTF-Solidity](https://github.com/AmazingAng/WTF-Solidity)

English translations by: [@to_22X](https://twitter.com/to_22X)

---

In this lesson, we will discuss the risks of centralization and pseudo-decentralization in smart contracts. The `Ronin` bridge and `Harmony` bridge were hacked due to these vulnerabilities, resulting in the theft of $624 million and $100 million, respectively.

## Centralization Risks

We often take pride in the decentralization of Web3, believing that in the world of Web3.0, ownership and control are decentralized. However, centralization is actually one of the most common risks in Web3 projects. In their [2021 DeFi Security Report](https://f.hubspotusercontent40.net/hubfs/4972390/Marketing/defi%20security%20report%202021-v6.pdf), renowned blockchain auditing firm Certik pointed out:

> Centralization risk is the most common vulnerability in DeFi, with 44 DeFi hacks in 2021 related to it, resulting in over $1.3 billion in user funds lost. This emphasizes the importance of decentralization, and many projects still need to work towards this goal.

Centralization risk refers to the centralization of ownership in smart contracts, where the `owner` of the contract is controlled by a single address. This owner can freely modify contract parameters and even withdraw user funds. Centralized projects have a single point of failure and can be exploited by malicious developers (insiders) or hackers who gain control over the address with control permissions. They can perform actions such as `rug-pull`ing, unlimited minting, or other methods to steal funds.

Gaming project `Vulcan Forged` was hacked for $140 million in December 2021 due to a leaked private key. DeFi project `EasyFi` was hacked for $59 million in April 2021 due to a leaked private key. DeFi project `bZx` lost $55 million in a phishing attack due to a leaked private key.

## Pseudo-Decentralization Risks

Pseudo-decentralized projects often claim to be decentralized but still have a single point of failure, similar to centralized projects. For example, they may use a multi-signature wallet to manage smart contracts, but a few signers act in consensus and are controlled by a single person. These projects, packaged as decentralized, easily gain the trust of investors. Therefore, when a hack occurs, the amount stolen is often larger.

The Ronin bridge of the popular gaming project Axie was hacked for $624 million in March 2022, making it the largest theft in history. The Ronin bridge is maintained by 9 validators, and 5 of them must reach consensus to approve deposit and withdrawal transactions. This appears to be similar to a multi-signature setup and highly decentralized. However, 4 of the validators are controlled by Axie's development company, Sky Mavis, and the other validator controlled by Axie DAO also approved transactions on behalf of Sky Mavis. Therefore, once the attacker gains access to Sky Mavis' private key (specific method undisclosed), they can control the 5 validators and authorize the theft of 173,600 ETH and $25.5 million USDC.

The Harmony cross-chain bridge was hacked for $100 million in June 2022. The Harmony bridge is controlled by 5 multi-signature signers, and shockingly, only 2 signatures are required to approve a transaction. After the hacker managed to steal the private keys of two signers, they emptied the assets pledged by users.

![](./img/S03-1.png)

## Examples of Vulnerable Contracts

There are various types of contracts with centralization risks, but here is the most common example: an `ERC20` contract where the `owner` address can mint tokens arbitrarily. When an insider or hacker obtains the private key of the `owner`, they can mint an unlimited amount of tokens, causing significant losses for investors.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Centralization is ERC20, Ownable {
    constructor() ERC20("Centralization", "Cent") {
        address exposedAccount = 0xe16C1623c1AA7D919cd2241d8b36d9E79C1Be2A2;
        transferOwnership(exposedAccount);
    }

    function mint(address to, uint256 amount) external onlyOwner{
        _mint(to, amount);
    }
}
```

## How to Reduce Centralization/Pseudo-Decentralization Risks?

1. Use a multi-signature wallet to manage the treasury and control contract parameters. To balance efficiency and decentralization, you can choose a 4/7 or 6/9 multi-signature setup. If you are not familiar with multi-signature wallets, you can read [WTF Solidity 50: Multi-Signature Wallet](https://github.com/AmazingAng/WTF-Solidity/blob/main/Languages/en/50_MultisigWallet_en/readme.md).

2. Diversify the holders of the multi-signature wallet, spreading them among the founding team, investors, and community leaders, and do not authorize each other's signatures.

3. Use time locks to control the contract, giving the project team and community some time to respond and minimize losses in case of hacking or insider manipulation of contract parameters/asset theft. If you are not familiar with time lock contracts, you can read [WTF Solidity 45: Time Lock](https://github.com/AmazingAng/WTF-Solidity/blob/main/Languages/en/45_Timelock_en/readme.md).

## Summary

Centralization/pseudo-decentralization is the biggest risk for blockchain projects, causing over $2 billion in user fund losses in the past two years. Centralization risks can be identified by analyzing the contract code, while pseudo-decentralization risks are more hidden and require thorough due diligence of the project to uncover.
