// SPDX-License-Identifier: MIT
// autor: 0xAA
// contrato original no ETH: https://rinkeby.etherscan.io/token/0xc778417e063141139fce010982780140aa0cd5ab?a=0xe16c1623c1aa7d919cd2241d8b36d9e79c1be2a2#code
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract WETH is ERC20{
    // Eventos: Depósito e Retirada
    event  Deposit(address indexed dst, uint wad);
    event  Withdrawal(address indexed src, uint wad);

    // Construtor, inicializa o nome do ERC20
    constructor() ERC20("WETH", "WETH"){
    }

    // Função de retorno, quando o usuário converte ETH para o contrato WETH, a função deposit() é acionada
    fallback() external payable {
        deposit();
    }
    // Função de retorno, quando o usuário converte ETH para o contrato WETH, a função deposit() é acionada
    receive() external payable {
        deposit();
    }

    // Função de depósito, quando o usuário deposita ETH, ele recebe a mesma quantidade de WETH cunhado.
    function deposit() public payable {
        _mint(msg.sender, msg.value);
        emit Deposit(msg.sender, msg.value);
    }

    // Função de saque, o usuário destrói o WETH e recebe de volta a mesma quantidade de ETH
    function withdraw(uint amount) public {
        require(balanceOf(msg.sender) >= amount);
        _burn(msg.sender, amount);
        payable(msg.sender).transfer(amount);
        emit Withdrawal(msg.sender, amount);
    }
}