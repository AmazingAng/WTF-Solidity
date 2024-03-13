// SPDX-License-Identifier: MIT
// Por 0xAA
pragma solidity ^0.8.21;

//importar IERC20

/// @notice Transfer ERC20 tokens to multiple addresses
contract Airdrop {
    mapping(address => uint) failTransferList;

    /// @notice Transfer ERC20 tokens to multiple addresses, authorization is required before use.
    ///
    /// @param _token Endereço do token ERC20 a ser transferido
    /// @param _addresses Array de endereços para o airdrop
    /// @param _amounts Array de quantidades de tokens (quantidade de airdrop para cada endereço)
    function multiTransferToken(
        address _token,
        address[] calldata _addresses,
        uint256[] calldata _amounts
    ) external {
        // Verificar se os arrays _addresses e _amounts têm o mesmo comprimento
        require(
            _addresses.length == _amounts.length,
            "Lengths of Addresses and Amounts NOT EQUAL"
        );
        // Declaração da variável do contrato IERC
        // Calcular o total de tokens airdrop
        // Verificar: quantidade de tokens autorizados > quantidade total de tokens airdrop
        require(
            token.allowance(msg.sender, address(this)) > _amountSum,
            "Need Approve ERC20 token"
        );

        // for loop, using the transferFrom function to send airdrop
        for (uint256 i; i < _addresses.length; i++) {
            token.transferFrom(msg.sender, _addresses[i], _amounts[i]);
        }
    }

    /// Transferindo ETH para vários endereços
    function multiTransferETH(
        address payable[] calldata _addresses,
        uint256[] calldata _amounts
    ) public payable {
        // Verificar se os arrays _addresses e _amounts têm o mesmo comprimento
        require(
            _addresses.length == _amounts.length,
            "Lengths of Addresses and Amounts NOT EQUAL"
        );
        // Calcular o total de ETH airdrop
        // Verificando se a quantidade de ETH recebida é igual à quantidade total do airdrop
        require(msg.value == _amountSum, "Transfer amount error");
        // para loop, use a função transfer para enviar ETH
        for (uint256 i = 0; i < _addresses.length; i++) {
            // O código comentado apresenta riscos de ataque DoS e o uso do transfer também não é recomendado.
            // Ataque DoS. Consulte https://github.com/AmazingAng/WTF-Solidity/blob/main/S09_DoS/readme.md para mais informações.
            // _addresses[i].transfer(_amounts[i]);
            (bool success, ) = _addresses[i].call{value: _amounts[i]}("");
            if (!success) {
                failTransferList[_addresses[i]] = _amounts[i];
            }
        }
    }

    // Fornecer uma oportunidade de ação proativa para falhas na entrega de airdrops.
    function withdrawFromFailList(address _to) public {
        uint failAmount = failTransferList[msg.sender];
        require(failAmount > 0, "You are not in failed list");
        failTransferList[msg.sender] = 0;
        (bool success, ) = _to.call{value: failAmount}("");
        require(success, "Fail withdraw");
    }

    // Função para somar elementos de um array
    function getSum(uint256[] calldata _arr) public pure returns (uint sum) {
        for (uint i = 0; i < _arr.length; i++) sum = sum + _arr[i];
    }
}

// Contrato de token ERC20
contract ERC20 is IERC20 {
    mapping(address => uint256) public override balanceOf;

    mapping(address => mapping(address => uint256)) public override allowance;

    // Fornecimento total de tokens

    // Nome
    // Símbolos

    // Número de casas decimais

    constructor(string memory name_, string memory symbol_) {
        name = name_;
        symbol = symbol_;
    }

    // @dev Implement the `transfer` function, logic for token transfer
    function transfer(
        address recipient,
        uint amount
    ) external override returns (bool) {
        balanceOf[msg.sender] -= amount;
        balanceOf[recipient] += amount;
        emit Transfer(msg.sender, recipient, amount);
        return true;
    }

    // @dev Implement the `approve` function, token authorization logic
    function approve(
        address spender,
        uint amount
    ) external override returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    // @dev Implement the `transferFrom` function, which handles token transfer with authorization
    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external override returns (bool) {
        allowance[sender][msg.sender] -= amount;
        balanceOf[sender] -= amount;
        balanceOf[recipient] += amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }

    // @dev Cunhar tokens e transferir do endereço `0` para o endereço do chamador
    function mint(uint amount) external {
        balanceOf[msg.sender] += amount;
        totalSupply += amount;
        emit Transfer(address(0), msg.sender, amount);
    }

    // @dev Destruir tokens, transferindo-os do endereço do chamador para o endereço `0`
    function burn(uint amount) external {
        balanceOf[msg.sender] -= amount;
        totalSupply -= amount;
        emit Transfer(msg.sender, address(0), amount);
    }
}
