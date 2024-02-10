# WTF Solidity Segurança do Contrato: S06. Reprodução de Assinatura

Recentemente, tenho revisado meus conhecimentos sobre Solidity para consolidar os detalhes e escrever um "Guia Simplificado de Solidity WTF" para uso de iniciantes (os programadores experientes podem procurar outros tutoriais). Atualizo de 1 a 3 lições por semana.

Twitter: [@0xAA_Science](https://twitter.com/0xAA_Science) | [@WTFAcademy_](https://twitter.com/WTFAcademy_)

Comunidade: [Discord](https://discord.gg/5akcruXrsk) | [Grupo do WhatsApp](https://docs.google.com/forms/d/e/1FAIpQLSe4KGT8Sh6sJ7hedQRuIYirOoZK_85miz3dw7vA1-YjodgJ-A/viewform?usp=sf_link) | [Site oficial wtf.academy](https://wtf.academy)

Todo o código e tutorial estão disponíveis no GitHub: [github.com/AmazingAng/WTFSolidity](https://github.com/AmazingAng/WTFSolidity)

---

Nesta lição, vamos abordar o ataque de Reprodução de Assinatura em contratos inteligentes e os métodos de prevenção. Esse tipo de ataque indiretamente levou ao roubo de 20 milhões de tokens $OP da famosa corretora Wintermute.

## Reprodução de Assinatura

Lembra quando na escola o professor pedia a assinatura dos pais e, às vezes, por estarem ocupados, eu copiava a assinatura anterior? De certa forma, isso é uma reprodução de assinatura.

No ecossistema blockchain, assinaturas digitais são utilizadas para identificar o autor de dados e verificar a integridade dos mesmos. Ao enviar uma transação, o usuário assina a transação com sua chave privada, permitindo que outros verifiquem se a transação foi emitida pela conta correspondente. Os contratos inteligentes também podem usar o algoritmo `ECDSA` para verificar a assinatura criada extra-cadeia e, em seguida, executar lógicas como a emissão ou transferência de tokens. Para mais informações sobre assinaturas digitais, consulte [WTF Solidity lição 37: Assinaturas Digitais](../37_Signature/readme_pt-br.md).

Em geral, existem dois tipos comuns de ataques de reprodução de assinatura:

1. Reprodução Comum: usar uma assinatura que deveria ser de uso único várias vezes. Os tokens NFT da coleção "The Association" lançados pela NBA foram gratuitamente emitidos devido a esse tipo de ataque.

2. Reprodução Inter-cadeia: usar uma assinatura que deveria ser usada em uma cadeia em outra cadeia. A corretora Wintermute foi roubada em 20 milhões de tokens $OP devido a esse tipo de ataque.

## Exemplo de Contrato com Vulnerabilidade

O contrato `SigReplay` abaixo é um contrato de token `ERC20` que possui uma vulnerabilidade de reprodução de assinaturas em sua função de emissão. Ele usa assinaturas off-chain para permitir que endereços na lista branca `to` emitam uma determinada quantidade `amount` de tokens. O contrato mantém o endereço do `signer` para validar se a assinatura é válida.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract SigReplay is ERC20 {
    address public signer;

    constructor() ERC20("SigReplay", "Replay") {
        signer = msg.sender;
    }
    
    // Função de emissão com vulnerabilidade de reprodução de assinaturas
    function badMint(address to, uint amount, bytes memory signature) public {
        bytes32 _msgHash = toEthSignedMessageHash(getMessageHash(to, amount));
        require(verify(_msgHash, signature), "Invalid Signer!");
        _mint(to, amount);
    }

    function getMessageHash(address to, uint256 amount) public pure returns(bytes32){
        return keccak256(abi.encodePacked(to, amount));
    }

    function toEthSignedMessageHash(bytes32 hash) public pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    function verify(bytes32 _msgHash, bytes memory _signature) public view returns (bool){
        return ECDSA.recover(_msgHash, _signature) == signer;
    }
}
```

**Observação:** A função de emissão `badMint()` não verifica se a assinatura já foi utilizada, permitindo que a mesma assinatura seja usada repetidamente para emitir tokens.

## Reprodução no Remix

**1.** Implante o contrato `SigReplay`, onde o endereço do `signer` é inicializado com o endereço do criador do contrato.

**2.** Use a função `getMessageHash()` para obter a mensagem.

**3.** Clique no botão de assinatura no painel de implantação do Remix e assine a mensagem com sua chave privada.

**4.** Chame repetidamente a função `badMint()` para realizar o ataque de reprodução de assinaturas e emitir uma grande quantidade de tokens.

## Métodos de Prevenção

Os ataques de reprodução de assinatura têm duas principais formas de prevenção:

1. Registrar as assinaturas usadas anteriormente, como gravar os endereços já usados para emissão de tokens, impedindo assim sua reutilização:

    ```solidity
    mapping(address => bool) public mintedAddress;   // Record minted addresses
    
    function goodMint(address to, uint amount, bytes memory signature) public {
        bytes32 _msgHash = toEthSignedMessageHash(getMessageHash(to, amount));
        require(verify(_msgHash, signature), "Invalid Signer!");
        // Check if the address was already minted
        require(!mintedAddress[to], "Already minted");
        // Record the minted address
        mintedAddress[to] = true;
        _mint(to, amount);
    }
    ```

2. Incluir um `nonce` (valor que aumenta a cada transação) e `chainid` (ID da cadeia) na mensagem assinada para prevenir ataques comuns e inter-cadeias:

    ```solidity
    uint nonce;

    function nonceMint(address to, uint amount, bytes memory signature) public {
        bytes32 _msgHash = toEthSignedMessageHash(keccak256(abi.encodePacked(to, amount, nonce, block.chainid)));
        require(verify(_msgHash, signature), "Invalid Signer!");
        _mint(to, amount);
        nonce++;
    }
    ```

## Conclusão

Nesta lição, exploramos a vulnerabilidade de reprodução de assinatura em contratos inteligentes e apresentamos duas formas de prevenção:

1. Registrar as assinaturas utilizadas anteriormente para evitar reprodução.

2. Incluir `nonce` e `chainid` na mensagem assinada.

<!-- This file was translated using AI by repo_ai_translate. For more information, visit https://github.com/marcelojsilva/repo_ai_translate -->