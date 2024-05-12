// SPDX-License-Identifier: MIT
// Por 0xAA
pragma solidity ^0.8.21;

//importar IERC20

contract ERC20 is IERC20 {

    mapping(address => uint256) public override balanceOf;

    mapping(address => mapping(address => uint256)) public override allowance;

    // Fornecimento total de tokens

    // Nome
    // Símbolos
    
    // Número de casas decimais

    constructor(string memory name_, string memory symbol_){
        name = name_;
        symbol = symbol_;
    }

    // @dev Implement the `transfer` function, logic for token transfer
    function transfer(address recipient, uint amount) external override returns (bool) {
        balanceOf[msg.sender] -= amount;
        balanceOf[recipient] += amount;
        emit Transfer(msg.sender, recipient, amount);
        return true;
    }

    // @dev Implement the `approve` function, token authorization logic
    function approve(address spender, uint amount) external override returns (bool) {
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

// Contrato de torneira para tokens ERC20
contract Faucet {

    // Cada vez que você resgata 100 unidades de tokens.
    // Endereço do contrato de token
    // Registre os endereços que receberam tokens

    // Evento SendToken
    event SendToken(address indexed Receiver, uint256 indexed Amount); 

    // Ao implantar, defina o contrato de token ERC2.
    constructor(address _tokenContract) {
        // definir contrato de token
    }

    // Função para o usuário receber tokens
    function requestTokens() external {
        // Cada endereço só pode ser resgatado uma vez.
        // Criar objeto de contrato IERC20
        // A torneira está vazia.

        // Enviar token
        // Registre o endereço de recebimento
        
        // Liberar o evento SendToken
    }
}
