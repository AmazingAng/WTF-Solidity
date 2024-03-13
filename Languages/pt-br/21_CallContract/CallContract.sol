// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

contract OtherContract {
    // Variável de estado x
    // Recebendo evento eth, registrando amount e gas
    event Log(uint amount, uint gas);
    
    // Retorna o saldo de ETH do contrato
    function getBalance() view public returns(uint) {
        return address(this).balance;
    }

    // Você pode ajustar a função da variável de estado _x e também pode enviar ETH para o contrato (payable)
    function setX(uint256 x) external payable{
        _x = x;
        // Se ETH for transferido, dispara o evento Log
        if(msg.value > 0){
            emit Log(msg.value, gasleft());
        }
    }

    // Ler x
    function getX() external view returns(uint x){
        x = _x;
    }
}

contract CallContract{
    function callSetX(address _Address, uint256 x) external{
        OtherContract(_Address).setX(x);
    }

    function callGetX(OtherContract _Address) external view returns(uint x){
        x = _Address.getX();
    }

    function callGetX2(address _Address) external view returns(uint x){
        OtherContract oc = OtherContract(_Address);
        x = oc.getX();
    }

    function setXTransferETH(address otherContract, uint256 x) payable external{
        OtherContract(otherContract).setX{value: msg.value}(x);
    }
}
