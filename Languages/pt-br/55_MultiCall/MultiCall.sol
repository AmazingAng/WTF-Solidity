// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract Multicall {
    // Estrutura Call, contendo o contrato alvo target, se é permitido chamadas que falhem allowFailure, e os dados da chamada
    struct Call {
        address target;
        bool allowFailure;
        bytes callData;
    }

    // Estrutura Result, que inclui se a chamada foi bem-sucedida e os dados de retorno
    struct Result {
        bool success;
        bytes returnData;
    }

    /// @notice Combine várias chamadas (suportando diferentes contratos / métodos diferentes / parâmetros diferentes) em uma única chamada
    /// @param calls Array de estruturas Chamada
    /// @return returnData Array composto por estruturas de dados Result
    function multicall(Call[] calldata calls) public returns (Result[] memory returnData) {
        uint256 length = calls.length;
        returnData = new Result[](length);
        Call calldata calli;
        
        // Chame sequencialmente no loop
        for (uint256 i = 0; i < length; i++) {
            Result memory result = returnData[i];
            calli = calls[i];
            (result.success, result.returnData) = calli.target.call(calli.callData);
            // Se calli.allowFailure e result.success forem ambos falsos, reverter
            if (!(calli.allowFailure || result.success)){
                revert("Multicall: call failed");
            }
        }
    }
}