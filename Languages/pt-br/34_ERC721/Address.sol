// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

// Biblioteca de Endereços
library Address {
    // Usando extcodesize para verificar se um endereço é um contrato
    function isContract(address account) internal view returns (bool) {
        uint size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }
}
