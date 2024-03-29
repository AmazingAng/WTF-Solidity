// SPDX-License-Identifier: MIT
// por 0xAA
pragma solidity ^0.8.21;

import "./IERC165.sol";
import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./IERC721Metadata.sol";
import "./Address.sol";
import "./String.sol";

contract ERC721 is IERC721, IERC721Metadata{
    // Usando a biblioteca Address, use isContract para verificar se um endereço é um contrato
    // Importando a biblioteca String,

    // Token nome
    string public override name;
    // Token código
    string public override symbol;
    // Mapeamento do tokenId para o endereço do proprietário
    mapping(uint => address) private _owners;
    // mapeamento da quantidade de posições de 'address' para a quantidade de posições em '持仓数量'
    mapping(address => uint) private _balances;
    // Mapeamento de autorização do tokenID para o endereço autorizado
    mapping(uint => address) private _tokenApprovals;
    // Mapeamento de autorização em lote do endereço do proprietário para o endereço do operador.
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * Construtor, inicializa `name` e `symbol`.
     */
    constructor(string memory name_, string memory symbol_) {
        name = name_;
        symbol = symbol_;
    }

    // Implementação do método supportsInterface da interface IERC165
    function supportsInterface(bytes4 interfaceId)
        external
        pure
        override
        returns (bool)
    {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC165).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId;
    }

    // Implementação do balanceOf do IERC721, utilizando a variável _balances para consultar o saldo do endereço do proprietário.
    function balanceOf(address owner) external view override returns (uint) {
        require(owner != address(0), "owner = zero address");
        return _balances[owner];
    }

    // Implementação do ownerOf do IERC721, utilizando a variável _owners para consultar o proprietário do tokenId.
    function ownerOf(uint tokenId) public view override returns (address owner) {
        owner = _owners[tokenId];
        require(owner != address(0), "token doesn't exist");
    }

    // Implementação do isApprovedForAll do IERC721, utilizando a variável _operatorApprovals para verificar se o endereço do proprietário concedeu autorização em lote para o endereço do operador para os NFTs que ele possui.
    function isApprovedForAll(address owner, address operator)
        external
        view
        override
        returns (bool)
    {
        return _operatorApprovals[owner][operator];
    }

    // Implemente o setApprovalForAll do IERC721, autorizando todos os tokens detidos para o endereço do operador. Chame a função _setApprovalForAll.
    function setApprovalForAll(address operator, bool approved) external override {
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    // Implemente o método getApproved da IERC721, utilizando a variável _tokenApprovals para consultar o endereço autorizado do tokenId.
    function getApproved(uint tokenId) external view override returns (address) {
        require(_owners[tokenId] != address(0), "token doesn't exist");
        return _tokenApprovals[tokenId];
    }
     
    // Função de autorização. Através da manipulação de _tokenApprovals, autoriza o endereço a operar o tokenId e emite o evento Approval.
    function _approve(
        address owner,
        address to,
        uint tokenId
    ) private {
        _tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }

    // Implemente o método approve do IERC721 para autorizar o tokenId para o endereço 'to'. Condições: 'to' não é o proprietário e 'msg.sender' é o proprietário ou um endereço autorizado. Chame a função _approve.
    function approve(address to, uint tokenId) external override {
        address owner = _owners[tokenId];
        require(
            msg.sender == owner || _operatorApprovals[owner][msg.sender],
            "not owner nor approved for all"
        );
        _approve(owner, to, tokenId);
    }

    // Verifique se o endereço do spender pode usar o tokenId (deve ser o proprietário ou um endereço autorizado)
    function _isApprovedOrOwner(
        address owner,
        address spender,
        uint tokenId
    ) private view returns (bool) {
        return (spender == owner ||
            _tokenApprovals[tokenId] == spender ||
            _operatorApprovals[owner][spender]);
    }

    /*
     * Função de transferência. Transfere o tokenId de from para to, ajustando as variáveis _balances e _owner, e emite o evento Transfer.
     * Condições:
     * 1. tokenId é possuído por from
     * 2. to não é um endereço 0
     */
    function _transfer(
        address owner,
        address from,
        address to,
        uint tokenId
    ) private {
        require(from == owner, "not owner");
        require(to != address(0), "transfer to the zero address");

        _approve(owner, address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }
    
    // Implementação do transferFrom do IERC721, uma transferência não segura, não recomendada para uso. Chama a função _transfer.
    function transferFrom(
        address from,
        address to,
        uint tokenId
    ) external override {
        address owner = ownerOf(tokenId);
        require(
            _isApprovedOrOwner(owner, msg.sender, tokenId),
            "not owner nor approved"
        );
        _transfer(owner, from, to, tokenId);
    }

    /**
     * Transferência segura, transferindo com segurança o token de tokenId de from para to, verificando se o receptor do contrato entende o protocolo ERC721 para evitar que o token seja bloqueado permanentemente. Chama a função _transfer e _checkOnERC721Received. Condições:
     * from não pode ser um endereço 0.
     * to não pode ser um endereço 0.
     * O token de tokenId deve existir e ser de propriedade de from.
     * Se to for um contrato inteligente, ele deve suportar IERC721Receiver-onERC721Received.
     */
    function _safeTransfer(
        address owner,
        address from,
        address to,
        uint tokenId,
        bytes memory _data
    ) private {
        _transfer(owner, from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "not ERC721Receiver");
    }

    /**
     * Implementa o safeTransferFrom do IERC721, uma transferência segura que chama a função _safeTransfer.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint tokenId,
        bytes memory _data
    ) public override {
        address owner = ownerOf(tokenId);
        require(
            _isApprovedOrOwner(owner, msg.sender, tokenId),
            "not owner nor approved"
        );
        _safeTransfer(owner, from, to, tokenId, _data);
    }

    // Função sobrecarregada safeTransferFrom
    function safeTransferFrom(
        address from,
        address to,
        uint tokenId
    ) external override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * Função de cunhagem. Cunha o tokenId ajustando as variáveis _balances e _owners e transfere para o endereço 'to', liberando o evento Transfer. 
     * Esta função de cunhagem pode ser chamada por qualquer pessoa, mas é recomendado que os desenvolvedores a reescrevam e adicionem algumas condições.
     * Condições:
     * 1. O tokenId ainda não existe.
     * 2. 'to' não é um endereço 0.
     */
    function _mint(address to, uint tokenId) internal virtual {
        require(to != address(0), "mint to zero address");
        require(_owners[tokenId] == address(0), "token already minted");

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    // Função de destruição, destrói o tokenId ajustando as variáveis _balances e _owners, e libera o evento Transfer. Condição: tokenId existe.
    function _burn(uint tokenId) internal virtual {
        address owner = ownerOf(tokenId);
        require(msg.sender == owner, "not owner of token");

        _approve(owner, address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    // _checkOnERC721Received: função usada para chamar o onERC721Received do IERC721Receiver quando 'to' é um contrato, evitando que o tokenId seja acidentalmente enviado para o vazio.
    function _checkOnERC721Received(
        address from,
        address to,
        uint tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            return
                IERC721Receiver(to).onERC721Received(
                    msg.sender,
                    from,
                    tokenId,
                    _data
                ) == IERC721Receiver.onERC721Received.selector;
        } else {
            return true;
        }
    }

    /**
     * Implementa a função tokenURI da interface IERC721Metadata para consultar metadados.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_owners[tokenId] != address(0), "Token Not Exist");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * Calculando o BaseURI de {tokenURI}, onde tokenURI é a concatenação de baseURI e tokenId, que precisa ser reescrito pelo desenvolvedor.
     * O baseURI do BAYC é ipfs://QmeSjSinHpPnmXmspMjwiXyN6zS4E9zccariGR3jxcaWtq/
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }
}
