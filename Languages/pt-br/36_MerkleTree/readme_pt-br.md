# 36. Árvore de Merkle

Recentemente tenho revisitado o Solidity, reforçando os detalhes e escrevendo um "Guia Simplificado de Solidity" para iniciantes (os experts em programação podem procurar por outros tutoriais). Estarei lançando de 1 a 3 lições por semana.

Siga-me no Twitter: [@0xAA_Science](https://twitter.com/0xAA_Science)

Junte-se à comunidade de cientistas do WTF, com instruções para acessar o grupo do Discord [aqui](https://discord.gg/5akcruXrsk).

Todo o código e tutoriais estão disponíveis no GitHub (Certificado de Curso após 1024 stars, NFT do grupo após 2048 stars): [github.com/AmazingAng/WTFSolidity](https://github.com/AmazingAng/WTFSolidity)

---

Nesta lição, apresentarei a Árvore de Merkle e como usá-la para distribuir uma lista branca de NFTs.

## Árvore de Merkle
A Árvore de Merkle, também conhecida como árvore de hash, é uma tecnologia de criptografia fundamental para blockchain, amplamente utilizada no Bitcoin e Ethereum. É uma árvore criptográfica construída de baixo para cima, em que cada folha é o hash dos dados correspondentes, e cada não folha é o hash dos seus 2 nós filhos.

A Árvore de Merkle permite verificar eficaz e seguramente o conteúdo de estruturas de dados grandes (Merkle Proof). Para uma Árvore de Merkle com `N` folhas, verificar se um dado é válido (pertence às folhas da Árvore de Merkle) com o conhecimento da raiz (`root`) requer apenas `log(N)` dados (também chamados de `proof`), sendo muito eficiente. Se os dados estiverem incorretos ou o `proof` fornecido estiver errado, não será possível derivar a raiz (`root`).
No exemplo abaixo, a `Merkle Proof` da folha `L1` é o `Hash 0-1` e o `Hash 1`: com esses dois valores, é possível verificar se o valor de `L1` está nas folhas da Árvore de Merkle. Por quê?
Pois a partir da folha `L1`, podemos calcular o `Hash 0-0`. Sabendo o `Hash 0-1`, também podemos calcular o `Hash 0`. Então, usando o `Hash 0` e o `Hash 1`, conseguimos calcular o `Top Hash`, que é a raiz da árvore.

## Gerando uma Ávore de Merkle
Podemos usar um [site](https://lab.miguelmota.com/merkletreejs/example/) ou a biblioteca Javascript [merkletreejs](https://github.com/miguelmota/merkletreejs) para gerar uma Árvore de Merkle.

Aqui, vamos usar o site para gerar uma Árvore de Merkle com 4 endereços como folhas. Os endereços das folhas são:

```solidity
[
  "0x5B38Da6a701c568545dCfcB03FcB875f56beddC4", 
  "0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2",
  "0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db",
  "0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB"
]
```

Selecionamos as opções `Keccak-256`, `HashLeaves` e `SortPairs` no menu, e clicamos em `Compute` para gerar a Árvore de Merkle. A Árvore de Merkle expandida fica assim:

```
└─ Raiz: eeefd63003e0e702cb41cd0043015a6e26ddb38073cc6ffeb0ba3e808ba8c097
   ├─ 9d997719c0a5b5f6db9b8ac69a988be57cf324cb9fffd51dc2c37544bb520d65
   │  ├─ Folha0: 5931b4ed56ace4c46b68524cb5bcbf4195f1bbaacbe5228fbd090546c88dd229
   │  └─ Folha1: 999bf57501565dbd2fdcea36efa2b9aef8340a8901e3459f4a4c926275d36cdb
   └─ 4726e4102af77216b09ccd94f40daa10531c87c4d60bba7f3b3faf5ff9f19b3c
      ├─ Folha2: 04a10bfd00977f54cc3450c9b25c9b3a502a089eba0097ba35fc33c4ea5fcb54
      └─ Folha3: dfbe3e504ac4e35541bebad4d0e7574668e16fefa26cd4172f93e18b59ce9486
```

## Verificação da `Merkle Proof`
Através do site, podemos obter a `proof` para o `endereço0`, que são os valores dos nós azuis na imagem 2:

```solidity
[
  "0x999bf57501565dbd2fdcea36efa2b9aef8340a8901e3459f4a4c926275d36cdb",
  "0x4726e4102af77216b09ccd94f40daa10531c87c4d60bba7f3b3faf5ff9f19b3c"
]
```

Vamos usar a biblioteca `MerkleProof` para verificar:

```solidity
library MerkleProof {
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    function _hashPair(bytes32 a, bytes32 b) private pure returns (bytes32) {
        return a < b ? keccak256(abi.encodePacked(a, b)) : keccak256(abi.encodePacked(b, a));
    }
}
```

A biblioteca `MerkleProof` possui três funções:

1. A função `verify()`: verifica se o `leaf` pertence à Árvore de Merkle com raiz `root`. Ela chama a função `processProof()`.

2. A função `processProof()`: calcula a raiz da Árvore de Merkle usando o `proof` e o `leaf`. Ela chama a função `_hashPair()`.

3. A função `_hashPair()`: calcula o hash dos dois nós filhos (ordenados) em um nó não folha.

Vamos inserir o `endereço0`, a `root` e a `proof` na função `verify()`. Se os valores estiverem corretos, a função retornará `true`. Qualquer valor alterado resultará em `false`.

## Distribuição de uma lista branca de `NFT` usando `Merkle Tree`

Com uma lista branca de 800 endereços, a taxa de gás necessária para atualização pode facilmente exceder 1 ETH. Como a verificação da Árvore de Merkle pode ser feita com `proof` e `leaf` armazenados no backend, e no blockchain apenas a raiz precisa ser mantida, é muito econômico em termos de gás. Muitos projetos usam a Árvore de Merkle para distribuir listas brancas. Muitos NFTs padronizados pelo ERC721 e tokens padronizados pelo ERC20 distribuem listas brancas ou recompensas usando a Árvore de Merkle, como por exemplo, a otimização de distribuição.

Aqui, explicamos como utilizar o contrato `MerkleTree` para distribuir uma lista branca de NFTs:

```solidity
contract MerkleTree is ERC721 {
    bytes32 immutable public root; 
    mapping(address => bool) public mintedAddress;

    constructor(string memory name, string memory symbol, bytes32 merkleroot)
    ERC721(name, symbol)
    {
        root = merkleroot;
    }

    function mint(address account, uint256 tokenId, bytes32[] calldata proof)
    external
    {
        require(_verify(_leaf(account), proof), "Invalid merkle proof"); 
        require(!mintedAddress[account], "Already minted!"); 
        _mint(account, tokenId); 
        mintedAddress[account] = true; 
    }

    function _leaf(address account)
    internal pure returns (bytes32)
    {
        return keccak256(abi.encodePacked(account));
    }

    function _verify(bytes32 leaf, bytes32[] memory proof)
    internal view returns (bool)
    {
        return MerkleProof.verify(proof, root, leaf);
    }
}
```

O contrato `MerkleTree` herda o padrão `ERC721` e utiliza a biblioteca `MerkleProof`.

### Variáveis de Estado
O contrato possui duas variáveis de estado:
- `root` armazena a raiz da Árvore de Merkle, que é definida no momento da implantação.
- `mintedAddress` é um mapeamento que rastreia os endereços que já receberam a mintagem, marcando-os como `true`.

### Funções
O contrato possui quatro funções:
- O construtor inicia o contrato com o nome e símbolo do NFT, bem como com a raiz da Árvore de Merkle.
- A função `mint()` é usada para a mintagem de NFTs para os endereços da lista branca. Os parâmetros são o endereço da lista branca (`account`), o `tokenId` a ser mintado e a `proof`. Primeiro, verifica se o endereço está na lista branca, se sim, minta o NFT e marque o endereço como mintado no `mintedAddress`. Durante esse processo, as funções `_leaf()` e `_verify()` são chamadas.
- A função `_leaf()` calcula o hash do endereço do nó folha da Árvore de Merkle.
- A função `_verify()` chama a função `verify()` da biblioteca `MerkleProof` para verificar a Árvore de Merkle.

### Validação no Remix

Usamos os 4 endereços do exemplo anterior como lista branca e geramos uma Árvore de Merkle. Implantamos o contrato `MerkleTree` com 3 parâmetros:
```solidity
name = "WTF MerkleTree"
symbol = "WTF"
merkleroot = 0xeeefd63003e0e702cb41cd0043015a6e26ddb38073cc6ffeb0ba3e808ba8c097
```

A seguir, usamos a função `mint` para dar o NFT para o endereço0, com os 3 parâmetros:
```solidity
account = 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4
tokenId = 0
proof = [   "0x999bf57501565dbd2fdcea36efa2b9aef8340a8901e3459f4a4c926275d36cdb",   "0x4726e4102af77216b09ccd94f40daa10531c87c4d60bba7f3b3faf5ff9f19b3c" ]
```

Podemos verificar o sucesso do contrato ao usar a função `ownerOf` para verificar se o NFT do `tokenId` 0 foi dado para o endereço0. A operação do contrato foi um sucesso!

Se tentarmos usar a função mint novamente, o endereço já estará marcado como `true` em `mintedAddress` e a transação será interrompida devido ao motivo `"Already minted!"`.

## Conclusão

Nesta lição, abordamos o conceito de Árvore de Merkle, como gerar uma Árvore de Merkle simples, como verificar uma Árvore de Merkle em um smart contract e como utilizar isso para distribuir uma lista branca de NFTs.

Na prática, Árvores de Merkle mais complexas podem ser geradas e gerenciadas usando a biblioteca `merkletreejs` em JavaScript, e apenas a raiz precisa ser armazenada no blockchain, economizando muito gás. Muitos projetos optam por usar a Árvore de Merkle para distribuir listas brancas.

<!-- This file was translated using AI by repo_ai_translate. For more information, visit https://github.com/marcelojsilva/repo_ai_translate -->