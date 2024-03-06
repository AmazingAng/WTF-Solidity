// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract Fallback {
    /* Acionar fallback() ou receive()?
           Receber ETH
              |
         msg.data está vazio?
            /  \
          Sim   Não
          /      \
receive() existe?   fallback()
        / \
       Sim  Não
      /     \
receive()  fallback   
    */

    // Definir evento
    event receivedCalled(address Sender, uint Value);
    event fallbackCalled(address Sender, uint Value, bytes Data);

    // Receber o evento "Received" ao receber ETH
    receive() external payable {
        emit receivedCalled(msg.sender, msg.value);
    }

    // fallback
    fallback() external payable{
        emit fallbackCalled(msg.sender, msg.value, msg.data);
    }
}
