// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

contract Fallback {
    /* 
        Ejecutar receive() o fallback()?
                 Recibir ETH
                      |
              msg.data está vacío?
                    /  \
                  Sí   No
                  /      \
        ¿Tiene receive()?   fallback()
                /          \
                Sí            No
                /              \
        receive()           fallback()
    */

    // Eventos
    event receivedCalled(address Sender, uint Value);
    event fallbackCalled(address Sender, uint Value, bytes Data);

    // Emitir evento Received al recibir ETH
    receive() external payable {
        emit receivedCalled(msg.sender, msg.value);
    }

    // Emitir evento fallbackCalled al recibir ETH
    fallback() external payable{
        emit fallbackCalled(msg.sender, msg.value, msg.data);
    }
}
