// SPDX-License-Identifier: MIT
// OpenZeppelin Contratos (última atualização v4.5.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./IERC721Metadata.sol";
import "./Address.sol";
import "./Context.sol";
import "./Strings.sol";
import "./ERC165.sol";

/**
 * @dev Implementação do https://eips.ethereum.org/EIPS/eip-721[Padrão de Token Não-Fungível ERC721], incluindo
 * a extensão de Metadados, mas não incluindo a extensão Enumerável, que está disponível separadamente como
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Nome do token
    // Nome do token
    string private _name;

    // Símbolo do token
    // Código do token
    string private _symbol;

    // Mapeamento do ID do token para o endereço do proprietário
    // Mapeamento do tokenId para o endereço do proprietário
    mapping(uint256 => address) private _owners;

    // Mapeando o endereço do proprietário para a contagem de tokens
    // Mapeamento do endereço do proprietário para a quantidade de moedas detidas
    mapping(address => uint256) private _balances;

    // Mapeamento do ID do token para o endereço aprovado
    // Mapeamento do tokenId para o endereço de autorização
    mapping(uint256 => address) private _tokenApprovals;

    // Mapeamento do proprietário para aprovações do operador
    // Endereço do proprietário para mapeamento de aprovação em lote
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Inicializa o contrato definindo um `nome` e um `símbolo` para a coleção de tokens.
     */
     // Construtor, precisa definir o nome e o código do token ERC721
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Veja {IERC165-supportsInterface}.
     */
    // Implementação do método supportsInterface da interface IERC165
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev Veja {IERC721-balanceOf}.
     */
     // Implementação do balanceOf do IERC721, usado para consultar a quantidade de tokens que um endereço possui.
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev Veja {IERC721-ownerOf}.
     */
     // Implementação do ownerOf do IERC721, usado para consultar o proprietário do tokenId
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev Veja {IERC721Metadata-name}.
     */
     // Implementação do método 'name' da interface IERC721Metadata para consultar o nome do token.
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Veja {IERC721Metadata-symbol}.
     */
    // Implementação da função symbol da interface IERC721Metadata para consultar o código do token.
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Veja {IERC721Metadata-tokenURI}.
     */
    // Implementação do tokenURI da IERC721Metadata
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
    // URI base, called by tokenURI(), concatenated with tokenId to form tokenURI, default is empty, needs to be overridden by child contract.
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev Veja {IERC721-approve}.
     */
    // Implemente o método approve da interface IERC721 para conceder autorização do tokenId para o endereço 'to'.
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
    // Implementação do getApproved do IERC721, que consulta o endereço autorizado para o tokenId.
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev Veja {IERC721-setApprovalForAll}.
     */
    // Implementação do setApprovalForAll do IERC721
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev Veja {IERC721-isApprovedForAll}.
     */
    // Implementação do isApprovedForAll do IERC721
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev Veja {IERC721-transferFrom}.
     */
    // Implementar transferFrom de IERC721
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
    // Implementação do safeTransferFrom do IERC721
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
    // Implementação do safeTransferFrom do IERC721
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

    /**
    * @dev Transfere o token `tokenId` de forma segura de `from` para `to`, verificando primeiro se o receptor do contrato entende o protocolo ERC721 para evitar que o token seja bloqueado permanentemente.
    *
    * `_data` é um dado adicional, sem formato específico, que será chamado pelo contrato `to`.
    *
    * Esta função interna é equivalente a {safeTransferFrom}.
    *
    * Requisitos:
    *
    * - `from` não pode ser o endereço 0.
    * - `to` não pode ser o endereço 0.
    * - O token `tokenId` deve existir e ser possuído por `from`.
    * - Se `to` for um contrato inteligente, ele deve suportar {IERC721Receiver-onERC721Received}.
    *
    * Esta função emite o evento {Transfer} durante a execução.
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
    // Retorna se o `tokenId` existe (o proprietário não é um endereço 0)
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
    // Retorna se `spender` tem permissão para usar `tokenId` (sendo o proprietário ou autorizado)
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
    // Segurança mint `tokenId` e transferir para `to`. Condições: 1. `tokenId` ainda não existe, 2. Se `to` for um contrato inteligente, ele deve suportar a interface {IERC721Receiver-onERC721Received}.
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Mesmo que {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], com um parâmetro adicional `data` que é
     * encaminhado em {IERC721Receiver-onERC721Received} para os destinatários do contrato.
     */
    // Implementação segura de mint
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
    // Função interna, cria um novo token com o ID `tokenId` e transfere para `to`, com as seguintes condições: 1. O token com o ID `tokenId` ainda não existe, 2. `to` não é um endereço 0. Será emitido o evento {Transfer}.
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
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
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
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
    // Função interna que transfere o `tokenId` de `from` para `to`. Condições: 1. `tokenId` é possuído por `from`, 2. `to` não é um endereço 0. Irá emitir o evento {Transfer}.
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Limpar autorização
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Aprova `to` para operar em `tokenId`
     *
     * Emite um evento {Approval}.
     */
    // Função interna, autoriza 'to' a operar 'tokenId'. Dispara o evento {Approval}
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Aprova o `operador` para operar em todos os tokens do `proprietário`
     *
     * Emite um evento {ApprovalForAll}.
     */
    // Função interna para conceder permissão em lote para 'to' operar com todos os tokens do 'owner'. Dispara o evento {ApprovalForAll}.
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
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
    // Função interna para chamar {IERC721Receiver-onERC721Received} quando `to` é um contrato, evitando que `tokenId` seja acidentalmente enviado para o vácuo negro.
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
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
     * e queima.
     *
     * Condições de chamada:
     *
     * - Quando `from` e `to` são ambos diferentes de zero, o `tokenId` de ``from`` será
     * transferido para `to`.
     * - Quando `from` é zero, `tokenId` será criado para `to`.
     * - Quando `to` é zero, o `tokenId` de ``from`` será queimado.
     * - `from` e `to` nunca são ambos zero.
     *
     * Para saber mais sobre ganchos, acesse xref:ROOT:extending-contracts.adoc#using-hooks[Usando Ganchos].
     */
    // Esta função será usada antes da transferência do token, incluindo a criação e destruição.
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev Gancho que é chamado após qualquer transferência de tokens. Isso inclui
     * criação e queima.
     *
     * Condições de chamada:
     *
     * - quando `from` e `to` são ambos diferentes de zero.
     * - `from` e `to` nunca são ambos zero.
     *
     * Para saber mais sobre ganchos, consulte xref:ROOT:extending-contracts.adoc#using-hooks[Usando Ganchos].
     */
    // Esta função será chamada após a transferência do token, incluindo a criação e destruição.
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}
