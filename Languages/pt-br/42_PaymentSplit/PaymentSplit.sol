// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
 * Contrato de divisão de pagamentos
 * @dev Este contrato irá dividir os ETH recebidos em várias contas de acordo com as proporções pré-determinadas. Os ETH recebidos serão armazenados no contrato de divisão e cada beneficiário precisará chamar a função release() para receber sua parte.
 */
contract PaymentSplit{
    // Eventos
    // Adicionar evento de beneficiário
    // Evento de saque do beneficiário
    // Evento de recebimento de contrato

    // Total de participações
    // Total de pagamento

    // Cota de cada beneficiário
    // Valor a ser pago para cada beneficiário
    // Array de beneficiários

    /**
     * @dev Inicializa os arrays de beneficiários _payees e de participação na divisão _shares
     * O comprimento dos arrays não pode ser zero e os comprimentos dos dois arrays devem ser iguais.
     * Os elementos do array _shares devem ser maiores que zero, os endereços do array _payees não podem ser endereços zero e não podem haver endereços duplicados.
    */
        // Verifique se os arrays '_payees' e '_shares' têm o mesmo comprimento e não são vazios.
        require(_payees.length == _shares.length, "PaymentSplitter: payees and shares length mismatch");
        require(_payees.length > 0, "PaymentSplitter: no payees");
        // Chamando _addPayee, atualizando os endereços dos beneficiários payees, as cotas dos beneficiários shares e o total de cotas totalShares
        for (uint256 i = 0; i < _payees.length; i++) {
            _addPayee(_payees[i], _shares[i]);
        }
    }

    /**
     * @dev Função de retorno, recebe ETH e dispara o evento PaymentReceived
     */
    receive() external payable virtual {
        emit PaymentReceived(msg.sender, msg.value);
    }

    /**
     * @dev Divide the ETH to the valid beneficiary address _account, and send the corresponding ETH directly to the beneficiary address. Anyone can trigger this function, but the money will be sent to the account address.
     * The releasable() function is called.
     */
    function release(address payable _account) public virtual {
        // A conta deve ser um beneficiário válido.
        require(shares[_account] > 0, "PaymentSplitter: account has no shares");
        // Calcular a quantidade de ETH que a conta deve receber
        uint256 payment = releasable(_account);
        // O ETH merecido não pode ser igual a 0
        require(payment != 0, "PaymentSplitter: account is not due payment");
        // Atualizar o total de pagamentos totalReleased e o valor pago a cada beneficiário released
        totalReleased += payment;
        released[_account] += payment;
        // Transferência
        _account.transfer(payment);
        emit PaymentReleased(_account, payment);
    }

    /**
     * @dev Calcula a quantidade de eth que uma conta pode receber.
     * Chama a função pendingPayment().
     */
    function releasable(address _account) public view returns (uint256) {
        // Calcular a receita total do contrato de divisão de pagamentos totalReceived
        uint256 totalReceived = address(this).balance + totalReleased;
        // Chamando _pendingPayment para calcular a quantidade de ETH que a conta account deve receber.
        return pendingPayment(_account, totalReceived, released[_account]);
    }

    /**
     * @dev Calcula o valor em `ETH` que o beneficiário `_account` deve receber com base na receita total do contrato de divisão `_totalReceived` e no valor já liberado para esse endereço `_alreadyReleased`.
     */
    function pendingPayment(
        address _account,
        uint256 _totalReceived,
        uint256 _alreadyReleased
    ) public view returns (uint256) {
        // A quantidade de ETH que a conta deve receber é igual à quantidade total de ETH menos a quantidade de ETH já recebida.
        return (_totalReceived * shares[_account]) / totalShares - _alreadyReleased;
    }

    /**
     * @dev Adiciona um beneficiário _account e a quantidade de ações correspondente _accountShares. Só pode ser chamado no construtor e não pode ser modificado.
     */
    function _addPayee(address _account, uint256 _accountShares) private {
        // Verifique se _account não é um endereço 0.
        require(_account != address(0), "PaymentSplitter: account is the zero address");
        // Verifique se _accountShares não é igual a zero
        require(_accountShares > 0, "PaymentSplitter: shares are 0");
        // Verificar se _account não está duplicado
        require(shares[_account] == 0, "PaymentSplitter: account already has shares");
        // Atualizar payees, shares e totalShares
        payees.push(_account);
        shares[_account] = _accountShares;
        totalShares += _accountShares;
        // Liberar evento de adição de beneficiário.
        emit PayeeAdded(_account, _accountShares);
    }
}
