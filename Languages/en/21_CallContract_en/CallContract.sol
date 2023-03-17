// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract OtherContract {
    uint256 private _x = 0; // state variable x
    // Receiving ETH event, log the amount and gas
    event Log(uint amount, uint gas);
    
    // get the balance of the contract
    function getBalance() view public returns(uint) {
        return address(this).balance;
    }

    // set the value of x, as well as receiving ETH (payable)
    function setX(uint256 x) external payable{
        _x = x;
        // emit Log event when receiving ETH
        if(msg.value > 0){
            emit Log(msg.value, gasleft());
        }
    }

    // read the value of x
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
