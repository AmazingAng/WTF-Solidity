// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "../34_ERC721/ERC721.sol";

// Biblioteca ECDSA
library ECDSA{
    /**
     * @dev Verifica se o endereço de assinatura está correto usando ECDSA, se estiver correto, retorna true
     * _msgHash é o hash da mensagem
     * _signature é a assinatura
     * _signer é o endereço de assinatura
     */
    function verify(bytes32 _msgHash, bytes memory _signature, address _signer) internal pure returns (bool) {
        return recoverSigner(_msgHash, _signature) == _signer;
    }

    // @dev Recupera o endereço do signatário a partir de _msgHash e _signature
    function recoverSigner(bytes32 _msgHash, bytes memory _signature) internal pure returns (address){
        // Verificando o comprimento da assinatura, 65 é o comprimento padrão da assinatura r,s,v.
        require(_signature.length == 65, "invalid signature length");
        bytes32 r;
        bytes32 s;
        uint8 v;
        // Atualmente, só é possível obter os valores r, s e v da assinatura usando assembly (inline assembly).
        assembly {
            /*
            Os primeiros 32 bytes armazenam o comprimento da assinatura (regra de armazenamento em array dinâmico)
            add(sig, 32) = ponteiro de sig + 32
            Equivalente a pular os primeiros 32 bytes da assinatura
            mload(p) carrega os próximos 32 bytes de dados a partir do endereço de memória p
            */
            // Lendo os 32 bytes de dados de comprimento
            r := mload(add(_signature, 0x20))
            // Ler os próximos 32 bytes
            s := mload(add(_signature, 0x40))
            // Ler o último byte
            v := byte(0, mload(add(_signature, 0x60)))
        }
        // Usando ecrecover (função global): recuperando o endereço do signatário usando msgHash, r, s e v
        return ecrecover(_msgHash, v, r, s);
    }
    
    /**
     * @dev Retorna a mensagem de assinatura Ethereum
     * `hash`: hash da mensagem
     * Segue o padrão de assinatura Ethereum: https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * E também `EIP191`: https://eips.ethereum.org/EIPS/eip-191`
     * Adiciona o campo "\x19Ethereum Signed Message:\n32" para evitar que a assinatura seja uma transação executável.
     */
    function toEthSignedMessageHash(bytes32 hash) public pure returns (bytes32) {
        // 32 é o comprimento em bytes do hash,
        // aplicado pela assinatura de tipo acima
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }
}

contract SignatureNFT is ERC721 {
    // Endereço de assinatura
    // Registre os endereços já mintados

    // Construtor, inicializa o nome, código e endereço de assinatura da coleção NFT
    constructor(string memory _name, string memory _symbol, address _signer)
    ERC721(_name, _symbol)
    {
        signer = _signer;
    }

    // Usando ECDSA para verificar a assinatura e criar uma nova moeda
    function mint(address _account, uint256 _tokenId, bytes memory _signature)
    external
    {
        // Empacotar mensagem com _account e _tokenId
        // Calcular mensagem de assinatura Ethereum
        // ECDSA verificado com sucesso
        // O endereço não foi mintado antes.
                
        // Registre os endereços que foram mintados
        // mint
    }

    /*
     * Combine the mint address (address type) and tokenId (uint256 type) to form the message msgHash
     * _account: 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4
     * _tokenId: 0
     * Corresponding message msgHash: 0x1bf2c0ce4546651a1a2feb457b39d891a6b83931cc2454434f39961345ac378c
     */
    function getMessageHash(address _account, uint256 _tokenId) public pure returns(bytes32){
        return keccak256(abi.encodePacked(_account, _tokenId));
    }

    // Verificação ECDSA, chamando a função verify() da biblioteca ECDSA
    function verify(bytes32 _msgHash, bytes memory _signature)
    public view returns (bool)
    {
        return ECDSA.verify(_msgHash, _signature, signer);
    }
}


