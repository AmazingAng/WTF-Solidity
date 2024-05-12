/**
 * Enviado para verificação em Etherscan.io em 2021-04-22
*/

// Arquivo: @openzeppelin/contracts/utils/Context.sol

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Fornece informações sobre o contexto de execução atual, incluindo o
 * remetente da transação e seus dados. Embora essas informações estejam geralmente disponíveis
 * através de msg.sender e msg.data, elas não devem ser acessadas de forma direta
 * maneira, pois ao lidar com meta-transações GSN, a conta que envia e
 * paga pela execução pode não ser o remetente real (pelo menos no que diz respeito a um aplicativo).
 *
 * Este contrato é necessário apenas para contratos intermediários semelhantes a bibliotecas.
 */
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        // silenciar aviso de mutabilidade de estado sem gerar bytecode - veja https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// Arquivo: @openzeppelin/contracts/introspection/IERC165.sol



pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface do padrão ERC165, conforme definido no
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementadores podem declarar suporte a interfaces de contratos, que podem então ser
 * consultadas por outros ({ERC165Checker}).
 *
 * Para uma implementação, veja {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Retorna verdadeiro se este contrato implementa a interface definida por
     * `interfaceId`. Consulte a seção correspondente
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP]
     * para saber mais sobre como esses ids são criados.
     *
     * Esta chamada de função deve usar menos de 30.000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// Arquivo: @openzeppelin/contracts/token/ERC721/IERC721.sol



pragma solidity >=0.6.2 <0.8.0;


