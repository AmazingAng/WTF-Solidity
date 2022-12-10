
-----

这一讲，我们将介绍智能合约低级调用返回值检查的注意事项。如果合约中忘记对低级调用的返回值进行检查，逻辑上往往会出现严重的问题。
## 低级调用(low level call)
在Solidity中，合约间相互调用基本上有两种方式，即直接通过合约的接口进行调用，比如：
```solidity
contract A {
    function a() public {

    }
}
contract B {
    function b(A a) public {
        a.a();
    }
}
```
由于在编译时合约A内部的函数签名可知，因此这种直接使用`a.a()`调用的方式是可行的，也是推荐使用的一种方式。但是有些时候我们也可以使用低级一些的方式进行转账或调用，例如向合约转Ether的最佳实践是使用`call()`配合重入保护。  
低级调用共有`call`, `staticcall`, `delegatecall`和`send`四种方式，其中`send`被设计为专门用来转Ether，但出于未来Gas成本可能会变化的顾虑，不推荐继续使用该函数转账。而其他三种低级调用在有些场景下是必须使用的，譬如必须使用delegatecall实现合约的代理模式。
那么低级调用和普通函数究竟有什么不一样呢？
## 低级调用的特殊性
在solidity层面，低级调用和普通调用最关键的区别是，低级调用的调用链上的某一层如果发生了revert，不会直接造成整个交易归滚，它只是平静地向上层返回一个元组。
```
contract AnError {
    function callToAnError() public {
        (bool success, bytes memory returnData) = address(this).call(abi.encodeWithSignature("anError()"));
    }

    function anError() public {
        revert("sorry sir");
    }
}
```
success是false，而如果把`returnData`是0x08c379a000000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000009736f727279207369720000000000000000000000000000000000000000000000  
拿去解码，""Error(string)" , sorry sir。  
这段代码的关键在于，`anError()`发生了revert，而它的上层`callToAnError`没有跟着revert。
在这个做演示的小例子里，我们没有对返回结果做检查，无伤大雅。但在一些需要根据执行结果决定接下来做什么的场景里，如果默认执行是成功的，这将会引入Bug。

## 永远记得对低级调用的返回值做检查
简而言之，在一些场景下，忘记对执行结果做检查会发生严重的事故。假设你构建了一个抽奖程序，有两个合约账户胜出，你需要向他们平均分发合约中所有的Ether代币：
```
contract RewardsWrong {
    /*
    * some complex、amazing and perfect logic code
    */
    address admin = 0xAb5801a7D398351b8bE11C439e05C5B3259aeC9B; // your address
    function sendEtherToWinners(address winner1 ,address winner2) public {
        require(msg.sender == admin );
        payable(winner1).send(address(this).balance/2);
        payable(winner2).send(address(this).balance);
    }
}
```
sendEtherToWinners函数的逻辑是简单的，但有一个致命的漏洞，合约没有检查winner1是否成功接收代币。假设winnder1的代码里既没有receive也没有fallback，这意味着winnner1没有接收Ether的能力，那么实际上send并未完成你想要的转账逻辑，相反的是，Rewards合约的balance在向winner1转钱之后并没有改变。而恰好winner2合约有一个被payable修饰的fallback函数，这会使得Rewards合约中所有的Ether都发送给了winner2。
想要修正这个错误也很简单：
```
function sendEtherToWinners(address winner1 ,address winner2) public {
        require(msg.sender == admin );
        bool success1 = payable(winner1).send(address(this).balance/2);
        bool success2 = payable(winner2).send(address(this).balance);
        require(success1 && success2);
}
```
这样，一旦任何一个合约不能正常接收Ether，整个交易就会回滚，你可以联系那个不能正常接收Ether的winner重新提供一个地址。