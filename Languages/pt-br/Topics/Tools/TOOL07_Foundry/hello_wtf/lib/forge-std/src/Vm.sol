// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.9.0;
pragma experimental ABIEncoderV2;

interface Vm {
    struct Log {
        bytes32[] topics;
        bytes data;
    }

    // Define block.timestamp (newTimestamp)
    function warp(uint256) external;
    // Define block.height (newHeight)
    function roll(uint256) external;
    // Define block.basefee (newBasefee)
    function fee(uint256) external;
    // Define block.difficulty (newDifficulty)
    function difficulty(uint256) external;
    // Define block.chainid
    function chainId(uint256) external;
    // Carrega um slot de armazenamento de um endereço (quem, slot)
    function load(address,bytes32) external returns (bytes32);
    // Armazena um valor em um slot de armazenamento de um endereço (quem, slot, valor)
    function store(address,bytes32,bytes32) external;
    // Assina os dados, (chavePrivada, digest) => (v, r, s)
    function sign(uint256,bytes32) external returns (uint8,bytes32,bytes32);
    // Obtém o endereço para uma chave privada fornecida, (privateKey) => (address)
    function addr(uint256) external returns (address);
    // Obtém o nonce de uma conta
    function getNonce(address) external returns (uint64);
    // Define o nonce de uma conta; deve ser maior que o nonce atual da conta
    function setNonce(address, uint64) external;
    // Executa uma chamada de função estrangeira via terminal, (stringInputs) => (resultado)
    function ffi(string[] calldata) external returns (bytes memory);
    // Define variáveis de ambiente, (nome, valor)
    function setEnv(string calldata, string calldata) external;
    // Lê as variáveis de ambiente, (nome) => (valor)
    function envBool(string calldata) external returns (bool);
    function envUint(string calldata) external returns (uint256);
    function envInt(string calldata) external returns (int256);
    function envAddress(string calldata) external returns (address);
    function envBytes32(string calldata) external returns (bytes32);
    function envString(string calldata) external returns (string memory);
    function envBytes(string calldata) external returns (bytes memory);
    // Lê as variáveis de ambiente como arrays, (nome, delimitador) => (valor[])
    function envBool(string calldata, string calldata) external returns (bool[] memory);
    function envUint(string calldata, string calldata) external returns (uint256[] memory);
    function envInt(string calldata, string calldata) external returns (int256[] memory);
    function envAddress(string calldata, string calldata) external returns (address[] memory);
    function envBytes32(string calldata, string calldata) external returns (bytes32[] memory);
    function envString(string calldata, string calldata) external returns (string[] memory);
    function envBytes(string calldata, string calldata) external returns (bytes[] memory);
    // Define o msg.sender da próxima chamada como o endereço de entrada
    function prank(address) external;
    // Define todas as chamadas subsequentes do msg.sender para ser o endereço de entrada até que `stopPrank` seja chamado
    function startPrank(address) external;
    // Define o msg.sender da próxima chamada como o endereço de entrada e o tx.origin como o segundo parâmetro.
    function prank(address,address) external;
    // Define todas as chamadas subsequentes do msg.sender para ser o endereço de entrada até que `stopPrank` seja chamado, e o tx.origin para ser o segundo input
    function startPrank(address,address) external;
    // Reseta o valor de msg.sender para `address(this)` nas chamadas subsequentes.
    function stopPrank() external;
    // Define o saldo de um endereço, (quem, novoSaldo)
    function deal(address, uint256) external;
    // Define o código de um endereço, (quem, novoCódigo)
    function etch(address, bytes calldata) external;
    // Espera um erro na próxima chamada
    function expectRevert(bytes calldata) external;
    function expectRevert(bytes4) external;
    function expectRevert() external;
    // Registra todas as leituras e escritas de armazenamento
    function record() external;
    // Obtém todos os slots de leitura e escrita acessados de uma sessão de gravação, para um determinado endereço
    function accesses(address) external returns (bytes32[] memory reads, bytes32[] memory writes);
    // Preparar um log esperado com (bool checkTopic1, bool checkTopic2, bool checkTopic3, bool checkData).
    // Chame esta função, emita um evento e, em seguida, chame uma função. Internamente, após a chamada, verificamos se
    // os logs foram emitidos na ordem esperada com os tópicos e dados esperados (conforme especificado pelos booleanos)
    function expectEmit(bool,bool,bool,bool) external;
    function expectEmit(bool,bool,bool,bool,address) external;
    // Simula uma chamada a um endereço, retornando os dados especificados.
    // Calldata pode ser estrito ou uma correspondência parcial, por exemplo, se você apenas
    // passar um seletor Solidity para o calldata esperado, em seguida, todo o Solidity
    // A função será simulada.
    function mockCall(address,bytes calldata,bytes calldata) external;
    // Simula uma chamada a um endereço com um determinado msg.value, retornando os dados especificados.
    // Calldata match takes precedence over msg.value in case of ambiguity.
    function mockCall(address,uint256,bytes calldata,bytes calldata) external;
    // Limpa todas as chamadas simuladas
    function clearMockedCalls() external;
    // Espera uma chamada para um endereço com os dados de chamada especificados.
    // Calldata pode ser uma correspondência estrita ou parcial
    function expectCall(address,bytes calldata) external;
    // Espera uma chamada para um endereço com o msg.value e calldata especificados
    function expectCall(address,uint256,bytes calldata) external;
    // Obtém o bytecode de criação de um arquivo de artefato. Recebe o caminho relativo para o arquivo json
    function getCode(string calldata) external returns (bytes memory);
    // Obtém o bytecode _deployed_ de um arquivo de artefato. Recebe o caminho relativo para o arquivo json
    function getDeployedCode(string calldata) external returns (bytes memory);
    // Rotula um endereço em rastreamentos de chamadas
    function label(address, string calldata) external;
    // Se a condição for falsa, descarte as entradas de fuzz deste ciclo e gere novas entradas
    function assume(bool) external;
    // Define block.coinbase (quem)
    function coinbase(address) external;
    // Usando o endereço que chama o contrato de teste, a próxima chamada (somente nessa profundidade de chamada) cria uma transação que pode ser assinada e enviada posteriormente na cadeia.
    function broadcast() external;
    // A próxima chamada (somente nesta profundidade de chamada) cria uma transação com o endereço fornecido como remetente, que pode ser posteriormente assinada e enviada para a cadeia.
    function broadcast(address) external;
    // A próxima chamada (somente nesta profundidade de chamada) cria uma transação com a chave privada fornecida como remetente, que pode ser assinada posteriormente e enviada para a cadeia de blocos.
    function broadcast(uint256) external;
    // Usando o endereço que chama o contrato de teste, todas as chamadas subsequentes (somente nessa profundidade de chamada) criam transações que podem ser assinadas e enviadas posteriormente na cadeia.
    function startBroadcast() external;
    // Todas as chamadas subsequentes (somente nesta profundidade de chamada) criarão transações com o endereço fornecido que podem ser posteriormente assinadas e enviadas na cadeia
    function startBroadcast(address) external;
    // Todas as chamadas subsequentes (somente nesta profundidade de chamada) criarão transações com a chave privada fornecida, que posteriormente podem ser assinadas e enviadas na cadeia
    function startBroadcast(uint256) external;
    // Para de coletar transações onchain
    function stopBroadcast() external;