/**
 * @dev Interface necessária de um contrato compatível com ERC721.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitido quando o token `tokenId` é transferido de `from` para `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitido quando `owner` permite que `approved` gerencie o token `tokenId`.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitido quando `owner` habilita ou desabilita (`approved`) `operator` para gerenciar todos os seus ativos.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Retorna o número de tokens na conta do ``owner``.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Retorna o proprietário do token `tokenId`.
     *
     * Requisitos:
     *
     * - `tokenId` deve existir.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Transfere com segurança o token `tokenId` de `from` para `to`, verificando primeiro se os destinatários do contrato
     * estão cientes do protocolo ERC721 para evitar que os tokens fiquem bloqueados para sempre.
     *
     * Requisitos:
     *
     * - `from` não pode ser o endereço zero.
     * - `to` não pode ser o endereço zero.
     * - O token `tokenId` deve existir e ser de propriedade de `from`.
     * - Se o chamador não for `from`, ele deve ter sido autorizado a mover este token por meio de {approve} ou {setApprovalForAll}.
     * - Se `to` se referir a um contrato inteligente, ele deve implementar {IERC721Receiver-onERC721Received}, que é chamado durante uma transferência segura.
     *
     * Emite um evento {Transfer}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Transfere o token `tokenId` de `from` para `to`.
     *
     * AVISO: O uso deste método é desencorajado, use {safeTransferFrom} sempre que possível.
     *
     * Requisitos:
     *
     * - `from` não pode ser o endereço zero.
     * - `to` não pode ser o endereço zero.
     * - O token `tokenId` deve ser de propriedade de `from`.
     * - Se o chamador não for `from`, ele deve ser aprovado para mover este token por meio de {approve} ou {setApprovalForAll}.
     *
     * Emite um evento {Transfer}.
     */
    function transferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Concede permissão para `to` transferir o token `tokenId` para outra conta.
     * A aprovação é removida quando o token é transferido.
     *
     * Apenas uma única conta pode ser aprovada por vez, portanto, aprovar o endereço zero remove aprovações anteriores.
     *
     * Requisitos:
     *
     * - O chamador deve ser o proprietário do token ou um operador aprovado.
     * - `tokenId` deve existir.
     *
     * Emite um evento {Approval}.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Retorna a conta aprovada para o token `tokenId`.
     *
     * Requisitos:
     *
     * - `tokenId` deve existir.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Aprova ou remove `operador` como um operador para o chamador.
     * Operadores podem chamar {transferFrom} ou {safeTransferFrom} para qualquer token de propriedade do chamador.
     *
     * Requisitos:
     *
     * - O `operador` não pode ser o chamador.
     *
     * Emite um evento {ApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Retorna se o `operador` está autorizado a gerenciar todos os ativos do `proprietário`.
     *
     * Veja {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
      * @dev Transfere com segurança o token `tokenId` de `from` para `to`.
      *
      * Requisitos:
      *
      * - `from` não pode ser o endereço zero.
      * - `to` não pode ser o endereço zero.
      * - O token `tokenId` deve existir e ser de propriedade de `from`.
      * - Se o chamador não for `from`, ele deve ser aprovado para mover este token por meio de {approve} ou {setApprovalForAll}.
      * - Se `to` se referir a um contrato inteligente, ele deve implementar {IERC721Receiver-onERC721Received}, que é chamado durante uma transferência segura.
      *
      * Emite um evento {Transfer}.
      */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

// Arquivo: @openzeppelin/contracts/token/ERC721/IERC721Metadata.sol



pragma solidity >=0.6.2 <0.8.0;


/**
 * @title Padrão de Token Não-Fungível ERC-721, extensão opcional de metadados
 * @dev Veja https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {

    /**
     * @dev Retorna o nome da coleção de tokens.
     */
    function name() external view returns (string memory);

    /**
     * @dev Retorna o símbolo da coleção de tokens.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Retorna o Identificador de Recurso Uniforme (URI) para o token `tokenId`.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// Arquivo: @openzeppelin/contracts/token/ERC721/IERC721Enumerable.sol



pragma solidity >=0.6.2 <0.8.0;


/**
 * @title Padrão de Token Não-Fungível ERC-721, extensão opcional de enumeração
 * @dev Veja https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {

    /**
     * @dev Retorna a quantidade total de tokens armazenados pelo contrato.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Retorna um ID de token de propriedade do `owner` em um determinado `índice` de sua lista de tokens.
     * Use junto com {balanceOf} para enumerar todos os tokens do `owner`.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Retorna um ID de token em um determinado `índice` de todos os tokens armazenados pelo contrato.
     * Use junto com {totalSupply} para enumerar todos os tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// Arquivo: @openzeppelin/contracts/token/ERC721/IERC721Receiver.sol



pragma solidity >=0.6.0 <0.8.0;

/**
 * @title Interface do receptor de tokens ERC721
 * @dev Interface para qualquer contrato que deseje suportar transferências seguras
 * de contratos de ativos ERC721.
 */
interface IERC721Receiver {
    /**
     * @dev Sempre que um token {IERC721} `tokenId` for transferido para este contrato via {IERC721-safeTransferFrom}
     * por `operador` de `de`, esta função é chamada.
     *
     * Ela deve retornar o seletor Solidity para confirmar a transferência do token.
     * Se qualquer outro valor for retornado ou a interface não for implementada pelo destinatário, a transferência será revertida.
     *
     * O seletor pode ser obtido em Solidity com `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}

// Arquivo: @openzeppelin/contracts/introspection/ERC165.sol



pragma solidity >=0.6.0 <0.8.0;


/**
 * @dev Implementação da interface {IERC165}.
 *
 * Contratos podem herdar desta implementação e chamar {_registerInterface} para declarar
 * seu suporte a uma interface.
 */
abstract contract ERC165 is IERC165 {
    /*
     * bytes4(keccak256('supportsInterface(bytes4)')) == 0x01ffc9a7
     */
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;

    /**
     * @dev Mapeamento de ids de interface para saber se é suportado ou não.
     */
    mapping(bytes4 => bool) private _supportedInterfaces;

    constructor () internal {
        // Contratos derivados só precisam registrar suporte para suas próprias interfaces,
        // registramos suporte para ERC165 aqui
        _registerInterface(_INTERFACE_ID_ERC165);
    }

    /**
     * @dev Veja {IERC165-supportsInterface}.
     *
     * Complexidade de tempo O(1), garantido que sempre usará menos de 30.000 gas.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return _supportedInterfaces[interfaceId];
    }

    /**
     * @dev Registra o contrato como um implementador da interface definida por
     * `interfaceId`. O suporte à interface ERC165 real é automático e
     * registrar seu ID de interface não é necessário.
     *
     * Veja {IERC165-supportsInterface}.
     *
     * Requisitos:
     *
     * - `interfaceId` não pode ser a interface inválida ERC165 (`0xffffffff`).
     */
    function _registerInterface(bytes4 interfaceId) internal virtual {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }
}

// Arquivo: @openzeppelin/contracts/math/SafeMath.sol



pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Invólucros sobre as operações aritméticas do Solidity com verificações adicionais de overflow.
 *
 * As operações aritméticas no Solidity envolvem em caso de overflow. Isso pode facilmente resultar em bugs, porque os programadores geralmente assumem que um overflow gera um erro, que é o comportamento padrão em linguagens de programação de alto nível. `SafeMath` restaura essa intuição revertendo a transação quando ocorre um overflow.
 *
 * Usar essa biblioteca em vez das operações não verificadas elimina uma classe inteira de bugs, por isso é recomendado usá-la sempre.
 */
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Retorna a adição de dois inteiros não assinados, com uma flag de overflow.
     *
     * _Disponível desde a versão 3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Retorna a subtração de dois inteiros não assinados, com uma flag de overflow.
     *
     * _Disponível desde a versão 3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Retorna a multiplicação de dois números inteiros não assinados, com uma flag de overflow.
     *
     * _Disponível desde a versão 3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Otimização de gás: isso é mais barato do que exigir que 'a' não seja zero, mas o
        // benefício é perdido se 'b' também for testado.
        // Veja: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Retorna a divisão de dois números inteiros não assinados, com uma flag de divisão por zero.
     *
     * _Disponível desde a versão 3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Retorna o resto da divisão de dois números inteiros não assinados, com uma flag de divisão por zero.
     *
     * _Disponível desde a versão 3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Retorna a adição de dois inteiros não assinados, revertendo em caso de
     * overflow.
     *
     * Contraparte do operador `+` do Solidity.
     *
     * Requisitos:
     *
     * - A adição não pode causar overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    /**
     * @dev Retorna a subtração de dois números inteiros não assinados, revertendo em caso de
     * overflow (quando o resultado é negativo).
     *
     * Contraparte do operador `-` do Solidity.
     *
     * Requisitos:
     *
     * - A subtração não pode causar overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Retorna a multiplicação de dois inteiros não assinados, revertendo em caso de
     * overflow.
     *
     * Contraparte do operador `*` do Solidity.
     *
     * Requisitos:
     *
     * - A multiplicação não pode causar overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Retorna a divisão inteira de dois números inteiros não assinados, revertendo em
     * divisão por zero. O resultado é arredondado em direção a zero.
     *
     * Contraparte do operador `/` do Solidity. Observação: esta função usa um
     * opcode `revert` (que deixa o gás restante intocado), enquanto o Solidity
     * usa um opcode inválido para reverter (consumindo todo o gás restante).
     *
     * Requisitos:
     *
     * - O divisor não pode ser zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Retorna o resto da divisão de dois números inteiros não assinados (módulo de número inteiro não assinado),
     * revertendo quando dividido por zero.
     *
     * Contraparte do operador `%` do Solidity. Esta função usa uma operação `revert`
     * opcode (que deixa o gás restante inalterado), enquanto o Solidity usa um
     * opcode inválido para reverter (consumindo todo o gás restante).
     *
     * Requisitos:
     *
     * - O divisor não pode ser zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Retorna a subtração de dois números inteiros não assinados, revertendo com uma mensagem personalizada em caso de
     * overflow (quando o resultado é negativo).
     *
     * CUIDADO: Esta função está obsoleta porque requer alocar memória para a mensagem de erro
     * desnecessariamente. Para motivos de revert personalizados, use {trySub}.
     *
     * Contraparte do operador `-` do Solidity.
     *
     * Requisitos:
     *
     * - A subtração não pode causar overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Retorna a divisão inteira de dois números inteiros não assinados, revertendo com uma mensagem personalizada
     * em caso de divisão por zero. O resultado é arredondado em direção a zero.
     *
     * CUIDADO: Esta função está obsoleta porque requer alocar memória para a mensagem de erro
     * desnecessariamente. Para motivos de revert personalizados, use {tryDiv}.
     *
     * Contraparte do operador `/` do Solidity. Observação: esta função usa um
     * opcode `revert` (que deixa o gás restante intocado), enquanto o Solidity
     * usa um opcode inválido para reverter (consumindo todo o gás restante).
     *
     * Requisitos:
     *
     * - O divisor não pode ser zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Retorna o resto da divisão de dois números inteiros não assinados (módulo de número inteiro não assinado),
     * revertendo com uma mensagem personalizada quando dividido por zero.
     *
     * CUIDADO: Esta função está obsoleta porque requer alocar memória para o erro
     * mensagem desnecessariamente. Para motivos de reverter personalizados, use {tryMod}.
     *
     * Contraparte do operador `%` do Solidity. Esta função usa um opcode `revert`
     * (que deixa o gás restante intocado), enquanto o Solidity usa um
     * opcode inválido para reverter (consumindo todo o gás restante).
     *
     * Requisitos:
     *
     * - O divisor não pode ser zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// Arquivo: @openzeppelin/contracts/utils/Address.sol



pragma solidity >=0.6.2 <0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // Este método depende de extcodesize, que retorna 0 para contratos em
        // construção, já que o código é armazenado apenas no final do
        // execução do construtor.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Mesmo que {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], mas
     * com `errorMessage` como motivo de fallback de revert quando `target` reverte.
     *
     * _Disponível desde a versão 3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Procurar motivo de reversão e propagá-lo se estiver presente
            if (returndata.length > 0) {
                // A maneira mais fácil de bolhar a razão de reverter é usando memória via assembly

                // solhint-disable-next-line no-inline-assembly
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

// Arquivo: @openzeppelin/contracts/utils/EnumerableSet.sol



pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Biblioteca para gerenciar conjuntos de tipos primitivos.
 *
 * Conjuntos têm as seguintes propriedades:
 *
 * - Elementos são adicionados, removidos e verificados em tempo constante (O(1)).
 * - Elementos são enumerados em O(n). Não há garantias sobre a ordem.
 *
 * ```
 * contract Example {
 *     // Adicione os métodos da biblioteca
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare uma variável de estado do conjunto
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * A partir da versão v3.3.0, conjuntos do tipo `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * e `uint256` (`UintSet`) são suportados.
 */
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // Para implementar esta biblioteca para vários tipos com o mínimo de código
    // repetição possível, escrevemos em termos de um tipo genérico Set com
    // valores bytes32.
    // A implementação do Set utiliza funções privadas e voltadas para o usuário.
    // implementações (como AddressSet) são apenas invólucros em torno do
    // Conjunto subjacente.
    // Isso significa que só podemos criar novos EnumerableSets para tipos que se encaixam
    // em bytes32.

    struct Set {
        // Armazenamento dos valores definidos
        bytes32[] _values;

        // Posição do valor no array `values`, mais 1 porque o índice começa em 0
        // significa que um valor não está no conjunto.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Adicione um valor a um conjunto. O(1).
     *
     * Retorna verdadeiro se o valor foi adicionado ao conjunto, ou seja, se ele não
     * já estava presente.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // O valor é armazenado em length-1, mas adicionamos 1 a todos os índices
            // e use 0 como valor sentinela
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Remove um valor de um conjunto. O(1).
     *
     * Retorna true se o valor foi removido do conjunto, ou seja, se ele estava presente.
     */
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // Nós lemos e armazenamos o índice do valor para evitar múltiplas leituras do mesmo slot de armazenamento
        uint256 valueIndex = set._indexes[value];

        // Equivalente a contains(set, value)
            // Para excluir um elemento do array _values em O(1), trocamos o elemento a ser excluído pelo último elemento em
            // o array e, em seguida, remover o último elemento (às vezes chamado de 'swap and pop').
            // Isso modifica a ordem do array, como observado em {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // Quando o valor a ser excluído é o último, a operação de troca é desnecessária. No entanto, como isso ocorre
            // tão raramente, ainda fazemos a troca de qualquer maneira para evitar o custo de gás de adicionar uma declaração 'if'.

            bytes32 lastvalue = set._values[lastIndex];

            // Mova o último valor para o índice onde o valor a ser excluído está
            set._values[toDeleteIndex] = lastvalue;
            // Atualize o índice para o valor movido
            // Todos os índices são baseados em 1

            // Excluir o slot onde o valor movido estava armazenado
            set._values.pop();

            // Excluir o índice para o slot excluído
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Retorna verdadeiro se o valor estiver no conjunto. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Retorna o número de valores no conjunto. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

   /**
    * @dev Retorna o valor armazenado na posição `index` no conjunto. O(1).
    *
    * Observe que não há garantias sobre a ordem dos valores dentro do
    * array, e isso pode mudar quando mais valores forem adicionados ou removidos.
    *
    * Requisitos:
    *
    * - `index` deve ser estritamente menor que {length}.
    */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Adicione um valor a um conjunto. O(1).
     *
     * Retorna verdadeiro se o valor foi adicionado ao conjunto, ou seja, se ele não
     * já estava presente.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Remove um valor de um conjunto. O(1).
     *
     * Retorna true se o valor foi removido do conjunto, ou seja, se ele estava presente.
     */
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Retorna verdadeiro se o valor estiver no conjunto. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Retorna o número de valores no conjunto. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Retorna o valor armazenado na posição `index` no conjunto. O(1).
    *
    * Observe que não há garantias sobre a ordem dos valores dentro do
    * array, e isso pode mudar quando mais valores forem adicionados ou removidos.
    *
    * Requisitos:
    *
    * - `index` deve ser estritamente menor que {length}.
    */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Adicione um valor a um conjunto. O(1).
     *
     * Retorna verdadeiro se o valor foi adicionado ao conjunto, ou seja, se ele não
     * já estava presente.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Remove um valor de um conjunto. O(1).
     *
     * Retorna true se o valor foi removido do conjunto, ou seja, se ele estava presente.
     */
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Retorna verdadeiro se o valor estiver no conjunto. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Retorna o número de valores no conjunto. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Retorna o valor armazenado na posição `index` no conjunto. O(1).
    *
    * Observe que não há garantias sobre a ordem dos valores dentro do
    * array, e isso pode mudar quando mais valores forem adicionados ou removidos.
    *
    * Requisitos:
    *
    * - `index` deve ser estritamente menor que {length}.
    */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }


    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Adicione um valor a um conjunto. O(1).
     *
     * Retorna verdadeiro se o valor foi adicionado ao conjunto, ou seja, se ele não
     * já estava presente.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Remove um valor de um conjunto. O(1).
     *
     * Retorna true se o valor foi removido do conjunto, ou seja, se ele estava presente.
     */
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Retorna verdadeiro se o valor estiver no conjunto. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Retorna o número de valores no conjunto. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Retorna o valor armazenado na posição `index` no conjunto. O(1).
    *
    * Observe que não há garantias sobre a ordem dos valores dentro do
    * array, e isso pode mudar quando mais valores forem adicionados ou removidos.
    *
    * Requisitos:
    *
    * - `index` deve ser estritamente menor que {length}.
    */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}

// Arquivo: @openzeppelin/contracts/utils/EnumerableMap.sol



pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Biblioteca para gerenciar uma variante enumerável do tipo
 * https://solidity.readthedocs.io/en/latest/types.html#mapping-types[`mapping`] do Solidity.
 *
 * Os mapas têm as seguintes propriedades:
 *
 * - Entradas são adicionadas, removidas e verificadas em tempo constante
 * (O(1)).
 * - As entradas são enumeradas em O(n). Não há garantias sobre a ordem.
 *
 * ```
 * contract Example {
 *     // Adicione os métodos da biblioteca
 *     using EnumerableMap for EnumerableMap.UintToAddressMap;
 *
 *     // Declare uma variável de estado do tipo conjunto
 *     EnumerableMap.UintToAddressMap private myMap;
 * }
 * ```
 *
 * A partir da versão 3.0.0, apenas mapas do tipo `uint256 -> address` (`UintToAddressMap`) são suportados.
 */
 * supported.
 */
library EnumerableMap {
    // Para implementar esta biblioteca para vários tipos com o mínimo de código
    // repetição, se possível, escrevemos em termos de um tipo genérico Map com
    // bytes32 chaves e valores.
    // A implementação do Map utiliza funções privadas e voltadas para o usuário.
    // implementações (como Uint256ToAddressMap) são apenas invólucros em torno de
    // o Map subjacente.
    // Isso significa que só podemos criar novos EnumerableMaps para tipos que se encaixam
    // em bytes32.

    struct MapEntry {
        bytes32 _key;
        bytes32 _value;
    }

    struct Map {
        // Armazenamento das chaves e valores do mapa
        MapEntry[] _entries;

        // Posição da entrada definida por uma chave no array `entries`, mais 1
        // porque o índice 0 significa que uma chave não está no mapa.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Adiciona um par chave-valor a um mapa, ou atualiza o valor para uma chave existente
     * chave. O(1).
     *
     * Retorna true se a chave foi adicionada ao mapa, ou seja, se ela não estava
     * presente anteriormente.
     */
    function _set(Map storage map, bytes32 key, bytes32 value) private returns (bool) {
        // Nós lemos e armazenamos o índice da chave para evitar múltiplas leituras do mesmo slot de armazenamento
        uint256 keyIndex = map._indexes[key];

        // Equivalente a !contém(mapa, chave)
            map._entries.push(MapEntry({ _key: key, _value: value }));
            // A entrada é armazenada no comprimento-1, mas adicionamos 1 a todos os índices
            // e use 0 como valor sentinela
            map._indexes[key] = map._entries.length;
            return true;
        } else {
            map._entries[keyIndex - 1]._value = value;
            return false;
        }
    }

    /**
     * @dev Remove um par chave-valor de um mapa. O(1).
     *
     * Retorna true se a chave foi removida do mapa, ou seja, se ela estava presente.
     */
    function _remove(Map storage map, bytes32 key) private returns (bool) {
        // Nós lemos e armazenamos o índice da chave para evitar múltiplas leituras do mesmo slot de armazenamento
        uint256 keyIndex = map._indexes[key];

        // Equivalente a contém(mapa, chave)
            // Para excluir um par chave-valor do array _entries em O(1), trocamos a entrada a ser excluída pela última
            // no array, e então remover a última entrada (às vezes chamada de 'swap and pop').
            // Isso modifica a ordem do array, como observado em {at}.

            uint256 toDeleteIndex = keyIndex - 1;
            uint256 lastIndex = map._entries.length - 1;

            // Quando a entrada a ser excluída é a última, a operação de troca é desnecessária. No entanto, como isso ocorre
            // tão raramente, ainda fazemos a troca de qualquer maneira para evitar o custo de gás de adicionar uma declaração 'if'.

            MapEntry storage lastEntry = map._entries[lastIndex];

            // Mova a última entrada para o índice onde a entrada a ser excluída está
            map._entries[toDeleteIndex] = lastEntry;
            // Atualize o índice para a entrada movida
            // Todos os índices são baseados em 1

            // Excluir o slot onde a entrada movida estava armazenada
            map._entries.pop();

            // Excluir o índice para o slot excluído
            delete map._indexes[key];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Retorna verdadeiro se a chave estiver no mapa. O(1).
     */
    function _contains(Map storage map, bytes32 key) private view returns (bool) {
        return map._indexes[key] != 0;
    }

    /**
     * @dev Retorna o número de pares chave-valor no mapa. O(1).
     */
    function _length(Map storage map) private view returns (uint256) {
        return map._entries.length;
    }

   /**
    * @dev Retorna o par chave-valor armazenado na posição `index` no mapa. O(1).
    *
    * Observe que não há garantias sobre a ordem das entradas dentro do
    * array, e isso pode mudar quando mais entradas forem adicionadas ou removidas.
    *
    * Requisitos:
    *
    * - `index` deve ser estritamente menor que {length}.
    */
    function _at(Map storage map, uint256 index) private view returns (bytes32, bytes32) {
        require(map._entries.length > index, "EnumerableMap: index out of bounds");

        MapEntry storage entry = map._entries[index];
        return (entry._key, entry._value);
    }

    /**
     * @dev Tenta retornar o valor associado à `key`. O(1).
     * Não reverte se `key` não estiver no mapa.
     */
    function _tryGet(Map storage map, bytes32 key) private view returns (bool, bytes32) {
        uint256 keyIndex = map._indexes[key];
        // Equivalente a contém(mapa, chave)
        // Todos os índices são baseados em 1
    }

    /**
     * @dev Retorna o valor associado à `key`. O(1).
     *
     * Requisitos:
     *
     * - `key` deve estar no mapa.
     */
    function _get(Map storage map, bytes32 key) private view returns (bytes32) {
        uint256 keyIndex = map._indexes[key];
        // Equivalente a contém(mapa, chave)
        // Todos os índices são baseados em 1
    }

    /**
     * @dev Mesmo que {_get}, com uma mensagem de erro personalizada quando `key` não está no mapa.
     *
     * CUIDADO: Esta função está obsoleta porque requer alocar memória para a mensagem de erro
     * desnecessariamente. Para motivos de revert personalizados, use {_tryGet}.
     */
    function _get(Map storage map, bytes32 key, string memory errorMessage) private view returns (bytes32) {
        uint256 keyIndex = map._indexes[key];
        // Equivalente a contém(mapa, chave)
        // Todos os índices são baseados em 1
    }

    // UintToAddressMap

    struct UintToAddressMap {
        Map _inner;
    }

    /**
     * @dev Adiciona um par chave-valor a um mapa, ou atualiza o valor para uma chave existente
     * chave. O(1).
     *
     * Retorna true se a chave foi adicionada ao mapa, ou seja, se ela não estava
     * presente anteriormente.
     */
    function set(UintToAddressMap storage map, uint256 key, address value) internal returns (bool) {
        return _set(map._inner, bytes32(key), bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Remove um valor de um conjunto. O(1).
     *
     * Retorna true se a chave foi removida do mapa, ou seja, se ela estava presente.
     */
    function remove(UintToAddressMap storage map, uint256 key) internal returns (bool) {
        return _remove(map._inner, bytes32(key));
    }

    /**
     * @dev Retorna verdadeiro se a chave estiver no mapa. O(1).
     */
    function contains(UintToAddressMap storage map, uint256 key) internal view returns (bool) {
        return _contains(map._inner, bytes32(key));
    }

    /**
     * @dev Retorna o número de elementos no mapa. O(1).
     */
    function length(UintToAddressMap storage map) internal view returns (uint256) {
        return _length(map._inner);
    }

   /**
    * @dev Retorna o elemento armazenado na posição `index` no conjunto. O(1).
    * Observe que não há garantias sobre a ordem dos valores dentro do
    * array, e isso pode mudar quando mais valores forem adicionados ou removidos.
    *
    * Requisitos:
    *
    * - `index` deve ser estritamente menor que {length}.
    */
    function at(UintToAddressMap storage map, uint256 index) internal view returns (uint256, address) {
        (bytes32 key, bytes32 value) = _at(map._inner, index);
        return (uint256(key), address(uint160(uint256(value))));
    }

    /**
     * @dev Tenta retornar o valor associado à `key`. O(1).
     * Não reverte se `key` não estiver no mapa.
     *
     * _Disponível desde a versão 3.4._
     */
    function tryGet(UintToAddressMap storage map, uint256 key) internal view returns (bool, address) {
        (bool success, bytes32 value) = _tryGet(map._inner, bytes32(key));
        return (success, address(uint160(uint256(value))));
    }

    /**
     * @dev Retorna o valor associado à `key`. O(1).
     *
     * Requisitos:
     *
     * - `key` deve estar no mapa.
     */
    function get(UintToAddressMap storage map, uint256 key) internal view returns (address) {
        return address(uint160(uint256(_get(map._inner, bytes32(key)))));
    }

    /**
     * @dev Mesmo que {get}, com uma mensagem de erro personalizada quando `key` não está no mapa.
     *
     * CUIDADO: Esta função está obsoleta porque requer alocar memória para a mensagem de erro
     * desnecessariamente. Para motivos de revert personalizados, use {tryGet}.
     */
    function get(UintToAddressMap storage map, uint256 key, string memory errorMessage) internal view returns (address) {
        return address(uint160(uint256(_get(map._inner, bytes32(key), errorMessage))));
    }
}

// Arquivo: @openzeppelin/contracts/utils/Strings.sol



pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Operações de string.
 */
library Strings {
    /**
     * @dev Converte um `uint256` para sua representação `string` em ASCII.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspirado na implementação da OraclizeAPI - licença MIT
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        uint256 index = digits - 1;
        temp = value;
        while (temp != 0) {
            buffer[index--] = bytes1(uint8(48 + temp % 10));
            temp /= 10;
        }
        return string(buffer);
    }
}

// Arquivo: @openzeppelin/contracts/token/ERC721/ERC721.sol



pragma solidity >=0.6.0 <0.8.0;












/**
 * @title Implementação básica do padrão de token não fungível ERC721
 * @dev veja https://eips.ethereum.org/EIPS/eip-721
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata, IERC721Enumerable {
    using SafeMath for uint256;
    using Address for address;
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableMap for EnumerableMap.UintToAddressMap;
    using Strings for uint256;

    // Equals to `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
    // que também pode ser obtido como `IERC721Receiver(0).onERC721Received.selector`
    bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;

    // Mapeamento do endereço do titular para seu conjunto (enumerável) de tokens possuídos
    mapping (address => EnumerableSet.UintSet) private _holderTokens;

    // Mapeamento enumerável de IDs de tokens para seus proprietários
    EnumerableMap.UintToAddressMap private _tokenOwners;

    // Mapeamento do ID do token para o endereço aprovado
    mapping (uint256 => address) private _tokenApprovals;

    // Mapeamento do proprietário para aprovações do operador
    mapping (address => mapping (address => bool)) private _operatorApprovals;

    // Nome do token
    string private _name;

    // Símbolo do token
    string private _symbol;

    // Mapeamento opcional para URIs de token
    mapping (uint256 => string) private _tokenURIs;

    // Base URI
    string private _baseURI;

    /*
     *     bytes4(keccak256('balanceOf(address)')) == 0x70a08231
     *     bytes4(keccak256('ownerOf(uint256)')) == 0x6352211e
     *     bytes4(keccak256('approve(address,uint256)')) == 0x095ea7b3
     *     bytes4(keccak256('getApproved(uint256)')) == 0x081812fc
     *     bytes4(keccak256('setApprovalForAll(address,bool)')) == 0xa22cb465
     *     bytes4(keccak256('isApprovedForAll(address,address)')) == 0xe985e9c5
     *     bytes4(keccak256('transferFrom(address,address,uint256)')) == 0x23b872dd
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256)')) == 0x42842e0e
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256,bytes)')) == 0xb88d4fde
     *
     *     => 0x70a08231 ^ 0x6352211e ^ 0x095ea7b3 ^ 0x081812fc ^
     *        0xa22cb465 ^ 0xe985e9c5 ^ 0x23b872dd ^ 0x42842e0e ^ 0xb88d4fde == 0x80ac58cd
     */
    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;

    /*
     *     bytes4(keccak256('name()')) == 0x06fdde03
     *     bytes4(keccak256('symbol()')) == 0x95d89b41
     *     bytes4(keccak256('tokenURI(uint256)')) == 0xc87b56dd
     *
     *     => 0x06fdde03 ^ 0x95d89b41 ^ 0xc87b56dd == 0x5b5e139f
     */
    bytes4 private constant _INTERFACE_ID_ERC721_METADATA = 0x5b5e139f;

    /*
     *     bytes4(keccak256('totalSupply()')) == 0x18160ddd
     *     bytes4(keccak256('tokenOfOwnerByIndex(address,uint256)')) == 0x2f745c59
     *     bytes4(keccak256('tokenByIndex(uint256)')) == 0x4f6ccce7
     *
     *     => 0x18160ddd ^ 0x2f745c59 ^ 0x4f6ccce7 == 0x780e9d63
     */
    bytes4 private constant _INTERFACE_ID_ERC721_ENUMERABLE = 0x780e9d63;

    /**
     * @dev Inicializa o contrato definindo um `nome` e um `símbolo` para a coleção de tokens.
     */
    constructor (string memory name_, string memory symbol_) public {
        _name = name_;
        _symbol = symbol_;

        // registrar as interfaces suportadas para conformar com ERC721 via ERC165
        _registerInterface(_INTERFACE_ID_ERC721);
        _registerInterface(_INTERFACE_ID_ERC721_METADATA);
        _registerInterface(_INTERFACE_ID_ERC721_ENUMERABLE);
    }

    /**
     * @dev Veja {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _holderTokens[owner].length();
    }

    /**
     * @dev Veja {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        return _tokenOwners.get(tokenId, "ERC721: owner query for nonexistent token");
    }

    /**
     * @dev Veja {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Veja {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Veja {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = baseURI();

        // Se não houver um URI base, retorne o URI do token.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // Se ambos estiverem definidos, concatene o baseURI e tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }
        // Se houver um baseURI, mas não houver tokenURI, concatene o tokenID ao baseURI.
        return string(abi.encodePacked(base, tokenId.toString()));
    }

    /**
    * @dev Retorna o URI base definido via {_setBaseURI}. Isso será
    * automaticamente adicionado como prefixo em {tokenURI} para o URI de cada token, ou
    * para o ID do token se nenhum URI específico for definido para esse ID de token.
    */
    function baseURI() public view virtual returns (string memory) {
        return _baseURI;
    }

    /**
     * @dev Veja {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        return _holderTokens[owner].at(index);
    }

    /**
     * @dev Veja {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        // _tokenOwners são indexados por tokenIds, então .length() retorna o número de tokenIds
        return _tokenOwners.length();
    }

    /**
     * @dev Veja {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        (uint256 tokenId, ) = _tokenOwners.at(index);
        return tokenId;
    }

    /**
     * @dev Veja {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(_msgSender() == owner || ERC721.isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev Veja {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev Veja {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev Veja {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev Veja {IERC721-transferFrom}.
     */
    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        //solhint-disable-next-line max-line-length
        Se o texto contiver alguma parte em 'zh', traduza todo o texto para 'pt-br', caso contrário, mantenha o texto original.

        _transfer(from, to, tokenId);
    }

    /**
     * @dev Veja {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev Veja {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Transfere com segurança o token `tokenId` de `from` para `to`, verificando primeiro se os destinatários do contrato
     * estão cientes do protocolo ERC721 para evitar que os tokens fiquem bloqueados para sempre.
     *
     * `_data` é um dado adicional, não possui um formato especificado e é enviado na chamada para `to`.
     *
     * Esta função interna é equivalente a {safeTransferFrom} e pode ser usada, por exemplo,
     * para implementar mecanismos alternativos para realizar a transferência de tokens, como baseados em assinatura.
     *
     * Requisitos:
     *
     * - `from` não pode ser o endereço zero.
     * - `to` não pode ser o endereço zero.
     * - O token `tokenId` deve existir e ser de propriedade de `from`.
     * - Se `to` se refere a um contrato inteligente, ele deve implementar {IERC721Receiver-onERC721Received}, que é chamado durante uma transferência segura.
     *
     * Emite um evento {Transfer}.
     */
    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory _data) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Retorna se o `tokenId` existe.
     *
     * Tokens podem ser gerenciados pelo seu proprietário ou contas aprovadas através de {approve} ou {setApprovalForAll}.
     *
     * Tokens começam a existir quando são criados (`_mint`),
     * e param de existir quando são queimados (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _tokenOwners.contains(tokenId);
    }

    /**
     * @dev Retorna se `spender` está autorizado a gerenciar `tokenId`.
     *
     * Requisitos:
     *
     * - `tokenId` deve existir.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || ERC721.isApprovedForAll(owner, spender));
    }

    /**
     * @dev Seguramente cria `tokenId` e transfere-o para `to`.
     *
     * Requisitos:
     *
     * - `tokenId` não deve existir.
     * - Se `to` se refere a um contrato inteligente, ele deve implementar {IERC721Receiver-onERC721Received}, que é chamado durante uma transferência segura.
     *
     * Emite um evento {Transfer}.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Mesmo que {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], com um parâmetro adicional `data` que é
     * encaminhado em {IERC721Receiver-onERC721Received} para os destinatários do contrato.
     */
    function _safeMint(address to, uint256 tokenId, bytes memory _data) internal virtual {
        _mint(to, tokenId);
        require(_checkOnERC721Received(address(0), to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Emite um novo token `tokenId` e transfere-o para `to`.
     *
     * AVISO: O uso deste método é desencorajado, use {_safeMint} sempre que possível.
     *
     * Requisitos:
     *
     * - `tokenId` não deve existir.
     * - `to` não pode ser o endereço zero.
     *
     * Emite um evento {Transfer}.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _holderTokens[to].add(tokenId);

        _tokenOwners.set(tokenId, to);

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    /**
        * @dev Destroys `tokenId`.
 * A aprovação é limpa quando o token é queimado.
        *
 * Requisitos:
        *
        * - `tokenId` deve existir.
 *
        * Emite um evento {Transfer}.
        */
            delete _tokenURIs[tokenId];
        }

        _holderTokens[owner].remove(tokenId);

        _tokenOwners.remove(tokenId);

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfere `tokenId` de `from` para `to`.
     *  Ao contrário de {transferFrom}, isso não impõe restrições ao msg.sender.
     *
     * Requisitos:
     *
     * - `to` não pode ser o endereço zero.
     * - O token `tokenId` deve ser de propriedade de `from`.
     *
     * Emite um evento {Transfer}.
     */
    function _transfer(address from, address to, uint256 tokenId) internal virtual {
        // internal owner
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Limpar aprovações do proprietário anterior
        _approve(address(0), tokenId);

        _holderTokens[from].remove(tokenId);
        _holderTokens[to].add(tokenId);

        _tokenOwners.set(tokenId, to);

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Define `_tokenURI` como o tokenURI de `tokenId`.
     *
     * Requisitos:
     *
     * - `tokenId` deve existir.
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721Metadata: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }

    /**
     * @dev Função interna para definir o URI base para todos os IDs de token. É
     * automaticamente adicionado como um prefixo ao valor retornado em {tokenURI},
     * ou ao ID do token se {tokenURI} estiver vazio.
     */
    function _setBaseURI(string memory baseURI_) internal virtual {
        _baseURI = baseURI_;
    }

    /**
     * @dev Função interna para invocar {IERC721Receiver-onERC721Received} em um endereço de destino.
     * A chamada não é executada se o endereço de destino não for um contrato.
     *
     * @param from endereço que representa o proprietário anterior do token ID fornecido
     * @param to endereço de destino que receberá os tokens
     * @param tokenId uint256 ID do token a ser transferido
     * @param _data bytes dados opcionais a serem enviados junto com a chamada
     * @return bool se a chamada retornou corretamente o valor mágico esperado
     */
    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data)
        private returns (bool)
    {
        if (!to.isContract()) {
            return true;
        }
        bytes memory returndata = to.functionCall(abi.encodeWithSelector(
            IERC721Receiver(to).onERC721Received.selector,
            _msgSender(),
            from,
            tokenId,
            _data
        ), "ERC721: transfer to non ERC721Receiver implementer");
        bytes4 retval = abi.decode(returndata, (bytes4));
        return (retval == _ERC721_RECEIVED);
    }

    /**
     * @dev Aprova `to` para operar em `tokenId`
     *
     * Emite um evento {Approval}.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        // internal owner
    }

    /**
     * @dev Gancho que é chamado antes de qualquer transferência de token. Isso inclui a criação
     * e queima.
     *
     * Condições de chamada:
     *
     * - Quando `from` e `to` não são zero, o `tokenId` de ``from`` será
     * transferido para `to`.
     * - Quando `from` é zero, `tokenId` será criado para `to`.
     * - Quando `to` é zero, o `tokenId` de ``from`` será queimado.
     * - `from` não pode ser o endereço zero.
     * - `to` não pode ser o endereço zero.
     *
     * Para saber mais sobre ganchos, acesse xref:ROOT:extending-contracts.adoc#using-hooks[Usando Ganchos].
     */
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual { }
}

// Arquivo: @openzeppelin/contracts/access/Ownable.sol



pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Módulo de contrato que fornece um mecanismo básico de controle de acesso, onde
 * há uma conta (um proprietário) que pode receber acesso exclusivo a
 * funções específicas.
 *
 * Por padrão, a conta do proprietário será aquela que implanta o contrato. Isso
 * pode ser alterado posteriormente com {transferOwnership}.
 *
 * Este módulo é usado por meio de herança. Ele disponibilizará o modificador
 * `onlyOwner`, que pode ser aplicado às suas funções para restringir seu uso ao
 * proprietário.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Inicializa o contrato definindo o deployer como o proprietário inicial.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Retorna o endereço do proprietário atual.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Lança uma exceção se chamado por qualquer conta que não seja do proprietário.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Deixa o contrato sem proprietário. Não será mais possível chamar
     * funções `onlyOwner`. Só pode ser chamado pelo proprietário atual.
     *
     * NOTA: Renunciar à propriedade deixará o contrato sem um proprietário,
     * removendo assim qualquer funcionalidade que esteja disponível apenas para o proprietário.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfere a propriedade do contrato para uma nova conta (`newOwner`).
     * Só pode ser chamado pelo proprietário atual.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// Arquivo: contracts/BoredApeYachtClub.sol


pragma solidity ^0.7.0;



/**
 * @title Contrato BoredApeYachtClub
 * @dev Estende a implementação básica do padrão de token não fungível ERC721
 */
contract BoredApeYachtClub is ERC721, Ownable {
    using SafeMath for uint256;

    string public BAYC_PROVENANCE = "";

    uint256 public startingIndexBlock;

    uint256 public startingIndex;

    //0.08 ETH

    uint public constant maxApePurchase = 20;

    uint256 public MAX_APES;

    bool public saleIsActive = false;

    uint256 public REVEAL_TIMESTAMP;

    constructor(string memory name, string memory symbol, uint256 maxNftSupply, uint256 saleStart) ERC721(name, symbol) {
        MAX_APES = maxNftSupply;
        REVEAL_TIMESTAMP = saleStart + (86400 * 9);
    }

    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        msg.sender.transfer(balance);
    }

    /**
     * Defina alguns Bored Apes de lado
     */
    function reserveApes() public onlyOwner {        
        uint supply = totalSupply();
        uint i;
        for (i = 0; i < 30; i++) {
            _safeMint(msg.sender, supply + i);
        }
    }

    /**
     * Envie uma mensagem privada para Gargamel no Discord dizendo que você está bem atrás dele.
     */
    function setRevealTimestamp(uint256 revealTimeStamp) public onlyOwner {
        REVEAL_TIMESTAMP = revealTimeStamp;
    } 

    /*     
    * Defina a proveniência assim que for calculada
    */
    function setProvenanceHash(string memory provenanceHash) public onlyOwner {
        BAYC_PROVENANCE = provenanceHash;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _setBaseURI(baseURI);
    }

    /*
    * Pausar venda se estiver ativa, ativar se estiver pausada
    */
    function flipSaleState() public onlyOwner {
        saleIsActive = !saleIsActive;
    }

    /**
    * Mints Bored Apes
    */
    function mintApe(uint numberOfTokens) public payable {
        require(saleIsActive, "Sale must be active to mint Ape");
        require(numberOfTokens <= maxApePurchase, "Can only mint 20 tokens at a time");
        require(totalSupply().add(numberOfTokens) <= MAX_APES, "Purchase would exceed max supply of Apes");
        require(apePrice.mul(numberOfTokens) <= msg.value, "Ether value sent is not correct");
        
        for(uint i = 0; i < numberOfTokens; i++) {
            uint mintIndex = totalSupply();
            if (totalSupply() < MAX_APES) {
                _safeMint(msg.sender, mintIndex);
            }
        }

        // Se não definimos o índice inicial e este é 1) o último token vendável ou 2) o primeiro token a ser vendido após
        // o fim da pré-venda, defina o bloco de índice inicial
        if (startingIndexBlock == 0 && (totalSupply() == MAX_APES || block.timestamp >= REVEAL_TIMESTAMP)) {
            startingIndexBlock = block.number;
        } 
    }

    /**
     * Defina o índice inicial para a coleção
     */
    function setStartingIndex() public {
        require(startingIndex == 0, "Starting index is already set");
        require(startingIndexBlock != 0, "Starting index block must be set");
        
        startingIndex = uint(blockhash(startingIndexBlock)) % MAX_APES;
        // Apenas um caso de sanidade no pior cenário se esta função for chamada tarde (EVM armazena apenas os últimos 256 hashes de bloco)
        if (block.number.sub(startingIndexBlock) > 255) {
            startingIndex = uint(blockhash(block.number - 1)) % MAX_APES;
        }
        // Prevenir sequência padrão
        if (startingIndex == 0) {
            startingIndex = startingIndex.add(1);
        }
    }

    /**
     * Defina o bloco de índice inicial para a coleção, essencialmente desbloqueando
     * a definição do índice inicial
     */
    function emergencySetStartingIndexBlock() public onlyOwner {
        require(startingIndex == 0, "Starting index is already set");
        
        startingIndexBlock = block.number;
    }
}
