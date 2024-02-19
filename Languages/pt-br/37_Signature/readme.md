---
title: 37. Assinatura Digital
tags:
  - solidity
  - aplicação
  - wtfacademy
  - ERC721
  - Assinatura
---

# WTF Solidity Introdução Simples: 37. Assinatura Digital

Recentemente, tenho estudado solidity novamente para revisar alguns detalhes e escrever um "WTF Solidity Introdução Simples" para iniciantes (programadores experientes podem procurar outros tutoriais). Serão publicadas de 1 a 3 aulas por semana.

Siga-me no Twitter: [@0xAA_Science](https://twitter.com/0xAA_Science)

Junte-se à comunidade WTF Academy, temos um grupo no WeChat: [link](https://discord.gg/5akcruXrsk)

Todo o código e tutoriais estão disponíveis no GitHub (curso certificado com 1024 estrelas, comunidade NFT com 2048 estrelas): [github.com/AmazingAng/WTFSolidity](https://github.com/AmazingAng/WTFSolidity)

-----

Nesta aula, vamos dar uma breve introdução à assinatura digital `ECDSA` no Ethereum e como usá-la para criar uma lista branca de NFTs. A biblioteca `ECDSA` utilizada no código é uma versão simplificada da biblioteca de mesmo nome do OpenZeppelin.

## Assinatura Digital

Se você já negociou NFTs no OpenSea, está familiarizado com a assinatura digital. A imagem abaixo mostra a janela pop-up exibida pela carteira MetaMask (representada pela raposa) ao assinar uma transação. Essa janela prova que você possui a chave privada sem precisar divulgá-la publicamente.

![MetaMask Assinatura](./img/37-1.png)

O algoritmo de assinatura digital usado no Ethereum é chamado de Algoritmo de Assinatura Digital de Curva Elíptica (ECDSA, na sigla em inglês), que é um algoritmo de assinatura digital baseado em pares de chaves "chave privada-chave pública" em curvas elípticas. Ele desempenha três funções principais [fonte](https://en.wikipedia.org/wiki/Digital_signature):

1. **Autenticação de identidade**: prova que o signatário é o detentor da chave privada.
2. **Não repúdio**: o remetente não pode negar ter enviado a mensagem.
3. **Integridade**: verificação de que a mensagem não foi alterada durante a transmissão, por meio da verificação da assinatura digital gerada para a mensagem transmitida.

## Contrato ECDSA

O padrão ECDSA consiste em duas partes:

1. O signatário usa a `chave privada` (privada) para criar uma `assinatura` (pública) para a `mensagem` (pública).
2. Outras pessoas usam a `mensagem` (pública) e a `assinatura` (pública) para recuperar a `chave pública` do signatário (pública) e verificar a assinatura.

Vamos explicar essas duas partes usando a biblioteca `ECDSA`. Os valores usados neste tutorial para `chave privada`, `chave pública`, `mensagem`, `mensagem assinada do Ethereum` e `assinatura` são os seguintes:

```
Chave privada: 0x227dbb8586117d55284e26620bc76534dfbd2394be34cf4a09cb775d593b6f2b
Chave pública: 0xe16C1623c1AA7D919cd2241d8b36d9E79C1Be2A2
Mensagem: 0x1bf2c0ce4546651a1a2feb457b39d891a6b83931cc2454434f39961345ac378c
Mensagem assinada do Ethereum: 0xb42ca4636f721c7a331923e764587e98ec577cea1a185f60dfcc14dbb9bd900b
Assinatura: 0x390d704d7ab732ce034203599ee93dd5d3cb0d4d1d7c600ac11726659489773d559b12d220f99f41d17651b0c1c6a669d346a397f8541760d6b32a5725378b241c
```

### Criação de Assinatura

**1. Empacotar a mensagem**: No padrão ECDSA do Ethereum, a `mensagem` a ser assinada é o hash `keccak256` de um conjunto de dados, que é do tipo `bytes32`. Podemos empacotar qualquer conteúdo que desejamos assinar usando a função `abi.encodePacked()` e, em seguida, calcular o hash usando `keccak256()` para obter a `mensagem`. No exemplo abaixo, a `mensagem` é obtida a partir de uma variável do tipo `address` e uma variável do tipo `uint256`:

```solidity
    /*
     * Empacota o endereço de mint (tipo address) e o tokenId (tipo uint256) para obter a mensagem msgHash
     * _account: 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4
     * _tokenId: 0
     * Mensagem correspondente msgHash: 0x1bf2c0ce4546651a1a2feb457b39d891a6b83931cc2454434f39961345ac378c
     */
    function getMessageHash(address _account, uint256 _tokenId) public pure returns(bytes32){
        return keccak256(abi.encodePacked(_account, _tokenId));
    }
```

![Empacotando a mensagem](./img/37-2.png)

**2. Calcular a mensagem assinada do Ethereum**: A `mensagem` pode ser qualquer transação executável ou qualquer outra forma de dados. Para evitar que os usuários assinem transações maliciosas por engano, o EIP191 recomenda adicionar o caractere `"\x19Ethereum Signed Message:\n32"` antes da `mensagem` e, em seguida, calcular o hash `keccak256` novamente para obter a `mensagem assinada do Ethereum`. A mensagem processada pela função `toEthSignedMessageHash()` não pode ser usada para executar transações:

```solidity
    /**
     * @dev Retorna a mensagem assinada do Ethereum
     * `hash`: mensagem
     * Segue o padrão de assinatura do Ethereum: https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * e `EIP191`:https://eips.ethereum.org/EIPS/eip-191`
     * Adiciona o campo "\x19Ethereum Signed Message:\n32" para evitar que a assinatura seja uma transação executável.
     */
    function toEthSignedMessageHash(bytes32 hash) public pure returns (bytes32) {
        // O hash tem 32 bytes de comprimento
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }
```

A mensagem processada é:

```
Mensagem assinada do Ethereum: 0xb42ca4636f721c7a331923e764587e98ec577cea1a185f60dfcc14dbb9bd900b
```

![Mensagem assinada do Ethereum](./img/37-3.png)

**3-1. Assinatura usando uma carteira**: Na maioria das vezes, os usuários assinam mensagens dessa maneira. Após obter a `mensagem` a ser assinada, precisamos usar a carteira MetaMask para assiná-la. O método `personal_sign` do MetaMask converte automaticamente a `mensagem` em `mensagem assinada do Ethereum` e, em seguida, realiza a assinatura. Portanto, só precisamos fornecer a `mensagem` e a `conta da carteira do signatário`. É importante observar que a `conta da carteira do signatário` fornecida deve ser a mesma conta conectada ao MetaMask.

Primeiro, importe a `chave privada` do exemplo para a carteira MetaMask e abra a página do `console` do navegador: `Menu do Chrome - Mais Ferramentas - Ferramentas de Desenvolvedor - Console`. Com a carteira conectada (por exemplo, conectada ao OpenSea, caso contrário, ocorrerá um erro), digite as seguintes instruções uma por vez para realizar a assinatura:

```
ethereum.enable()
account = "0xe16C1623c1AA7D919cd2241d8b36d9E79C1Be2A2"
hash = "0x1bf2c0ce4546651a1a2feb457b39d891a6b83931cc2454434f39961345ac378c"
ethereum.request({method: "personal_sign", params: [account, hash]})
```

No resultado retornado (promessa `PromiseResult`), você verá a assinatura criada. Cada conta tem uma chave privada diferente, portanto, a assinatura gerada será diferente. A assinatura criada com a chave privada do exemplo é a seguinte:

```
0x390d704d7ab732ce034203599ee93dd5d3cb0d4d1d7c600ac11726659489773d559b12d220f99f41d17651b0c1c6a669d346a397f8541760d6b32a5725378b241c
```

![Assinatura usando uma carteira no console do navegador](./img/37-4.jpg)

**3-2. Assinatura usando web3.py**: Para chamadas em lote, é mais comum usar código para realizar a assinatura. Abaixo está um exemplo de implementação usando web3.py.

```py
from web3 import Web3, HTTPProvider
from eth_account.messages import encode_defunct

private_key = "0x227dbb8586117d55284e26620bc76534dfbd2394be34cf4a09cb775d593b6f2b"
address = "0x5B38Da6a701c568545dCfcB03FcB875f56beddC4"
rpc = 'https://rpc.ankr.com/eth'
w3 = Web3(HTTPProvider(rpc))

# Empacotar a mensagem
msg = Web3.solidityKeccak(['address','uint256'], [address,0])
print(f"Mensagem: {msg.hex()}")
# Construir a mensagem assinada
message = encode_defunct(hexstr=msg.hex())
# Assinar
signed_message = w3.eth.account.sign_message(message, private_key=private_key)
print(f"Assinatura: {signed_message['signature'].hex()}")
```

O resultado da execução é o seguinte. A mensagem calculada, a assinatura e os valores correspondem aos exemplos anteriores.

```
Mensagem: 0x1bf2c0ce4546651a1a2feb457b39d891a6b83931cc2454434f39961345ac378c
Assinatura: 0x390d704d7ab732ce034203599ee93dd5d3cb0d4d1d7c600ac11726659489773d559b12d220f99f41d17651b0c1c6a669d346a397f8541760d6b32a5725378b241c
```

### Verificação da Assinatura

Para verificar a assinatura, o verificador precisa ter acesso à `mensagem`, à `assinatura` e à `chave pública` usada para assinar. Podemos verificar a assinatura porque apenas o detentor da `chave privada` pode gerar uma assinatura como essa para uma transação, enquanto outras pessoas não podem.

**4. Recuperar a chave pública a partir da assinatura e da mensagem**: A `assinatura` é gerada por um algoritmo matemático. Neste caso, estamos usando uma `assinatura rsv`, que contém as informações `r, s, v`. A partir dessas informações e da `mensagem assinada do Ethereum`, podemos recuperar a `chave pública`. A função `recoverSigner()` abaixo implementa essas etapas, usando uma simples montagem inline para obter os valores `r, s, v` da `assinatura`:

```solidity
    // @dev Recupera o endereço do signatário a partir da _msgHash e da _signature
    function recoverSigner(bytes32 _msgHash, bytes memory _signature) internal pure returns (address){
        // Verifica o comprimento da assinatura, 65 é o comprimento padrão para assinaturas r, s, v
        require(_signature.length == 65, "invalid signature length");
        bytes32 r;
        bytes32 s;
        uint8 v;
        // Atualmente, só é possível usar assembly (montagem inline) para obter os valores r, s, v da assinatura
        assembly {
            /*
            Os primeiros 32 bytes armazenam o comprimento da assinatura (regra de armazenamento de arrays dinâmicos)
            add(sig, 32) = ponteiro para sig + 32
            Equivalente a pular os primeiros 32 bytes da assinatura
            mload(p) carrega os próximos 32 bytes de dados a partir do endereço de memória p
            */
            // Lê os próximos 32 bytes após o comprimento
            r := mload(add(_signature, 0x20))
            // Lê os próximos 32 bytes
            s := mload(add(_signature, 0x40))
            // Lê o último byte
            v := byte(0, mload(add(_signature, 0x60)))
        }
        // Usa a função ecrecover (função global) para recuperar o endereço do signatário a partir do _msgHash, r, s, v
        return ecrecover(_msgHash, v, r, s);
    }
```
Os parâmetros são:
```
_msgHash: 0xb42ca4636f721c7a331923e764587e98ec577cea1a185f60dfcc14dbb9bd900b
_signature: 0x390d704d7ab732ce034203599ee93dd5d3cb0d4d1d7c600ac11726659489773d559b12d220f99f41d17651b0c1c6a669d346a397f8541760d6b32a5725378b241c
```
![Recuperar a chave pública a partir da assinatura e da mensagem](./img/37-8.png)

**5. Comparar a chave pública e verificar a assinatura**: Agora, só precisamos comparar a `chave pública` recuperada com a `chave pública` do signatário `_signer`. Se forem iguais, a assinatura é válida; caso contrário, a assinatura é inválida:

```solidity
    /**
     * @dev Verifica se o endereço do signatário está correto usando ECDSA e retorna true se estiver correto
     * _msgHash é o hash da mensagem
     * _signature é a assinatura
     * _signer é o endereço do signatário
     */
    function verify(bytes32 _msgHash, bytes memory _signature, address _signer) internal pure returns (bool) {
        return recoverSigner(_msgHash, _signature) == _signer;
    }
```
Os parâmetros são:
```
_msgHash: 0xb42ca4636f721c7a331923e764587e98ec577cea1a185f60dfcc14dbb9bd900b
_signature: 0x390d704d7ab732ce034203599ee93dd5d3cb0d4d1d7c600ac11726659489773d559b12d220f99f41d17651b0c1c6a669d346a397f8541760d6b32a5725378b241c
_signer: 0xe16C1623c1AA7D919cd2241d8b36d9E79C1Be2A2
```
![Comparar a chave pública e verificar a assinatura](./img/37-9.png)

## Emitindo uma Lista Branca com Assinatura

Os projetos de NFT podem usar essa característica do ECDSA para emitir uma lista branca. Como a assinatura é feita fora da cadeia e não requer gás, esse método de emissão de lista branca é mais econômico do que o método de árvore de Merkle. O processo é simples: o projeto usa sua conta para assinar o endereço da lista branca (pode incluir o `tokenId` que o endereço pode criar). Em seguida, ao fazer o `mint`, o projeto verifica se a assinatura é válida usando o ECDSA e, se for, faz o `mint` para o endereço.

O contrato `SignatureNFT` implementa a emissão de uma lista branca de NFTs usando assinatura.

### Variáveis de Estado
O contrato possui duas variáveis de estado:
- `signer`: a `chave pública`, o endereço que assina a lista branca.
- `mintedAddress`: um `mapping` que registra os endereços que já receberam `mint`.

### Funções
O contrato possui quatro funções:
- O construtor inicializa o nome e o símbolo da coleção de NFTs, além do endereço da `chave pública` do ECDSA.
- A função `mint()` recebe o endereço `_account`, o `tokenId` e a `_signature` como parâmetros e verifica se a assinatura é válida: se for, o NFT com o `tokenId` é criado para o endereço `_account` e o endereço é registrado no `mintedAddress`. Ela chama as funções `getMessageHash()`, `ECDSA.toEthSignedMessageHash()` e `verify()`.

- A função `getMessageHash()` empacota o endereço de mint (`address`) e o `tokenId` (`uint256`) para obter a `mensagem`.

- A função `verify()` chama a função `verify()` da biblioteca `ECDSA` para realizar a verificação da assinatura ECDSA.

```solidity
contract SignatureNFT is ERC721 {
    address immutable public signer; // Chave pública, endereço que assina a lista branca
    mapping(address => bool) public mintedAddress;   // Registra os endereços que já receberam mint

    // Construtor, inicializa o nome, símbolo e endereço da chave pública do NFT
    constructor(string memory _name, string memory _symbol, address _signer)
    ERC721(_name, _symbol)
    {
        signer = _signer;
    }

    // Verifica a assinatura ECDSA e faz o mint
    function mint(address _account, uint256 _tokenId, bytes memory _signature)
    external
    {
        bytes32 _msgHash = getMessageHash(_account, _tokenId); // Empacota o _account e _tokenId para obter a mensagem
        bytes32 _ethSignedMessageHash = ECDSA.toEthSignedMessageHash(_msgHash); // Calcula a mensagem assinada do Ethereum
        require(verify(_ethSignedMessageHash, _signature), "Invalid signature"); // Verificação ECDSA passou
        require(!mintedAddress[_account], "Already minted!"); // Endereço não foi mintado antes
        _mint(_account, _tokenId); // Mint
        mintedAddress[_account] = true; // Registra o endereço como mintado
    }

    /*
     * Empacota o endereço de mint (tipo address) e o tokenId (tipo uint256) para obter a mensagem msgHash
     * _account: 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4
     * _tokenId: 0
     * Mensagem correspondente: 0x1bf2c0ce4546651a1a2feb457b39d891a6b83931cc2454434f39961345ac378c
     */
    function getMessageHash(address _account, uint256 _tokenId) public pure returns(bytes32){
        return keccak256(abi.encodePacked(_account, _tokenId));
    }

    // Verificação ECDSA, chama a função verify() da biblioteca ECDSA
    function verify(bytes32 _msgHash, bytes memory _signature)
    public view returns (bool)
    {
        return ECDSA.verify(_msgHash, _signature, signer);
    }
}
```

### Verificação no Remix

- Fora da cadeia, obtenha a `assinatura` usando a assinatura Ethereum para o endereço `_account` e o `tokenId = 0`. Os dados usados estão na seção <Contrato ECDSA>.

- Implante o contrato `SignatureNFT`, com os seguintes parâmetros:
```
_name: WTF Signature
_symbol: WTF
_signer: 0xe16C1623c1AA7D919cd2241d8b36d9E79C1Be2A2
```

![Implantação do contrato SignatureNFT](./img/37-5.png)

- Chame a função `mint()`, verificando a assinatura usando o ECDSA e fazendo o mint. Os parâmetros são:
```
_account: 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4
_tokenId: 0
_signature: 0x390d704d7ab732ce034203599ee93dd5d3cb0d4d1d7c600ac11726659489773d559b12d220f99f41d17651b0c1c6a669d346a397f8541760d6b32a5725378b241c
```

![Chamada da função mint()](./img/37-6.png)

- Chame a função `ownerOf()`, você verá que o `tokenId = 0` foi mintado com sucesso para o endereço `_account`. O contrato está funcionando corretamente!

![Alteração do proprietário do tokenId 0, o contrato está funcionando corretamente!](./img/37-7.png)

## Conclusão

Nesta aula, apresentamos a assinatura digital `ECDSA` no Ethereum, como criar e verificar assinaturas usando `ECDSA`, o contrato `ECDSA` e como usar a assinatura para emitir uma lista branca de NFTs. A biblioteca `ECDSA` usada é uma versão simplificada da biblioteca de mesmo nome do OpenZeppelin.
- Como a assinatura é feita fora da cadeia e não requer gás, esse método de emissão de lista branca é mais econômico do que o método de árvore de Merkle.
- No entanto, como os usuários precisam solicitar a assinatura por meio de uma interface centralizada, há uma perda parcial de descentralização.
- Uma vantagem adicional é que a lista branca pode ser dinamicamente alterada, em vez de ser pré-definida no contrato, pois a interface centralizada do projeto pode aceitar solicitações de novos endereços e fornecer assinaturas de lista branca.

.

