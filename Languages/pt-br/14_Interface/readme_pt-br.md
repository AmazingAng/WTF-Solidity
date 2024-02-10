# WTF Introdução Simples ao Solidity: 14. Contratos Abstratos e Interfaces

Recentemente, tenho revisado meus conhecimentos de Solidity para consolidar os detalhes e estou escrevendo uma "Introdução Simples ao Solidity" para iniciantes (programadores avançados podem buscar outros tutoriais). Atualizo de 1 a 3 lições por semana.

Twitter: [@0xAA_Science](https://twitter.com/0xAA_Science)

Comunidade: [Discord](https://discord.gg/5akcruXrsk) | [Grupo do WeChat](https://docs.google.com/forms/d/e/1FAIpQLSe4KGT8Sh6sJ7hedQRuIYirOoZK_85miz3dw7vA1-YjodgJ-A/viewform?usp=sf_link) | [Site oficial wtf.academy](https://wtf.academy)

Todo código e tutorial estão disponíveis no GitHub: [github.com/AmazingAng/WTFSolidity](https://github.com/AmazingAng/WTFSolidity)

-----

Nesta lição, vamos usar o contrato de interface `ERC721` para explicar contratos abstratos (`abstract`) e interfaces (`interface`) no Solidity, ajudando a entender melhor o padrão `ERC721`.

## Contratos Abstratos

Se um contrato Solidity possui pelo menos uma função não implementada, ou seja, uma função que falta conteúdo na chave `{}`, então esse contrato deve ser marcado como `abstract`, caso contrário haverá um erro de compilação. Além disso, as funções não implementadas devem ser marcadas como `virtual`, para que possam ser sobrescritas pelos contratos filhos. Por exemplo, no contrato de [ordenamento por inserção](https://github.com/AmazingAng/WTFSolidity/tree/main/10_InsertionSort) que vimos anteriormente, se ainda não decidimos como implementar a função de ordenação por inserção, podemos marcar o contrato como `abstract` e deixar outros preencherem esse detalhe.

```solidity
abstract contract InsertionSort {
    function insertionSort(uint[] memory a) public pure virtual returns (uint[] memory);
}
```

## Interfaces

As interfaces são semelhantes a contratos abstratos, mas não implementam funcionalidades. Regras para interfaces:

1. Não podem conter variáveis de estado.
2. Não podem conter construtores.
3. Não podem herdar de contratos que não sejam interfaces.
4. Todas as funções devem ser do tipo `external` e não devem ter um corpo de função.
5. Contratos que herdam de uma interface devem implementar todas as funções definidas na interface, exceto os eventos.

Embora as interfaces não implementem nenhuma funcionalidade, elas são muito importantes. As interfaces são o esqueleto de um contrato inteligente, definem as funcionalidades do contrato e como elas podem ser acionadas: se um contrato inteligente implementa uma determinada interface (como `ERC20` ou `ERC721`), outras DApps e contratos inteligentes sabem como interagir com ele. Isso porque as interfaces fornecem duas informações importantes:

1. O seletor `bytes4` para cada função do contrato e a assinatura da função `nomeDaFuncao(tipoDeCadaParametro)`.

2. O ID da interface (para mais informações, veja [EIP165](https://eips.ethereum.org/EIPS/eip-165)).

Além disso, as interfaces são equivalentes ao ABI (Application Binary Interface) de um contrato e podem ser convertidas uma na outra: compilando uma interface, podemos obter o ABI do contrato. Além disso, é possível converter um arquivo `json` ABI em um arquivo `sol` de interface usando a ferramenta [abi-to-sol](https://gnidan.github.io/abi-to-sol/).

Vamos usar a interface do contrato `IERC721` como exemplo, que define 3 eventos e 9 funções. Todos os NFTs que seguem o padrão `ERC721` implementam essas funções. Podemos ver que a diferença entre uma interface e um contrato convencional é que cada função de uma interface termina com `;` enquanto em um contrato terminaria com `{}`.

```solidity
interface IERC721 is IERC165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    
    function balanceOf(address owner) external view returns (uint256 balance);

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    function transferFrom(address from, address to, uint256 tokenId) external;

    function approve(address to, uint256 tokenId) external;

    function getApproved(uint256 tokenId) external view returns (address operator);

    function setApprovalForAll(address operator, bool _approved) external;

    function isApprovedForAll(address owner, address operator) external view returns (bool);

    function safeTransferFrom( address from, address to, uint256 tokenId, bytes calldata data) external;
}
```

### Eventos do IERC721

O `IERC721` possui 3 eventos, sendo que os eventos `Transfer` e `Approval` são encontrados também em contratos `ERC20`.

- Evento `Transfer`: emitido durante transferências para registrar o endereço de origem `from`, o endereço de destino `to` e o `tokenId`.
- Evento `Approval`: emitido durante autorizações para registrar o endereço do proprietário `owner`, o endereço autorizado `approved` e o `tokenId`.
- Evento `ApprovalForAll`: emitido durante autorizações em massa para registrar o endereço de origem `owner`, o endereço autorizado `operator` e se a autorização foi concedida (`approved`).

### Funções do IERC721

- `balanceOf`: retorna o saldo de NFTs de um determinado endereço `owner`.
- `ownerOf`: retorna o proprietário de um determinado `tokenId`.
- `transferFrom`: transfere um NFT normalmente, com os parâmetros sendo o endereço de origem `from`, o endereço de destino `to` e o `tokenId`.
- `safeTransferFrom`: transfere um NFT com segurança (se o destino for um contrato, o contrato precisa implementar a interface `ERC721Receiver`). Os parâmetros são o endereço de origem `from`, o endereço de destino `to` e o `tokenId`.
- `approve`: autoriza outro endereço a utilizar seu NFT. Os parâmetros são o endereço autorizado `approve` e o `tokenId`.
- `getApproved`: consulta qual endereço foi autorizado a utilizar um determinado `tokenId`.
- `setApprovalForAll`: concede autorização em massa dos seus NFTs para um determinado endereço `operator`.
- `isApprovedForAll`: verifica se um determinado endereço autorizou em massa outro endereço `operator`.
- `safeTransferFrom`: uma sobrecarga da função de transferência segura, com o parâmetro `data` adicionado.

### Quando usar interfaces?

Se soubermos que um contrato implementa a interface `IERC721`, não precisamos conhecer a implementação do código, apenas sabemos a função e como interagir com ele.

Por exemplo, o token `Bored Ape Yacht Club (BAYC)` é um NFT do tipo `ERC721`, que implementa as funções definidas na interface `IERC721`. Não precisamos saber o código fonte, apenas o endereço do contrato. Com a interface `IERC721`, podemos interagir com o contrato, como consultar o saldo de um endereço com `balanceOf()` ou transferir um NFT com `safeTransferFrom()`.

```solidity
contract interactBAYC {
    // Criar uma variável de interface para o contrato BAYC (na mainnet do Ethereum)
    IERC721 BAYC = IERC721(0xBC4CA0EdA7647A8aB7C2061c2E118A18a936f13D);

    // Consultar o saldo de BAYC de um endereço usando a função balanceOf()
    function balanceOfBAYC(address owner) external view returns (uint256 balance) {
        return BAYC.balanceOf(owner);
    }

    // Transferir BAYC de forma segura usando a função safeTransferFrom()
    function safeTransferFromBAYC(address from, address to, uint256 tokenId) external {
        BAYC.safeTransferFrom(from, to, tokenId);
    }
}
```

## Verificação no Remix

- Exemplo de contrato abstrato (um código de demonstração simples está na imagem abaixo)

  ![14-1](./img/14-1.png)
- Exemplo de interface (um código de demonstração simples está na imagem abaixo)

  ![14-2](./img/14-2.png)

## Conclusão

Nesta lição, expliquei os contratos abstratos (`abstract`) e interfaces (`interface`) no Solidity, que são úteis para escrever modelos e reduzir a repetição de código. Também discutimos a interface do contrato `IERC721` e como interagir com o contrato do Bored Ape Yacht Club (`BAYC`) usando essa interface.

<!-- This file was translated using AI by repo_ai_translate. For more information, visit https://github.com/marcelojsilva/repo_ai_translate -->