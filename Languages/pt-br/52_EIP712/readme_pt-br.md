# 52. Assinaturas de Dados Tipados EIP712

Recentemente, tenho revisado meus conhecimentos em Solidity para reforçar os detalhes e estou escrevendo uma série chamada "Introdução Mínima ao Solidity" (WTF Solidity) para iniciantes (os programadores avançados podem procurar outros tutoriais). Atualizo de 1 a 3 lições por semana.

Twitter: [@0xAA_Science](https://twitter.com/0xAA_Science)

Comunidade: [Discord](https://discord.gg/5akcruXrsk) | [Grupo no WeChat](https://docs.google.com/forms/d/e/1FAIpQLSe4KGT8Sh6sJ7hedQRuIYirOoZK_85miz3dw7vA1-YjodgJ-A/viewform?usp=sf_link) | [Website wtf.academy](https://wtf.academy)

Todo o código e tutoriais estão disponíveis no GitHub: [github.com/AmazingAng/WTFSolidity](https://github.com/AmazingAng/WTFSolidity)

---

Nesta lição, vamos falar sobre um método de assinatura mais avançado e seguro chamado Assinaturas de Dados Tipados EIP712.

## EIP712

Anteriormente, falamos sobre o [padrão de assinatura EIP191 (personal sign)](../37_Signature/readme_pt-br.md), que permite assinar uma mensagem. Porém, esse padrão é muito simples e, quando a mensagem a ser assinada é complexa, o usuário só vê uma string hexadecimal (o hash dos dados), sem conseguir verificar se a assinatura está correta.

A [Assinatura de Dados Tipados EIP712](https://eips.ethereum.org/EIPS/eip-712) é um método mais avançado e seguro de assinatura. Quando um Dapp que suporta o EIP712 solicita uma assinatura, a carteira exibirá os dados originais da mensagem para que o usuário possa verificar e, em seguida, assinar.

## Como Usar o EIP712

A aplicação do EIP712 geralmente envolve duas partes: a assinatura off-chain (no frontend ou em scripts) e a verificação on-chain (no contrato). Abaixo, vamos aprender como usar o EIP712 com um exemplo simples chamado `EIP712Storage`, que possui uma variável de estado `number` que só pode ser modificada com uma assinatura EIP712.

### Assinatura Off-Chain

1. Uma assinatura EIP712 deve incluir a parte `EIP712Domain`, que contém o nome do contrato, a versão (geralmente "1"), o chainId e o verifyingContract (o endereço do contrato que verificara a assinatura).

    ```js
    EIP712Domain: [
        { name: "name", type: "string" },
        { name: "version", type: "string" },
        { name: "chainId", type: "uint256" },
        { name: "verifyingContract", type: "address" },
    ]
    ```

    Essas informações serão exibidas para o usuário durante a assinatura e garantirão que apenas contratos específicos de uma chain específica possam verificar a assinatura. Você precisará passar esses parâmetros no script.

    ```js
    const domain = {
        name: "EIP712Storage",
        version: "1",
        chainId: "1",
        verifyingContract: "0xf8e81D47203A594245E36C48e151709F0C19fBe8",
    };
    ```

2. Você precisa definir um tipo de dados de assinatura personalizado conforme a necessidade do cenário. No exemplo do `EIP712Storage`, definimos um tipo `Storage` com dois membros: `spender`, do tipo `address`, que define quem pode modificar a variável; e `number`, do tipo `uint256`, que define o valor a ser modificado.

    ```js
    const types = {
        Storage: [
            { name: "spender", type: "address" },
            { name: "number", type: "uint256" },
        ],
    };
    ```
3. Crie uma variável `message` com os dados a serem assinados.

    ```js
    const message = {
        spender: "0x5B38Da6a701c568545dCfcB03FcB875f56beddC4",
        number: "100",
    };
    ```

4. Chame o método `signTypedData()` do objeto da carteira, passando as variáveis `domain`, `types` e `message` para assinar (usaremos o `ethersjs v6`).

    ```js
    // Obtenha o provedor
    const provider = new ethers.BrowserProvider(window.ethereum)
    // Obtenha o signer e chame o método signTypedData para a assinatura EIP712
    const signature = await signer.signTypedData(domain, types, message);
    console.log("Assinatura:", signature);
    ```

### Verificação On-Chain

Agora, vamos nos concentrar na parte do contrato `EIP712Storage`, que precisa verificar a assinatura para modificar a variável `number`. O contrato possui 5 variáveis de estado.

1. `EIP712DOMAIN_TYPEHASH`: o hash do tipo `EIP712Domain`, é uma constante.
2. `STORAGE_TYPEHASH`: o hash do tipo `Storage`, é uma constante.
3. `DOMAIN_SEPARATOR`: este valor único misturado na assinatura é composto pelo `EIP712DOMAIN_TYPEHASH` e pelas informações do `EIP712Domain` (nome, versão, chainId, verifyingContract) e é inicializado no `constructor()`.
4. `number`: a variável de estado que armazena o valor, que pode ser modificado pelo método `permitStore()`.
5. `owner`: o dono do contrato, inicializado no `constructor()` e verificado na função `permitStore()`.

Além disso, o contrato `EIP712Storage` possui 3 funções:

1. Construtor: inicializa o `DOMAIN_SEPARATOR` e o `owner`.
2. `retrieve()`: lê o valor de `number`.
3. `permitStore`: verifica a assinatura EIP712 e modifica o valor de `number`. Primeiro, ele separa a assinatura em `r`, `s` e `v`. Em seguida, combina o `DOMAIN_SEPARATOR`, `STORAGE_TYPEHASH`, o endereço do chamador e o parâmetro `_num` de entrada para obter a mensagem assinada `digest`. Por fim, usando o método `recover()` da `ECDSA`, ele recupera o endereço do assinante e, se a assinatura for válida, atualiza o valor de `number`.

Abaixo está a implementação em Solidity do contrato `EIP712Storage`:

```solidity
// SPDX-License-Identifier: MIT
// By 0xAA 
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract EIP712Storage {
    using ECDSA for bytes32;

    bytes32 private constant EIP712DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");
    bytes32 private constant STORAGE_TYPEHASH = keccak256("Storage(address spender,uint256 number)");
    bytes32 private DOMAIN_SEPARATOR;
    uint256 number;
    address owner;

    constructor(){
        DOMAIN_SEPARATOR = keccak256(abi.encode(
            EIP712DOMAIN_TYPEHASH, // tipo hash
            keccak256(bytes("EIP712Storage")), // nome
            keccak256(bytes("1")), // versão
            block.chainid, // chain id
            address(this) // endereço do contrato
        ));
        owner = msg.sender;
    }

    /**
     * @dev Armazena valor na variável
     */
    function permitStore(uint256 _num, bytes memory _signature) public {
        // Verifica o comprimento da assinatura, onde 65 é o comprimento padrão das assinaturas r, s, v
        require(_signature.length == 65, "comprimento de assinatura inválido");
        bytes32 r;
        bytes32 s;
        uint8 v;
        // Atualmente só conseguimos obter os valores r, s, v através de assembly
        assembly {
            /*
            Os primeiros 32 bytes armazenam o comprimento da assinatura (regra de armazenamento de arrays dinâmicos)
            add(sig, 32) = ponteiro de sig + 32
            Isso é equivalente a pular os 32 primeiros bytes da assinatura
            mload(p) carrega os próximos 32 bytes de dados a partir do endereço de memória p
            */
            // Lê os próximos 32 bytes após o comprimento
            r := mload(add(_signature, 0x20))
            // Lê os próximos 32 bytes
            s := mload(add(_signature, 0x40))
            // Lê o último byte
            v := byte(0, mload(add(_signature, 0x60)))
        }

        // Obter o hash da mensagem assinada
        bytes32 digest = keccak256(abi.encodePacked(
            "\x19\x01",
            DOMAIN_SEPARATOR,
            keccak256(abi.encode(STORAGE_TYPEHASH, msg.sender, _num))
        )); 
        
        address signer = digest.recover(v, r, s); // Recupera o endereço do assinante
        require(signer == owner, "EIP712Storage: Assinatura inválida"); // Verifica a assinatura

        // Modifica a variável de estado
        number = _num;
    }

    /**
     * @dev Retorna o valor
     * @return valor de 'number'
     */
    function retrieve() public view returns (uint256){
        return number;
    }    
}
```

## Reproduzindo no Remix

1. Implante o contrato `EIP712Storage`.

2. Execute o arquivo `eip712storage.html`, alterando o `Endereço do Contrato` para o endereço do contrato `EIP712Storage` implantado. Em seguida, clique em `Conectar Metamask` e em `Assinar Permitir`. A assinatura deve ser feita usando a carteira do contrato implantada, como a carteira de teste do Remix:

    ```js
    Chave Pública: 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4
    Chave Privada: 503f38a9c967ed597e47fe25643985f032b072db8075426a92110f82df48dfcb
    ```

3. Chame o método `permitStore()` do contrato, inserindo o `_num` e a assinatura adequada para modificar o valor de `number`.

4. Chame o método `retrieve()` do contrato para ver o novo valor de `number`.

## Conclusão

Espero que você tenha compreendido bem esse método de assinatura mais avançado e seguro que é o EIP712. Ele é amplamente utilizado em diversos projetos, como Metamask, pares de tokens no Uniswap, DAI e muitos outros. Eu espero que você consiga dominar essa técnica com sucesso.

<!-- This file was translated using AI by repo_ai_translate. For more information, visit https://github.com/marcelojsilva/repo_ai_translate -->