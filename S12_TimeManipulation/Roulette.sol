pragma solidity ^0.8.0;

contract Roulette {
    uint public pastBlockTime;
    constructor() payable {}

    // call spin and send 1 ether to play
    function spin() external payable {
        require(msg.value == 1 ether);
        require(block.timestamp != pastBlockTime);
        pastBlockTime = block.timestamp;
        // if the block.timestamp is divisible by 7 you win the Ether in the contract
        if(block.timestamp % 7 == 0) {
            (bool sent, ) = msg.sender.call{value: address(this).balance}("");
            require(sent, "Failed to send Ether");
        }
    }
}
