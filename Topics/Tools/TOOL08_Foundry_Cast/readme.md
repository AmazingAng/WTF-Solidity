# WTF Solidity极简入门-工具篇7: Foundry，以Solidity为中心的开发工具包

我最近在重新学solidity，巩固一下细节，也写一个“WTF Solidity极简入门”，供小白们使用），每周更新1-3讲。

推特：[@0xAA_Science](https://twitter.com/0xAA_Science)

社区：[Discord](https://discord.wtf.academy)｜[微信群](https://docs.google.com/forms/d/e/1FAIpQLSe4KGT8Sh6sJ7hedQRuIYirOoZK_85miz3dw7vA1-YjodgJ-A/viewform?usp=sf_link)｜[官网 wtf.academy](https://wtf.academy)

所有代码和教程开源在github: [github.com/AmazingAng/WTFSolidity](https://github.com/AmazingAng/WTFSolidity)

-----
## Foundry入门

[WTF Solidity极简入门-工具篇7: Foundry，以Solidity为中心的开发工具包](https://github.com/AmazingAng/WTF-Solidity/blob/main/Topics/Tools/TOOL07_Foundry/readme.md)


## Foundry 的组成

Foundry 项目由 `Forge`, `Cast`, `Anvil` 几个部分（命令行工具）组成

-   Forge: Foundry 项目中**执行初始化项目、管理依赖、测试、构建、部署智能合约**的命令行工具;
-   Cast: Foundry 项目中**与 RPC 节点交互**的命令行工具。可以进行智能合约的调用、发送交易数据或检索任何类型的链上数据;
-   Anvil: Foundry 项目中**启动的本地测试网/节点**的命令行工具。可以使用它配合测试前端应用与部署在该测试网的合约或通过 RPC 进行交互;

## 目标
这篇文章主要介绍Cast的使用，使用Cast在命令行下达到[Ethereum (ETH) Blockchain Explorer](https://etherscan.io/) 的效果。
这篇文章会使用cast达到如下的练习目标
* 查询区块
* 查询交易
* 交易解析
* 账户管理
* 合约查询
* 合约交互
* 编码解析
* 本地模拟链上交易



## 区块相关

### 查询区块

```shell
# $PRC_MAIN 替换成需要的RPC地址
cast block-number --rpc-url=$RPC_MAIN
```

输出结果：

```
15769241
```

> 将环境变量的`ETH_PRC_URL`设置为 `--rpc-url` 你就不需要在每个命令行后面增加  `--rpc-url=$RPC_MAIN`  我这里直接设置为主网

### 查询区块信息

```shell
# cast block <BLOCK> --rpc-url=$RPC_MAIN

cast block 15769241 --rpc-url=$RPC_MAIN

# 格式化

cast block 15769241 --json --rpc-url=$RPC_MAIN


```

输出结果：

```shell 
baseFeePerGas        22188748210
difficulty           0
extraData            0x
gasLimit             30000000
gasUsed              10595142
hash                 0x016e71f4130bac96a20761acbc0ba82a77c26f85513f1661adfd406d1c809543
logsBloom            0x1c6150404140580410990400a61d01e30030b00100c2a6310b11b9405d012980125671129881101011501d399081855523a106443aef3ab07148626315f721550290981058030b2af90b213961204c6103d2002a076c9e12d0800475b8231f0d06a20100da57c60aa0c008280128284418503340087c8650104c34500c18aa1c2070878008c21c64207d1424000244811415afc507640448122060644c181204ba412f0af11365020880508105551226004c0801c1840183003a42062a5a2444c13266020c00081440008038492740a8204a0c6c050a29d52405b92e4b20f028a97a604c6b0849ca81c4d06009258b4206217803a168824484deb8513242f082
miner                0x4675C7e5BaAFBFFbca748158bEcBA61ef3b0a263
mixHash              0x09b7a94ef1d6c93caaff49ca8bf387652e0e33e116076b61f4d5ee79f0b91f92
nonce                0x0000000000000000
number               15769241
parentHash           0x95c60d89f2275a6a7b1a9545cf1fb6d8c614402cd7311c82bc7972c177f7812d
receiptsRoot         0xe0240d60c448387123e412114cd0165b2af7b926d34bb824f8c544b022aa76f9
sealFields           []
sha3Uncles           0x1dcc4de8dec75d7aab85b567b6ccd41ad312451b948a7413f0a142fd40d49347
size                 149912
stateRoot            0xaa3e9d839e99c4791827c81df9c9129028a320432920205f191e3fb261d0951c
timestamp            1666026803
totalDifficulty      58750003716598352816469
transactions:        [
	0xc4f5c10e4419698edaf7431df464340b389e4b79db959d58f42e82e8d1ed18ae
	0xb90edeacf833ac6cb91a326c775ed86d8047a467404bd8c69782d2260983eaad
	0x6f280650e35238ab930c9a0f3163443fffe2efedc5b553f408174d4bcd89cd8d
	0x2e0eafea64aaf2f53240a16b11a4f250ba74ab9ca5a1a90e6f2a6e92185877d2
	0x34f41d22ed8209da379691640cec5bfb8bf9404ad0f7264709b7959d61532343
	0x7569ab5ce2d1ca13a0c65ad52cc901dfc186e8ff8800793550b97760cbe34db2
	0xcdeef0ffe859fcf96fb52e22a9789295c6f1a94280df9faf0ebb9d52abefb3e7
	0x00d6793f3dbdd616351441b9e3da9a0de51370174e0d9383b4aae5c3c9806c2a
	0xff3daf63a431af021351d3da5f2f39a894352328d7f3df96afab1888f5a7093f
	0x7938399bee5293c384831c8e5aa698cdb491d568f9ebfb6d5c946f4ef7bf7e51
	0x20e7dda515f04ea6a787f68689e27bcadbba914184da5336204f3f36771f59f0
	0x0435d78a1b62484fbe3a7680d68ba4bdf0d692f087f4a6b70eb377421c58a5dd
	0xe16d1fa4d60cca7447850337c63cdf7b888318cc1bbb893b115f262dc01132d7
	0x44af4f696dcfedee682d7e511ad2469780443052565eea731b86b652a175c05e
	0xe88732f92ac376efb6e7517e66fc586447e0d065b8686556f2c1a7c3b7a519ce
	0x7ee890b096e97fc0c7e3cf74e0f0402532e0f3b8fa0e0c494d3d691d031f57e7
	...]
```

## 交易相关

### 查询交易

```shell
# 跟ethersjs中的 provider.getTransaction 类似
# cast tx <HASH> [FIELD] --rpc-url=$RPC

# 跟ethersjs中的 provider.getTransactionReceipt类似
# cast receipt <HASH> [FIELD] --rpc-url=$RPC 

cast tx 0x20e7dda515f04ea6a787f68689e27bcadbba914184da5336204f3f36771f59f0 --rpc-url=$RPC 

cast receipt 0x20e7dda515f04ea6a787f68689e27bcadbba914184da5336204f3f36771f59f0 --rpc-url=$RPC

# 只获取logs

cast receipt 0x20e7dda515f04ea6a787f68689e27bcadbba914184da5336204f3f36771f59f0 logs --rpc-url=$RPC

```

第一条命令行结果：

```shell
blockHash            0x016e71f4130bac96a20761acbc0ba82a77c26f85513f1661adfd406d1c809543
blockNumber          15769241
from                 0x9C0649d7325990D98375F7864eA167B5EAdCD46a
gas                  313863
gasPrice             35000000000
hash                 0x20e7dda515f04ea6a787f68689e27bcadbba914184da5336204f3f36771f59f0
input                0x38ed173900000000000000000000000000000000000000000000000332ca1b67940c000000000000000000000000000000000000000000000000000416b4849e6ba1475000000000000000000000000000000000000000000000000000000000000000a00000000000000000000000009c0649d7325990d98375f7864ea167b5eadcd46a00000000000000000000000000000000000000000000000000000000634d91c1000000000000000000000000000000000000000000000000000000000000000200000000000000000000000097be09f2523b39b835da9ea3857cfa1d3c660cbb0000000000000000000000001bbf25e71ec48b84d773809b4ba55b6f4be946fb
nonce                14
r                    0x288aef25af73a4d1916f8d37107ef5f24729a423f23acc38920829c4180fe794
s                    0x7644d26a91da02ff1e774cc821febf6387b8ee9f3e3085140b781819d0d8ede0
to                   0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
transactionIndex     10
v                    38
value                0
```

第二行命令行结果：

```shell
blockHash               0x016e71f4130bac96a20761acbc0ba82a77c26f85513f1661adfd406d1c809543
blockNumber             15769241
contractAddress
cumulativeGasUsed       805082
effectiveGasPrice       35000000000
gasUsed                 114938
logs                    [{"address":"0x97be09f2523b39b835da9ea3857cfa1d3c660cbb","topics":["0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef","0x0000000000000000000000009c0649d7325990d98375f7864ea167b5eadcd46a","0x000000000000000000000000f848e97469538830b0b147152524184a255b9106"],"data":"0x00000000000000000000000000000000000000000000000332ca1b67940c0000","blockHash":"0x016e71f4130bac96a20761acbc0ba82a77c26f85513f1661adfd406d1c809543","blockNumber":"0xf09e99","transactionHash":"0x20e7dda515f04ea6a787f68689e27bcadbba914184da5336204f3f36771f59f0","transactionIndex":"0xa","logIndex":"0x2","removed":false},{"address":"0x1bbf25e71ec48b84d773809b4ba55b6f4be946fb","topics":["0x06b541ddaa720db2b10a4d0cdac39b8d360425fc073085fac19bc82614677987","0x000000000000000000000000f848e97469538830b0b147152524184a255b9106","0x000000000000000000000000f848e97469538830b0b147152524184a255b9106","0x0000000000000000000000009c0649d7325990d98375f7864ea167b5eadcd46a"],"data":"0x0000000000000000000000000000000000000000000000044b0a580cbdcfc0d90000000000000000000000000000000000000000000000000000000000000060000000000000000000000000000000000000000000000000000000000000008000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000","blockHash":"0x016e71f4130bac96a20761acbc0ba82a77c26f85513f1661adfd406d1c809543","blockNumber":"0xf09e99","transactionHash":"0x20e7dda515f04ea6a787f68689e27bcadbba914184da5336204f3f36771f59f0","transactionIndex":"0xa","logIndex":"0x3","removed":false},{"address":"0x1bbf25e71ec48b84d773809b4ba55b6f4be946fb","topics":["0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef","0x000000000000000000000000f848e97469538830b0b147152524184a255b9106","0x0000000000000000000000009c0649d7325990d98375f7864ea167b5eadcd46a"],"data":"0x0000000000000000000000000000000000000000000000044b0a580cbdcfc0d9","blockHash":"0x016e71f4130bac96a20761acbc0ba82a77c26f85513f1661adfd406d1c809543","blockNumber":"0xf09e99","transactionHash":"0x20e7dda515f04ea6a787f68689e27bcadbba914184da5336204f3f36771f59f0","transactionIndex":"0xa","logIndex":"0x4","removed":false},{"address":"0xf848e97469538830b0b147152524184a255b9106","topics":["0x1c411e9a96e071241c2f21f7726b17ae89e3cab4c78be50e062b03a9fffbbad1"],"data":"0x00000000000000000000000000000000000000000000213ebfba613ffdcdd6ad0000000000000000000000000000000000000000000018b4b7f855bdcaac3b14","blockHash":"0x016e71f4130bac96a20761acbc0ba82a77c26f85513f1661adfd406d1c809543","blockNumber":"0xf09e99","transactionHash":"0x20e7dda515f04ea6a787f68689e27bcadbba914184da5336204f3f36771f59f0","transactionIndex":"0xa","logIndex":"0x5","removed":false},{"address":"0xf848e97469538830b0b147152524184a255b9106","topics":["0xd78ad95fa46c994b6551d0da85fc275fe613ce37657fb8d5e3d130840159d822","0x0000000000000000000000007a250d5630b4cf539739df2c5dacb4c659f2488d","0x0000000000000000000000009c0649d7325990d98375f7864ea167b5eadcd46a"],"data":"0x000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000332ca1b67940c00000000000000000000000000000000000000000000000000044b0a580cbdcfc0d90000000000000000000000000000000000000000000000000000000000000000","blockHash":"0x016e71f4130bac96a20761acbc0ba82a77c26f85513f1661adfd406d1c809543","blockNumber":"0xf09e99","transactionHash":"0x20e7dda515f04ea6a787f68689e27bcadbba914184da5336204f3f36771f59f0","transactionIndex":"0xa","logIndex":"0x6","removed":false}]
logsBloom               0x00200000000000000000000080000000000000000000000000010000000008000000000000800000000000000000000000000000002000000000000000000000000000000000000000000008000000200000000000000000000000400000100000000000800000002000000000000000000000400000000000000010000000000000000000000000005000000000040000000000000000080000004004000000000000084100000000000000000000000000000040000000000000000000040000000002000000000000000000000000000000000000001000002000000020000000000000000000000000000000000000004000000000000000000000000000
root
status                  1
transactionHash         0x20e7dda515f04ea6a787f68689e27bcadbba914184da5336204f3f36771f59f0
transactionIndex        10
type                    0

```

### 交易解析

Cast 会从 [Ethereum Signature Database](https://sig.eth.samczsun.com.) 解析对应的方法名称

```shell
# cast 4byte <SELECTOR> 解析交易的名称
cast 4byte 0x38ed1739
```

输出结果：

```shell
swapExactTokensForTokens(uint256,uint256,address[],address,uint256)
```

### 交易签名 

> 使用 Keccak-256 能够计算出方法名
> 函数名为被调函数原型[1]的Keccak-256哈希值的前4个字节。这允许EVM准确无误地识别被调函数。

交易签名：

```shell
# cast sig <SIG>

cast sig "swapExactTokensForTokens(uint256,uint256,address[],address,uint256)"

```

输出结果：

```shell
0x38ed1739
```

所以你可以看到最终都是 `0x38ed1739`

有些方法名称可能没有，你可以通过`cast upload-signature <SIG> `上传给 [Ethereum Signature Database](https://sig.eth.samczsun.com) 

### 交易解码

```shell
# 获得calldata
cast tx 0x20e7dda515f04ea6a787f68689e27bcadbba914184da5336204f3f36771f59f0 input

# 可以通过该方法decode交易的数据，类似etherscan中的decode方法
# cast pretty-calldata <CALLDATA>
cast pretty-calldata 0x38ed173900000000000000000000000000000000000000000000000332ca1b67940c000000000000000000000000000000000000000000000000000416b4849e6ba1475000000000000000000000000000000000000000000000000000000000000000a00000000000000000000000009c0649d7325990d98375f7864ea167b5eadcd46a00000000000000000000000000000000000000000000000000000000634d91c1000000000000000000000000000000000000000000000000000000000000000200000000000000000000000097be09f2523b39b835da9ea3857cfa1d3c660cbb0000000000000000000000001bbf25e71ec48b84d773809b4ba55b6f4be946fb
```

输出结果：

```shell
 Possible methods:
 - swapExactTokensForTokens(uint256,uint256,address[],address,uint256)
 ------------
 [0]:  00000000000000000000000000000000000000000000000332ca1b67940c0000
 [1]:  00000000000000000000000000000000000000000000000416b4849e6ba14750
 [2]:  00000000000000000000000000000000000000000000000000000000000000a0
 [3]:  0000000000000000000000009c0649d7325990d98375f7864ea167b5eadcd46a
 [4]:  00000000000000000000000000000000000000000000000000000000634d91c1
 [5]:  0000000000000000000000000000000000000000000000000000000000000002
 [6]:  00000000000000000000000097be09f2523b39b835da9ea3857cfa1d3c660cbb
 [7]:  0000000000000000000000001bbf25e71ec48b84d773809b4ba55b6f4be946fb
```

### 模拟运行

```
# Usage: cast run --rpc-url <URL> <TXHASH>

cast run 0x20e7dda515f04ea6a787f68689e27bcadbba914184da5336204f3f36771f59f0
```

运行结果：

![](https://afox-1256168983.cos.ap-shanghai.myqcloud.com/20221018120934.png)

可以在结果中看到运行消耗的gas，以及方法顺序调用的过程，以及释放的emit的事件。通过这个可以了解一个hash的内在过程。类似 [BlockSec Building BlockChain Security Infrastructure](https://blocksec.com/) 和 [Tenderly | Ethereum Developer Platform](https://tenderly.co/) 可以结合使用。

## 账户管理

### 新建账户

```shell
# 新建一个账号
# cast wallet new [OUT_DIR] 
cast wallet new

# 新建一个keystore的账号，带有密码
# cast wallet new <PATH>
cast wallet new  ~/Downloads
```

第一条命令行结果输出：

```shell
Successfully created new keypair.
Address: 0xDD20b18E001A80d8b27B8Caa94EeAC884D1c****
Private Key: edb4444199bddea91879c0214af27c0c7f99****bf18e46ba4078a39ccdbe0bc
```

第二条命令行结果输出：

```shell
Enter secret:
Created new encrypted keystore file: `/Users/EasyPlux/Downloads/b5832df5-21e9-4959-8c85-969eec9c0***`\nPublic Address of the key: 0x58c1C8f6A7D92A9b20A5343949cd624570Ab****
```

### 账户签名

```shell
# 两种方法都可以使用签名，第一种载入刚才生成的keystore私钥，第二种直接输入自己的私钥。
cast wallet sign <MESSAGE> --keystore=<PATH> 
cast wallet sign <MESSAGE> -i
```

### 账户验证

```shell
cast wallet verify --address <ADDRESS> <MESSAGE> <SIGNATURE> 
```

## 合约交互

### 获取合约

```shell
cast etherscan-source <contract address>

cast etherscan-source 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2 --etherscan-api-key=‘key’

```

### 下载合约

```shell
#cast etherscan-source -d <path>
# 我这里已经将$WETH的地址写入环境变量，如果没写入的，可以写成合约地址
cast etherscan-source $WETH -d ~/Downloads
```

### 调用合约

调用 WETH合约的`balanceOf`方法,查看`0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2`账号的余额

```shell
#cast call [OPTIONS] [TO] [SIG] [ARGS]... [COMMAND]

cast call $WETH "balanceOf(address)" 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2

# 输出
# 0x0000000000000000000000000000000000000000000000230d12770f2845219c

# 格式化输出 在参数后面加一个返回值的格式

cast call $WETH "balanceOf(address)(uint256)" 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2

# 输出
# 646577988758891995548

```

### 解析ABI

可以根据ABI反向解析出solidity代码
```shell
# cast interface [OPTIONS] <PATH_OR_ADDRESS>
cast interface ./weth.abi
```

## 编码解码

```shell
cast --to-hex 

cast --to-dec 

cast --to-unit 

cast --to-wei 

cast --to-rlp 

cast --from-rlp

```

## Tips

### 设置ETH_PRC_URL
将环境变量的`ETH_PRC_URL`设置为 `--rpc-url` 你就不需要在每个命令行后面增加  `--rpc-url=$RPC_MAIN`  我这里直接设置为主网

### 设置ETHERSCAN_API_KEY
设置`ETHERSCAN_API_KEY`环境变量可以直接代替 `--etherscan-api-key`

### JSON格式化

加上 `--json`  可以格式化输出

```shell
cast block 15769241 --json --rpc-url=$RPC_MAIN
```


## 参考
[使用 foundry 框架加速智能合约开发](https://www.youtube.com/watch?v=EXYeltwvftw) 
[cast Commands - Foundry Book](https://book.getfoundry.sh/reference/cast/)
[https://twitter.com/wp__lai](https://twitter.com/wp__lai)