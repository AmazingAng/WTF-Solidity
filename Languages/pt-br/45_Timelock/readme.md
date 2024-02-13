# WTF Introdução Simples à Solidity: 45. Time Lock

Recentemente, tenho revisitado meus conhecimentos em Solidity para consolidar alguns detalhes e escrever um "WTF Introdução Simples à Solidity" para iniciantes (os mestres da programação podem procurar outros tutoriais). Atualizo de 1 a 3 lições por semana.

Twitter: [@0xAA_Science](https://twitter.com/0xAA_Science)

Comunidade: [Discord](https://discord.gg/5akcruXrsk) | [Grupo do WeChat](https://wechat.wtf.academy) | [Site oficial wtf.academy](https://wtf.academy)

Todo o código e tutorial está disponível no GitHub: [github.com/AmazingAng/WTFSolidity](https://github.com/AmazingAng/WTF-Solidity)

---

Nesta lição, vamos falar sobre o conceito de time lock (bloqueio de tempo) e contratos de time lock. O código é uma simplificação do contrato Timelock do Compound.

## Time Lock

O time lock (bloqueio de tempo) é um mecanismo de segurança comum em cofres de banco e outros contêineres de alta segurança. Ele funciona como um cronômetro, projetado para impedir que um cofre ou depósito seja aberto antes de um determinado tempo, mesmo que a pessoa com a senha correta tente abrir.

Na blockchain, o time lock é amplamente utilizado em DeFi e DAOs. Ele é um pedaço de código que pode bloquear algumas funcionalidades de um smart contract por um determinado período de tempo. Isso pode aumentar significativamente a segurança dos contratos inteligentes. Por exemplo, imagine que um hacker comprometa a multisig do Uniswap e esteja prestes a retirar o dinheiro do cofre, mas o contrato do cofre possui um time lock de 2 dias. O hacker terá que esperar 2 dias entre a criação da transação de retirada e a real execução dela. Durante esse período, a equipe do projeto pode encontrar uma solução e os investidores podem se proteger vendendo os tokens.

## Contrato de Time Lock

A seguir, vamos apresentar o contrato Timelock. Sua lógica não é complexa:

- Ao criar o contrato Timelock, os desenvolvedores podem definir um período de bloqueio e configurar o administrador como eles mesmos.
- O Timelock possui três funções principais:
    - Criar transações e adicioná-las à fila do time lock.
    - Executar as transações após o término do período de bloqueio.
    - Se arrepender e cancelar algumas transações na fila do time lock.
- As equipes de projeto geralmente designam o contrato Timelock como administrador de contratos importantes, como o cofre, e usam o Timelock para operá-los.
- O administrador do contrato Timelock é geralmente a carteira multisig da equipe, garantindo a descentralização.

### Eventos

O contrato Timelock possui quatro eventos:

- `QueueTransaction`: evento de criação e adição de transações à fila do time lock.
- `ExecuteTransaction`: evento de execução da transação após o período de bloqueio.
- `CancelTransaction`: evento de cancelamento da transação.
- `NewAdmin`: evento de alteração do endereço do administrador.

```solidity
// Eventos
event CancelTransaction(bytes32 indexed txHash, address indexed target, uint value, string signature, bytes data, uint executeTime);
event ExecuteTransaction(bytes32 indexed txHash, address indexed target, uint value, string signature, bytes data, uint executeTime);
event QueueTransaction(bytes32 indexed txHash, address indexed target, uint value, string signature, bytes data, uint executeTime);
event NewAdmin(address indexed newAdmin);
```

### Variáveis de Estado

O contrato Timelock possui quatro variáveis de estado:

- `admin`: endereço do administrador.
- `delay`: período de bloqueio.
- `GRACE_PERIOD`: tempo para expirar a transação. Se a transação estiver agendada para execução, mas dentro do `GRACE_PERIOD` não for executada, ela é considerada expirada.
- `queuedTransactions`: mapeamento do identificador `txHash` de transações na fila do time lock.

```solidity
// Variáveis de Estado
address public admin; // Endereço do administrador
uint public constant GRACE_PERIOD = 7 dias; // Tempo de expiração da transação
uint public delay; // Período de bloqueio (segundos)
mapping (bytes32 => bool) public queuedTransactions; // mapeamento dos txHash de transações na fila do time lock
```

### Modificadores

O contrato Timelock possui dois modificadores:

- `onlyOwner()`: garante que a função só possa ser executada pelo administrador.
- `onlyTimelock()`: garante que a função só possa ser executada pelo próprio contrato Timelock.

```solidity
// Modificador onlyOwner
modifier onlyOwner() {
    require(msg.sender == admin, "Timelock: Caller not admin");
    _;
}

// Modificador onlyTimelock
modifier onlyTimelock() {
    require(msg.sender == address(this), "Timelock: Caller not Timelock");
    _;
}
```

### Funções

O contrato Timelock possui sete funções:

- Construtor: inicializa o período de bloqueio e o endereço do administrador.
- `queueTransaction()`: cria uma transação e a adiciona à fila do time lock. São necessários os seguintes parâmetros para descrever uma transação completa:
    - `target`: endereço do contrato de destino.
    - `value`: valor em ETH a ser enviado.
    - `signature`: assinatura da função a ser chamada.
    - `data`: dados de chamada da transação.
    - `executeTime`: timestamp da blockchain para a execução da transação.
    
    Ao chamar essa função, certifique-se de que o tempo de execução da transação `executeTime` seja maior que o timestamp atual da blockchain somado ao período de bloqueio `delay`. A identificação única da transação é o hash de todos os parâmetros, calculado usando a função `getTxHash()`. A transação que entra na fila será atualizada na variável `queuedTransactions` e emitirá o evento `QueueTransaction`.
- `executeTransaction()`: executa a transação. Os parâmetros são os mesmos do `queueTransaction()`. A transação a ser executada deve estar na fila do time lock, atingir o tempo de execução e não ter expirado. A função de execução da transação utiliza o método de baixo nível `call` do Solidity, explicado na [lição 22](./22_Call/readme.md).
- `cancelTransaction()`: cancela a transação. Os parâmetros são os mesmos do `queueTransaction()`. A transação a ser cancelada deve estar na fila, e a variável `queuedTransactions` é atualizada, emitindo o evento `CancelTransaction`.
- `changeAdmin()`: modifica o endereço do administrador, só pode ser chamado pelo contrato Timelock.
- `getBlockTimestamp()`: obtém o timestamp atual da blockchain.
- `getTxHash()`: retorna o identificador da transação, que é o hash de muitos parâmetros da transação.

```solidity
// Construtor
constructor(uint delay_) {
    delay = delay_;
    admin = msg.sender;
}

// Função changeAdmin
function changeAdmin(address newAdmin) public onlyTimelock {
    admin = newAdmin;

    emit NewAdmin(newAdmin);
}

// Função queueTransaction
function queueTransaction(address target, uint256 value, string memory signature, bytes memory data, uint256 executeTime) public onlyOwner returns (bytes32) {
    // verificação se o tempo de execução da transação satisfaça o período de bloqueio
    require(executeTime >= getBlockTimestamp() + delay, "Timelock::queueTransaction: Estimated execution block must satisfy delay.");
    // cálculo do identificador único da transação
    bytes32 txHash = getTxHash(target, value, signature, data, executeTime);
    // adição da transação à fila
    queuedTransactions[txHash] = true;

    emit QueueTransaction(txHash, target, value, signature, data, executeTime);
    return txHash;
}

// Função executeTransaction
function executeTransaction(address target, uint256 value, string memory signature, bytes memory data, uint256 executeTime) public payable onlyOwner returns (bytes memory) {
    bytes32 txHash = getTxHash(target, value, signature, data, executeTime);
    // Verifica se a transação está na fila
    require(queuedTransactions[txHash], "Timelock::executeTransaction: Transaction hasn't been queued.");
    // Verifica se passou do tempo de execução
    require(getBlockTimestamp() >= executeTime, "Timelock::executeTransaction: Transaction hasn't surpassed time lock.");
    // Verifica se a transação não expirou
    require(getBlockTimestamp() <= executeTime + GRACE_PERIOD, "Timelock::executeTransaction: Transaction is stale.");
    // Remove a transação da fila
    queuedTransactions[txHash] = false;

    // Obtém os dados da chamada
    bytes memory callData;
    if (bytes(signature).length == 0) {
        callData = data;
    } else {
        callData = abi.encodePacked(bytes4(keccak256(bytes(signature))), data);
    }
    // Executa a transação usando o método call
    (bool success, bytes memory returnData) = target.call{value: value}(callData);
    require(success, "Timelock::executeTransaction: Transaction execution reverted.");

    emit ExecuteTransaction(txHash, target, value, signature, data, executeTime);

    return returnData;
}

// Função para obter o timestamp atual da blockchain
function getBlockTimestamp() public view returns (uint) {
    return block.timestamp;
}

// Função para obter o identificador da transação
function getTxHash(
    address target,
    uint value,
    string memory signature,
    bytes memory data,
    uint executeTime
) public pure returns (bytes32) {
    return keccak256(abi.encode(target, value, signature, data, executeTime));
}
```

## Demonstração no Remix

### 1. Deploy do contrato Timelock com um período de bloqueio de `120` segundos.

### 2. Tente chamar diretamente a função `changeAdmin()`, o que resultará em um erro.

### 3. Construa a transação para alterar o administrador.

### 4. Chame a função `queueTransaction` para adicionar a transação à fila do time lock.

### 5. Tente executar a transação dentro do período de bloqueio para ver que falha.

### 6. Execute a transação após o término do período de bloqueio.

### 7. Verifique o novo endereço do administrador.

O time lock é uma ferramenta poderosa para aumentar a segurança dos contratos inteligentes, reduzindo as chances de ataques de hackers e de "rug pull". Ele é amplamente utilizado em projetos DeFi e DAOs, como Uniswap e Compound. Se você investe em projetos, verifique se eles usam o time lock em suas operações.

<!-- This file was translated using AI by repo_ai_translate. For more information, visit https://github.com/marcelojsilva/repo_ai_translate -->