// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/Counter.sol";
// Importe a interface IERC20, através dessa interface é possível chamar os métodos correspondentes
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract IERC20Test is Test {
  // Declarando uma variável de objeto do contrato Counter
  Counter public counter;
  // Declarar uma variável de endereço
  address public alice;
  // Declarando um msgSender
  address public msgSender;
  // Declarar a função do contrato de ajuda
  Helper public h;

  //Definir um objeto de contrato IERC20
  IERC20 public dai;


   event  MyEvent(uint256 indexed a, uint256 indexed b, uint256 indexed c, uint256 d, uint256 e);

  function setUp() public {
    // novo objeto de contrato de teste
    counter = new Counter();
    // Chamando um método de objeto
    counter.setNumber(0);
    // novo objeto helper
    h = new Helper();

    alice = address(10086);
    console2.log(alice);
    // Obter o endereço das variáveis de ambiente através de vm.envAddress
    dai = IERC20(vm.envAddress("DAI"));
  }


  // Testando a transferência para um endereço de contrato
  function testCheatCode() public {
    console2.log("before:", dai.balanceOf(alice));
    deal(address(dai), alice,1 ether);
    console2.log("after:", dai.balanceOf(alice));
  }
  // Testando a alteração do msg.sender do contrato
  function testCheatAddress() public {
    console2.log("before:", h.whoCalled());
    vm.prank(address(1));
    console2.log("after:", h.whoCalled());
  }

  function testCodeFork() public {
    console2.log(address(dai));
    string memory rpc = vm.envString("ETH_RPC_URL");
    uint256 mainnet = vm.createFork(rpc);
    vm.selectFork(mainnet);
    // Aqui abaixo é onde a rede é bifurcada diretamente
    console2.log("before:",dai.balanceOf(alice));
    deal(address(dai),alice,1 ether);
    console2.log("after:",dai.balanceOf(alice));
  }

  function testEmit() public {
    vm.expectEmit(true,true,true,true);
    emit MyEvent(1,2,3,4,5);
    h.emitIt();
  }

}


contract Helper {

  event  MyEvent(uint256 indexed a, uint256 indexed b, uint256 indexed c, uint256 d, uint256 e);

  function whoCalled() public view returns (address) {
    return msg.sender;
  }

  function emitIt() public {
    emit MyEvent(1,2,3,4,5);
  }

}