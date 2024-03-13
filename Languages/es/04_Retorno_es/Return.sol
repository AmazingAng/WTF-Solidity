// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

// Devolver múltiples variables
// Parámetros de retorno con nombre
// Asignaciones de desestructuración

contract Return {
	// retornando múltiples variables sin nombrarlas
    function returnMultiple() public pure returns(uint256, bool, uint256[3] memory){
        return(1, true, [uint256(1),2,5]);
    }
	
	// retornos con nombre
    function returnNamed() public pure returns(uint256 _number, bool _bool, uint256[3] memory _array){
        _number = 2;
        _bool = false; 
        _array = [uint256(3),2,1];
    }
	
    //Parámetros de retorno con nombre, también soportan return
    function returnNamed2() public pure returns(uint256 _number, bool _bool, uint256[3] memory _array){
        return(1, true, [uint256(1),2,5]);
    }

	// Se leen los valores de retorno, con asignaciones de desestructuración
    function readReturn() public pure{
		// Leer todos los valores de retorno
        uint256 _number;
        bool _bool;
        bool _bool2;
        uint256[3] memory _array;
        (_number, _bool, _array) = returnNamed();
        
		// Leer parte de los valores de retorno, asignaciones de desestructuración
        (, _bool2, ) = returnNamed();
    }
}
