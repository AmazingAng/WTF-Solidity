// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
 * import from github and npm
 * Import files are stored in the .deps directory of the current workspace
 */
import "../34_ERC721/ERC721.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";

contract RandomNumber is ERC721, VRFConsumerBase {
    // NFT parameters
    uint256 public totalSupply = 100; // total supply
    uint256[100] public ids; // used to calculate tokenId that can be mint
    uint256 public mintCount; // the number of mint, the default value is 0
    // chainlink VRF parameters
    bytes32 internal keyHash;
    uint256 internal fee;

    // Record the mint address corresponding to the VRF application ID
    mapping(bytes32 => address) public requestToSender;

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
        ERC721("WTF Random", "WTF")
    {
        keyHash = 0x2ed0feb3e7fd2022120aa84fab1945545a9f2ffc9076fd6156fa96eaff4c1311;
        fee = 0.1 * 10 ** 18; // 0.1 LINK (VRF usage fee, Rinkeby test network)
    }

    /**
     * Input a uint256 number and return a tokenId that can be mint
     */
    function pickRandomUniqueId(
        uint256 random
    ) private returns (uint256 tokenId) {
        // Calculate the subtraction first, then calculate ++, pay attention to the difference between (a++, ++a)
        uint256 len = totalSupply - mintCount++; // mint quantity
        require(len > 0, "mint close"); // all tokenIds are mint finished
        uint256 randomIndex = random % len; // get the random number on the chain

        // Take the modulus of the random number to get the tokenId as an array subscript, and record the value as len-1 at the same time. If the value obtained by taking the modulus already exists, then tokenId takes the value of the array subscript
        tokenId = ids[randomIndex] != 0 ? ids[randomIndex] : randomIndex; // get tokenId
        ids[randomIndex] = ids[len - 1] == 0 ? len - 1 : ids[len - 1]; // update ids list
        ids[len - 1] = 0; // delete the last element, can return gas
    }

    /**
     * On-chain pseudo-random number generation
     * keccak256(abi.encodePacked() fill in some global variables/custom variables on the chain
     * Convert to uint256 type when returning
     */
    function getRandomOnchain() public view returns (uint256) {
        /*
         * In this case, randomness on the chain only depends on block hash, caller address, and block time,
         * If you want to improve the randomness, you can add some attributes such as nonce, etc., but it cannot fundamentally solve the security problem
         */
        bytes32 randomBytes = keccak256(
            abi.encodePacked(
                blockhash(block.number - 1),
                msg.sender,
                block.timestamp
            )
        );
        return uint256(randomBytes);
    }

    // Use the pseudo-random number on the chain to cast NFT
    function mintRandomOnchain() public {
        uint256 _tokenId = pickRandomUniqueId(getRandomOnchain()); // Use the random number on the chain to generate tokenId
        _mint(msg.sender, _tokenId);
    }

    /**
     * Call VRF to get random number and mintNFT
     * To call the requestRandomness() function to obtain, the logic of consuming random numbers is written in the VRF callback function fulfillRandomness()
     * Before calling, transfer LINK tokens to this contract
     */
    function mintRandomVRF() public returns (bytes32 requestId) {
        // Check the LINK balance in the contract
        require(
            LINK.balanceOf(address(this)) >= fee,
            "Not enough LINK - fill contract with faucet"
        );
        // Call requestRandomness to get a random number
        requestId = requestRandomness(keyHash, fee);
        requestToSender[requestId] = msg.sender;
        return requestId;
    }

    /**
     * VRF callback function, called by VRF Coordinator
     * The logic of consuming random numbers is written in this function
     */
    function fulfillRandomness(
        bytes32 requestId,
        uint256 randomness
    ) internal override {
        address sender = requestToSender[requestId]; // Get minter user address from requestToSender
        uint256 _tokenId = pickRandomUniqueId(randomness); // Use the random number returned by VRF to generate tokenId
        _mint(sender, _tokenId);
    }
}
