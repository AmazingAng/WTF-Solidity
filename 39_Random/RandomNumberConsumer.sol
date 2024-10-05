// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";

contract RandomNumberConsumer is VRFConsumerBaseV2Plus{
    
    // 申请后的subId
    //订阅ID类型已从VRF V2中的uint64变为VRF V2.5中的uint256
    uint256 subId;

    //存放得到的 requestId 和 随机数
    uint256 public requestId;
    uint256[] public randomWords;
    
    /**
     * 使用chainlink VRF，构造函数需要继承 VRFConsumerBaseV2Plus
     * 不同链参数填的不一样
     * 网络: Sepolia测试网
     * Chainlink VRF Coordinator 地址: 0x9ddfaca8183c41ad55329bdeed9f6a8d53168b1b
     * LINK 代币地址: 0x779877a7b0d9e8603169ddbd7836e478b4624789
     * 30 gwei Key Hash: 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae
     * Minimum Confirmations 最小确认块数 : 3 （数字大安全性高，一般填12）
     * callbackGasLimit gas限制 : 最大 2,500,000
     * Maximum Random Values 一次可以得到的随机数个数 : 最大 500          
     */
    address vrfCoordinator = 0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B;
    bytes32 keyHash = 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae;
    uint16 requestConfirmations = 3;
    uint32 callbackGasLimit = 200_000;
    uint32 numWords = 3;
    
    constructor(uint256 s_subId) VRFConsumerBaseV2Plus(vrfCoordinator){
        subId = s_subId;
    }

    /** 
     * 向VRF合约申请随机数 
     */
    function requestRandomWords() external {
        requestId = s_vrfCoordinator.requestRandomWords(
            VRFV2PlusClient.RandomWordsRequest(
                {
                    keyHash:keyHash,
                    subId:subId,
                    requestConfirmations: requestConfirmations,
                    callbackGasLimit: callbackGasLimit,
                    numWords: numWords,
                    extraArgs: VRFV2PlusClient._argsToBytes(
                    //此为是否指定原生代币如ETH等，来支付VRF请求的费用，当为false表示使用LINK代币支付
                    VRFV2PlusClient.ExtraArgsV1({nativePayment: false})
                    )
                }
            )
        );
    }

    /**
     * VRF合约的回调函数，验证随机数有效之后会自动被调用
     * 消耗随机数的逻辑写在这里
     */
    function fulfillRandomWords(uint256 _requestId, uint256[] calldata s_randomWords) internal override {
        randomWords = s_randomWords;
    }

}