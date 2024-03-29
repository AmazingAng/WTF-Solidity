// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract Multicall {
    // Estrutura Call, contendo o contrato alvo (target), se é permitido falha na chamada (allowFailure) e os dados da chamada (call data)
    struct Call {
        address target;
        bool allowFailure;
        bytes callData;
    }

    // Estrutura de dados Result, contendo se a chamada foi bem sucedida e os dados de retorno
    struct Result {
        bool success;
        bytes returnData;
    }

    /// @notice Combina várias chamadas (suportando contratos diferentes/métodos diferentes/parâmetros diferentes) em uma única chamada.
    /// @param calls Array of structures Call
    /// @return returnData Array of Result structures
    function multicall(Call[] calldata calls) public returns (Result[] memory returnData) {
        uint256 length = calls.length;
        returnData = new Result[](length);
        Call calldata calli;
        
        // No loop, no translation needed.
        for (uint256 i = 0; i < length; i++) {
            Result memory result = returnData[i];
            calli = calls[i];
            (result.success, result.returnData) = calli.target.call(calli.callData);
            // Se calli.allowFailure e result.success forem ambos falsos, reverta
            if (!(calli.allowFailure || result.success)){
                revert("Multicall: call failed");
            }
        }
    }
}