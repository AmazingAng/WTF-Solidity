// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";

/**
 * Faucets for LINK and ETH to apply for testnet: https://faucets.chain.link/
 */

contract RandomNumberConsumer is VRFConsumerBase {
    bytes32 internal keyHash; // VRF unique identifier
    uint256 internal fee; // VRF usage fee

    uint256 public randomResult; // store random number

    /**
     * To use chainlink VRF, the constructor needs to inherit VRFConsumerBase
     * The parameters of different chains are filled differently
     * Network: Rinkeby test network
     * Chainlink VRF Coordinator address: 0xb3dCcb4Cf7a26f6cf6B120Cf5A73875B7BBc655B
     * LINK token address: 0x01BE23585060835E02B77ef475b0Cc51aA1e0709
     * Key Hash: 0x2ed0feb3e7fd2022120aa84fab1945545a9f2ffc9076fd6156fa96eaff4c1311
     */
    constructor()
        VRFConsumerBase(
            0xb3dCcb4Cf7a26f6cf6B120Cf5A73875B7BBc655B, // VRF Coordinator
            0x01BE23585060835E02B77ef475b0Cc51aA1e0709 // LINK Token
        )
    {
        keyHash = 0x2ed0feb3e7fd2022120aa84fab1945545a9f2ffc9076fd6156fa96eaff4c1311;
        fee = 0.1 * 10 ** 18; // 0.1 LINK (VRF usage fee, Rinkeby test network)
    }

    /**
     * Apply random number to VRF contract
     */
    function getRandomNumber() public returns (bytes32 requestId) {
        // There needs to be enough LINK in the contract
        require(
            LINK.balanceOf(address(this)) >= fee,
            "Not enough LINK - fill contract with faucet"
        );
        return requestRandomness(keyHash, fee);
    }

    /**
     * The callback function of the VRF contract will be called automatically after verifying that the random number is valid
     * The logic of consuming random numbers is written here
     */
    function fulfillRandomness(
        bytes32 requestId,
        uint256 randomness
    ) internal override {
        randomResult = randomness;
    }
}
