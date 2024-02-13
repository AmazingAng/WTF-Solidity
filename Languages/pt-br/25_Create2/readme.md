# WTF Solidity Simplificado: 25. CREATE2

Recentemente, tenho revisado meus conhecimentos em Solidity para reforçar os detalhes e criar um guia "WTF Solidity Simplificado" para iniciantes (programadores avançados podem procurar outros tutoriais). A atualização é feita semanalmente com 1-3 lições.

Twitter: [@0xAA_Science](https://twitter.com/0xAA_Science)

Comunidade: [Discord](https://discord.gg/5akcruXrsk) | [Grupo do WeChat](https://docs.google.com/forms/d/e/1FAIpQLSe4KGT8Sh6sJ7hedQRuIYirOoZK_85miz3dw7vA1-YjodgJ-A/viewform?usp=sf_link) | [Site wtf.academy](https://wtf.academy)

Todo código e tutoriais estão disponíveis no Github: [github.com/AmazingAng/WTFSolidity](https://github.com/AmazingAng/WTF-Solidity)

---

## CREATE2

O opcode `CREATE2` nos permite prever o endereço de um contrato antes de implantá-lo na rede Ethereum. O `Uniswap` utiliza o `CREATE2` para criar contratos de pares, em vez do `CREATE`. Nesta lição, vou explicar o uso do `CREATE2`.

### Como é calculado o endereço com CREATE

Os contratos inteligentes podem ser criados por outros contratos ou contas normais usando o opcode `CREATE`. Em ambos os casos, o endereço do novo contrato é calculado da mesma maneira: pelo hash do endereço do criador (normalmente o endereço da carteira de implantação ou o endereço do contrato) e do nonce (o número total de transações enviadas desse endereço, no caso de um contrato é o total de contratos criados, incrementando o nonce a cada criação de contrato).

```text
Novo endereço = hash(endereço do criador, nonce)
```

O endereço do criador não muda, mas o nonce pode mudar ao longo do tempo, o que torna difícil prever o endereço de um contrato criado com `CREATE`.

### Como é calculado o endereço com CREATE2

O `CREATE2` foi projetado para permitir que o endereço do contrato seja independente de eventos futuros. Não importa o que aconteça na blockchain no futuro, você pode implantar o contrato em um endereço previamente calculado. O endereço do contrato criado com `CREATE2` é determinado por quatro partes:

- `0xFF`: uma constante para evitar conflitos com o `CREATE`
- `EndereçoCriador`: o endereço do contrato atual que chama o `CREATE2`
- `salt` (sal): um valor `bytes32` especificado pelo criador, usado para influenciar o endereço do novo contrato
- `initcode`: o bytecode inicial do novo contrato (código de criação do contrato e parâmetros do construtor)

```text
Novo endereço = hash("0xFF", EndereçoCriador, salt, initcode)
```

O `CREATE2` garante que, se o criador usar `CREATE2` com um `salt` e o `initcode` do contrato específicos, o contrato será armazenado no `novo endereço`.

## Como usar o `CREATE2`

A sintaxe do `CREATE2` é semelhante à do `CREATE` mencionada anteriormente. Você simplesmente precisa instanciar um novo contrato passando o parâmetro `salt` adicional:

```solidity
Contract x = new Contract{salt: _salt, value: _value}(params)
```

Onde `Contract` é o nome do contrato a ser criado, `x` é o objeto do contrato (endereço), `_salt` é o sal especificado; se o construtor aceitar ETH no momento da criação, você pode transferir `_value` ETH durante a criação, `params` são os parâmetros necessários para o construtor do novo contrato.

## Uniswap2 Simplificado

Semelhante à lição anterior, vamos usar o `CREATE2` para implementar uma versão simplificada do `Uniswap`.

### `Pair`

```solidity
contract Pair {
    address public factory; // endereço do contrato de fábrica
    address public token0; // token 1
    address public token1; // token 2

    constructor() payable {
        factory = msg.sender;
    }

    // chamado uma vez pela fábrica no momento da implantação
    function initialize(address _token0, address _token1) external {
        require(msg.sender == factory, 'UniswapV2: FORBIDDEN'); // verificação suficiente
        token0 = _token0;
        token1 = _token1;
    }
}
```

O contrato `Pair` é simples e contém 3 variáveis de estado: `factory`, `token0` e `token1`.

O construtor `constructor` define o endereço da fábrica como sendo o remetente da mensagem na implantação. A função `initialize` é chamada uma vez pela fábrica no momento da criação do contrato `Pair`, atualizando `token0` e `token1` com os endereços dos dois tokens do par.

### `PairFactory2`

```solidity
contract PairFactory2 {
    mapping(address => mapping(address => address)) public getPair; // mapeia dois endereços de tokens para o endereço do par
    address[] public allPairs; // armazena todos os endereços dos pares

    function createPair2(address tokenA, address tokenB) external returns (address pairAddr) {
        require(tokenA != tokenB, 'IDENTICAL_ADDRESSES'); // evita endereços idênticos
        // calcula o salt com os endereços tokenA e tokenB
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA); // ordena os tokens em ordem crescente
        bytes32 salt = keccak256(abi.encodePacked(token0, token1));
        // implanta um novo contrato usando create2
        Pair pair = new Pair{salt: salt}(); 
        // chama o método initialize do novo contrato
        pair.initialize(tokenA, tokenB);
        // atualiza o mapa de endereços
        pairAddr = address(pair);
        allPairs.push(pairAddr);
        getPair[tokenA][tokenB] = pairAddr;
        getPair[tokenB][tokenA] = pairAddr;
    }
}
```

O contrato da fábrica (`PairFactory2`) possui duas variáveis de estado: `getPair`, que mapeia dois endereços de tokens para o endereço do par, e `allPairs`, que armazena os endereços de todos os pares.

O contrato `PairFactory2` possui apenas uma função `createPair2` que utiliza o `CREATE2` para criar um novo contrato `Pair` com base nos endereços dos dois tokens `tokenA` e `tokenB` fornecidos. O código é simples:

```solidity
Pair pair = new Pair{salt: salt}(); 
```

É assim que se cria contratos usando `CREATE2`. E o `salt` é o hash dos dois tokens:

```solidity
bytes32 salt = keccak256(abi.encodePacked(token0, token1));
```

### Cálculo antecipado do endereço do `Pair`

```solidity
// calcula antecipadamente o endereço do contrato de par
function calculateAddr(address tokenA, address tokenB) public view returns(address predictedAddress){
    require(tokenA != tokenB, 'IDENTICAL_ADDRESSES'); // evita endereços idênticos
    // calcula o salt com os endereços tokenA e tokenB
    (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA); // ordena os tokens em ordem crescente
    bytes32 salt = keccak256(abi.encodePacked(token0, token1));
    // método de cálculo de endereço hash()
    predictedAddress = address(uint160(uint(keccak256(abi.encodePacked(
        bytes1(0xff),
        address(this),
        salt,
        keccak256(type(Pair).creationCode)
        )))));
}
```

Criamos uma função `calculateAddr` para calcular antecipadamente o endereço do `Pair` com base nos tokens `tokenA` e `tokenB. Isso nos permite verificar se o endereço calculado antecipadamente é o mesmo do endereço real.

Você pode implantar o contrato `PairFactory2` e chamar o `createPair2` com os seguintes endereços como argumentos para ver o endereço do par criado e compará-lo com o endereço calculado antecipadamente:

```text
Endereço do WBNB: 0x2c44b726ADF1963cA47Af88B284C06f30380fC78
Endereço do PEOPLE na rede BSC: 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c
```

### Como validar no Remix

1. Calcule o endereço do contrato `Pair` com os hashes dos endereços WBNB e PEOPLE.
2. Chame a função `createPair2` da `PairFactory2` passando os endereços WBNB e PEOPLE como parâmetros para obter o endereço do par criado.
3. Compare os endereços dos contratos.

![create2_remix_test.png](./img/25-1.png)

## Aplicações práticas do `CREATE2`

1. Reservar endereços de carteira para novos usuários em exchanges.

2. `Factory` alimentado por `CREATE2` em projetos como o `Uniswap V2`, onde a criação de pares ocorre na `Factory` por meio da chamada de `CREATE2`. Isso permite que o `Router` calcule o endereço do `pair` diretamente usando `(tokenA, tokenB)`, sem a necessidade de chamar `Factory.getPair(tokenA, tokenB)` em outra chamada de contrato.

## Conclusão

Nesta lição, falamos sobre os princípios e utilização do opcode `CREATE2`, e implementamos uma versão simplificada do `Uniswap` utilizando essa funcionalidade, além de calcular antecipadamente os endereços dos pares. O `CREATE2` nos permite determinar o endereço de um contrato antes de implantá-lo, sendo fundamental para alguns projetos de `layer2`.

<!-- This file was translated using AI by repo_ai_translate. For more information, visit https://github.com/marcelojsilva/repo_ai_translate -->