/* Verificação de Assinatura
 
Como Assinar e Verificar
# Assinatura
1. Criar mensagem para assinar
2. Fazer o hash da mensagem
3. Assinar o hash (fora da cadeia, mantenha sua chave privada em segredo)
 
# Verificação
1. Recriar o hash a partir da mensagem original
2. Recuperar o assinante da assinatura e do hash
3. Comparar o assinante recuperado com o assinante alegado
*/



contract VerifySignature {
    /* 1. Desbloquear conta MetaMask
    ethereum.enable()
    */

    /* 2. Obtenha o hash da mensagem para assinar
    getMessageHash(
        0x14723A09ACff6D2A60DcdF7aA4AFf308FDDC160C,
        123,
        "café e donuts",
        1
    )
 
    hash = "0xcf36ac4f97dc10d91fc2cbb20d718e94a8cbfe0f82eaedc6a4aa38946fb797cd"
    */
    function getMessageHash(
        address _addr,
        uint256 _tokenId
    ) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_addr, _tokenId));
    }

    /* 3. Assinar hash da mensagem
    # usando o navegador
    conta = "copie e cole a conta do signatário aqui"
    ethereum.request({ method: "personal_sign", params: [conta, hash]}).then(console.log)
 
    # usando web3
    web3.personal.sign(hash, web3.eth.defaultAccount, console.log)
 
    A assinatura será diferente para contas diferentes
    0x993dab3dd91f5c6dc28e17439be475478f5635c92a56e17e82349d3fb2f166196f466c0b4e0c146f285204f0dcb13e5ae67bc33f4b888ec32dfe0a063e8f3f781b
    */
    function getEthSignedMessageHash(bytes32 _messageHash)
        public
        pure
        returns (bytes32)
    {
        /*
        A assinatura é produzida ao assinar um hash keccak256 com o seguinte formato:
        "\x19Ethereum Signed Message\n" + len(msg) + msg
        */
        return
            keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", _messageHash)
            );
    }

    /* 4. Verificar assinatura
    signatário = 0xB273216C05A8c0D4F0a4Dd0d7Bae1D2EfFE636dd
    para = 0x14723A09ACff6D2A60DcdF7aA4AFf308FDDC160C
    quantidade = 123
    mensagem = "café e rosquinhas"
    nonce = 1
    assinatura =
        0x993dab3dd91f5c6dc28e17439be475478f5635c92a56e17e82349d3fb2f166196f466c0b4e0c146f285204f0dcb13e5ae67bc33f4b888ec32dfe0a063e8f3f781b
    */
    function verify(
        address _signer,
        address _addr,
        uint _tokenId,
        bytes memory signature
    ) public pure returns (bool) {
        bytes32 messageHash = getMessageHash(_addr, _tokenId);
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);

        return recoverSigner(ethSignedMessageHash, signature) == _signer;
    }

    function recoverSigner(bytes32 _ethSignedMessageHash, bytes memory _signature)
        public
        pure
        returns (address)
    {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);

        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

    function splitSignature(bytes memory sig)
        public
        pure
        returns (
            bytes32 r,
            bytes32 s,
            uint8 v
        )
    {
        // Verificando o comprimento da assinatura, 65 é o comprimento padrão da assinatura r,s,v.
        require(sig.length == 65, "invalid signature length");

        assembly {
            /*
            Primeiros 32 bytes armazenam o comprimento da assinatura
 
            add(sig, 32) = ponteiro de sig + 32
            efetivamente, pula os primeiros 32 bytes da assinatura
 
            mload(p) carrega os próximos 32 bytes a partir do endereço de memória p para a memória
            */

            // primeiro 32 bytes, após o prefixo de comprimento
            r := mload(add(sig, 0x20))
            // segundo 32 bytes
            s := mload(add(sig, 0x40))
            // final byte (primeiro byte dos próximos 32 bytes)
            v := byte(0, mload(add(sig, 0x60)))
        }

        // retornar implicitamente (r, s, v)
    }
}
