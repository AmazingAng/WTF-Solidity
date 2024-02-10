# WTF Introdução Simples à Solidity: 26. Excluindo Contratos

Eu recentemente tenho revisitado o estudo da Solidity para consolidar alguns detalhes e estou escrevendo uma série chamada "WTF Introdução Simples à Solidity" para iniciantes (programadores mais avançados podem procurar outros tutoriais). Atualizo com 1-3 lições por semana.

Twitter: [@0xAA_Science](https://twitter.com/0xAA_Science)

Comunidade: [Discord](https://discord.gg/5akcruXrsk) | [Grupo no WeChat](https://docs.google.com/forms/d/e/1FAIpQLSe4KGT8Sh6sJ7hedQRuIYirOoZK_85miz3dw7vA1-YjodgJ-A/viewform?usp=sf_link) | [Site oficial wtf.academy](https://wtf.academy)

Todo o código e tutoriais estão disponíveis no GitHub: [github.com/AmazingAng/WTFSolidity](https://github.com/AmazingAng/WTFSolidity)

---

## `selfdestruct`

O comando `selfdestruct` pode ser utilizado para excluir contratos inteligentes e transferir o restante de `ETH` do contrato para um endereço específico. O `selfdestruct` foi originalmente chamado de `suicide` (suicídio), mas devido à sensibilidade do termo, foi renomeado para `selfdestruct`. Na versão [v0.8.18](https://blog.soliditylang.org/2023/02/01/solidity-0.8.18-release-announcement/) do Solidity, a palavra-chave `selfdestruct` foi marcada como "não recomendada", pois em alguns casos pode resultar em semântica de contrato inesperada. No entanto, como ainda não há uma alternativa, por enquanto, apenas um aviso de compilação foi adicionado aos desenvolvedores. Mais informações podem ser encontradas em [EIP-6049](https://eips.ethereum.org/EIPS/eip-6049).

### Como usar `selfdestruct`

O uso de `selfdestruct` é bastante simples:

```solidity
selfdestruct(_addr);
```

Onde `_addr` é o endereço que receberá o restante de `ETH` do contrato. O endereço `_addr` não precisa ter funções `receive()` ou `fallback()` para receber `ETH`.

### Exemplo

```solidity
contract DeleteContract {

    uint public value = 10;

    constructor() payable {}

    receive() external payable {}

    function deleteContract() external {
        // Chamando selfdestruct para destruir o contrato e transferir o ETH restante para msg.sender
        selfdestruct(payable(msg.sender));
    }

    function getBalance() external view returns(uint balance){
        balance = address(this).balance;
    }
}
```

No contrato `DeleteContract`, temos uma variável de estado `public` chamada `value`, duas funções: `getBalance()` para obter o saldo do contrato em `ETH` e `deleteContract()` para autodestruir o contrato e transferir o `ETH` para o iniciador da ação.

Após implantar o contrato, transferimos 1 `ETH` para o contrato. Neste momento, `getBalance()` retornará 1 `ETH` e o valor `value` será 10.

Quando chamamos a função `deleteContract()`, o contrato é destruído e qualquer interação com as funções do contrato resultará em erro.

### Observações

1. Ao fornecer uma interface para destruir o contrato, é melhor limitar o acesso apenas ao proprietário do contrato, o que pode ser feito com modificadores de função como `onlyOwner`.
2. Após a destruição do contrato, qualquer tentativa de interagir com funções do contrato resultará em erro.
3. O uso frequente da funcionalidade `selfdestruct` em contratos pode gerar problemas de segurança e confiança. A função `selfdestruct` em um contrato abre vetores de ataque para invasores, como transferir tokens repetidamente para um contrato usando `selfdestruct` para economizar muito em taxas de GAS. Embora poucas pessoas façam isso, essa funcionalidade mina a confiança dos usuários no contrato.

### Verificação no Remix

1. Implantar o contrato e transferir 1 ETH, verifique o estado do contrato

    ![deployContract.png](./img/26-1.png)
2. Destruir o contrato, verifique o estado do contrato

    ![deleteContract.png](./img/26-2.png)

Observando o estado do contrato durante o teste, podemos ver que após a exclusão do contrato, o `ETH` é transferido para o endereço especificado. Qualquer tentativa de interagir com o contrato após a exclusão resultará em falha.

## Conclusão

`selfdestruct` é o botão de emergência dos contratos inteligentes, permitindo a destruição do contrato e a transferência do `ETH` restante para um endereço específico. Certamente, os fundadores do Ethereum devem ter se arrependido de não ter incluído `selfdestruct` no contrato do `The DAO` para interromper o ataque dos hackers.

<!-- This file was translated using AI by repo_ai_translate. For more information, visit https://github.com/marcelojsilva/repo_ai_translate -->