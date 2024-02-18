# WTF Introdução Simples à Solidity: 12. Eventos

Eu tenho revisado Solidity recentemente para consolidar os detalhes e estou escrevendo uma série de "WTF Introdução Simples à Solidity" para iniciantes (os programadores experientes podem procurar por outros tutoriais). Atualizo de 1 a 3 lições por semana.

Twitter: [@0xAA_Science](https://twitter.com/0xAA_Science)

Comunidade: [Discord](https://discord.gg/5akcruXrsk) | [Grupo no WeChat](https://docs.google.com/forms/d/e/1FAIpQLSe4KGT8Sh6sJ7hedQRuIYirOoZK_85miz3dw7vA1-YjodgJ-A/viewform?usp=sf_link) | [Website WTF.academy](https://wtf.academy)

Todo o código e tutoriais estão disponíveis no Github: [github.com/AmazingAng/WTFSolidity](https://github.com/AmazingAng/WTF-Solidity)

---

Nesta lição, usaremos uma transferência de tokens ERC20 como exemplo para apresentar os eventos (`event`) em Solidity.

## Eventos

Os eventos em Solidity são uma abstração dos logs na EVM e têm duas características principais:

- Responsividade: Os aplicativos (como o [ethers.js](https://learnblockchain.cn/docs/ethers.js/api-contract.html#id18)) podem assinar e ouvir esses eventos através da interface RPC e responder a eles no frontend.
- Economia: Os eventos são uma forma econômica de armazenar dados na EVM, custando cerca de 2.000 `gas` por evento. Em comparação, armazenar uma nova variável na cadeia custa pelo menos 20.000 `gas`.

### Declarando Eventos

A declaração de um evento começa com a palavra-chave `event`, seguida pelo nome do evento e entre parênteses os tipos e nomes das variáveis que o evento registrará. Um exemplo é o evento `Transfer` do contrato de token ERC20:

```solidity
event Transfer(address indexed from, address indexed to, uint256 value);
```

Neste exemplo, o evento `Transfer` registra 3 variáveis: `from`, `to` e `value`, que correspondem ao endereço do remetente do token, ao endereço do destinatário e à quantidade transferida. As variáveis `from` e `to` têm a palavra-chave `indexed` antes delas, o que significa que serão armazenadas nos `topics` do log da máquina virtual Ethereum, facilitando pesquisas futuras.

### Emitted Events

Podemos emitir eventos dentro de funções. No exemplo abaixo, cada vez que a função `_transfer()` é chamada para realizar uma transferência, o evento `Transfer` é emitido e as variáveis correspondentes são registradas.

```solidity
function _transfer(
    address from,
    address to,
    uint256 amount
) external {

    _balances[from] = 10000000; // Dá ao endereço de transferência algum saldo inicial

    _balances[from] -=  amount; // subtrai a quantidade transferida do endereço remetente
    _balances[to] += amount; // adiciona a quantidade transferida ao endereço destinatário

    // Emite o evento
    emit Transfer(from, to, amount);
}
```

## Log EVM

A Máquina Virtual Ethereum (EVM) utiliza logs para armazenar eventos Solidity. Cada registro de log contém duas partes: os tópicos (`topics`) e os dados (`data`).

### Tópicos

A primeira parte do log são os tópicos, que são um array usado para descrever o evento e não pode ter mais do que 4 elementos. O primeiro elemento é a assinatura do evento (hash). Para o evento `Transfer` mencionado acima, o hash do evento é:

```solidity
keccak256("Transfer(address,address,uint256)")

//0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef
```

Além do hash do evento, os tópicos podem incluir até 3 parâmetros `indexed`, que são os endereços de transferência no caso do evento `Transfer`.

### Dados

Os parâmetros não marcados como `indexed` serão armazenados na parte de dados (`data`) do log e correspondem aos "valores" do evento. Esses parâmetros não podem ser pesquisados diretamente, mas podem armazenar dados de qualquer tamanho. Portanto, a parte de dados no log pode ser usada para armazenar estruturas de dados complexas, como arrays e strings, que excedem 256 bits. Mesmo que esses dados sejam armazenados na parte de tópicos como um hash, o espaço consumido na armazenagem por dados na parte de dados é menor do que nos tópicos.

## Demonstração no Remix

Vamos compilar e implantar o contrato `Event.sol`.

Depois, chamaremos a função `_transfer`.

### Consultando Eventos no Etherscan

Vamos tentar realizar uma transferência de 100 tokens na rede de testes Rinkeby usando a função `_transfer()`. Podemos consultar os detalhes do evento no Etherscan: [link para a transação](https://rinkeby.etherscan.io/tx/0x8cf87215b23055896d93004112bbd8ab754f081b4491cb48c37592ca8f8a36c7).

Clicando no botão `Logs`, podemos ver os detalhes do evento:

![Detalhes do Evento](https://images.mirror-media.xyz/publication-images/gx6_wDMYEl8_Gc_JkTIKn.png?height=980&width=1772)

Os `tópicos` contêm três elementos, sendo o `[0]` o hash do evento, o `1` e o `2` são informações dos dois parâmetros marcados como `indexed` que definimos, ou seja, os endereços do remetente e do destinatário da transferência. Os `dados` contêm o restante, ou seja, a quantia da transferência.

## Conclusão

Nesta lição, aprendemos como usar e consultar eventos em Solidity. Muitas ferramentas de análise blockchain, como a Nansen e a Dune Analysis, são baseadas em eventos.

