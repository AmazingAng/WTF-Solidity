# Solidity极简入门: 24. Create2

我最近在重新学solidity，巩固一下细节，也写一个“Solidity极简入门”，供小白们使用（编程大佬可以另找教程），每周更新1-3讲。

欢迎关注我的推特：[@0xAA_Science](https://twitter.com/0xAA_Science)

欢迎加入WTF科学家社区：[discord](https://discord.gg/5akcruXrsk)

所有代码开源在github(64个star开微信交流群；128个star录教学视频): [github.com/AmazingAng/WTFSolidity](https://github.com/AmazingAng/WTFSolidity)

-----

## CREATE2
`CREATE2` 操作码使我们在智能合约部署在以太坊网络之前就能预测合约的地址。`Uniswap`创建`Pair`合约用的就是`CREATE2`而不是`CREATE`。这一讲，我将介绍`CREATE2`的用法

### CREATE如何计算地址
智能合约可以由其他合约和普通账户利用`CREATE`操作码创建。 在这两种情况下，新合约的地址都以相同的方式计算：创建者的地址(通常为部署的钱包地址或者合约地址)和`nounce`(该地址发送交易的总数,对于合约账户是创建的合约总数,每创建一个合约nonce+1))的哈希。
```
新地址 = hash(创建者地址, nonce)
```
创建者地址不会变，但`nounce`可能会随时间而改变，因此用`CREATE`创建的合约地址不好预测。

### CREATE2如何计算地址
`CREATE2`的目的是为了让合约地址独立于未来的事件。不管未来区块链上发生了什么，你都可以把合约部署在事先计算好的地址上。用`CREATE2`创建的合约地址由4个部分决定：
- `0xFF`：一个常数，避免和`CREATE`冲突
- 创建者地址
- `salt`（盐）：一个创建者给定的数值
- 待部署合约的字节码（`bytecode`）

```
新地址 = hash("0xFF",创建者地址, salt, bytecode)
```
`CREATE2` 确保，如果创建者使用 `CREATE2` 和提供的 `salt` 部署给定的合约`bytecode`，它将存储在 `新地址` 中。

## 如何使用`CREATE2`
`CREATE2`的用法和之前讲的`Create`类似，同样是`new`一个合约，并传入新合约构造函数所需的参数，只不过要多传一个`salt`参数：
```
Contract x = new Contract{salt: _salt, value: _value}(params)
```
其中`Contract`是要创建的合约名，`x`是合约对象（地址），`_salt`是指定的盐；如果构造函数是`payable`，可以创建时转入`_value`数量的`ETH`，`params`是新合约构造函数的参数。

## 极简Uniswap2

跟[上一讲](https://mirror.xyz/dashboard/edit/kojopp2CgDK3ehHxXc_2fkZe87uM0O5OmsEU6y83eJs)类似，我们用`Create2`来实现极简`Uniswap`。

### `Pair`
```
contract Pair{
    address public factory; // 工厂合约地址
    address public token0; // 代币1
    address public token1; // 代币2

    constructor() payable {
        factory = msg.sender;
    }

    // called once by the factory at time of deployment
    function initialize(address _token0, address _token1) external {
        require(msg.sender == factory, 'UniswapV2: FORBIDDEN'); // sufficient check
        token0 = _token0;
        token1 = _token1;
    }
}
```
`Pair`合约很简单，包含3个状态变量：`factory`，`token0`和`token1`。

构造函数`constructor`在部署时将`factory`赋值为工厂合约地址。`initialize`函数会在`Pair`合约创建的时候被工厂合约调用一次，将`token0`和`token1`更新为币对中两种代币的地址。

### `PairFactory2`
```
contract PairFactory2{
        mapping(address => mapping(address => address)) public getPair; // 通过两个代币地址查Pair地址
        address[] public allPairs; // 保存所有Pair地址

        function createPair2(address tokenA, address tokenB) external returns (address pairAddr) {
            // 计算用tokenA和tokenB地址计算salt
            (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA); //将tokenA和tokenB按大小排序
            bytes32 salt = keccak256(abi.encodePacked(token0, token1));
            // 用create2部署新合约
            Pair pair = new Pair{salt: salt}(); 
            // 调用新合约的initialize方法
            pair.initialize(tokenA, tokenB);
            // 更新地址map
            pairAddr = address(pair);
            allPairs.push(pairAddr);
            getPair[tokenA][tokenB] = pairAddr;
            getPair[tokenB][tokenA] = pairAddr;
        }
```
工厂合约（`PairFactory2`）有两个状态变量`getPair`是两个代币地址到币对地址的`map`，方便根据代币找到币对地址；`allPairs`是币对地址的数组，存储了所有代币地址。

`PairFactory2`合约只有一个`createPair2`函数，使用`CREATE2`根据输入的两个代币地址`tokenA`和`tokenB`来创建新的`Pair`合约。其中
```
    Pair pair = new Pair{salt: salt}(); 
```
就是利用`CREATE2`创建合约的代码，非常简单，而`salt`为`token1`和`token2`的`hash`：
```
            bytes32 salt = keccak256(abi.encodePacked(token0, token1));
```

### 事先计算`Pair`地址
```
        // 提前计算pair合约地址
        function calculateAddr(address tokenA, address tokenB) public view returns(address predictedAddress){
            // 计算用tokenA和tokenB地址计算salt
            (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA); //将tokenA和tokenB按大小排序
            bytes32 salt = keccak256(abi.encodePacked(token0, token1));
            // 计算合约地址方法 hash()
            predictedAddress = address(uint160(uint(keccak256(abi.encodePacked(
                bytes1(0xff),
                address(this),
                salt,
                keccak256(type(Pair).creationCode)
            )))));
        }
```
我们写了一个`calculateAddr`函数来事先计算`tokenA`和`tokenB`将会生成的`Pair`地址。通过它，我们可以验证我们事先计算的地址和实际地址是否相同。

大家可以部署好`PairFactory2`合约，然后用下面两个地址作为参数调用`createPair2`，看看创建的币对地址是什么，是否与事先计算的地址一样：
```
WBNB地址: 0x2c44b726ADF1963cA47Af88B284C06f30380fC78
BSC链上的PEOPLE地址:
0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c
```
### 在remix上验证
1. 首先用`WBNB`和`PEOPLE`的地址哈希作为`salt`来计算出`Pair`合约的地址
2. 调用`PairFactory2.createPair2`传入参数为`WBNB`和`PEOPLE`的地址，获取出创建的`pair`合约地址
3. 对比合约地址
![create2_remix_test.png](https://github.com/AmazingAng/WTFSolidity/blob/main/24_Create2/create2_remix_test.png)

## create2的实际应用场景
1. 交易所为新用户预留创建钱包合约地址。

2. 由 `CREATE2` 驱动的 `factory` 合约，在`uniswapV2`中交易对的创建是在 `Factory`中调用`create2`完成。这样做的好处是: 它可以得到一个确定的`pair`地址, 使得 `Router`中就可以通过 `(tokenA, tokenB)` 计算出`pair`地址, 不再需要执行一次 `Factory.getPair(tokenA, tokenB)` 的跨合约调用。

## 总结

这一讲，我们介绍了`CREATE2`操作码的原理，使用方法，并用它完成了极简版的`Uniswap`并提前计算币对合约地址。`CREATE2`让我们可以在部署合约前确定它的合约地址，这也反事实系统和很多`layer2`的基础。
