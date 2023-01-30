# OnChain Transaction Debugging: 5. Analysis for CirculateBUSD Project Rugpull, Loss of $2.27 Million!

Author: [Numen Cyber Technology](https://twitter.com/numencyber)

## 前言
根据NUMEN链上监控显示，新加坡时间2023年1月12日下午 14:22:39 ，CirculateBUSD项目跑路，损失金额227万美金。该项目资金转移主要是管理员调用`CirculateBUSD.startTrading`，并且在startTrading里面的主要判断参数是由管理员设置的未开源合约`SwapHelper.TradingInfo`返回的数值，之后调用`SwapHelper.swaptoToken`转走资金。

<div align=center>
<img src="https://user-images.githubusercontent.com/107821372/212806617-33a2e763-754b-4682-baef-d78bccdbcbaa.png" alt="Cover" width="80%"/>
</div>

### 事件分析

* 首先调用了合约的`startTrading`，在函数内部调用了[SwapHelper合约](https://bscscan.com/address/0x9639d76092b2ae074a7e2d13ac030b4b6a0313ff)的`TradingInfo`函数，详细代码如下。

 <div align=center>
 <img src="https://user-images.githubusercontent.com/107821372/212807067-c3dfccde-6a26-4bb0-96e8-9a1141b88fc6.png" alt="Cover" width="80%"/>
 </div>

---
 <div align=center>
 <img src="https://user-images.githubusercontent.com/107821372/212807682-d99be725-a9a9-41a9-a380-329413af4b2f.png" alt="Cover" width="80%"/>
 </div>

  上图是tx的调用栈，结合代码可知`TradingInfo`里面只是一些静态调用，关键问题不在这个函数。继续往下分析，发现调用栈中的`approve`操作和`safeapprove`对应上。接着又调用了SwapHelper的`swaptoToken`函数，结合调用栈发现这是个关键函数，转账交易在这个`call`里面执行的。通过链上信息发现`SwapHelper`合约并不开源，具体地址如下：https://bscscan.com/address/0x112f8834cd3db8d2dded90be6ba924a88f56eb4b#code

* 尝试逆向分析一下。
  1. 首先定位函数签名`0x63437561`。
  <div align=center>
  <img src="https://user-images.githubusercontent.com/107821372/212841887-76fcfd50-81a4-4929-98f4-855dee1ec7ea.png" alt="Cover" width="80%"/>
  </div>
 
 
  2. 定位到这个反编译之后的函数，因为看到调用栈触发了转账，所以尝试寻找`transfer`等关键字。
  <div align=center>
  <img src="https://user-images.githubusercontent.com/107821372/212847664-c7b75363-38c1-422b-81f9-3ecdd669e9f8.png" alt="Cover" width="80%"/>
  </div>
  
  
  3. 于是定位到函数的这一分支，首先`stor_6_0_19`，先把这部分读出来。
  <div align=center>
  <img src="https://user-images.githubusercontent.com/107821372/212848157-38e7cb71-cf37-48c1-82b3-97122293f935.png" alt="Cover" width="80%"/>
  </div>
  
  
  4. 此时获得了转账`to`地址，`0x0000000000000000000000005695ef5f2e997b2e142b38837132a6c3ddc463b7`，
  发现该地址和调用栈的转账`to`地址一致。
  <div align=center>
  <img src="https://user-images.githubusercontent.com/107821372/212848482-fcc3cc17-8719-4f58-ab3d-c26ffd256b45.png" alt="Cover" width="80%"/>
  </div>
  
  
  5. 仔细分析这个函数的if和else分支，发现如果走if是正常兑换。因为通过插槽得到`stor5`是`0x00000000000000000000000010ed43c718714eb63d5aa57b78b54704e256024e`，这个合约是`pancakerouter`。后门函数在`else`分支，只要传入的参数和`stor7`插槽存放的值相等即可触发。
  
  <div align=center>
  <img src="https://user-images.githubusercontent.com/107821372/212848758-b9590cc6-e750-4208-9a92-b000af150e99.png" alt="Cover" width="80%"/>
  </div> 
  
  
  6. 这个函数就是修改插槽7位置的值，而且调用权限只有合约的owner可以。
  
  <div align=center>
  <img src="https://user-images.githubusercontent.com/107821372/212848982-42624cef-df94-4f10-bf51-4b8816b6c452.png" alt="Cover" width="80%"/>
  </div> 
  
  以上所有分析足以判断这是一个项目方跑路事件。

## 总结
NUMEN实验室提醒用户投资的时候需要对项目方的合约进行安全审计，未验证的合约中可能存在项目方权限过大或者直接影响用户资产安全的功能。这个项目存在的问题只是整个区块链生态的冰山一角，用户投资和项目方开发项目时一定对代码进行安全审计，NUMEN专注于为web3生态安全保驾护航。


