## 16 dicas de segurança para programadores Solidity do projeto Metamask

**Texto original**: [Solidity Best Practices for Smart Contract Security](https://consensys.net/blog/developers/solidity-best-practices-for-smart-contract-security/)

**Autor original**: Consensys (projeto Metamask)

**Tradução**: [0xAA](https://twitter.com/0xAA_Science)

**Github**: [WTFSolidity](https://github.com/AmazingAng/WTFSolidity)


> Introdução:
>
> Este é um blog escrito pelo projeto Metamask (Consensys) em agosto de 2020, sobre segurança de contratos inteligentes. Ele fornece 16 dicas de segurança para programadores Solidity, incluindo exemplos de código.
>
> Este artigo foi escrito há um ano e meio, quando a versão do Solidity era 0.5, agora já estamos na versão 0.8, muitas funções são diferentes. Mas muitas das dicas ainda são aplicáveis até hoje e me ajudaram muito depois de lê-las. Não encontrei uma tradução em chinês online, então fiz uma tradução simples e marquei as possíveis diferenças de versão para ajudar os desenvolvedores chineses a aprenderem.
>
> Os conceitos de segurança deste artigo também estão incorporados no tutorial de introdução ao Solidity WTF.
>
> Por 0xAA

Se você já está familiarizado com os conceitos de segurança de contratos inteligentes e está lidando com as peculiaridades da EVM, é hora de considerar algumas práticas de segurança específicas da linguagem de programação Solidity. Nesta visão geral, vamos nos concentrar nas melhores práticas de desenvolvimento seguro em Solidity, que também podem ser úteis para o desenvolvimento de contratos inteligentes em outras linguagens.

Vamos começar.

## 1. Use `assert(), require(), revert()` corretamente
As funções auxiliares `assert` e `require` podem ser usadas para verificar condições e lançar exceções se as condições não forem atendidas.

A função `assert` deve ser usada apenas para testar erros internos e verificar invariantes.

A função `require` deve ser usada para garantir que condições válidas sejam atendidas, como entradas ou variáveis de estado do contrato, ou para verificar o valor de retorno de chamadas a contratos externos. (0xAA: O Solidity introduziu a funcionalidade de erro personalizado na versão 0.8.21, então use `require` antes dessa versão e `revert-error` depois dessa versão para garantir que as condições válidas sejam atendidas)

Seguir esse padrão permite que ferramentas de análise formal verifiquem que nenhuma operação inválida seja executada: isso significa que nenhum invariante é violado no código e é verificado formalmente.
```
pragma solidity ^0.5.0;

contract Sharer {
    function sendHalf(address payable addr) public payable returns (uint balance) {
        require(msg.value % 2 == 0, "Even value required."); //Require() pode ter uma mensagem personalizada
        uint balanceBeforeTransfer = address(this).balance;
        (bool success, ) = addr.call.value(msg.value / 2)("");
        require(success);
        // If success is false, it will revert. The following always holds.
        assert(address(this).balance == balanceBeforeTransfer - msg.value / 2); // used for internal error checking
        return address(this).balance;
    }
}
```

## 2. Modificadores devem ser usados apenas para verificação
O código dentro de um modificador é executado antes do corpo da função, portanto, qualquer alteração de estado ou chamada externa violará o padrão "Checks-Effects-Interactions". Além disso, os desenvolvedores podem não perceber essas declarações, pois o código do modificador pode estar distante da declaração da função. Por exemplo, uma chamada externa dentro de um modificador pode levar a um ataque de reentrada:
```
contract Registry {
    address owner;

    function isVoter(address _addr) external returns(bool) {
        // Code
    }
}

contract Election {
    Registry registry;

    modifier isEligible(address _addr) {
        require(registry.isVoter(_addr));
        _;
    }

    function vote() isEligible(msg.sender) public {
        // Code
    }
}
```
Neste caso, o contrato `Registry` pode realizar um ataque de reentrada chamando `Election.vote()` dentro de `isVoter()`.

Observação: Use modificadores para substituir verificações de condições repetitivas em várias funções, como `isOwner()`, em vez de usar `require` ou `revert` dentro da função. Isso torna o código do seu contrato mais legível e mais fácil de auditar.

## 3. Cuidado com a divisão de inteiros
Todas as divisões de inteiros são arredondadas para baixo para o número inteiro mais próximo. Se você precisa de uma precisão maior, considere usar multiplicação ou armazenar o numerador e o denominador separadamente.

(No futuro, o Solidity terá tipos de ponto flutuante, o que tornará isso mais fácil.)
```
// bad
uint x = 5 / 2; // Result is 2, all integer division rounds DOWN to the nearest integer
```
O uso de multiplicação evita arredondamentos e você precisa levar em consideração essa multiplicação ao usar x no futuro:
```
// good
uint multiplier = 10;
uint x = (5 * multiplier) / 2;
```
Armazenar o numerador e o denominador significa que você pode calcular o resultado em uma cadeia de frações numerador/denominador:
```
// good
uint numerator = 5;
uint denominator = 2;
```

## 4. Considere o trade-off entre contratos abstratos (`abstract`) e interfaces (`interface`)
Interfaces e contratos abstratos fornecem maneiras personalizáveis e reutilizáveis de definir métodos para contratos inteligentes. As interfaces, introduzidas no Solidity 0.4.11, são semelhantes aos contratos abstratos, mas não podem implementar nenhuma funcionalidade. As interfaces também têm limitações, como não poder acessar o armazenamento ou herdar de outras interfaces, o que geralmente torna os contratos abstratos mais úteis. No entanto, as interfaces são úteis para projetar contratos antes de serem implementados. Além disso, é importante lembrar que, se um contrato herdar de um contrato abstrato, ele deve implementar todas as funcionalidades não implementadas, caso contrário, ele também será abstrato.

## 5. Função de fallback (função de fallback)
> 0xAA: Na versão 0.5.0 do Solidity, ainda não havia a função `receive` e a função `fallback` era declarada diretamente como `function()`. Para um tutorial sobre a função `fallback` na versão mais recente, consulte o [link](https://mirror.xyz/wtfacademy.eth/EroVZqHW1lfJFai3umiu4tb9r1ZbDVPOYC-puaZklAw)
### Mantenha a função de fallback simples
Quando um contrato recebe uma mensagem sem parâmetros (ou nenhuma função corresponde) ou quando é acionado por `.send()` ou `.transfer()`, a função de fallback é chamada. Quando acionada por `.send()` ou `.transfer()`, a função de fallback só pode acessar 2300 gas. Se você deseja executar mais cálculos, use a função apropriada.
```
// bad
function() payable { balances[msg.sender] += msg.value; }

// good
function deposit() payable external { balances[msg.sender] += msg.value; }

function() payable { require(msg.data.length == 0); emit LogDepositReceived(msg.sender); }
```

### Verifique o comprimento dos dados na função de fallback
Como a função de fallback é chamada não apenas em transferências de ether normais (sem `msg.data`), mas também quando não há nenhuma função correspondente chamada, é importante verificar se os dados estão vazios. Caso contrário, se o seu contrato for usado incorretamente e chamar uma função inexistente, o chamador não perceberá.
```
// bad
function() payable { emit LogDepositReceived(msg.sender); }

// good
function() payable { require(msg.data.length == 0); emit LogDepositReceived(msg.sender); }
```

## 6. Marque explicitamente as funções e variáveis de estado como `payable`
A partir do Solidity 0.4.0, cada função que recebe ether deve usar o modificador `payable`, caso contrário, a transação será revertida se `msg.value > 0`.

**Observação**: algo que pode não ser óbvio é que o modificador `payable` só se aplica a chamadas de contratos externos. Se eu chamar uma função não `payable` em um contrato `payable`, essa função não falhará, mesmo que `msg.value` não seja zero.

## 7. Marque explicitamente a visibilidade das funções e variáveis de estado
Marque explicitamente a visibilidade das funções e variáveis de estado. As funções podem ser especificadas como `external`, `public`, `internal` ou `private`. Entenda as diferenças entre elas, por exemplo, `external` pode ser suficiente em vez de `public`. Quanto às variáveis de estado, `external` não é necessário. Marcar explicitamente a visibilidade tornará mais fácil capturar erros sobre quem pode chamar a função ou acessar a variável.

1. Funções `external` fazem parte da interface do contrato. A função `external` `f` não pode ser chamada internamente (ou seja, `f()` não funciona, mas `this.f()` funciona). Funções externas são mais eficientes ao receber grandes quantidades de dados.

2. Funções `public` fazem parte da interface do contrato e podem ser chamadas tanto internamente quanto por mensagem. Para variáveis de estado públicas, uma função `getter` automática será gerada.

3. Funções e variáveis de estado `internal` só podem ser acessadas internamente, sem usar `this`.

4. Funções e variáveis de estado `private` são visíveis apenas para o contrato em que são definidas e não são visíveis nas contratos derivados. **Observação**: todo o conteúdo dentro de um contrato é visível para todos os observadores externos à blockchain, mesmo as variáveis `private`.

```
// bad
uint x; // the default is internal for state variables, but it should be made explicit
function buy() { // the default is public
    // public code
}

// good
uint private y;
function buy() external {
    // only callable externally or using this.buy()
}

function utility() public {
    // callable externally, as well as internally: changing this code requires thinking about both cases.
}

function internalAction() internal {
    // internal code
}
```

## 8. Bloqueie as instruções de compilação para uma versão específica do compilador
Os contratos devem ser implantados usando a mesma versão e sinalizadores do compilador com os quais foram mais testados. Bloquear o pragma ajuda a garantir que os contratos não sejam implantados acidentalmente com uma versão mais recente do compilador que possa ter erros não descobertos de maior risco. Os contratos também podem ser implantados por outras pessoas e o pragma indica a versão do compilador que o autor original esperava.

```
// bad
pragma solidity ^0.4.4;


// good
pragma solidity 0.4.4;
```
**Observação**: versões flutuantes do pragma (ou seja, `^0.4.25`) podem ser compiladas com `0.4.26-nightly.2018.9.25`, mas não devem ser usadas para compilar código de produção com versões `nightly`.

**Aviso**: quando um contrato é destinado a ser usado por outros desenvolvedores, é possível permitir que a instrução Pragma flutue, como em bibliotecas ou pacotes EthPM. Caso contrário, os desenvolvedores precisarão atualizar manualmente a instrução de compilação para compilar localmente.

## 9. Use eventos para monitorar a atividade do contrato
É útil ter uma maneira de monitorar a atividade de um contrato após a implantação. Uma maneira de fazer isso é examinar todas as transações do contrato, mas isso pode não ser suficiente, pois as chamadas de mensagem entre contratos não são registradas na blockchain. Além disso, ele mostra apenas os parâmetros de entrada e não as alterações reais no estado. Os eventos também podem ser usados para acionar funcionalidades na interface do usuário.

```
contract Charity {
    mapping(address => uint) balances;

    function donate() payable public {
        balances[msg.sender] += msg.value;
    }
}

contract Game {
    function buyCoins() payable public {
        // 5% goes to charity
        charity.donate.value(msg.value / 20)();
    }
}
```
Aqui, o contrato `Game` faz uma chamada interna para `Charity.donate()`. Essa transação não aparecerá na lista de transações externas do `Charity`, apenas nas transações internas.

Os eventos são uma maneira conveniente de registrar o que acontece em um contrato. Os eventos emitidos permanecem na blockchain junto com outros dados do contrato e podem ser auditados no futuro. Aqui está uma melhoria para o exemplo acima, usando eventos para fornecer um histórico de doações para a instituição de caridade.
```
contract Charity {
    // define event
    event LogDonate(uint _amount);

    mapping(address => uint) balances;

    function donate() payable public {
        balances[msg.sender] += msg.value;
        // emit event
        emit LogDonate(msg.value);
    }
}

contract Game {
    function buyCoins() payable public {
        // 5% goes to charity
        charity.donate.value(msg.value / 20)();
    }
}
```
Aqui, todas as transações para `Charity`, independentemente de serem chamadas diretamente pelo contrato ou não, serão exibidas na lista de eventos desse contrato.

**Observação**: é preferível usar as estruturas atualizadas do Solidity. Use estruturas/alias preferidas, como `selfdestruct` (em vez de `suicide`) e `keccak256` (em vez de `sha3`). Padrões semelhantes, como `require(msg.sender.send(1 ether))`, também podem ser simplificados usando `transfer()`, como `msg.sender.transfer(1 ether)`. Consulte o log de alterações do Solidity para obter mais alterações semelhantes.

## 10. Esteja ciente de que as funções "built-in" podem ser ocultadas
Atualmente, é possível ocultar as variáveis globais internas no Solidity. Isso permite que um contrato substitua a funcionalidade interna embutida, como `msg` e `revert()`. Embora isso seja intencional, pode ser enganoso para os usuários do contrato sobre o comportamento real do contrato.

```
contract PretendingToRevert {
    function revert() internal constant {}
}

contract ExampleContract is PretendingToRevert {
    function somethingBad() public {
        revert();
    }
}
```
Os usuários do contrato (e auditores) devem estar cientes do código-fonte completo do aplicativo que pretendem usar.

## 11. Evite o uso de `tx.origin`
Nunca use `tx.origin` para autenticação, pois outro contrato pode ter um método para chamar seu contrato (por exemplo, um usuário tem algum fundo) e seu contrato autenticará a transação porque seu endereço está em `tx.origin`.

```
contract MyContract {

    address owner;

    function MyContract() public {
        owner = msg.sender;
    }

    function sendTo(address receiver, uint amount) public {
        require(tx.origin == owner);
        (bool success, ) = receiver.call.value(amount)("");
        require(success);
    }

}

contract AttackingContract {

    MyContract myContract;
    address attacker;

    function AttackingContract(address myContractAddress) public {
        myContract = MyContract(myContractAddress);
        attacker = msg.sender;
    }

    function() public {
        myContract.sendTo(attacker, msg.sender.balance);
    }

}
```
Você deve usar a autenticação `msg.sender` (se outro contrato chamar seu contrato, `msg.sender` será o endereço desse contrato, não o endereço do usuário).

**Aviso**: Além de problemas de autenticação, `tx.origin` pode ser removido do protocolo Ethereum no futuro, portanto, o código que usa `tx.origin` será incompatível com versões futuras. Vitalik: 'Não assuma que `tx.origin` continuará existindo.

Também vale a pena mencionar que, ao usar `tx.origin`, você limitará a interoperabilidade entre contratos, pois um contrato que usa `tx.origin` não pode ser usado por outro contrato, pois os contratos não podem ser `tx.origin`.

## 12. Dependência de carimbo de data/hora
Ao usar o carimbo de data/hora para executar funcionalidades críticas em um contrato, existem três considerações principais, especialmente quando as operações envolvem transferência de fundos.

### Operações de carimbo de data/hora
Observe que o carimbo de data/hora de um bloco pode ser manipulado pelos mineradores. Considere este contrato:
```
uint256 constant private salt =  block.timestamp;

function random(uint Max) constant private returns (uint256 result){
    //get the best seed for randomness
    uint256 x = salt * 100/Max;
    uint256 y = salt * block.number/(salt % 5) ;
    uint256 seed = block.number/3 + (salt % 300) + Last_Payout + y;
    uint256 h = uint256(block.blockhash(seed));

return uint256((h / x)) % Max + 1; //random number between 1 and Max
}
```

When a contract uses the timestamp to seed a random number, miners can actually publish a timestamp within 15 seconds after the block is verified, effectively allowing miners to pre-calculate an option that gives them a better chance of winning. Timestamps are not random and should not be used in this context.

## 13. The 15-second rule
The Yellow Paper (Ethereum's formal specification) does not specify how many blocks can drift in time, but it does specify that each timestamp should be greater than its parent timestamp. Popular Ethereum protocol implementations like Geth and Parity reject blocks with future timestamps that are more than 15 seconds ahead. Therefore, a good rule of thumb when evaluating timestamp usage is: if the scale of your time-sensitive events can vary by 15 seconds and still maintain integrity, then you can use `block.timestamp`.

### Avoid using `block.number` as a timestamp
You can use the `block.number` property and average block time to estimate time increments, but this is not future-proof evidence as block times can change (e.g., due to chain reorganizations and the difficulty bomb). However, in short-lived sales that only last a few days, the 15-second rule allows people to have more reliable time estimates.

## 14. Multiple inheritance considerations
When using multiple inheritance in Solidity, it is important to understand how the compiler constructs the inheritance graph.

```
contract Final {
    uint public a;
    function Final(uint f) public {
        a = f;
    }
}

contract B is Final {
    int public fee;

    function B(uint f) Final(f) public {
    }
    function setFee() public {
        fee = 3;
    }
}

contract C is Final {
    int public fee;

    function C(uint f) Final(f) public {
    }
    function setFee() public {
        fee = 5;
    }
}

contract A is B, C {
  function A() public B(3) C(5) {
      setFee();
  }
}
```
When deploying the contracts, the compiler linearizes the inheritance from right to left (after the `is` keyword, the parents are listed from most basic class to most derived). This is the linearization of contract `A`:

`Final <- B <- C <- A`

The linearization result will yield a value of `fee = 5` because `C` is the closest derived contract. This may seem obvious, but imagine if `C` is able to hide critical functions, reorder boolean clauses, and cause developers to write exploitable contracts. Static analysis currently does not raise issues with overridden functions, so manual checks must be performed.

To help contribute, Solidity's Github has a [project](https://github.com/ethereum/solidity/projects/9#card-8027020) that contains all inheritance-related issues.

## 15. Use interface types instead of address to guarantee type safety
When a function takes a contract address as a parameter, it is best to pass an interface or contract type instead of a plain `address`. This is because if the function is called elsewhere in the source code, the compiler will provide additional type safety guarantees.

Here, we see two options:
```
contract Validator {
    function validate(uint) external returns(bool);
}

contract TypeSafeAuction {
    // good
    function validateBet(Validator _validator, uint _value) internal returns(bool) {
        bool valid = _validator.validate(_value);
        return valid;
    }
}

contract TypeUnsafeAuction {
    // bad
    function validateBet(address _addr, uint _value) internal returns(bool) {
        Validator validator = Validator(_addr);
        bool valid = validator.validate(_value);
        return valid;
    }
}
```
The benefits of using the `TypeSafeAuction` contract can be seen in the example below. If `validateBet()` uses an `address` parameter or contract type instead of the `Validator` contract type, the compiler will throw this error when the function is called elsewhere in the source code:
```
contract NonValidator{}

contract Auction is TypeSafeAuction {
    NonValidator nonValidator;

    function bet(uint _value) {
        bool valid = validateBet(nonValidator, _value); // TypeError: Invalid type for argument in function call.
                                                        // Invalid implicit conversion from contract NonValidator
                                                        // to contract Validator requested.
    }
}
```

## 16. Avoid using `extcodesize` to check for externally owned accounts
The following modifier (or similar checks) is often used to verify if a call is coming from an externally owned account (EOA) or a contract account:
```
// bad
modifier isNotContract(address _a) {
  uint size;
  assembly {
    size := extcodesize(_a)
  }
    require(size == 0);
     _;
}
```

The idea is simple: if an address contains code, it is not an EOA but a contract account. However, contracts do not have available source code during construction. This means that during the constructor runtime, it can call other contracts, but `extcodesize` will return zero for its address. Here's a minimal example showing how to bypass this check:
```
contract OnlyForEOA {    
    uint public flag;

    // bad
    modifier isNotContract(address _a){
        uint len;
        assembly { len := extcodesize(_a) }
        require(len == 0);
        _;
    }

    function setFlag(uint i) public isNotContract(msg.sender){
        flag = i;
    }
}

contract FakeEOA {
    constructor(address _a) public {
        OnlyForEOA c = OnlyForEOA(_a);
        c.setFlag(1);
    }
}
```
Because the contract address can be precomputed, if it checks for an empty address at block n but is deployed after block n, it will still fail.

**Warning**: This issue is subtle. If your goal is to prevent other contracts from calling your contract, then the `extcodesize` check may be sufficient. Another approach is to check the value (`tx.origin == msg.sender`), although this also has drawbacks.

In other cases, `extcodesize` may serve you well. Describing all these cases is beyond the scope here. Understand the basic behavior of the EVM and use your judgment.

