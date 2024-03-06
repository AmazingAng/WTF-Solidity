// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract DataStorage {
    // A localização dos dados de x é armazenamento.
    // Este é o único lugar onde o
    // A localização dos dados pode ser omitida.
    uint[] public x = [1,2,3];

    function fStorage() public{
        //Declare a variable xStorage that points to x. Modifying xStorage will also affect x.
        uint[] storage xStorage = x;
        xStorage[0] = 100;
    }

    function fMemory() public view{
        //Declare a variable xMemory of type Memory, copy x. Modifying xMemory will not affect x.
        uint[] memory xMemory = x;
        xMemory[0] = 100;
        xMemory[1] = 200;
        uint[] memory xMemory2 = x;
        xMemory2[0] = 300;
    }

    function fCalldata(uint[] calldata _x) public pure returns(uint[] calldata){
        // Parâmetro é um array de calldata, não pode ser modificado.
        // _x[0] = 0 // Essa modificação resultará em um erro
        return(_x);
    }
}

contract Variables {
    uint public x = 1;
    uint public y;
    string public z;

    function foo() external{
        // Você pode alterar o valor da variável de estado dentro de uma função
        x = 5;
        y = 2;
        z = "0xAA";
    }

    function bar() external pure returns(uint){
        uint xx = 1;
        uint yy = 3;
        uint zz = xx + yy;
        return(zz);
    }

    function global() external view returns(address, uint, bytes memory){
        address sender = msg.sender;
        uint blockNum = block.number;
        bytes memory data = msg.data;
        return(sender, blockNum, data);
    }

    function weiUnit() external pure returns(uint) {
        assert(1 wei == 1e0);
        assert(1 wei == 1);
        return 1 wei;
    }

    function gweiUnit() external pure returns(uint) {
        assert(1 gwei == 1e9);
        assert(1 gwei == 1000000000);
        return 1 gwei;
    }

    function etherUnit() external pure returns(uint) {
        assert(1 ether == 1e18);
        assert(1 ether == 1000000000000000000);
        return 1 ether;
    }
    
    function secondsUnit() external pure returns(uint) {
        assert(1 seconds == 1);
        return 1 seconds;
    }

    function minutesUnit() external pure returns(uint) {
        assert(1 minutes == 60);
        assert(1 minutes == 60 seconds);
        return 1 minutes;
    }

    function hoursUnit() external pure returns(uint) {
        assert(1 hours == 3600);
        assert(1 hours == 60 minutes);
        return 1 hours;
    }

    function daysUnit() external pure returns(uint) {
        assert(1 days == 86400);
        assert(1 days == 24 hours);
        return 1 days;
    }

    function weeksUnit() external pure returns(uint) {
        assert(1 weeks == 604800);
        assert(1 weeks == 7 days);
        return 1 weeks;
    }
}



