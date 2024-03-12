// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// Importar por localização relativa do arquivo
import './Yeye.sol';
// Importar um contrato específico através do `símbolo global`
import {Yeye} from './Yeye.sol';
// Por meio de um URL de referência
//github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Address.sol';
// Importar contrato OpenZeppelin
import '@openzeppelin/contracts/access/Ownable.sol';

contract Import {
    // Sucesso ao importar a biblioteca Address
    using Address for address;
    // Declarando a variável yeye
    Yeye yeye = new Yeye();

    // Testar se é possível chamar a função do yeye
    function test() external{
        yeye.hip();
    }
}
