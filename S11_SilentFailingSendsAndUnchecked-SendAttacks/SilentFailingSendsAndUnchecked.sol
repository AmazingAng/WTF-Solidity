// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract A {
    function a() public {

    }
}
contract B {
    function b(A a) public {
        a.a();
    }
}

contract AnError {
    function callToAnError() public {
        (bool success, bytes memory returnData) = address(this).call(abi.encodeWithSignature("anError()"));
    }

    function anError() public {
        revert("sorry sir");
    }
}

contract RewardsWrong {
    /*
    * some complex、amazing and perfect logic code
    */
    address admin = 0xAb5801a7D398351b8bE11C439e05C5B3259aeC9B; // your address
    function sendEtherToWinners(address winner1 ,address winner2) public {
        require(msg.sender == admin );
        payable(winner1).send(address(this).balance/2);
        payable(winner2).send(address(this).balance);
    }
}

contract RewardsRight {
    /*
    * some complex、amazing and perfect logic code
    */
    address admin = 0xAb5801a7D398351b8bE11C439e05C5B3259aeC9B; // your address
   function sendEtherToWinners(address winner1 ,address winner2) public {
        require(msg.sender == admin );
        bool success1 = payable(winner1).send(address(this).balance/2);
        bool success2 = payable(winner2).send(address(this).balance);
        require(success1 && success2);
    }
}

contract winner1 {
    
}

contract winner2 {
    fallback() external payable {

    }
}


