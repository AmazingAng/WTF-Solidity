# OnChain Transaction Debugging: 6. Analysis for CirculateBUSD Project Rugpull, Loss of $2.27 Million!

Author: [Numen Cyber Technology](https://twitter.com/numencyber)

Jan-12–2023 07:22:39 AM +UTC， according to NUMEN on-chain monitoring, CirculateBUSD project has been drained by the contract creator, causing a loss of 2.27 million dollars.

The fund transfer of this project is mainly because the administrator calls CirculateBUSD.startTrading, and the main judgment parameter in startTrading is the value returned by the non-open source contract SwapHelper.TradingInfo set by the administrator, and then calls SwapHelper.swaptoToken to transfer funds.

Transaction：[https://bscscan.com/tx/0x3475278b4264d4263309020060a1af28d7be02963feaf1a1e97e9830c68834b3](https://bscscan.com/tx/0x3475278b4264d4263309020060a1af28d7be02963feaf1a1e97e9830c68834b3)

<div align=center>
<img src="https://miro.medium.com/max/1400/1*fLhvqu5spyN0EIycnFNqiw.png" alt="Cover" width="80%"/>
</div>

**Analysis:**
=============

Firstly, it calls contract startTrading ([https://bscscan.com/address/0x9639d76092b2ae074a7e2d13ac030b4b6a0313ff](https://bscscan.com/address/0x9639d76092b2ae074a7e2d13ac030b4b6a0313ff)), and inside the function the SwapHelper contract’s TradingInfo function is called, with the following details The code is as follows.

<div align=center>
<img src="https://miro.medium.com/max/1400/1*2LithcaYFRGcqls5IY_83g.png" alt="Cover" width="80%"/>
</div>

---

<div align=center>
<img src="https://miro.medium.com/max/1400/1*XbJHPldO3T-9frrr0SQrHA.png" alt="Cover" width="80%"/>
</div>

The above figure is the call stack of tx. Combined with the code we can see that TradingInfo inside only some static calls, the key problem is not in this function. Continuing with the analysis, we found that the call stack is corresponding to the approve operation and safeapprove. Then SwapHelper’s swaptoToken function was called, which was found to be a key function in combination with the call stack, and the transfer transaction was executed in this call. The SwapHelper contract is not open source as found by the on-chain information at the following address.

[https://bscscan.com/address/0x112f8834cd3db8d2dded90be6ba924a88f56eb4b#code](https://bscscan.com/address/0x112f8834cd3db8d2dded90be6ba924a88f56eb4b#code)

Try to reverse the analysis， we firstly locate the function signature 0x63437561.

<div align=center>
<img src="https://miro.medium.com/max/1400/1*i7kEvPo_8gYbNs9UGlo-KA.png" alt="Cover" width="80%"/>
</div>

Afterward, we located this function after decompiling and tried to find keywords such as transfer because you see that the call stack triggers a transfer.

<div align=center>
<img src="https://miro.medium.com/max/1400/1*n8BEIqfn0tZ6plky2MFd7w.png" alt="Cover" width="80%"/>
</div>

So locate this branch of the function, first stor\_6\_0\_19, and read that part out first.

<div align=center>
<img src="https://miro.medium.com/max/1400/1*ZGTqmc1sIz2_onKUT6-56Q.png" alt="Cover" width="80%"/>
</div>

At this point , the transfer to address was obtained, 0x0000000000000000000000005695ef5f2e997b2e142b38837132a6c3ddc463b7, which was found to be the same as the transfer to address of the call stack.

<div align=center>
<img src="https://miro.medium.com/max/1400/1*v37FEiN6L-0Nwn5OtbDgxQ.png" alt="Cover" width="80%"/>
</div>

When we analyzed the if and else branches of this function carefully, we found that if meet the if condition, then it will do normal redemption . Because through the slot to get stor5 is 0x00000000000000000000000010ed43c718714eb63d5aa57b78b54704e256024e, this contract is pancakerouter. backdoor function in the else branch, as long as the parameters passed in and stor7 slot stored value equal to trigger.

<div align=center>
<img src="https://miro.medium.com/max/1400/1*xlYEmp6nsdLA85FUmANxfw.png" alt="Cover" width="80%"/>
</div>

Below function is to modify the value of the slot 7 position, and the call permission only owned by the owner of the contract.

<div align=center>
<img src="https://miro.medium.com/max/1400/1*lHLaCA9HM1HtmL3pXYxltw.png" alt="Cover" width="80%"/>
</div>

All the above analysis is enough to determine that this is a project side run event.

Summary
=======

Numen Cyber Labs remind users that when do investment, it’s necessory to conduct security audits on the project’s contracts. There may be functions in the unverified contract where the project’s authority is too large or directly affects the safety of the user’s assets. The problems with this project are just the tip of the iceberg of the entire blockchain ecosystem. When users invest and project parties develop projects, they must conduct security audits on the code.

Numen Cyber Labs is committed to protecting the ecological security of Web3. Please stay tuned for more latest attack news and analysis.
