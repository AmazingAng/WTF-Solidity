// SPDX-License-Identifier: MIT
// autor: @0xAA_Science da wtf.academy
pragma solidity ^0.8.21;

/// Carteira multi-assinatura baseada em assinaturas, simplificada a partir do contrato Gnosis Safe, para fins educacionais.
contract MultisigWallet {
    // Evento de transação bem-sucedida
    // Evento de falha na transação
    // Array de detentores de múltiplas assinaturas
    // Registra se um endereço é um endereço multi-assinatura
    // Número de titulares de múltiplas assinaturas
    // O limite de execução de assinaturas múltiplas requer que uma transação seja assinada por pelo menos n pessoas para ser executada.
    // nonce, para evitar ataques de repetição de assinatura

    receive() external payable {}

    // Construtor, inicializa owners, isOwner, ownerCount, threshold
    constructor(        
        address[] memory _owners,
        uint256 _threshold
    ) {
        _setupOwners(_owners, _threshold);
    }

    /// @dev Inicializa owners, isOwner, ownerCount e threshold
    /// @param _owners: Array of multi-signature holders
    /// @param _threshold: Limiar de execução de múltiplas assinaturas, pelo menos quantas pessoas assinaram a transação
    function _setupOwners(address[] memory _owners, uint256 _threshold) internal {
        // threshold não foi inicializado antes
        require(threshold == 0, "WTF5000");
        // Limiar de execução de assinaturas múltiplas menor que o número de assinantes múltiplos
        require(_threshold <= _owners.length, "WTF5001");
        // O limite mínimo de execução de assinaturas múltiplas é de 1.
        require(_threshold >= 1, "WTF5002");

        for (uint256 i = 0; i < _owners.length; i++) {
            address owner = _owners[i];
            // Os signatários múltiplos não podem ser endereços zero, nem o endereço deste contrato, e não podem ser repetidos.
            require(owner != address(0) && owner != address(this) && !isOwner[owner], "WTF5003");
            owners.push(owner);
            isOwner[owner] = true;
        }
        ownerCount = _owners.length;
        threshold = _threshold;
    }

    /// @dev Após coletar assinaturas suficientes de múltiplas partes, execute a transação.
    /// @param to Endereço do contrato de destino
    /// @param value msg.value, pagamento em Ethereum
    /// @param data calldata
    /// @param signatures Assinaturas empacotadas, correspondentes aos endereços de várias assinaturas em ordem crescente, para facilitar a verificação. ({bytes32 r}{bytes32 s}{uint8 v}) (Assinatura do primeiro endereço, Assinatura do segundo endereço, ...)
    function execTransaction(
        address to,
        uint256 value,
        bytes memory data,
        bytes memory signatures
    ) public payable virtual returns (bool success) {
        // Codificando dados de transação, calculando o hash
        bytes32 txHash = encodeTransactionData(to, value, data, nonce, block.chainid);
        // Adicionar nonce
        // Verificar assinatura
        // Usando a função call para executar uma transação e obter o resultado da transação
        (success, ) = to.call{value: value}(data);
        require(success , "WTF5004");
        if (success) emit ExecutionSuccess(txHash);
        else emit ExecutionFailure(txHash);
    }

    /**
     * @dev Verifica se a assinatura corresponde aos dados da transação. Se a assinatura for inválida, a transação será revertida.
     * @param dataHash Hash dos dados da transação
     * @param signatures Assinaturas de várias partes juntas
     */
    function checkSignatures(
        bytes32 dataHash,
        bytes memory signatures
    ) public view {
        // Ler o limiar de execução de assinaturas múltiplas
        uint256 _threshold = threshold;
        require(_threshold > 0, "WTF5005");

        // Verifique se o comprimento da assinatura é suficientemente longo
        require(signatures.length >= _threshold * 65, "WTF5006");

        // Através de um loop, verifique se as assinaturas coletadas são válidas
        // Grande ideia:
        // 1. Verificar primeiro se a assinatura é válida usando o algoritmo ECDSA
        // 2. Usando currentOwner > lastOwner para determinar se a assinatura vem de um contrato multi-assinatura diferente (endereços de contrato multi-assinatura em ordem crescente)
        // 3. Utilize isOwner[currentOwner] to determine if the signer is a multi-signature holder
        address lastOwner = address(0); 
        address currentOwner;
        uint8 v;
        bytes32 r;
        bytes32 s;
        uint256 i;
        for (i = 0; i < _threshold; i++) {
            (v, r, s) = signatureSplit(signatures, i);
            // Usando ecrecover para verificar se a assinatura é válida
            currentOwner = ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", dataHash)), v, r, s);
            require(currentOwner > lastOwner && isOwner[currentOwner], "WTF5007");
            lastOwner = currentOwner;
        }
    }
    
    /// Separar uma assinatura individual de uma assinatura empacotada
    /// @param signatures Assinaturas de pacotes multi-assinados
    /// @param pos Índice do multisig a ser lido.
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

    /// @dev Codificar dados de transação
    /// @param to Endereço do contrato de destino
    /// @param value msg.value, pagamento em Ethereum
    /// @param data calldata
    /// @param _nonce Número de sequência da transação.
    /// @param chainid ID da cadeia
    /// @return Bytes do hash da transação.
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
}
