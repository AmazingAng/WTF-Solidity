// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

// Importar mediante la ubicación relativa del archivo
import './Yeye.sol';
// Importar específicamente contratos a través de `global symbols`
import {Yeye} from './Yeye.sol';
// Importar por URL
import 'https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Address.sol';
// Importar contrato "OpenZeppelin"
import '@openzeppelin/contracts/access/Ownable.sol';

contract Import {
    // Exitosamente importar la librería Address
    using Address for address;
    // declarar la variable "yeye"
    Yeye yeye = new Yeye();

    // Probar si la función de "yeye" puede ser llamada
    function test() external{
        yeye.hip();
    }
}
