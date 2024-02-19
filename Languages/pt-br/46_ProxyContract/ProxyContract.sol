// SPDX-License-Identifier: MIT
// wtf.academy
pragma solidity ^0.8.4;

/**
 * @dev Todas as chamadas ao contrato Proxy são delegadas para a execução em outro contrato usando o opcode `delegatecall`. Este último é chamado de contrato lógico (Implementation).
 *
 * O valor de retorno da chamada delegada é diretamente retornado ao chamador do Proxy.
 */
contract Proxy {
    // Endereço do contrato lógico. O tipo de variável de estado da implementação deve ser o mesmo do contrato Proxy no mesmo local, caso contrário, ocorrerá um erro.

    /**
     * @dev Inicializa o endereço do contrato lógico
     */
    constructor(address implementation_){
        implementation = implementation_;
    }

    /**
     * @dev Função de callback, chama a função `_delegate()` para delegar a chamada deste contrato para o contrato `implementation`
     */
    fallback() external payable {
        _delegate();
    }

    /**
     * @dev Delega a chamada para a execução do contrato lógico
     */
    function _delegate() internal {
        assembly {
            // Copie msg.data. Assumimos total controle da memória neste assembly inline
            // bloco porque não retornará ao código Solidity. Sobrescrevemos o
            // Ler o storage na posição 0, que é o endereço de implementação.
            let _implementation := sload(0)

            calldatacopy(0, 0, calldatasize())

            // Usando delegatecall para chamar o contrato de implementação
            // Os parâmetros do opcode delegatecall são: gas, endereço do contrato de destino, posição inicial da memória de entrada, comprimento da memória de entrada, posição inicial da área de memória de saída, comprimento da área de memória de saída.
            // output area起始位置和长度位置，所以设为0
            // delegatecall retorna 1 se for bem-sucedido, 0 se falhar
            let result := delegatecall(gas(), _implementation, 0, calldatasize(), 0, 0)

            // Copie o returndata, com início na posição 0 e comprimento returndatasize(), para a posição de memória 0.
            returndatacopy(0, 0, returndatasize())

            switch result
            // Se a chamada do delegado falhar, reverta
            case 0 {
                revert(0, returndatasize())
            }
            // Se a chamada de delegação for bem-sucedida, retorna os dados da memória a partir da posição 0, com o tamanho returndatasize() (formato bytes)
            default {
                return(0, returndatasize())
            }
        }
    }
}

/**
 * @dev Contrato lógico, executa a chamada delegada
 */
contract Logic {
    // Manter consistência com o Proxy para evitar conflitos de slots
    uint public x = 99; 
    event CallSuccess();

    // Esta função libera LogicCalled e retorna um uint.
    // Função seletora: 0xd09de08a
    function increment() external returns(uint) {
        emit CallSuccess();
        return x + 1;
    }
}

/**
 * @dev Contrato Caller, chama o contrato proxy e obtém o resultado da execução
 */
contract Caller{
    // Endereço do contrato de proxy

    constructor(address proxy_){
        proxy = proxy_;
    }

    // Ao chamar a função increase() através do contrato de proxy
    function increase() external returns(uint) {
        ( , bytes memory data) = proxy.call(abi.encodeWithSignature("increment()"));
        return abi.decode(data,(uint));
    }
}
