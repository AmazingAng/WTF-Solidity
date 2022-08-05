# BanaCat NFT Contract（3/3）

# 关于BanaCatNFT

BanaCat一期项目是一个部署在polygon区块链上的头像数字艺术品

![banner.png](banner.png)

项目链接：**[https://opensea.io/collection/banacat-v2](https://opensea.io/collection/banacat-v2)**

合约源码地址：**[https://polygonscan.com/address/0xd2bc5c3990c06ccd26f10a3e9d93b19450136c8d#code](https://polygonscan.com/address/0xd2bc5c3990c06ccd26f10a3e9d93b19450136c8d#code)**

同时，基于这款数字艺术品，我们也设计了配套的表情包周边，目前已经有一款已经上架到微信表情包商城，表情包链接：[**香蕉猫看戏篇**](https://sticker.weixin.qq.com/cgi-bin/mmemoticon-bin/emoticonview?oper=single&t=shop/detail&productid=aL2PCfwK/89qO7sF6/+I+UDhfwEjhec2ZNvdnLLJRd/N7QVyYnUnFpeB0t9OOOGqFiGlj08OJVil+/ruMQmJp3eFNlkqDVcbCJC9A4/2eWbE=)

![Untitled](Untitled%201.png)

---

前期文章

[BanaCat NFT Contract（1/3）](BanaCat%20NFT%20Contract%EF%BC%881%203%EF%BC%89%209284fb7d529046fb908e70cfed5cbc64.md)

[BanaCat NFT Contract（2/3）](BanaCat%20NFT%20Contract%EF%BC%882%203%EF%BC%89%202fed2b20e00b4af9acf6104983616ced.md)

本文主要讲解BanaCatNFT内置的特殊的mint通道。发布BanaCatNFT之前因为没有进行前期的宣传以及收集白名单，但为了让项目尽快上线同时减少用户的获取门槛，不同于传统的白名列表或者默克尔树方式，一期的BanaCatNFT采用了输入密码进行mint的方式，接下来我们一起分析这种特殊的freeMint方案的利弊。

**整体思路：**设置长度为5的密码数组，分别记录5个不同的密码用以对应不用的mint场景，每个密码都可以设置对应可以mint的NFT数量，用户得知密码之后，在特殊通道输入密码之后，如果密码比对正确，则跳过扣费步骤，直接分配NFT给用户。

# 设置密码

定义一种关于密码信息的数据结构，然后定义一个存储密码信息的数组。

![Untitled](Untitled%2088.png)

**`showSecretattributes()`**：_ID对应密码在数组中的索引，secret 对应密码本身，supplyAmount 对应本次设置的密码可以mintNFT的数量。

注：要想改变同一个数组索引中不同的密码属性时，要先前一个密码中剩余的NFT数量。

![Untitled](Untitled%2089.png)

**`setMaxTokenAmountForEachAddress（）`**：设置在使用特殊通道mint的时候，单个地址最多可以mint多少个NFT。

![Untitled](Untitled%2090.png)

# 检查密码

`**checkSecret（）**`：循环比较userInput 是否和数组中的已设置的密码对应。如果出现比对成功的密码，则跳出循环。

![Untitled](Untitled%2091.png)

**`isEqual()`**： 会对比输入的两个字符串是否相同，因为solidity语法中没有直接比较两个字符串是否相同的语法，这里通过比较字符串的hash值来间接比对字符串是否相同.

![Untitled](Untitled%2092.png)

# 特殊通道mint

**`specialMint_tunnel()`**:使用上面验证函数对用户输入密码进行审查，审查通过之后分配NFT给当前账户

![Untitled](Untitled%2093.png)

通过特护通道mint交易举例

[Polygon Transaction Hash (Txhash) Details | PolygonScan](https://polygonscan.com/tx/0xc50d4022ff5a9e3b906ede41cf014a55bfe93d901711e3514f844778d31e9abd)

# 查看密码属性

**`showSecretattributes（）`**：根据输入的密码编号查看密码，onlyowner可看（这里我给自己挖了一个坑）

![Untitled](Untitled%2094.png)

**`getRemainingtokenAmount（）`**：根据密码编号查看单签密码还剩余多少个NFT可以mint。

![Untitled](Untitled%2095.png)

给自己挖的坑：**`showSecretattributes（）` ，  `getRemainingtokenAmount（）`**都是view（只读）方法，设定为 onlyOwner可读，部署过之后在remix后台可读，但是在polyscan浏览器中，这两个方法不可用。

# 密码白名单机制的利弊

优点：不需要收集白名单，知道密码的人都可以免费mint，可以用于临时性的活动

缺点：目前来看，缺点会更多

1. 凡是拿到密码的人都可以mint，不管你是谁，当一个知道密码的人传开密码之后场面会变得不可控，除非是项目方有意而为之；
2. 单个地址mint的数量限制“防君子不防小人”，只需要两个地址就可以把项目方薅爆；
3. 设置的密码会以明文的形式显示在交易记录中，导致密码只能临时设置；

# 改进方案：将Merkle树验证方案和密码机制结合起来

- Merkle树的白名单验证机制是把白名单中的地址两两hash最终生成一个树根，只将这个树根存到合约中，区别于以往将白名单整个存到链上，这种验证机制可以极大节约发行成本。将Merkle树验证方案和密码机制结合起来，我能想到的一种解决方案是：实现设定一定数量的密码，替换成白名单中的地址计算Merkle树根，然后将树根存入合约中，发放白名单的时候可以把这些密码以某种媒介发放到用户手中。
- 用映射表取代数组，在检测密码是否合法的时候不用循环遍历数组，从而节约gas。

# 应用场景：刮刮乐彩票与NFT的融合应用