# WTF Segurança de Contratos Solidity: S14. Manipulação do Tempo de Bloco

Recentemente, tenho revisado meus conhecimentos de Solidity para consolidar detalhes e escrever um "WTF Solidity Introdução Rápida" para iniciantes (os programadores experientes podem encontrar outros tutoriais), com atualizações semanais de 1-3 lições.

Twitter: [@0xAA_Science](https://twitter.com/0xAA_Science) | [@WTFAcademy_](https://twitter.com/WTFAcademy_)

Comunidade: [Discord](https://discord.gg/5akcruXrsk) | [Grupo do WhatsApp](https://docs.google.com/forms/d/e/1FAIpQLSe4KGT8Sh6sJ7hedQRuIYirOoZK_85miz3dw7vA1-YjodgJ-A/viewform?usp=sf_link) | [Site Oficial wtf.academy](https://wtf.academy)

Todo o código e tutoriais estão disponíveis no GitHub: [github.com/AmazingAng/WTFSolidity](https://github.com/AmazingAng/WTFSolidity)

-----

Nesta lição, vamos falar sobre o ataque de manipulação do tempo de bloco em contratos inteligentes e como reproduzi-lo usando o Foundry. Antes da implementação do The Merge, os mineradores do Ethereum podiam manipular o tempo do bloco, o que poderia ser explorado se um contrato de sorteio dependesse do tempo do bloco para gerar números aleatórios.

## Tempo de Bloco

O tempo de bloco (block timestamp) é um valor `uint64` incluído no cabeçalho de cada bloco Ethereum, representando o timestamp UTC de quando o bloco foi criado, medida em segundos. Antes do The Merge, o Ethereum ajustava a dificuldade do bloco com base no poder de processamento dos mineradores, tornando o tempo para minerar um bloco variável, com uma média de 14.5 segundos por bloco. Os mineradores podiam manipular o tempo do bloco. Após o The Merge, a Ethereum mudou para um tempo fixo de 12 segundos por bloco, e os validadores não podem mais manipular o tempo do bloco.

Em Solidity, os desenvolvedores podem acessar o timestamp do bloco atual usando a variável global `block.timestamp`, que é do tipo `uint256`.

## Exemplo de Vulnerabilidade

Este exemplo é uma modificação do contrato apresentado em [WTF Segurança de Contratos Solidity: S07. Má Geração de Números Aleatórios](https://github.com/AmazingAng/WTF-Solidity/tree/main/32_Faucet). Alteramos a condição da função `mint()`: agora, a função de mintagem só terá sucesso se o tempo do bloco for divisível por 170.

```solidity
contract TimeManipulation is ERC721 {
    uint256 totalSupply;

    // Constructor to initialize the name and symbol of the NFT collection
    constructor() ERC721("", ""){}

    // Mint function: mint is only successful when block.timestamp is divisible by 170
    function luckyMint() external returns(bool success){
        if(block.timestamp % 170 == 0){
            _mint(msg.sender, totalSupply); // mint
            totalSupply++;
            success = true;
        }else{
            success = false;
        }
    }
}
```

## Reproduzindo o Ataque com o Foundry

O atacante precisa apenas manipular o tempo do bloco, definindo um valor divisível por 170, para conseguir criar um NFT com sucesso. Vamos usar o Foundry para reproduzir esse ataque, pois ele oferece códigos de trapaça para modificar o tempo do bloco. Se você não estiver familiarizado com o Foundry / códigos de trapaça, pode ler o [tutorial do Foundry](../Topics/Tools/TOOL07_Foundry/readme_pt-br.md) e o [Livro do Foundry](https://book.getfoundry.sh/forge/cheatcodes).

O código abaixo faz o seguinte:

1. Cria uma variável do contrato `TimeManipulation` chamada `nft`.
2. Cria um endereço de carteira `alice`.
3. Usa os códigos de trapaça `vm.warp()` para modificar o tempo do bloco para 169, o que resulta em uma falha na criação do NFT.
4. Usa os códigos de trapaça `vm.warp()` para modificar o tempo do bloco para 17000, o que resulta na criação bem-sucedida do NFT.

Código:

```solidity
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../src/TimeManipulation.sol";

contract TimeManipulationTest is Test {
    TimeManipulation public nft;

    // Computes address for a given private key
    address alice = vm.addr(1);

    function setUp() public {
        nft = new TimeManipulation();
    }

    // forge test -vv --match-test  testMint
    function testMint() public {
        console.log("Condition 1: block.timestamp % 170 != 0");
        // Set block.timestamp to 169
        vm.warp(169);
        console.log("block.timestamp: %s", block.timestamp);
        // Sets all subsequent calls' msg.sender to be the input address
        // until `stopPrank` is called
        vm.startPrank(alice);
        console.log("alice balance before mint: %s", nft.balanceOf(alice));
        nft.luckyMint();
        console.log("alice balance after mint: %s", nft.balanceOf(alice));

        // Set block.timestamp to 17000
        console.log("Condition 2: block.timestamp % 170 == 0");
        vm.warp(17000);
        console.log("block.timestamp: %s", block.timestamp);
        console.log("alice balance before mint: %s", nft.balanceOf(alice));
        nft.luckyMint();
        console.log("alice balance after mint: %s", nft.balanceOf(alice));
        vm.stopPrank();
    }
}

```

Após instalar o Foundry, cole o código da aula no diretório `src` e `test`, em seguida, execute os testes com o seguinte comando:

```shell
forge test -vv --match-test testMint
```

A saída mostrará que a criação do NFT foi bem-sucedida quando o tempo do bloco foi alterado para 17000.

## Conclusão

Nesta lição, exploramos o ataque de manipulação do tempo de bloco em contratos inteligentes e reproduzimos o ataque usando o Foundry. Antes do The Merge, os mineradores do Ethereum podiam manipular o tempo do bloco, o que poderia ser explorado se um contrato de sorteio dependesse do tempo do bloco para gerar números aleatórios. Após o The Merge, o Ethereum mudou para um tempo fixo de 12 segundos por bloco e os validadores não podem mais manipular o tempo do bloco. Portanto, esse tipo de ataque não será mais possível no Ethereum, mas ainda pode ser encontrado em outras blockchains.

<!-- This file was translated using AI by repo_ai_translate. For more information, visit https://github.com/marcelojsilva/repo_ai_translate -->