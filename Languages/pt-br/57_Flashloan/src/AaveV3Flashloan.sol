// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./Lib.sol";

interface IFlashLoanSimpleReceiver {
    /**
    * @notice Executa ações após receber ativos de empréstimo relâmpago
    * @dev Garante que o contrato possa pagar a dívida + taxas extras, por exemplo,
    *      ter fundos suficientes para pagar e ter aprovado o Pool para sacar o valor total
    * @param asset O endereço do ativo de empréstimo relâmpago
    * @param amount A quantidade de ativos de empréstimo relâmpago
    * @param premium A taxa dos ativos de empréstimo relâmpago
    * @param initiator O endereço que iniciou o empréstimo relâmpago
    * @param params Os parâmetros codificados em bytes passados durante a inicialização do empréstimo relâmpago
    * @return Retorna True se a operação for executada com sucesso, caso contrário, retorna False
    */
    function executeOperation(
        address asset,
        uint256 amount,
        uint256 premium,
        address initiator,
        bytes calldata params
    ) external returns (bool);
}

// Contrato de Empréstimo Relâmpago AAVE V3
contract AaveV3Flashloan {
    address private constant AAVE_V3_POOL =
        0x87870Bca3F3fD6335C3F4ce8392D69350B4fA4E2;

    address private constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    ILendingPool public aave;

    constructor() {
        aave = ILendingPool(AAVE_V3_POOL);
    }

    // Função de Empréstimo Relâmpago
    function flashloan(uint256 wethAmount) external {
        aave.flashLoanSimple(address(this), WETH, wethAmount, "", 0);
    }

    // Função de retorno do empréstimo relâmpago, só pode ser chamada pelo contrato de pool
    function executeOperation(address asset, uint256 amount, uint256 premium, address initiator, bytes calldata)
        external
        returns (bool)
    {   
        // Confirm that the called contract is the DAI/WETH pair contract
        require(msg.sender == AAVE_V3_POOL, "not authorized");
        // Confirmar que o iniciador do empréstimo relâmpago é este contrato
        require(initiator == address(this), "invalid initiator");

        // lógica de flashloan, omitida aqui

        // Calcular o custo do flashloan
        // taxa = 5/1000 * valor
        uint fee = (amount * 5) / 10000 + 1;
        uint amountToRepay = amount + fee;

        // Devolver empréstimo relâmpago
        IERC20(WETH).approve(AAVE_V3_POOL, amountToRepay);

        return true;
    }
}