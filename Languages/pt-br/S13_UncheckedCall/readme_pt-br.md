# WTF Solidity Segurança do Contrato: S13. Chamadas de baixo nível não verificadas

Recentemente, tenho revisado meus conhecimentos em Solidity para consolidar detalhes e escrever um "Guia Simplificado de Solidity WTF" para iniciantes (programadores experientes podem procurar outros tutoriais), com atualizações semanais de 1 a 3 aulas.

Twitter: [@0xAA_Science](https://twitter.com/0xAA_Science) | [@WTFAcademy_](https://twitter.com/WTFAcademy_)

Comunidade: [Discord](https://discord.gg/5akcruXrsk) | [Grupo no WhatsApp](https://docs.google.com/forms/d/e/1FAIpQLSe4KGT8Sh6sJ7hedQRuIYirOoZK_85miz3dw7vA1-YjodgJ-A/viewform?usp=sf_link) | [Site oficial wtf.academy](https://wtf.academy)

Todo o código e tutoriais são de código aberto no GitHub: [github.com/AmazingAng/WTFSolidity](https://github.com/AmazingAng/WTFSolidity)

-----

Nesta aula, vamos abordar uma vulnerabilidade comum em contratos inteligentes, que é a falta de verificação em chamadas de baixo nível (low-level calls). Quando uma chamada de baixo nível falha, a transação não é revertida, e se o retorno dessa chamada não for verificado, problemas graves podem surgir.

## Chamadas de Baixo Nível

As chamadas de baixo nível em Ethereum incluem `call()`, `delegatecall()`, `staticcall()`, e `send()`. Essas funções se comportam de forma diferente das demais funções em Solidity: quando uma exceção ocorre, elas não são propagadas para o nível superior e não resultam em uma reversão completa da transação; em vez disso, elas retornam um valor booleano `false` indicando a falha na chamada. Portanto, se o retorno de uma chamada de baixo nível não for verificado, o código no nível superior continuará a ser executado. Para mais detalhes sobre chamadas de baixo nível, consulte a [aulas 20-23 do WTF Solidity](https://github.com/AmazingAng/WTF-Solidity).

Uma situação comum é o uso do `send()`: alguns contratos usam o `send()` para enviar `ETH`, porém o `send()` tem um limite de gas abaixo de 2300, caso contrário falha. Quando o destino da chamada tem uma função de callback complexa, o consumo de gas pode exceder 2300, resultando em falha. Se neste momento o retorno da função não for verificado no nível superior, a transação continuará a ser executada, causando problemas inesperados. Em 2016, o jogo "King of Ether" teve problemas de reembolso devido a essa vulnerabilidade ([relatório post-mortem](https://www.kingoftheether.com/postmortem.html)).

![](./img/S13-1.png)

## Exemplo de Vulnerabilidade

### Contrato do Banco

Este contrato é uma modificação do contrato bancário apresentado na aula `S01 Ataque de Reentrada`. Ele inclui uma variável de estado `balanceOf` para registrar os saldos em Ethereum de todos os usuários, e três funções:
- `deposit()`: função de depósito para adicionar `ETH` no contrato do banco e atualizar o saldo do usuário.
- `withdraw()`: função de saque para transferir o saldo do chamador. Os passos são semelhantes aos da história mencionada anteriormente: verificar o saldo, atualizar o saldo e transferir. **Observação: esta função não verifica o retorno do `send()`, então o saque pode falhar sem zerar o saldo!**
- `getBalance()`: função para obter o saldo em Ethereum do contrato do banco.

```solidity
contract UncheckedBank {
    mapping (address => uint256) public balanceOf;    // Mapping de saldos

    // Deposita ether e atualiza o saldo
    function deposit() external payable {
        balanceOf[msg.sender] += msg.value;
    }

    // Retira todo o ether do msg.sender
    function withdraw() external {
        // Obtém o saldo
        uint256 balance = balanceOf[msg.sender];
        require(balance > 0, "Saldo insuficiente");
        balanceOf[msg.sender] = 0;
        // Chamada de baixo nível não verificada
        bool success = payable(msg.sender).send(balance);
    }

    // Obtém o saldo do contrato do banco
    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }
}
```

## Contrato de Ataque

Criamos um contrato de ataque que representa um azarado depositante, cuja tentativa de saque falha, mas o saldo é zerado: a função de callback do contrato `receive()` com `revert()` faz a transação ser revertida e não aceita `ETH`; no entanto, a função de saque `withdraw()` do contrato pode ser chamada com sucesso, limpando o saldo.

```solidity
contract Attack {
    UncheckedBank public bank; // Endereço do contrato do Banco

    // Inicializa o endereço do contrato do Banco
    constructor(UncheckedBank _bank) {
        bank = _bank;
    }
    
    // Função de callback que falha ao receber ETH
    receive() external payable {
        revert();
    }

    // Função de depósito, o valor do depósito é passado como msg.value
    function deposit() external payable {
        bank.deposit{value: msg.value}();
    }

    // Função de saque, mesmo que a chamada tenha sucesso, o saque na verdade falha
    function withdraw() external payable {
        bank.withdraw();
    }

    // Obtém o saldo deste contrato
    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }
}
```

## Reproduzindo no Remix

1. Implemente o contrato `UncheckedBank`.

2. Implemente o contrato `Attack`, passando o endereço do contrato `UncheckedBank` como parâmetro no construtor.

3. Chame a função `deposit()` do contrato `Attack` para depositar `1 ETH`.

4. Chame a função `withdraw()` do contrato `Attack` para sacar os fundos, a chamada é feita com sucesso.

5. Em seguida, chame a função `balanceOf()` do contrato `UncheckedBank` e a função `getBalance()` do contrato `Attack`. Apesar do saque bem-sucedido na etapa anterior, o saldo da conta do depositante falha.

## Medidas Preventivas

Você pode adotar as seguintes medidas para prevenir a vulnerabilidade de chamadas de baixo nível não verificadas:

1. Verifique o retorno de chamadas de baixo nível. No contrato bancário mencionado anteriormente, podemos corrigir o `withdraw()`.
    ```solidity
    bool success = payable(msg.sender).send(balance);
    require(success, "Falha ao enviar ETH!");
    ```

2. Ao transferir `ETH` em contratos, use `call()` e implemente proteção contra reentrância.

3. Utilize a biblioteca [Address](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Address.sol) da OpenZeppelin, que encapsula chamadas de baixo nível verificadas.

## Conclusão

Exploramos a vulnerabilidade das chamadas de baixo nível não verificadas e as medidas preventiva. Chamadas de baixo nível em Ethereum (call, delegatecall, staticcall, send) retornam `false` em caso de falha, mas não revertam a transação completamente. Se o retorno não for verificado, podem ocorrer problemas inesperados.

<!-- This file was translated using AI by repo_ai_translate. For more information, visit https://github.com/marcelojsilva/repo_ai_translate -->