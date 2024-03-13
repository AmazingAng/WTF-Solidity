// SPDX-License-Identifier: MIT
// english translation by 22X
pragma solidity ^0.8.21;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

// Access control bad example
contract SigReplay is ERC20 {

    address public signer;

    // Constructor: initialize token name and symbol
    constructor() ERC20("SigReplay", "Replay") {
        signer = msg.sender;
    }
    
    /**
     * Mint function with signature replay vulnerability
     * to: 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4
     * amount: 1000
     * Signature: 0x5a4f1ad4d8bd6b5582e658087633230d9810a0b7b8afa791e3f94cc38947f6cb1069519caf5bba7b975df29cbfdb4ada355027589a989435bf88e825841452f61b
     */
    function badMint(address to, uint amount, bytes memory signature) public {
        bytes32 _msgHash = toEthSignedMessageHash(getMessageHash(to, amount));
        require(verify(_msgHash, signature), "Invalid Signer!");
        _mint(to, amount);
    }

    /**
     * Concatenate the 'to' address (address type) and 'amount' (uint256 type) to form the message 'msgHash'
     * to: 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4
     * amount: 1000
     * Corresponding message 'msgHash': 0xb4a4ba10fbd6886a312ec31c54137f5714ddc0e93274da8746a36d2fa96768be
     */
    function getMessageHash(address to, uint256 amount) public pure returns(bytes32){
        return keccak256(abi.encodePacked(to, amount));
    }

    /**
     * @dev Get the Ethereum signed message hash
     * `hash`: Message hash 
     * Follows the Ethereum signature standard: https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * and `EIP191`: https://eips.ethereum.org/EIPS/eip-191`
     * Adds the "\x19Ethereum Signed Message:\n32" field to prevent signing of executable transactions.
     */
    function toEthSignedMessageHash(bytes32 hash) public pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    // ECDSA verification
    function verify(bytes32 _msgHash, bytes memory _signature) public view returns (bool){
        return ECDSA.recover(_msgHash, _signature) == signer;
    }


    mapping(address => bool) public mintedAddress;   // Records addresses that have already minted
    
    function goodMint(address to, uint amount, bytes memory signature) public {
        bytes32 _msgHash = toEthSignedMessageHash(getMessageHash(to, amount));
        require(verify(_msgHash, signature), "Invalid Signer!");
        // Check if the address has already minted
        require(!mintedAddress[to], "Already minted");
        // Record the address minted
        mintedAddress[to] = true;
        _mint(to, amount);
    }
    
    uint nonce;

    function nonceMint(address to, uint amount, bytes memory signature) public {
        bytes32 _msgHash = toEthSignedMessageHash(keccak256(abi.encodePacked(to, amount, nonce, block.chainid)));
        require(verify(_msgHash, signature), "Invalid Signer!");
        _mint(to, amount);
        nonce++;
    }
}