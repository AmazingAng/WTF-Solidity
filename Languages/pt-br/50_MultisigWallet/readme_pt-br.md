# WTF Solidity Introdução Essencial: 50. Carteira Multisig

Recentemente, tenho revisado meus conhecimentos em Solidity para consolidar alguns dos detalhes e escrever um "WTF Solidity Introdução Essencial" para ajudar os iniciantes (programadores experientes podem procurar outros tutoriais). Atualizo de 1 a 3 lições por semana.

Twitter: [@0xAA_Science](https://twitter.com/0xAA_Science)

Comunidade: [Discord](https://discord.gg/5akcruXrsk) | [Grupo do WhatsApp](https://docs.google.com/forms/d/e/1FAIpQLSe4KGT8Sh6sJ7hedQRuIYirOoZK_85miz3dw7vA1-YjodgJ-A/viewform?usp=sf_link) | [Site wtf.academy](https://wtf.academy)

Todo o código e tutorial são de código aberto no GitHub: [github.com/AmazingAng/WTFSolidity](https://github.com/AmazingAng/WTFSolidity)

---

Vitalik Buterin uma vez disse que uma carteira multisig é mais segura do que uma carteira de hardware ([tweet](https://twitter.com/VitalikButerin/status/1558886893995134978?s=20&t=4WyoEWhwHNUtAuABEIlcRw)). Nesta lição, vamos apresentar a carteira multisig e escrever um contrato de carteira multisig simplificado. O código de exemplo (150 linhas de código) foi simplificado a partir do contrato Gnosis Safe (com milhares de linhas).

![Vitalik Buterin disse](./img/50-1.png)

## Carteira Multisig

Uma carteira multisig é um tipo de carteira eletrônica em que as transações só podem ser executadas após serem autorizadas por vários detentores de chaves privadas (multisig). Por exemplo, se uma carteira é gerenciada por `3` pessoas, uma transação requer pelo menos`2` assinaturas dos detentores de chaves para ser autorizada. As carteiras multisig podem prevenir falhas únicas (como perda de chaves ou má conduta de uma pessoa), são mais descentralizadas e mais seguras, sendo amplamente adotadas por DAOs.

A carteira multisig Gnosis Safe é a carteira multisig mais popular do Ethereum, gerenciando quase US $ 400 bilhões em ativos, com contrato auditado e testado na prática, suportando várias redes (Ethereum, BSC, Polygon, etc.) e fornecendo amplo suporte a aplicativos descentralizados. Para mais informações, você pode ler o tutorial de uso do Gnosis Safe que escrevi em dezembro de 2021 [aqui](https://peopledao.mirror.xyz/nFCBXda8B5ZxQVqSbbDOn2frFDpTxNVtdqVBXGIjj0s).

## Contrato de Carteira Multisig

As carteiras multisig no Ethereum são, na verdade, contratos inteligentes, que são chamados de contratos de carteira. Abaixo, escrevemos um contrato de carteira Multisig `MultisigWallet` simplificado, com lógica muito simples:

1. Definir os signatários e o limiar (on-chain): ao implantar o contrato multisig, precisamos inicializar a lista de signatários e o limiar de execução (pelo menos n signatários devem assinar para que a transação seja executada). A carteira multisig Gnosis Safe suporta adicionar/remover signatários e alterar o limiar de execução, mas no nosso versão simplificada, não consideramos essa funcionalidade.

2. Criar transação (off-chain): uma transação pendente de autorização inclui o seguinte conteúdo
    - `to`: endereço do contrato de destino.
    - `value`: quantidade de ether a ser enviada na transação.
    - `data`: calldata, incluindo o seletor da função chamada e parâmetros.
    - `nonce`: iniciado em `0`, aumenta com cada transação bem-sucedida executada pelo contrato multisig, pode evitar ataques de repetição de assinatura.
    - `chainid`: id da rede, evita ataques de repetição de assinatura em redes diferentes.

3. Coletar assinaturas multisig (off-chain): codificar a transação conforme mencionado acima e calcular o hash para obter o hash da transação. Em seguida, cada signatário da carteira multisig deve assinar a transação e as assinaturas são concatenadas para formar a assinatura embalada. Para quem não está familiarizado com a codificação ABI e o cálculo de hash, pode consultar as lições essenciais de Solidity [Leitura 27](../27_ABIEncode/readme_pt-br.md) e [Leitura 28](../28_Hash/readme_pt-br.md).

    ```solidity
    Hash da transação: 0xc1b055cf8e78338db21407b425114a2e258b0318879327945b661bfdea570e66

    Assinatura do signatário A: 0x014db45aa753fefeca3f99c2cb38435977ebb954f779c2b6af6f6365ba4188df542031ace9bdc53c655ad2d4794667ec2495196da94204c56b1293d0fbfacbb11c

    Assinatura do signatário B: 0xbe2e0e6de5574b7f65cad1b7062be95e7d73fe37dd8e888cef5eb12e964ddc597395fa48df1219e7f74f48d86957f545d0fbce4eee1adfbaff6c267046ade0d81c

    Assinatura embalada:
    0x014db45aa753fefeca3f99c2cb38435977ebb954f779c2b6af6f6365ba4188df542031ace9bdc53c655ad2d4794667ec2495196da94204c56b1293d0fbfacbb11cbe2e0e6de5574b7f65cad1b7062be95e7d73fe37dd8e888cef5eb12e964ddc597395fa48df1219e7f74f48d86957f545d0fbce4eee1adfbaff6c267046ade0d81c
    ```

4. Chamar a função de execução da carteira multisig, verificar as assinaturas e executar a transação (on-chain). Para quem não sabe sobre verificar assinaturas e executar transações, pode consultar as lições essenciais de Solidity [Leitura 22](../22_Call/readme_pt-br.md) e [Leitura 37](../37_Signature/readme_pt-br.md).

### Eventos

O contrato da `MultisigWallet` tem `2` eventos, `ExecutionSuccess` e `ExecutionFailure`, que são disparados quando uma transação é bem-sucedida ou falha, respectivamente, e passam o hash da transação como parâmetro.

```solidity
    event ExecutionSuccess(bytes32 txHash);    // Evento de transação bem-sucedida
    event ExecutionFailure(bytes32 txHash);    // Evento de transação falha
```

### Variáveis de Estado

O contrato da `MultisigWallet` possui `5` variáveis de estado:
1. `owners`: array de detentores da multichave
2. `isOwner`: mapeamento `address => bool`, registrando se um endereço é um detentor da multichave.
3. `ownerCount`: quantidade de detentores da multichave
4. `threshold`: limiar de execução da multichave, transações precisam ter pelo menos n assinaturas para serem executadas.
5. `nonce`: iniciado em `0`, aumenta com cada transação bem-sucedida executada pelo contrato da multichave, pode evitar ataque de repetição de assinatura.

```solidity
    address[] public owners;                   // array de detentores da multichave
    mapping(address => bool) public isOwner;   // mapeamento que registra se um endereço é um detentor da multichave
    uint256 public ownerCount;                 // quantidade de detentores da multichave
    uint256 public threshold;                  // limiar de execução da multichave, transações precisam ter pelo menos n assinaturas para serem executadas.
    uint256 public nonce;                      // nonce, pode evitar ataques de repetição de assinatura
```

### Funções

O contrato da `MultisigWallet` possui `6` funções:

1. Construtor: chama `_setupOwners()`, inicializando e relacionando as variáveis referentes aos detentores da multichave e ao limiar de execução.

    ```solidity
    // Construtor, inicializa owners, isOwner, ownerCount, threshold 
    constructor(        
        address[] memory _owners,
        uint256 _threshold
    ) {
        _setupOwners(_owners, _threshold);
    }
    ```

2. `_setupOwners()`: é chamada pelo construtor ao implantar o contrato para inicializar `owners`, `isOwner`, `ownerCount` e` threshold`. O limiar de execução deve ser maior ou igual a `1` e menor ou igual ao número de detentores da multichave; e os endereços dos detentores da multichave não podem ser endereço em branco nem se repetir.

    ```solidity
    /// @dev Inicializa owners, isOwner, ownerCount,threshold 
    /// @param _owners: array de detentores da multichave
    /// @param _threshold: limiar de execução da multichave, pelo menos n pessoas devem assinar transações
    function _setupOwners(address[] memory _owners, uint256 _threshold) internal {
        // se o limiar ainda não foi inicializado
        require(threshold == 0, "WTF5000");
        // o limiar deve ser menor ou igual ao número de detentores
        require(_threshold <= _owners.length, "WTF5001");
        // o limiar deve ser pelo menos 1
        require(_threshold >= 1, "WTF5002");

        for (uint256 i = 0; i < _owners.length; i++) {
            address owner = _owners[i];
            // endereço do detentor não deve ser endereço em branco, endereço do contrato, nem repetido
            require(owner != address(0) && owner != address(this) && !isOwner[owner], "WTF5003");
            owners.push(owner);
            isOwner[owner] = true;
        }
        ownerCount = _owners.length;
        threshold = _threshold;
    }
    ```

3. `execTransaction()`: verifica as assinaturas necessárias, verifica se as assinaturas são válidas e executa a transação. Os parâmetros da transação incluem o endereço de destino `to`, o valor a ser enviado em ether `value`, os dados `data` e as assinaturas empacotadas `signatures`. Esta função chama `encodeTransactionData()` para codificar a transação, chama `checkSignatures()` para verificar as assinaturas e, em seguida, chama a função interna `call` para executar a transação.

    ```solidity
    /// @dev Após coletar assinaturas suficientes, executa a transação
    /// @param to Endereço do contrato de destino
    /// @param value msg.value, valor de ether a ser enviado
    /// @param data calldata
    /// @param signatures Assinaturas empacotadas, contendo as assinaturas dos diferentes detentores ({bytes32 r}{bytes32 s}{uint8 v}) (primeira assinatura, segunda assinatura...)
    function execTransaction(
        address to,
        uint256 value,
        bytes memory data,
        bytes memory signatures
    ) public payable virtual returns (bool success) {
        // Codifica os dados da transação, calcula o hash
        bytes32 txHash = encodeTransactionData(to, value, data, nonce, block.chainid);
        nonce++;  // Incrementa o nonce
        checkSignatures(txHash, signatures); // Verifica as assinaturas
        // Usa o call para executar a transação e obtém o resultado
        (success, ) = to.call{value: value}(data);
        require(success , "WTF5004");
        if (success) emit ExecutionSuccess(txHash);
        else emit ExecutionFailure(txHash);
    }
    ```

4. `checkSignatures()`: verifica se as assinaturas e o hash dos dados da transação correspondem, se a quantidade de assinaturas atinge o limiar e, se não, a transação é revertida. O comprimento de uma única assinatura é de 65 bytes, portanto o comprimento da assinatura empacotada deve ser maior que `threshold * 65`. Esta função ocorre em um loop e verifica se cada assinatura é válida e pertence a um detentor da multichave.

    ```solidity
    /**
     * @dev Verifica se as assinaturas e os dados da transação correspondem. Se for uma assinatura inválida, a transação será revertida
     * @param dataHash Hash dos dados da transação
     * @param signatures As várias assinaturas empacotadas
     */
    function checkSignatures(
        bytes32 dataHash,
        bytes memory signatures
    ) public view {
        // Obtém o limiar de execução multisig
        uint256 _threshold = threshold;
        require(_threshold > 0, "WTF5005");

        // Verifica se o comprimento das assinaturas é suficiente
        require(signatures.length >= _threshold * 65, "WTF5006");

        // Loop para verificar a validade das assinaturas
        address lastOwner = address(0); 
        address currentOwner;
        uint8 v;
        bytes32 r;
        bytes32 s;
        uint256 i;
        for (i = 0; i < _threshold; i++) {
            (v, r, s) = signatureSplit(signatures, i);
            // Verifica se a assinatura é válida usando ecrecover
            currentOwner = ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", dataHash)), v, r, s);
            require(currentOwner > lastOwner && isOwner[currentOwner], "WTF5007");
            lastOwner = currentOwner;
        }
    }
    ```

5. `signatureSplit()`: separa uma única assinatura das várias assinaturas empacotadas, conforme sua posição. Esta função usa montagem inline para separar os valores `r`,` s` e `v` de uma assinatura empacotada.

    ```solidity
    /// Separa uma única assinatura das várias assinaturas empacotadas
    /// @param signatures As várias assinaturas empacotadas
    /// @param pos Posição da assinatura a ser lida.
    function signatureSplit(bytes memory signatures, uint256 pos)
        internal
        pure
        returns (
            uint8 v,
            bytes32 r,
            bytes32 s
        )
    {
        // Formato da assinatura: {bytes32 r}{bytes32 s}{uint8 v}
        assembly {
            let signaturePos := mul(0x41, pos)
            r := mload(add(signatures, add(signaturePos, 0x20)))
            s := mload(add(signatures, add(signaturePos, 0x40)))
            v := and(mload(add(signatures, add(signaturePos, 0x41))), 0xff)
        }
    }
    ```

6. `encodeTransactionData()`: codifica os dados da transação e calcula o hash, utilizando as funções `abi.encode()` e `keccak256()`. Esta função pode calcular o hash de uma transação e, em seguida, os signatários da multichave podem assiná-la e coletá-la fora da blockchain para, em seguida, executá-la usando a função `execTransaction()`.

    ```solidity
    /// @dev Codifica os dados da transação
    /// @param to Endereço do contrato de destino
    /// @param value msg.value, valor em ether a ser enviado
    /// @param data calldata
    /// @param _nonce Nonce da transação
    /// @param chainid Id da rede
    /// @return Hash da transação byte
    function encodeTransactionData(
        address to,
        uint256 value,
        bytes memory data,
        uint256 _nonce,
        uint256 chainid
    ) public pure returns (bytes32) {
        bytes32 safeTxHash =
            keccak256(
                abi.encode(
                    to,
                    value,
                    keccak256(data),
                    _nonce,
                    chainid
                )
            );
        return safeTxHash;
    }
    ```

## Demonstração no `Remix`

1. Implante o contrato da carteira multisig, com `2` endereços de detentores da multichave e um limiar de execução de `2`.

    ```solidity
    Detentor da Multichave 1: 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4
    Detentor da Multichave 2: 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2
    ```

    ![Implantação](./img/50-2.png)

2. Faça uma transferência de `1 ETH` para o endereço da carteira multisig.

    ![Transferência](

<!-- This file was translated using AI by repo_ai_translate. For more information, visit https://github.com/marcelojsilva/repo_ai_translate -->