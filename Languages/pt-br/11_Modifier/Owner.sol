// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract Owner {
   // Definir a variável owner

   // Construtor
   constructor() {
      // Ao implantar o contrato, defina o proprietário como o endereço do implantador.
   }

   // Definir modificador
   modifier onlyOwner {
      // Verificar se o chamador é o endereço do proprietário
      // Se for o caso, continue executando o corpo da função; caso contrário, ocorrerá um erro e a transação será revertida.
   }

   // Definir uma função com o modificador onlyOwner
   function changeOwner(address _newOwner) external onlyOwner{
      // Apenas o endereço do proprietário pode executar esta função e alterar o proprietário
   }
}
