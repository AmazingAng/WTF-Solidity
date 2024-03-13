// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

contract Timelock{
    // Eventos
    // Evento de cancelamento de transação
    event CancelTransaction(bytes32 indexed txHash, address indexed target, uint value, string signature,  bytes data, uint executeTime);
    // Evento de execução de transação
    event ExecuteTransaction(bytes32 indexed txHash, address indexed target, uint value, string signature,  bytes data, uint executeTime);
    // Evento de criação e entrada de transação na fila
    event QueueTransaction(bytes32 indexed txHash, address indexed target, uint value, string signature, bytes data, uint executeTime);
    // Evento para alterar o endereço do administrador
    event NewAdmin(address indexed newAdmin);

    // Variável de estado
    // Endereço do administrador
    // Prazo de validade da transação, transações expiradas serão canceladas
    // Tempo de bloqueio da transação (em segundos)
    // txHash para bool, registra todas as transações na fila de bloqueio de tempo
    
    // modificador onlyOwner
    modifier onlyOwner() {
        require(msg.sender == admin, "Timelock: Caller not admin");
        _;
    }

    // modificador onlyTimelock
    modifier onlyTimelock() {
        require(msg.sender == address(this), "Timelock: Caller not Timelock");
        _;
    }

    /**
     * @dev Construtor, inicializa o tempo de bloqueio da transação (em segundos) e o endereço do administrador
     */
    constructor(uint delay_) {
        delay = delay_;
        admin = msg.sender;
    }

    /**
     * @dev Altera o endereço do administrador, o chamador deve ser o contrato Timelock.
     */
    function changeAdmin(address newAdmin) public onlyTimelock {
        admin = newAdmin;

        emit NewAdmin(newAdmin);
    }

    /**
     * @dev Cria uma transação e a adiciona à fila de bloqueio de tempo.
     * @param target: Endereço do contrato de destino
     * @param value: Quantidade de eth a ser enviada
     * @param signature: Assinatura da função a ser chamada
     * @param data: Dados da chamada, contendo os parâmetros
     * @param executeTime: Timestamp da blockchain para a execução da transação
     *
     * Requisito: executeTime deve ser maior que o timestamp atual da blockchain + delay
     */
    function queueTransaction(address target, uint256 value, string memory signature, bytes memory data, uint256 executeTime) public onlyOwner returns (bytes32) {
        // Verificação: O tempo de execução da transação atende ao tempo de bloqueio
        require(executeTime >= getBlockTimestamp() + delay, "Timelock::queueTransaction: Estimated execution block must satisfy delay.");
        // Calcular o identificador único da transação: o hash de um conjunto de coisas
        bytes32 txHash = getTxHash(target, value, signature, data, executeTime);
        // Adicionar transação à fila
        queuedTransactions[txHash] = true;

        emit QueueTransaction(txHash, target, value, signature, data, executeTime);
        return txHash;
    }

    /**
     * @dev Cancelar uma transação específica.
     *
     * Requisitos: A transação está na fila de bloqueio de tempo.
     */
    function cancelTransaction(address target, uint256 value, string memory signature, bytes memory data, uint256 executeTime) public onlyOwner{
        // Calcular o identificador único da transação: o hash de um conjunto de coisas
        bytes32 txHash = getTxHash(target, value, signature, data, executeTime);
        // Verificando: a transação está na fila de bloqueio de tempo
        require(queuedTransactions[txHash], "Timelock::cancelTransaction: Transaction hasn't been queued.");
        // Remover a transação da fila
        queuedTransactions[txHash] = false;

        emit CancelTransaction(txHash, target, value, signature, data, executeTime);
    }

    /**
     * @dev Executa uma transação específica.
     *
     * Requisitos:
     * 1. A transação está na fila de bloqueio de tempo.
     * 2. Chegou a hora de executar a transação.
     * 3. A transação não está expirada.
     */
    function executeTransaction(address target, uint256 value, string memory signature, bytes memory data, uint256 executeTime) public payable onlyOwner returns (bytes memory) {
        bytes32 txHash = getTxHash(target, value, signature, data, executeTime);
        // Verificando se a transação está na fila de bloqueio de tempo
        require(queuedTransactions[txHash], "Timelock::executeTransaction: Transaction hasn't been queued.");
        // Verificação: Verificar o tempo de execução da transação
        require(getBlockTimestamp() >= executeTime, "Timelock::executeTransaction: Transaction hasn't surpassed time lock.");
        // Verificar: A transação não expirou
       require(getBlockTimestamp() <= executeTime + GRACE_PERIOD, "Timelock::executeTransaction: Transaction is stale.");
        // Remover a transação da fila
        queuedTransactions[txHash] = false;

        // Obter dados de chamada
        bytes memory callData;
        if (bytes(signature).length == 0) {
            callData = data;
        } else {
// Aqui, se o método encodeWithSignature for usado para chamar a função do administrador, por favor, altere o tipo do parâmetro 'data' para 'address'. Caso contrário, o valor do administrador será alterado para um valor semelhante a "0x0000000000000000000000000000000000000020", onde 0x20 representa o comprimento do array de bytes.
            callData = abi.encodePacked(bytes4(keccak256(bytes(signature))), data);
        }
        // Usando call para executar uma transação
        (bool success, bytes memory returnData) = target.call{value: value}(callData);
        require(success, "Timelock::executeTransaction: Transaction execution reverted.");

        emit ExecuteTransaction(txHash, target, value, signature, data, executeTime);

        return returnData;
    }

    /**
     * @dev Obter o timestamp atual da blockchain
     */
    function getBlockTimestamp() public view returns (uint) {
        return block.timestamp;
    }

    /**
     * @dev Cria um identificador de transação juntando um monte de coisas
     */
    function getTxHash(
        address target,
        uint value,
        string memory signature,
        bytes memory data,
        uint executeTime
    ) public pure returns (bytes32) {
        return keccak256(abi.encode(target, value, signature, data, executeTime));
    }
}
