// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

// Exemplo de erro de gerenciamento de permissões
contract SigReplay is ERC20 {

    address public signer;

    // Construtor: inicializa o nome e o código do token
    constructor() ERC20("SigReplay", "Replay") {
        signer = msg.sender;
    }
    
    /**
     * Função de construção com vulnerabilidade de reentrada
     * para: 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4
     * quantidade: 1000
     * Assinatura: 0x5a4f1ad4d8bd6b5582e658087633230d9810a0b7b8afa791e3f94cc38947f6cb1069519caf5bba7b975df29cbfdb4ada355027589a989435bf88e825841452f61b
     */
    function badMint(address to, uint amount, bytes memory signature) public {
        bytes32 _msgHash = toEthSignedMessageHash(getMessageHash(to, amount));
        require(verify(_msgHash, signature), "Invalid Signer!");
        _mint(to, amount);
    }

    /**
     * Combinar o endereço 'to' (tipo address) e o valor 'amount' (tipo uint256) para formar a mensagem msgHash
     * to: 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4
     * amount: 1000
     * msgHash correspondente: 0xb4a4ba10fbd6886a312ec31c54137f5714ddc0e93274da8746a36d2fa96768be
     */
    function getMessageHash(address to, uint256 amount) public pure returns(bytes32){
        return keccak256(abi.encodePacked(to, amount));
    }

    /**
     * @dev Obter mensagem assinada do Ethereum
     * `hash`: Hash da mensagem
     * Segue o padrão de assinatura do Ethereum: https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * E também `EIP191`: https://eips.ethereum.org/EIPS/eip-191`
     * Adiciona o campo "\x19Ethereum Signed Message:\n32" para evitar que a assinatura seja de uma transação executável.
     */
    function toEthSignedMessageHash(bytes32 hash) public pure returns (bytes32) {
        // 32 é o comprimento em bytes do hash,
        // aplicado pela assinatura de tipo acima
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    // ECDSA verificação
    function verify(bytes32 _msgHash, bytes memory _signature) public view returns (bool){
        return ECDSA.recover(_msgHash, _signature) == signer;
    }


    // Registre os endereços já mintados
    
    function goodMint(address to, uint amount, bytes memory signature) public {
        bytes32 _msgHash = toEthSignedMessageHash(getMessageHash(to, amount));
        require(verify(_msgHash, signature), "Invalid Signer!");
        // Verifique se este endereço já foi mintado
        require(!mintedAddress[to], "Already minted");
        // Registre os endereços que foram mintados
        mintedAddress[to] = true;
        _mint(to, amount);
    }
    
    uint nonce;

    function nonceMint(address to, uint amount, bytes memory signature) public {
        bytes32 _msgHash = toEthSignedMessageHash(keccak256(abi.encodePacked(to, amount, nonce, block.chainid)));
        require(verify(_msgHash, signature), "Invalid Signer!");
        _mint(to, amount);
        nonce++;
    }
}