    // Lê todo o conteúdo do arquivo para uma string, (caminho) => (dados)
    function readFile(string calldata) external returns (string memory);
    // Lê todo o conteúdo do arquivo como binário. O caminho é relativo à raiz do projeto. (caminho) => (dados)
    function readFileBinary(string calldata) external returns (bytes memory);
    // Obtenha o caminho da raiz do projeto atual
    function projectRoot() external returns (string memory);
    // Lê a próxima linha do arquivo para uma string, (caminho) => (linha)
    function readLine(string calldata) external returns (string memory);
    // Escreve dados em um arquivo, criando um arquivo se ele não existir e substituindo completamente seu conteúdo se ele existir.
    // (caminho, dados) => ()
    function writeFile(string calldata, string calldata) external;
    // Escreve dados binários em um arquivo, criando um arquivo se ele não existir e substituindo completamente seu conteúdo se ele existir.
    // O caminho é relativo à raiz do projeto. (caminho, dados) => ()
    function writeFileBinary(string calldata, bytes calldata) external;
    // Escreve uma linha no arquivo, criando o arquivo se ele não existir.
    // (caminho, dados) => ()
    function writeLine(string calldata, string calldata) external;
    // Fecha o arquivo para leitura, redefinindo o deslocamento e permitindo a leitura a partir do início com readLine.
    // (path) => ()
    function closeFile(string calldata) external;
    // Remove arquivo. Este cheatcode será revertido nas seguintes situações, mas não se limita apenas a esses casos:
    // - O caminho aponta para um diretório.
    // - O arquivo não existe.
    // - O usuário não possui permissões para remover o arquivo.
    // (path) => ()
    function removeFile(string calldata) external;

