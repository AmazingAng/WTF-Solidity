/**
 * Enviado para verificação em Etherscan.io em 2021-08-27
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

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
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

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
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}




/**
 * @dev Operações de string.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converte um `uint256` para sua representação decimal em `string` ASCII.
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
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converte um `uint256` para sua representação hexadecimal em `string` ASCII.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converte um `uint256` para sua representação hexadecimal `string` ASCII com comprimento fixo.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}




/*
 * @dev Fornece informações sobre o contexto de execução atual, incluindo o
 * remetente da transação e seus dados. Embora essas informações estejam geralmente disponíveis
 * através de msg.sender e msg.data, elas não devem ser acessadas de forma direta
 * maneira, pois ao lidar com meta-transações, a conta que envia e
 * paga pela execução pode não ser o remetente real (do ponto de vista de um aplicativo).
 *
 * Este contrato é necessário apenas para contratos intermediários semelhantes a bibliotecas.
 */
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}









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
    constructor() {
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfere a propriedade do contrato para uma nova conta (`newOwner`).
     * Só pode ser chamado pelo proprietário atual.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}





/**
 * @dev Módulo de contrato que ajuda a prevenir chamadas reentrantes a uma função.
 *
 * Herdar de `ReentrancyGuard` tornará o modificador {nonReentrant} disponível,
 * que pode ser aplicado a funções para garantir que não haja chamadas aninhadas
 * (reentrantes) para elas.
 *
 * Observe que, como há apenas uma guarda `nonReentrant`, funções marcadas como
 * `nonReentrant` não podem chamar umas às outras. Isso pode ser contornado tornando
 * essas funções `private` e, em seguida, adicionando pontos de entrada `external` `nonReentrant` a elas.
 *
 * DICA: Se você gostaria de aprender mais sobre reentrância e maneiras alternativas
 * de se proteger contra ela, confira nosso post no blog
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
 */
abstract contract ReentrancyGuard {
    // Booleans são mais caros do que uint256 ou qualquer tipo que ocupe um espaço completo.
    // palavra porque cada operação de escrita emite uma SLOAD extra para ler primeiro o
    // conteúdo do slot, substitua as partes ocupadas pelo booleano e, em seguida, escreva
    // de volta. Esta é a defesa do compilador contra atualizações de contrato e
    // ponteiro de aliasing, e não pode ser desativado.

    // Os valores sendo diferentes de zero tornam a implantação um pouco mais cara,
    // mas em troca, o reembolso em cada chamada para nãoReentrant será menor em
    // quantidade. Como os reembolsos são limitados a uma porcentagem do total
    // gás da transação, é melhor mantê-los baixos em casos como este, para
    // aumentar a probabilidade de o reembolso total entrar em vigor.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Impede que um contrato se chame a si mesmo, diretamente ou indiretamente.
     * Chamar uma função `nonReentrant` de outra função `nonReentrant` não é suportado.
     * É possível evitar que isso aconteça tornando a função `nonReentrant` externa e
     * fazendo-a chamar uma função `private` que realiza o trabalho real.
     */
     */
    modifier nonReentrant() {
        // Na primeira chamada para nonReentrant, _notEntered será verdadeiro
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Qualquer chamada a nonReentrant após este ponto falhará
        _status = _ENTERED;

        _;

        // Ao armazenar o valor original mais uma vez, um reembolso é acionado (veja
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}














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
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}







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
        assembly {
            size := extcodesize(account)
        }
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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

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
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
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









