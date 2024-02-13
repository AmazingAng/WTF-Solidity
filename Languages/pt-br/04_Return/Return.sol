// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// Retorna várias variáveis
// Retorno nomeado
// Atribuição por desestruturação

contract Return {
    // Retorna várias variáveis
    function returnMultiple() public pure returns(uint256, bool, uint256[3] memory){
        return(1, true, [uint256(1),2,5]);
    }

    // Retorno nomeado
    function returnNamed() public pure returns(uint256 _number, bool _bool, uint256[3] memory _array){
        _number = 2;
        _bool = false; 
        _array = [uint256(3),2,1];
    }

    // Retorno nomeado, ainda suporta return
    function returnNamed2() public pure returns(uint256 _number, bool _bool, uint256[3] memory _array){
        return(1, true, [uint256(1),2,5]);
    }

    // Ler o valor de retorno, atribuição por desestruturação
    function readReturn() public pure{
        // Ler todos os valores de retorno
        uint256 _number;
        bool _bool;
        bool _bool2;
        uint256[3] memory _array;
        (_number, _bool, _array) = returnNamed();
        
        // Ler parte dos valores de retorno, atribuição por desestruturação
        (, _bool2, ) = returnNamed();
    }
}
