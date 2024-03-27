// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

// O custo de gás foi testado no Remix usando a versão 0.8.17 de compilação.
// Parâmetros utilizados tokenId = 123, address = {qualquer endereço}

// Erro personalizado
error TransferNotOwner();

// erro TransferNotOwner(endereço remetente);

contract Errors {
    // Um mapa que registra o proprietário de cada TokenId
    mapping(uint256 => address) private _owners;

    // Error method: custo de gás 24457
    // Erro com o parâmetro: custo de gás 24660
    function transferOwner1(uint256 tokenId, address newOwner) public {
        if (_owners[tokenId] != msg.sender) {
            revert TransferNotOwner();
            // revert TransferNotOwner(msg.sender);
        }
        _owners[tokenId] = newOwner;
    }

    // require方法: custo de gas 24755
    function transferOwner2(uint256 tokenId, address newOwner) public {
        require(_owners[tokenId] == msg.sender, "Transfer Not Owner");
        _owners[tokenId] = newOwner;
    }

    // assert método: custo de gas 24473
    function transferOwner3(uint256 tokenId, address newOwner) public {
        assert(_owners[tokenId] == msg.sender);
        _owners[tokenId] = newOwner;
    }
}
