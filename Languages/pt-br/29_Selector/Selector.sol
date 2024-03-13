// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

contract Selector{
    // evento retorna msg.data
    event Log(bytes data);

    // Parâmetro de entrada para: 0x2c44b726ADF1963cA47Af88B284C06f30380fC78
    /*para*/
        emit Log(msg.data);
    } 

    // Output selector
    // "mint(address)": 0x6a627842
    function mintSelector() external pure returns(bytes4 mSelector){
        return bytes4(keccak256("mint(address)"));
    }

    // Usando o seletor para chamar uma função
    function callWithSignature() external returns(bool, bytes memory){
        // Apenas precisamos usar `abi.encodeWithSelector` para empacotar e codificar o `selector` e os argumentos da função `mint`.
        (bool success, bytes memory data) = address(this).call(abi.encodeWithSelector(0x6a627842, 0x2c44b726ADF1963cA47Af88B284C06f30380fC78));
        return(success, data);
    }
}