/**
 * @dev Implementação da interface {IERC165}.
 *
 * Contratos que desejam implementar o ERC165 devem herdar deste contrato e substituir {supportsInterface} para verificar
 * o ID de interface adicional que será suportado. Por exemplo:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternativamente, {ERC165Storage} fornece uma implementação mais fácil de usar, mas mais cara.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev Veja {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}


/**
 * @dev Implementação do https://eips.ethereum.org/EIPS/eip-721[Padrão de Token Não-Fungível ERC721], incluindo
 * a extensão de Metadados, mas não incluindo a extensão Enumerável, que está disponível separadamente como
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Nome do token
    string private _name;

    // Símbolo do token
    string private _symbol;

    // Mapeamento do ID do token para o endereço do proprietário
    mapping(uint256 => address) private _owners;

    // Mapeando o endereço do proprietário para a contagem de tokens
    mapping(address => uint256) private _balances;

    // Mapeamento do ID do token para o endereço aprovado
    mapping(uint256 => address) private _tokenApprovals;

    // Mapeamento do proprietário para aprovações do operador
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Inicializa o contrato definindo um `nome` e um `símbolo` para a coleção de tokens.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Veja {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev Veja {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev Veja {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
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

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev URI base para calcular {tokenURI}. Se definido, o URI resultante para cada
     * token será a concatenação do `baseURI` e do `tokenId`. Vazio
     * por padrão, pode ser substituído em contratos filhos.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev Veja {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
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
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        Se o texto contiver alguma parte em 'zh', traduza todo o texto para 'pt-br', caso contrário, mantenha o texto original.

        _transfer(from, to, tokenId);
    }

    /**
     * @dev Veja {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev Veja {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
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
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
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
        return _owners[tokenId] != address(0);
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
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Minta com segurança `tokenId` e transfere para `to`.
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
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
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

        _balances[to] += 1;
        _owners[tokenId] = to;

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
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Limpar aprovações do proprietário anterior
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Aprova `to` para operar em `tokenId`
     *
     * Emite um evento {Approval}.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
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
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver(to).onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Gancho que é chamado antes de qualquer transferência de token. Isso inclui a criação
     * e queima de tokens.
     *
     * Condições de chamada:
     *
     * - Quando `from` e `to` são ambos diferentes de zero, o `tokenId` de `from` será
     * transferido para `to`.
     * - Quando `from` é zero, `tokenId` será criado para `to`.
     * - Quando `to` é zero, o `tokenId` de `from` será queimado.
     * - `from` e `to` nunca são ambos zero.
     *
     * Para saber mais sobre ganchos, acesse xref:ROOT:extending-contracts.adoc#using-hooks[Usando Ganchos].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}







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


/**
 * @dev Isso implementa uma extensão opcional do {ERC721} definido no EIP que adiciona
 * a enumerabilidade de todos os IDs de token no contrato, bem como todos os IDs de token possuídos por cada
 * conta.
 */
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    // Mapeamento do proprietário para lista de IDs de tokens possuídos
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapeamento do ID do token para o índice da lista de tokens do proprietário
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array com todos os IDs de token, usado para enumeração
    uint256[] private _allTokens;

    // Mapeamento do id do token para a posição no array allTokens
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev Veja {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Veja {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev Veja {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev Veja {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
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
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Função privada para adicionar um token às estruturas de dados de rastreamento de propriedade desta extensão.
     * @param to endereço que representa o novo proprietário do ID do token fornecido
     * @param tokenId uint256 ID do token a ser adicionado à lista de tokens do endereço fornecido
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Função privada para adicionar um token às estruturas de dados de rastreamento de token desta extensão.
     * @param tokenId uint256 ID do token a ser adicionado à lista de tokens
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Função privada para remover um token das estruturas de dados de controle de propriedade desta extensão. Observe que
     * embora o token não seja atribuído a um novo proprietário, o mapeamento `_ownedTokensIndex` não é atualizado: isso permite
     * otimizações de gás, por exemplo, ao realizar uma operação de transferência (evitando gravações duplicadas).
     * Isso tem complexidade de tempo O(1), mas altera a ordem do array _ownedTokens.
     * @param from endereço que representa o proprietário anterior do token ID fornecido
     * @param tokenId uint256 ID do token a ser removido da lista de tokens do endereço fornecido
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // Para evitar uma lacuna no array de tokens do 'from', armazenamos o último token no índice do token a ser excluído, e
        // então exclua o último slot (troque e remova).

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // Quando o token a ser excluído é o último token, a operação de troca é desnecessária
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            // Mova o último token para o espaço do token a ser excluído
            // Atualize o índice do token movido
        }

        // Isso também exclui o conteúdo na última posição do array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Função privada para remover um token das estruturas de dados de rastreamento de token desta extensão.
     * Isso tem complexidade de tempo O(1), mas altera a ordem do array _allTokens.
     * @param tokenId uint256 ID do token a ser removido da lista de tokens
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // Para evitar uma lacuna no array de tokens, armazenamos o último token no índice do token a ser excluído, e
        // então exclua o último slot (troque e remova).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // Quando o token a ser excluído é o último token, a operação de troca é desnecessária. No entanto, como isso ocorre tão frequentemente, é mais eficiente manter a operação de troca em todos os casos.
        // raramente (quando o último token emitido é queimado) que ainda fazemos a troca aqui para evitar o custo de gás de adição
        // uma declaração 'if' (como em _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        // Mova o último token para o espaço do token a ser excluído
        // Atualize o índice do token movido

        // Isso também exclui o conteúdo na última posição do array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
}


contract Loot is ERC721Enumerable, ReentrancyGuard, Ownable {

        string[] private weapons = [
        "Warhammer",
        "Quarterstaff",
        "Maul",
        "Mace",
        "Club",
        "Katana",
        "Falchion",
        "Scimitar",
        "Long Sword",
        "Short Sword",
        "Ghost Wand",
        "Grave Wand",
        "Bone Wand",
        "Wand",
        "Grimoire",
        "Chronicle",
        "Tome",
        "Book"
    ];
    
    string[] private chestArmor = [
        "Divine Robe",
        "Silk Robe",
        "Linen Robe",
        "Robe",
        "Shirt",
        "Demon Husk",
        "Dragonskin Armor",
        "Studded Leather Armor",
        "Hard Leather Armor",
        "Leather Armor",
        "Holy Chestplate",
        "Ornate Chestplate",
        "Plate Mail",
        "Chain Mail",
        "Ring Mail"
    ];
    
    string[] private headArmor = [
        "Ancient Helm",
        "Ornate Helm",
        "Great Helm",
        "Full Helm",
        "Helm",
        "Demon Crown",
        "Dragon's Crown",
        "War Cap",
        "Leather Cap",
        "Cap",
        "Crown",
        "Divine Hood",
        "Silk Hood",
        "Linen Hood",
        "Hood"
    ];
    
    string[] private waistArmor = [
        "Ornate Belt",
        "War Belt",
        "Plated Belt",
        "Mesh Belt",
        "Heavy Belt",
        "Demonhide Belt",
        "Dragonskin Belt",
        "Studded Leather Belt",
        "Hard Leather Belt",
        "Leather Belt",
        "Brightsilk Sash",
        "Silk Sash",
        "Wool Sash",
        "Linen Sash",
        "Sash"
    ];
    
    string[] private footArmor = [
        "Holy Greaves",
        "Ornate Greaves",
        "Greaves",
        "Chain Boots",
        "Heavy Boots",
        "Demonhide Boots",
        "Dragonskin Boots",
        "Studded Leather Boots",
        "Hard Leather Boots",
        "Leather Boots",
        "Divine Slippers",
        "Silk Slippers",
        "Wool Shoes",
        "Linen Shoes",
        "Shoes"
    ];
    
    string[] private handArmor = [
        "Holy Gauntlets",
        "Ornate Gauntlets",
        "Gauntlets",
        "Chain Gloves",
        "Heavy Gloves",
        "Demon's Hands",
        "Dragonskin Gloves",
        "Studded Leather Gloves",
        "Hard Leather Gloves",
        "Leather Gloves",
        "Divine Gloves",
        "Silk Gloves",
        "Wool Gloves",
        "Linen Gloves",
        "Gloves"
    ];
    
    string[] private necklaces = [
        "Necklace",
        "Amulet",
        "Pendant"
    ];
    
    string[] private rings = [
        "Gold Ring",
        "Silver Ring",
        "Bronze Ring",
        "Platinum Ring",
        "Titanium Ring"
    ];
    
    string[] private suffixes = [
        "of Power",
        "of Giants",
        "of Titans",
        "of Skill",
        "of Perfection",
        "of Brilliance",
        "of Enlightenment",
        "of Protection",
        "of Anger",
        "of Rage",
        "of Fury",
        "of Vitriol",
        "of the Fox",
        "of Detection",
        "of Reflection",
        "of the Twins"
    ];
    
    string[] private namePrefixes = [
        "Agony", "Apocalypse", "Armageddon", "Beast", "Behemoth", "Blight", "Blood", "Bramble", 
        "Brimstone", "Brood", "Carrion", "Cataclysm", "Chimeric", "Corpse", "Corruption", "Damnation", 
        "Death", "Demon", "Dire", "Dragon", "Dread", "Doom", "Dusk", "Eagle", "Empyrean", "Fate", "Foe", 
        "Gale", "Ghoul", "Gloom", "Glyph", "Golem", "Grim", "Hate", "Havoc", "Honour", "Horror", "Hypnotic", 
        "Kraken", "Loath", "Maelstrom", "Mind", "Miracle", "Morbid", "Oblivion", "Onslaught", "Pain", 
        "Pandemonium", "Phoenix", "Plague", "Rage", "Rapture", "Rune", "Skull", "Sol", "Soul", "Sorrow", 
        "Spirit", "Storm", "Tempest", "Torment", "Vengeance", "Victory", "Viper", "Vortex", "Woe", "Wrath",
        "Light's", "Shimmering"  
    ];
    
    string[] private nameSuffixes = [
        "Bane",
        "Root",
        "Bite",
        "Song",
        "Roar",
        "Grasp",
        "Instrument",
        "Glow",
        "Bender",
        "Shadow",
        "Whisper",
        "Shout",
        "Growl",
        "Tear",
        "Peak",
        "Form",
        "Sun",
        "Moon"
    ];
    
    function random(string memory input) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(input)));
    }
    
    function getWeapon(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "WEAPON", weapons);
    }
    
    function getChest(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "CHEST", chestArmor);
    }
    
    function getHead(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "HEAD", headArmor);
    }
    
    function getWaist(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "WAIST", waistArmor);
    }

    function getFoot(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "FOOT", footArmor);
    }
    
    function getHand(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "HAND", handArmor);
    }
    
    function getNeck(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "NECK", necklaces);
    }
    
    function getRing(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "RING", rings);
    }
    
    function pluck(uint256 tokenId, string memory keyPrefix, string[] memory sourceArray) internal view returns (string memory) {
        uint256 rand = random(string(abi.encodePacked(keyPrefix, toString(tokenId))));
        string memory output = sourceArray[rand % sourceArray.length];
        uint256 greatness = rand % 21;
        if (greatness > 14) {
            output = string(abi.encodePacked(output, " ", suffixes[rand % suffixes.length]));
        }
        if (greatness >= 19) {
            string[2] memory name;
            name[0] = namePrefixes[rand % namePrefixes.length];
            name[1] = nameSuffixes[rand % nameSuffixes.length];
            if (greatness == 19) {
                output = string(abi.encodePacked('"', name[0], ' ', name[1], '" ', output));
            } else {
                output = string(abi.encodePacked('"', name[0], ' ', name[1], '" ', output, " +1"));
            }
        }
        return output;
    }

    function tokenURI(uint256 tokenId) override public view returns (string memory) {
        string[17] memory parts;
        //www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"><style>.base { fill: white; font-family: serif; font-size: 14px; }</style><rect width="100%" height="100%" fill="black" /><text x="10" y="20" class="base">

        parts[1] = getWeapon(tokenId);

        parts[2] = '</text><text x="10" y="40" class="base">';

        parts[3] = getChest(tokenId);

        parts[4] = '</text><text x="10" y="60" class="base">';

        parts[5] = getHead(tokenId);

        parts[6] = '</text><text x="10" y="80" class="base">';

        parts[7] = getWaist(tokenId);

        parts[8] = '</text><text x="10" y="100" class="base">';

        parts[9] = getFoot(tokenId);

        parts[10] = '</text><text x="10" y="120" class="base">';

        parts[11] = getHand(tokenId);

        parts[12] = '</text><text x="10" y="140" class="base">';

        parts[13] = getNeck(tokenId);

        parts[14] = '</text><text x="10" y="160" class="base">';

        parts[15] = getRing(tokenId);

        parts[16] = '</text></svg>';

        string memory output = string(abi.encodePacked(parts[0], parts[1], parts[2], parts[3], parts[4], parts[5], parts[6], parts[7], parts[8]));
        output = string(abi.encodePacked(output, parts[9], parts[10], parts[11], parts[12], parts[13], parts[14], parts[15], parts[16]));
        
        #', toString(tokenId), '", "descrição": "Loot é um equipamento de aventureiro gerado e armazenado aleatoriamente na cadeia. Estatísticas, imagens e outras funcionalidades são intencionalmente omitidas para que outros possam interpretar. Sinta-se à vontade para usar o Loot da maneira que desejar.", "imagem": "data:image/svg+xml;base64,', Base64.encode(bytes(output)), '"}'))));
        output = string(abi.encodePacked('data:application/json;base64,', json));

        return output;
    }

    function claim(uint256 tokenId) public nonReentrant {
        require(tokenId > 0 && tokenId < 7778, "Token ID invalid");
        _safeMint(_msgSender(), tokenId);
    }
    
    function ownerClaim(uint256 tokenId) public nonReentrant onlyOwner {
        require(tokenId > 7777 && tokenId < 8001, "Token ID invalid");
        _safeMint(owner(), tokenId);
    }
    
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
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
    
    constructor() ERC721("Loot", "LOOT") Ownable() {}
}

/// [Licença MIT]
/// @title Base64
/// @notice Fornece uma função para codificar alguns bytes em base64
/// @autor Brecht Devos <brecht@loopring.org>
library Base64 {
    bytes internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /// @notice Codifica alguns bytes para a representação base64
    function encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";

        // multiplicar por 4/3 arredondado para cima
        uint256 encodedLen = 4 * ((len + 2) / 3);

        // Adicione um buffer extra no final
        bytes memory result = new bytes(encodedLen + 32);

        bytes memory table = TABLE;

        assembly {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)

            for {
                let i := 0
            } lt(i, len) {

            } {
                i := add(i, 3)
                let input := and(mload(add(data, i)), 0xffffff)

                let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(input, 0x3F))), 0xFF))
                out := shl(224, out)

                mstore(resultPtr, out)

                resultPtr := add(resultPtr, 4)
            }

            switch mod(len, 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }

            mstore(result, encodedLen)
        }

        return string(result);
    }
}
