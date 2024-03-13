// SPDX-License-Identifier: MIT
// by 0xAA
// english translation by: 22X
pragma solidity ^0.8.21;

contract SelectorClash {
    bool public solved; // Whether the attack is successful

    // The attacker needs to call this function, but the caller msg.sender must be this contract.
    function putCurEpochConPubKeyBytes(bytes memory _bytes) public {
        require(msg.sender == address(this), "Not Owner");
        solved = true;
    }

    // Vulnerable, the attacker can collide function selectors by changing the _method variable, call the target function, and complete the attack.
    function executeCrossChainTx(bytes memory _method, bytes memory _bytes, bytes memory _bytes1, uint64 _num) public returns(bool success){
        (success, ) = address(this).call(abi.encodePacked(bytes4(keccak256(abi.encodePacked(_method, "(bytes,bytes,uint64)"))), abi.encode(_bytes, _bytes1, _num)));
    }

    function secretSlector() external pure returns(bytes4){
        return bytes4(keccak256("putCurEpochConPubKeyBytes(bytes)"));
    }

    function hackSlector() external pure returns(bytes4){
        return bytes4(keccak256("f1121318093(bytes,bytes,uint64)"));
    }
}