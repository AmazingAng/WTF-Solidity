## Metamask项目方给Solidity程序员的16个安全建议

**原文**：[Solidity Best Practices for Smart Contract Security](https://consensys.net/blog/developers/solidity-best-practices-for-smart-contract-security/)

**原文作者**：Consensys（metamask项目方）

**翻译**：[0xAA](https://twitter.com/0xAA_Science)

**Github**: [WTFSolidity]()https://github.com/AmazingAng/WTFSolidity

```
写在前面：

这是Metamask项目方（Consensys）在2020年8月写的一篇博客，关于智能合约安全，其中给了Solidity程序员16条安全建议，并包含代码样例。

这篇文章写于一年半前，那时候solidity版本才到0.5,现在已经是0.8了。但很多建议至今仍然适用，读完对我帮助很大。我在网上没找到中文翻译，就简单翻译了一下，供中文开发者学习。

这篇文章的安全理念也融入到WTF Solidity极简入门教程中。

By 0xAA
```
如果您已经牢记智能合约的安全理念并且正在处理`EVM`的特性，那么是时候考虑一​​些特定于`Solidity`编程语言的安全模式了。在本综述中，我们将重点关注`Solidity`的安全开发建议，这些建议也可能对用其他语言开发智能合约具有指导意义。 

好了，让我们开始吧。

## 1. 正确使用 `assert(), require(), revert()`
便利函数 `assert` 和 `require` 可用于检查条件，如果条件不满足则抛出异常。

`assert` 函数只能用于测试内部错误和检查不变量。 

应该使用 `require` 函数来确保满足有效条件，例如输入或合约状态变量，或者验证来自外部合约调用的返回值。 （`0xAA注: solidity在0.8.4版本引入自定义error功能，所以这个版本之前用require，之后用revert-error来确保满足有效条件`）

遵循这种范式可以让形式化分析工具来验证无效操作码永远不会被运行：这意味着代码中没有不变量被违反并且被形式化验证。
```
pragma solidity ^0.5.0;

contract Sharer {
    function sendHalf(address payable addr) public payable returns (uint balance) {
        require(msg.value % 2 == 0, "偶数required."); //Require() 可以加一个自定义消息
        uint balanceBeforeTransfer = address(this).balance;
        (bool success, ) = addr.call.value(msg.value / 2)("");
        require(success);
        // 如果success为false，就revert。下面的总是成立。
        assert(address(this).balance == balanceBeforeTransfer - msg.value / 2); // used for internal error checking
        return address(this).balance;
    }
}
```

## 2. `modifier`仅用于检查
修饰符（`modifier`）内的代码通常在函数体之前执行，因此任何状态更改或外部调用都会违反 `Checks-Effects-Interactions`模式。此外，开发人员也可能不会注意到这些语句，因为修饰符的代码可能远离函数声明。例如，修饰符的外部调用可能导致重入攻击：
```
contract Registry {
    address owner;

    function isVoter(address _addr) external returns(bool) {
        // Code
    }
}

contract Election {
    Registry registry;

    modifier isEligible(address _addr) {
        require(registry.isVoter(_addr));
        _;
    }

    function vote() isEligible(msg.sender) public {
        // Code
    }
}
```
在这种情况下，`Registry`合约可以通过调用`isVoter()`中的`Election.vote()` 进行重入攻击。

注意：使用`modifier`替换多个函数中的重复条件检查，例如 `isOwner()`，否则在函数内部使用`require`或`revert`。这使您的智能合约代码更具可读性和更易于审计。

## 3. 注意整数除法的舍入
所有整数除法都向下舍入到最接近的整数。如果您需要更高的精度，请考虑使用乘数，或同时存储分子和分母。

（将来，`Solidity` 会有浮点类型，这会让这更容易。）
```
// bad
uint x = 5 / 2; // Result is 2, all integer divison rounds DOWN to the nearest integer
```
使用乘数可以防止四舍五入，在将来使用 x 时需要考虑这个乘数：
```
// good
uint multiplier = 10;
uint x = (5 * multiplier) / 2;
```
存储分子和分母意味着你可以计算 numerator/denominator 链下的结果：
```
// good
uint numerator = 5;
uint denominator = 2;
```

### 4. 注意抽象合约`abstract`和接口`interface`之间的权衡
接口和抽象合约都为智能合约提供了一种可定制和可重用的方法。`Solidity 0.4.11`中引入的接口类似于抽象合约，但不能实现任何功能。接口也有限制，例如不能访问存储或从其他接口继承，这通常使抽象合约更实用。虽然，接口对于在实现之前设计合约肯定有用。此外，重要的是要记住，如果合约继承自抽象合约，它必须通过覆盖实现所有未实现的功能，否则它也将是抽象的。

## 5. Fallback function 后备函数
### 保持fallback function简单
当合约被发送一个没有参数的消息（或者没有函数匹配）或，`fallback function`会被调用。当被`.send()`或`.transfer`触发时，`fallback function`只能访问`2300 gas`。如果您希望能够从`send()`或`.transfer()`接收`ETH`，那么您在后备函数中最多可以做的就是记录一个事件。如果需要计算更多`gas`，请使用适当的函数。
```
// bad
function() payable { balances[msg.sender] += msg.value; }

// good
function deposit() payable external { balances[msg.sender] += msg.value; }

function() payable { require(msg.data.length == 0); emit LogDepositReceived(msg.sender); }
```

### 检查回退函数中的数据长度
由于 `fallback function` 不仅在普通以太传输（没有`msg.data`）时调用，并且也在没有其他函数匹配时调用，如果后备函数仅用于记录接收到的`ETH`，则应检查数据是否为空。否则，如果你的合约使用不正确，调用了不存在的函数，调用者将不会注意到。
```
// bad
function() payable { emit LogDepositReceived(msg.sender); }

// good
function() payable { require(msg.data.length == 0); emit LogDepositReceived(msg.sender); }
```

## 6. 显式标记应付函数和状态变量
从 `Solidity 0.4.0`开始，每个接收以太币的函数都必须使用 `payable`修饰符，否则如果交易有`msg.value > 0` 将被`revert`。

**注意**：可能不明显的事情： `payable` 修饰符仅适用于来自 `external` 合约的调用。如果我在同一个合约的`payable`函数中调用了一个非`payable`函数，这个非`payable`函数不会失败，尽管 `msg.value`不为零。

## 7. 显式标记函数和状态变量的可见性
明确标记函数和状态变量的可见性。函数可以指定为 `external`， `public`，`internal`或`private`。请理解它们之间的差异，例如，`external`可能足以代替 `public`。而对于状态变量，`external`是不用的。明确标记可见性将更容易捕捉关于谁可以调用函数或访问变量的错误。

1. `External`函数是合约接口的一部分。`external`函数`f`不能在内部调用（即`f()` 不工作，但 `this.f()` 工作）。外部函数在接收大量数据时效率更高。

2. `Public`函数是合约接口的一部分，既可以在内部调用，也可以通过消息调用。对于公共状态变量，会生成一个自动 `getter` 函数。

3. `Internal` 函数和状态变量只能在内部访问，不使用`this`.

4. `Private` 函数和状态变量仅对定义它们的合约可见，而在派生合约中不可见。 **注意**：合约内的所有内容对区块链外部的所有观察者都是可见的，甚至是 `Private` 变量。
```
// bad
uint x; // the default is internal for state variables, but it should be made explicit
function buy() { // the default is public
    // public code
}

// good
uint private y;
function buy() external {
    // only callable externally or using this.buy()
}

function utility() public {
    // callable externally, as well as internally: changing this code requires thinking about both cases.
}

function internalAction() internal {
    // internal code
}
```

## 8. 将编译指示锁定到特定的编译器版本
合约应该使用与它们经过最多测试的相同编译器版本和标志来部署。锁定 pragma 有助于确保合约不会被意外部署，例如使用可能具有更高风险未发现错误的最新编译器。合约也可能由其他人部署，并且 `pragma` 指示原作者预期的编译器版本。
```
// bad
pragma solidity ^0.4.4;


// good
pragma solidity 0.4.4;
```
**注意**：浮动 `pragma` 版本（即 `^0.4.25`）可以用`0.4.26-nightly.2018.9.25`编译，但不应使用`nightly`版本来编译生产代码。

**警告**：当合约打算供其他开发人员使用时，可以允许 `Pragma` 语句浮动，例如库或 `EthPM` 包中的合约。否则，开发人员需要手动更新编译指示才能在本地编译。


## 9. 使用事件来监控合约活动
有一种方法可以在部署后监控合约的活动是很有用的。实现这一点的一种方法是查看合约的所有交易，但这可能还不够，因为合约之间的消息调用不会记录在区块链中。此外，它只显示输入参数，而不是对状态进行的实际更改。事件也可用于触发用户界面中的功能。
```
contract Charity {
    mapping(address => uint) balances;

    function donate() payable public {
        balances[msg.sender] += msg.value;
    }
}

contract Game {
    function buyCoins() payable public {
        // 5% goes to charity
        charity.donate.value(msg.value / 20)();
    }
}
```
在这里， `Game` 合约将内部调用 `Charity.donate()`. 该交易不会出现在`Charity` 的外部交易列表中，而只在内部交易中可见。

事件是记录合约中发生的事情的便捷方式。发出的事件与其他合约数据一起留在区块链中，可供将来审计。这是对上述示例的改进，使用事件来提供慈善机构的捐赠历史。
```
contract Charity {
    // define event
    event LogDonate(uint _amount);

    mapping(address => uint) balances;

    function donate() payable public {
        balances[msg.sender] += msg.value;
        // emit event
        emit LogDonate(msg.value);
    }
}

contract Game {
    function buyCoins() payable public {
        // 5% goes to charity
        charity.donate.value(msg.value / 20)();
    }
}
```
在这里，无论是否直接通过合约的所有交易都 `Charity` 将与捐赠的金额一起显示在该合约的事件列表中。

**注意**：优先使用更新的 Solidity 结构。首选结构/别名，例如 `selfdestruct` (而不是  `suicide`) 和 `keccak256` (而不是  `sha3`)。类似的模式 `require(msg.sender.send(1 ether))` 也可以简化为使用 `transfer()`，如 `msg.sender.transfer(1 ether)`. 查看 `Solidity` 更改日志 以了解更多类似更改。

## 10. 请注意，“内置”函数可能会被隐藏
目前可以 在 `Solidity` 中隐藏内置的全局变量。这允许合约覆盖内置插件的功能，例如 `msg` 和 `revert()`。尽管这是有意为之，但它可能会误导合约用户对合约的真实行为。

```
contract PretendingToRevert {
    function revert() internal constant {}
}

contract ExampleContract is PretendingToRevert {
    function somethingBad() public {
        revert();
    }
}
```
合约用户（和审计员）应该了解他们打算使用的任何应用程序的完整智能合约源代码。

## 11. 避免使用 tx.origin
永远不要 tx.origin 用于授权，另一个合约可以有一个方法来调用你的合约（例如，用户有一些资金）并且你的合约将授权该交易，因为你的地址位于`tx.origin`.
```
contract MyContract {

    address owner;

    function MyContract() public {
        owner = msg.sender;
    }

    function sendTo(address receiver, uint amount) public {
        require(tx.origin == owner);
        (bool success, ) = receiver.call.value(amount)("");
        require(success);
    }

}

contract AttackingContract {

    MyContract myContract;
    address attacker;

    function AttackingContract(address myContractAddress) public {
        myContract = MyContract(myContractAddress);
        attacker = msg.sender;
    }

    function() public {
        myContract.sendTo(attacker, msg.sender.balance);
    }

}
```
您应该使用 `msg.sender` 授权（如果另一个合约调用您的合约 `msg.sender` 将是该合约的地址，而不是调用该合约的用户的地址）。

**警告**：除了授权问题外， `tx.origin` 将来有可能从以太坊协议中删除，因此使用的代码 `tx.origin` 将与未来版本不兼容. Vitalik：'不要假设 `tx.origin` 将继续存在。

还值得一提的是，通过使用 `tx.origin` 您会限制合约之间的互操作性，因为使用 `tx.origin` 的合约不能被另一个合约使用，因为合约不能是 `tx.origin.`


## 12. 时间戳依赖
使用时间戳执行合约中的关键功能时，有三个主要考虑因素，尤其是当操作涉及资金转移时。

### 时间戳操作
请注意，区块的时间戳可以由矿工操纵。考虑这个合约：
```
uint256 constant private salt =  block.timestamp;

function random(uint Max) constant private returns (uint256 result){
    //get the best seed for randomness
    uint256 x = salt * 100/Max;
    uint256 y = salt * block.number/(salt % 5) ;
    uint256 seed = block.number/3 + (salt % 300) + Last_Payout + y;
    uint256 h = uint256(block.blockhash(seed));

    return uint256((h / x)) % Max + 1; //random number between 1 and Max
}
```

当合约使用时间戳播种一个随机数时，矿工实际上可以在区块被验证后的 15 秒内发布一个时间戳，从而有效地允许矿工预先计算一个更有利于他们中奖机会的选项。时间戳不是随机的，不应在该上下文中使用。

## 13. 15秒规则
黄皮书 （Ethereum 的参考规范）没有规定多少块可以在时间上漂移的限制，但它确实规定每个时间戳应该大于其父时间戳。流行的以太坊协议实现 `Geth`和`Parity`都拒绝未来时间戳超过 15 秒的块。因此，评估时间戳使用的一个好的经验法则是：如果您的时间相关事件的规模可以变化 15 秒并保持完整性，那么可以使用`block.timestamp`.

### 避免 block.number 用作时间戳
可以使用 `block.number` 属性和 平均块时间来估计时间增量，但这不是未来的证据，因为出块时间可能会改变（例如 分叉重组 和 难度炸弹）。但在只持续几天的销售中，15秒规则允许人们获得更可靠的时间估计。


## 14. 多重继承注意事项
在 Solidity 中使用多重继承时，了解编译器如何构成继承图非常重要。
```
contract Final {
    uint public a;
    function Final(uint f) public {
        a = f;
    }
}

contract B is Final {
    int public fee;

    function B(uint f) Final(f) public {
    }
    function setFee() public {
        fee = 3;
    }
}

contract C is Final {
    int public fee;

    function C(uint f) Final(f) public {
    }
    function setFee() public {
        fee = 5;
    }
}

contract A is B, C {
  function A() public B(3) C(5) {
      setFee();
  }
}
```
部署合约时，编译器将从右到左线性化继承（在关键字`is`之后 ，父项从最基类到最派生列出）。这是合约 `A` 的线性化：

`Final <- B <- C <- A`

线性化的结果将产生 `fee = 5` 的值，因为 `C` 是最接近衍生的合约。这似乎很明显，但想象一下 `C` 能够隐藏关键函数、重新排序布尔子句并导致开发人员编写可利用的合约的场景。静态分析目前不会引发被遮盖的函数的问题，因此必须手动检查。

为了帮助做出贡献，`Solidity` 的 `Github` 有一个包含所有继承相关问题的[项目](https://github.com/ethereum/solidity/projects/9#card-8027020)。

## 15. 使用接口类型而不是地址来保证类型安全
当函数将合约地址作为参数时，最好传递接口或合约类型而不是  纯`address`。因为如果函数在源代码的其他地方被调用，编译器将提供额外的类型安全保证。

在这里，我们看到了两种选择：
```
contract Validator {
    function validate(uint) external returns(bool);
}

contract TypeSafeAuction {
    // good
    function validateBet(Validator _validator, uint _value) internal returns(bool) {
        bool valid = _validator.validate(_value);
        return valid;
    }
}

contract TypeUnsafeAuction {
    // bad
    function validateBet(address _addr, uint _value) internal returns(bool) {
        Validator validator = Validator(_addr);
        bool valid = validator.validate(_value);
        return valid;
    }
}
```
 可以从下面示例中看出使用`TypeSafeAuction`合约的好处 。如果 `validateBet()` 使用 `address` 参数或合约类型而不是`Validator`合约类型，编译器将抛出此错误：
```
contract NonValidator{}

contract Auction is TypeSafeAuction {
    NonValidator nonValidator;

    function bet(uint _value) {
        bool valid = validateBet(nonValidator, _value); // TypeError: Invalid type for argument in function call.
                                                        // Invalid implicit conversion from contract NonValidator
                                                        // to contract Validator requested.
    }
}
```

## 16. 避免 `extcodesize` 用于检查外部拥有的帐户
以下修饰符（或类似的检查）通常用于验证调用是来自外部拥有的账户（`EOA`）还是合约账户：
```
// bad
modifier isNotContract(address _a) {
  uint size;
  assembly {
    size := extcodesize(_a)
  }
    require(size == 0);
     _;
}
```

这个想法很简单：如果一个地址包含代码，它就不是一个 `EOA`，而是一个合约账户。但是，合约在构建期间没有可用的源代码。这意味着在构造函数运行时，它可以调用其他合约，但 `extcodesize` 在它的地址返回零。下面是一个最小的例子，展示了如何绕过这个检查：
```
contract OnlyForEOA {    
    uint public flag;

    // bad
    modifier isNotContract(address _a){
        uint len;
        assembly { len := extcodesize(_a) }
        require(len == 0);
        _;
    }

    function setFlag(uint i) public isNotContract(msg.sender){
        flag = i;
    }
}

contract FakeEOA {
    constructor(address _a) public {
        OnlyForEOA c = OnlyForEOA(_a);
        c.setFlag(1);
    }
}
```
因为可以预先计算合约地址，所以如果它检查一个在 `block n` 处为空，但在`block n`之后被部署的合约，依然会失败。

**警告**：这个问题很微妙。如果您的目标是阻止其他合约调用您的合约，那么 `extcodesize` 检查可能就足够了。另一种方法是检查 的值 (`tx.origin == msg.sender`)`，尽管这也有缺点。

在其他情况下， `extcodesize` 可能会为您服务。在这里描述所有这些超出了范围。了解 `EVM` 的基本行为并使用您的判断。