    // Converter valores para uma string, (valor) => (valor convertido para string)
    function toString(address) external returns(string memory);
    function toString(bytes calldata) external returns(string memory);
    function toString(bytes32) external returns(string memory);
    function toString(bool) external returns(string memory);
    function toString(uint256) external returns(string memory);
    function toString(int256) external returns(string memory);

    // Converter valores de uma string, (string) => (valor convertido)
    function parseBytes(string calldata) external returns (bytes memory);
    function parseAddress(string calldata) external returns (address);
    function parseUint(string calldata) external returns (uint256);
    function parseInt(string calldata) external returns (int256);
    function parseBytes32(string calldata) external returns (bytes32);
    function parseBool(string calldata) external returns (bool);

    // Registrar todos os registros de transações
    function recordLogs() external;
    // Obtém todos os registros de logs gravados, () => (logs)
    function getRecordedLogs() external returns (Log[] memory);
    // Capturar o estado atual da EVM.
    // Retorna o ID do snapshot que foi criado.
    // Para reverter um snapshot, use `revertTo`
    function snapshot() external returns(uint256);
    // Reverter o estado do evm para um snapshot anterior
    // Toma o ID do snapshot para reverter.
    // Isso exclui o instantâneo e todos os instantâneos tirados após o ID do instantâneo fornecido.
    function revertTo(uint256) external returns(bool);

    // Cria um novo fork com o endpoint e bloco fornecidos e retorna o identificador do fork
    function createFork(string calldata,uint256) external returns(uint256);
    // Cria um novo fork com o endpoint fornecido e o bloco _mais recente_ e retorna o identificador do fork
    function createFork(string calldata) external returns(uint256);
    // Cria um novo fork com o endpoint fornecido e no bloco em que a transação fornecida foi minerada, e reproduz todas as transações mineradas no bloco antes da transação
    function createFork(string calldata, bytes32) external returns (uint256);
    // Cria _e_ também seleciona um novo fork com o endpoint e bloco fornecidos e retorna o identificador do fork
    function createSelectFork(string calldata,uint256) external returns(uint256);
    // Cria _e_ também seleciona um novo fork com o endpoint fornecido e no bloco em que a transação fornecida foi minerada, e reproduz todas as transações mineradas no bloco antes da transação
    function createSelectFork(string calldata, bytes32) external returns (uint256);
    // Cria _e_ também seleciona um novo fork com o endpoint fornecido e o último bloco e retorna o identificador do fork
    function createSelectFork(string calldata) external returns(uint256);
    // Recebe um identificador de fork criado por `createFork` e define o estado bifurcado correspondente como ativo.
    function selectFork(uint256) external;
    /// Retorna o fork atualmente ativo
    /// Reverte se nenhum fork estiver atualmente ativo
    function activeFork() external returns(uint256);
    // Atualiza o fork atualmente ativo para o número de bloco fornecido
    // Isso é semelhante ao `roll`, mas para o fork ativo no momento
    function rollFork(uint256) external;
    // Atualiza o fork atualmente ativo para a transação fornecida
    // isso irá `rollFork` com o número do bloco em que a transação foi minerada e reproduz todas as transações mineradas antes dela no bloco
    function rollFork(bytes32) external;
    // Atualiza o fork fornecido para o número de bloco fornecido
    function rollFork(uint256 forkId, uint256 blockNumber) external;
    // Atualiza o fork fornecido para o número de bloco da transação fornecida e reproduz todas as transações mineradas antes dela no bloco
    function rollFork(uint256 forkId, bytes32 transaction) external;

