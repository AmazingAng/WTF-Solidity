// SPDX-License-Identifier: MIT
// Contratos OpenZeppelin (última atualização v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Coleção de funções relacionadas ao tipo de endereço
 */
library Address {
    /**
     * @dev Retorna verdadeiro se `conta` for um contrato.
     *
     * [IMPORTANTE]
     * ====
     * Não é seguro assumir que um endereço para o qual esta função retorna
     * falso é uma conta de propriedade externa (EOA) e não um contrato.
     *
     * Entre outros, `isContract` retornará falso para os seguintes
     * tipos de endereços:
     *
     *  - uma conta de propriedade externa
     *  - um contrato em construção
     *  - um endereço onde um contrato será criado
     *  - um endereço onde um contrato viveu, mas foi destruído
     * ====
     *
     * [IMPORTANTE]
     * ====
     * Você não deve confiar em `isContract` para se proteger contra ataques de empréstimo instantâneo!
     *
     * Impedir chamadas de contratos é altamente desencorajado. Isso quebra a composabilidade, quebra o suporte para carteiras inteligentes
     * como Gnosis Safe, e não fornece segurança, pois pode ser contornado chamando de um contrato
     * construtor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // Este método depende de extcodesize/address.code.length, que retorna 0
        // para contratos na construção civil, uma vez que o código é armazenado apenas no final
        // da execução do construtor.

        return account.code.length > 0;
    }

    /**
     * @dev Substituição para o `transfer` do Solidity: envia `amount` wei para
     * `recipient`, encaminhando todo o gás disponível e revertendo em caso de erros.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] aumenta o custo de gás
     * de certas opcodes, possivelmente fazendo com que contratos ultrapassem o limite de gás de 2300
     * imposto pelo `transfer`, tornando-os incapazes de receber fundos via
     * `transfer`. {sendValue} remove essa limitação.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Saiba mais].
     *
     * IMPORTANTE: porque o controle é transferido para `recipient`, é necessário ter cuidado
     * para não criar vulnerabilidades de reentrância. Considere usar
     * {ReentrancyGuard} ou o
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[padrão checks-effects-interactions].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Executa uma chamada de função Solidity usando um `call` de baixo nível. Um
     * `call` simples é uma substituição insegura para uma chamada de função: use esta
     * função em vez disso.
     *
     * Se `target` reverter com uma razão de revert, ela é propagada por esta
     * função (como chamadas de função Solidity regulares).
     *
     * Retorna os dados brutos retornados. Para converter para o valor de retorno esperado,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requisitos:
     *
     * - `target` deve ser um contrato.
     * - chamar `target` com `data` não deve reverter.
     *
     * _Disponível desde a versão 3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Mesmo que {xref-Address-functionCall-address-bytes-}[`functionCall`], mas com
     * `errorMessage` como motivo de fallback de revert quando `target` reverte.
     *
     * _Disponível desde a versão 3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Mesmo que {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * mas também transfere `value` wei para `target`.
     *
     * Requisitos:
     *
     * - o contrato chamador deve ter um saldo de ETH de pelo menos `value`.
     * - a função Solidity chamada deve ser `payable`.
     *
     * _Disponível desde a versão 3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Mesmo que {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], mas
     * com `errorMessage` como motivo de fallback de revert quando `target` reverte.
     *
     * _Disponível desde a versão 3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Mesmo que {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * mas realizando uma chamada estática.
     *
     * _Disponível desde a versão 3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Mesmo que {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * mas realizando uma chamada estática.
     *
     * _Disponível desde a versão 3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Mesmo que {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * mas realizando uma chamada de delegado.
     *
     * _Disponível desde a versão 3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Mesmo que {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * mas realizando uma chamada de delegado.
     *
     * _Disponível desde a versão 3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Ferramenta para verificar se uma chamada de baixo nível foi bem-sucedida e reverter se não foi, seja
     * propagando o motivo de reversão usando o fornecido.
     *
     * _Disponível desde a versão 4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Procurar motivo de reversão e propagá-lo se estiver presente
            if (returndata.length > 0) {
                // A maneira mais fácil de bolhar a razão de reverter é usando memória via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}
