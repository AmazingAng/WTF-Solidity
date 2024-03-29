// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

contract DataStorage {
    // La ubicación de los datos de x es en storage.
    // Este es el único lugar donde se puede omitir la ubicación de los datos.
    uint[] x = [1,2,3];

    function fStorage() public{
        //Declara una variable de almacenamiento xStorage, apuntando a x. Modificar xStorage también afecta a x
        uint[] storage xStorage = x;
        xStorage[0] = 100;
    }

    function fMemory() public view{
        //Declara una variable xMemory de tipo Memory, copiando x. Modificar xMemory no afecta a x
        uint[] memory xMemory = x;
        xMemory[0] = 100;
        xMemory[1] = 200;
        uint[] memory xMemory2 = x;
        xMemory2[0] = 300;
    }

    function fCalldata(uint[] calldata _x) public pure returns(uint[] calldata){
        //El parámetro es el arreglo calldata, el cual no puede ser modificado
        // _x[0] = 0 //Esta modificación devolverá un error
        return(_x);
    }
}

contract Variables {
    uint public x = 1;
    uint public y;
    string public z;

    function foo() external{
        // Puedes cambiar el valor de la variable de estado en la función
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
}