# WTF Introdução extremamente simples ao Solidity: 44. Bloqueio de tokens

Recentemente, tenho revisitado o estudo do Solidity para reforçar os detalhes e estou escrevendo uma série chamada "WTF Introdução extremamente simples ao Solidity" para iniciantes (os especialistas em programação podem buscar outros tutoriais). Estarei publicando de 1 a 3 lições por semana.

Twitter: [@0xAA_Science](https://twitter.com/0xAA_Science)

Comunidade: [Discord](https://discord.gg/5akcruXrsk) | [Grupo no WeChat](https://docs.google.com/forms/d/e/1FAIpQLSe4KGT8Sh6sJ7hedQRuIYirOoZK_85miz3dw7vA1-YjodgJ-A/viewform?usp=sf_link) | [Site oficial wtf.academy](https://wtf.academy)

Todo o código e tutoriais estão disponíveis no GitHub: [github.com/AmazingAng/WTFSolidity](https://github.com/AmazingAng/WTFSolidity)

---

Nesta lição, vamos falar sobre o que são tokens de provedor de liquidez LP, por que é importante bloquear a liquidez e como escrever um contrato simples de bloqueio de tokens ERC20.

## Bloqueio de Tokens

O Bloqueio de Tokens (Token Locker) é um tipo simples de contrato de bloqueio temporal que pode travar tokens em um contrato por um período de tempo determinado, permitindo que o beneficiário retire os tokens após o término do período de bloqueio. Normalmente, o bloqueio de tokens é usado para travar tokens de provedores de liquidez LP.

### O que são tokens de provedor de liquidez LP?

No blockchain, os usuários negociam tokens em bolsas descentralizadas (DEX), como a Uniswap. Diferente das bolsas centralizadas (CEX), as bolsas descentralizadas usam um mecanismo de Fabricante de Mercado Automático (AMM), no qual os usuários ou os donos de projetos precisam fornecer liquidez para o pool, para que outros usuários possam comprar e vender instantaneamente. Simplificando, os usuários/projetos precisam depositar pares de tokens (como ETH/DAI) no pool de liquidez e, em troca, a DEX emite tokens de provedor de liquidez LP como prova desse depósito, permitindo que eles recebam taxas.

### Por que é importante bloquear a liquidez?

Se um projeto remover os tokens LP do pool de liquidez sem aviso prévio, os tokens nas mãos dos investidores se tornam inutilizáveis e seu valor é reduzido a zero. Esse tipo de ação é conhecido como "rug-pull" e, somente em 2021, vários esquemas de "rug-pull" enganaram os investidores, resultando em mais de US$ 28 bilhões em criptomoedas perdidas.

No entanto, se os tokens LP estiverem bloqueados em um contrato de bloqueio de tokens, o projeto não pode sair do pool de liquidez prematuramente e não consegue fazer um "rug-pull". Portanto, o bloqueio de tokens pode impedir que o projeto saia muito cedo (é importante estar atento a possíveis "rug-pulls" após o término do bloqueio).

## Contrato de Bloqueio de Tokens

A seguir, vamos escrever um contrato `TokenLocker` que bloqueia tokens ERC20. Sua lógica é simples:

- O desenvolvedor define o tempo de bloqueio, o endereço do beneficiário e o contrato do token ao implantar o contrato.
- O desenvolvedor transfere os tokens para o contrato `TokenLocker`.
- Após o término do período de bloqueio, o beneficiário pode retirar os tokens do contrato.

*[Restante do texto omitido]*

<!-- This file was translated using AI by repo_ai_translate. For more information, visit https://github.com/marcelojsilva/repo_ai_translate -->