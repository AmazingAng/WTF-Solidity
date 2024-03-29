# WTF Solidity Security: S02. Colisão de Seletores

Recentemente, tenho revisitado meus estudos em Solidity para consolidar alguns detalhes e estou escrevendo um "WTF Solidity Introdução Simples" para ajudar os iniciantes (os mestres da programação podem buscar outros tutoriais). Atualizo de 1 a 3 lições por semana.

Twitter: [@0xAA_Science](https://twitter.com/0xAA_Science)

Comunidade: [Discord](https://discord.gg/5akcruXrsk) | [Grupo no WhatsApp](https://docs.google.com/forms/d/e/1FAIpQLSe4KGT8Sh6sJ7hedQRuIYirOoZK_85miz3dw7vA1-YjodgJ-A/viewform?usp=sf_link) | [Site oficial wtf.academy](https://wtf.academy)

Todo o código e tutoriais estão disponíveis no Github: [github.com/AmazingAng/WTFSolidity](https://github.com/AmazingAng/WTF-Solidity)

-----

Nesta lição, vamos falar sobre colisão de seletores, que foi uma das razões pelas quais a rede de pontes cross-chain Poly Network foi hackeada. Em agosto de 2021, contratos de pontes cross-chain da Poly Network nas redes ETH, BSC e Polygon foram hackeados, resultando em um prejuízo de até US$6,11 bilhões ([resumo](https://rekt.news/en/polynetwork-rekt/)). Este foi o maior hack da indústria blockchain em 2021 e o segundo maior da história, ficando atrás apenas do hack da ponte Ronin.

## Colisão de Seletores

Nos contratos inteligentes Ethereum, o seletor de funções é simplesmente os primeiros `4` bytes do valor hash da assinatura da função `"<nome da função>(<tipos de entrada da função>)"` (em hexadecimal). Quando um usuário chama uma função em um contrato, os primeiros `4` bytes dos dados de chamada (`calldata`) representam o seletor da função, determinando qual função está sendo chamada. Se não estiver familiarizado com isso, você pode ler a [Liçao 29: Seletor de Funções](../29_Selector/readme_pt-br.md) do WTF Solidity.

Devido ao fato de os seletores de funções serem de apenas `4` bytes, é muito fácil colidir com eles: ou seja, é possível encontrar duas funções diferentes que compartilham o mesmo seletor. Por exemplo, as funções `transferFrom(address,address,uint256)` e `gasprice_bit_ether(int128)` apresentam o mesmo seletor: `0x23b872dd`. Você também pode escrever um script para forçar essa colisão.

![](./img/S02-1.png)

Você pode usar os seguintes sites para procurar funções diferentes que compartilham o mesmo seletor:

1. https://www.4byte.directory/
2. https://sig.eth.samczsun.com/

Você também pode usar a ferramenta `Power Clash` para forçar essa colisão:

1. PowerClash: https://github.com/AmazingAng/power-clash

Em comparação, a probabilidade de colisão ao gerar chaves públicas de carteira, que possuem `64` bytes, é praticamente nula e muito mais segura.

## Resolvendo o Enigma da Esfinge com `0xAA`

Os habitantes do Ethereum desafiaram os deuses e enfureceram-os. A deusa Hera, para punir os habitantes do Ethereum, enviou a eles um ser misterioso chamado Esfinge, metade mulher, metade leão, com um enigma difícil. A Esfinge apresentava um enigma a cada viajante que passava: “O que tem quatro patas de manhã, duas ao meio-dia e três à noite, sendo o único ser vivo que utiliza diferentes quantidades de patas para andar. Quando tem mais patas, é quando sua velocidade e força são menores.” Aqueles que resolvessem o enigma poderiam passar sem problemas, enquanto os que não conseguissem seriam devorados. Todos os viajantes foram devorados pela Esfinge, e o povo do Ethereum entrava em desespero. A Esfinge validava a resposta correta utilizando o seletor `0x10cd2dc7`.

Em certa manhã, Édipo passou pelo local e, ao se deparar com a Esfinge, resolveu o enigma misterioso. Ele disse: “É a `function man()`! De manhã da vida, ele é uma criança que rasteja com quatro membros; ao meio-dia, torna-se um adulto e caminha com duas pernas; à noite, na velhice, ele usa uma bengala para caminhar, o que o faz ter três pernas.” Após desvendar o enigma, Édipo sobreviveu.

Naquela tarde, `0xAA` atravessou o mesmo caminho e deparou-se com a Esfinge, resolvendo mais uma vez o enigma misterioso. Ele disse: “É a `function peopleLduohW(uint256)`! De manhã da vida, ele é uma criança que rasteja com quatro membros; ao meio-dia, torna-se um adulto e caminha com duas pernas; à noite, na velhice, ele usa uma bengala para caminhar, o que o faz ter três pernas.” Ao resolver o enigma novamente, a Esfinge ficou extremamente irritada, escorregou e caiu da alta falésia, perecendo.

![](./img/S02-2.png)

## Exemplo de Contrato Vulnerável

### Contrato Vulnerável

A seguir, veremos um exemplo de contrato vulnerável. O contrato `SelectorClash` possui uma variável de estado `solved`, que é inicializada como `false`, e o atacante deve alterá-la para `true`. O contrato possui principalmente duas funções, com os nomes inspirados nos contratos vulneráveis Poly Network.

1. `putCurEpochConPubKeyBytes()`: O atacante deve chamar esta função para alterar o valor de `solved` para `true` e concluir o ataque. No entanto, esta função verifica se `msg.sender == address(this)`, o que significa que o chamador deve ser o próprio contrato. Precisamos verificar outras funções também.

2. `executeCrossChainTx()`: Esta função permite chamar funções internas do contrato, mas os tipos de parâmetros não se encaixam perfeitamente: a função alvo tem parâmetros do tipo `(bytes)`, enquanto os parâmetros nesta função são `(bytes,bytes,uint64)`.

```solidity
contract SelectorClash {
    bool public solved; // Indica se o ataque foi bem-sucedido

    // O atacante deve chamar esta função, com o msg.sender sendo obrigatoriamente o próprio contrato.
    function putCurEpochConPubKeyBytes(bytes memory _bytes) public {
        require(msg.sender == address(this), "Not Owner");
        solved = true;
    }

    // Vulnerável, o atacante pode alterar a variável _method para colidir com o seletor da função e concluir o ataque.
    function executeCrossChainTx(bytes memory _method, bytes memory _bytes, bytes memory _bytes1, uint64 _num) public returns(bool success){
        (success, ) = address(this).call(abi.encodePacked(bytes4(keccak256(abi.encodePacked(_method, "(bytes,bytes,uint64)"))), abi.encode(_bytes, _bytes1, _num)));
    }
}
```

### Método de Ataque

Nosso objetivo é usar a função `executeCrossChainTx()` para chamar a função `putCurEpochConPubKeyBytes()` do contrato, cujo seletor da função é `0x41973cd9`. Observamos que o seletor é calculado neste contrato utilizando o parâmetro `_method` e `"(bytes,bytes,uint64)"`. Portanto, precisamos escolher o valor adequado para `_method`, de modo que o seletor calculado seja igual a `0x41973cd9`, realizando um ataque bem-sucedido por meio de colisão de seletores.

No hack da Poly Network, o atacante gerou o `_method` `f1121318093`, que é o hash das primeiras `4` posições da função `f1121318093(bytes,bytes,uint64)`, resultando no mesmo seletor do alvo: `0x41973cd9`. Agora, o que precisamos fazer é converter `f1121318093` para o tipo `bytes`: `0x6631313231333138303933`, e então inseri-lo como parâmetro na função `executeCrossChainTx()`. Os outros `3` parâmetros podem ser preenchidos com `0x`, `0x` e `0`.

## Demonstração no `Remix`

1. Implante o contrato `SelectorClash`.
2. Chame `executeCrossChainTx()`, passando `0x6631313231333138303933`, `0x`, `0x`, `0`, para iniciar o ataque.
3. Verifique o valor da variável `solved`, que foi alterada para `true`, confirmando o sucesso do ataque.

## Conclusão

Nesta lição, discutimos a colisão de seletores de função, que foi uma das razões que levaram ao hack de US$6,1 bilhões da rede de pontes cross-chain Poly Network. Este ataque nos ensina:

1. Os seletores de função podem ser facilmente colididos, ou seja, é possível construir funções diferentes com o mesmo seletor mesmo ao alterar os tipos de parâmetros.

2. É essencial gerenciar adequadamente as permissões das funções do contrato, garantindo que funções de contratos com permissões especiais não possam ser chamadas por usuários.

