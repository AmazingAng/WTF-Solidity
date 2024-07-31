// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract OtherContract {
    uint256 private _x = 0; // variable de estado x
    // Evento de recepción de ETH, registrar la cantidad y el gas
    event Log(uint amount, uint gas);
    
    // obtener el saldo del contrato
    function getBalance() view public returns(uint) {
        return address(this).balance;
    }

    // establecer el valor de x, así como recibir ETH (payable)
    function setX(uint256 x) external payable{
        _x = x;
        // emitir evento Log al recibir ETH
        if(msg.value > 0){
            emit Log(msg.value, gasleft());
        }
    }

    // leer el valor de x
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
