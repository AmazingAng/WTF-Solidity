// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

contract OtherContract {
    // Variável de estado x
    // Recebendo evento eth, registrando amount e gas
    event Log(uint amount, uint gas);

    fallback() external payable{}

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

contract Call{
    // Definir o evento de resposta, exibindo o resultado de retorno da chamada 'success' e 'data'
    event Response(bool success, bytes data);

    function callSetX(address payable _addr, uint256 x) public payable {
        // chamar setX(), enquanto também é possível enviar ETH
        (bool success, bytes memory data) = _addr.call{value: msg.value}(
            abi.encodeWithSignature("setX(uint256)", x)
        );

        //Liberar evento
    }

    function callGetX(address _addr) external returns(uint256){
        // call getX()
        (bool success, bytes memory data) = _addr.call(
            abi.encodeWithSignature("getX()")
        );

        //Liberar evento
        return abi.decode(data, (uint256));
    }

    function callNonExist(address _addr) external{
        // call função inexistente
        (bool success, bytes memory data) = _addr.call(
            abi.encodeWithSignature("foo(uint256)")
        );

        //Liberar evento
    }
}