    // Marks that the account(s) should use persistent storage across fork swaps in a multifork setup
    // Significado, as alterações feitas no estado desta conta serão mantidas ao trocar de forks.
    function makePersistent(address) external;
    function makePersistent(address, address) external;
    function makePersistent(address, address, address) external;
    function makePersistent(address[] calldata) external;
    // Revoga o status persistente do endereço, previamente adicionado via `makePersistent`
    function revokePersistent(address) external;
    function revokePersistent(address[] calldata) external;
    // Retorna verdadeiro se a conta estiver marcada como persistente
    function isPersistent(address) external returns (bool);

    // No modo de bifurcação, conceda explicitamente acesso ao código de trapaça fornecido ao endereço especificado.
    function allowCheatcodes(address) external;

    // Busca a transação fornecida do fork ativo e a executa no estado atual
    function transact(bytes32 txHash) external;
    // Busca a transação fornecida do fork fornecido e a executa no estado atual
    function transact(uint256 forkId, bytes32 txHash) external;

    // Retorna a URL RPC para o alias fornecido
    function rpcUrl(string calldata) external returns(string memory);
    // Retorna todos os URLs e seus aliases `[alias, url][]`
    function rpcUrls() external returns(string[2][] memory);

    // Derive uma chave privada a partir de uma string mnemônica fornecida (ou caminho do arquivo mnemônico) no caminho de derivação m/44'/60'/0'/0/{índice}
    function deriveKey(string calldata, uint32) external returns (uint256);
    // Derive uma chave privada a partir de uma string mnemônica fornecida (ou caminho do arquivo mnemônico) no caminho de derivação {path}{index}
    function deriveKey(string calldata, string calldata, uint32) external returns (uint256);
    // Adiciona uma chave privada à carteira local do Forge e retorna o endereço
    function rememberKey(uint256) external returns (address);

    // parseJson

    // Dado uma string de JSON, retorne o valor codificado em ABI da chave fornecida
    // (json em formato de string, chave) => (dados codificados em ABI)
    // Leia a nota abaixo!
    function parseJson(string calldata, string calldata) external returns(bytes memory);

    // Dado uma string de JSON, retorne-a como codificada em ABI, (json stringificado, chave) => (dados codificados em ABI)
    // Leia a nota abaixo!
    function parseJson(string calldata) external returns(bytes memory);

    // Nota:
    // ----
    // Caso o valor retornado seja um objeto JSON, ele é codificado como uma tupla codificada em ABI. Como objetos JSON
    // não tem a noção de ordenado, mas as tuplas têm, o objeto JSON é codificado com seus campos ordenados
    // ORDEM alfabética. Isso significa que, para decodificar com sucesso a tupla, precisamos definir uma tupla que
    // codifica os campos na mesma ordem, que é alfabética. No caso das structs do Solidity, elas são codificadas
    // como tuplas, com os atributos na ordem em que são definidos.
    // Por exemplo: json = { 'a': 1, 'b': 0xa4tb......3xs}
    // a: uint256
    // b: endereço
    // Para decodificar esse json, precisamos definir uma struct ou uma tupla da seguinte forma:
    // struct json = { uint256 a; address b; }
    // Se definirmos uma estrutura json com a ordem oposta, ou seja, colocando o endereço b primeiro, ele tentaria
    // decodificar a tupla nessa ordem e, portanto, falhar.

}
