// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../src/TimeManipulation.sol";

contract TimeManipulationTest is Test {
    TimeManipulation public nft;

    // Calcula o endereço para uma chave privada fornecida
    address alice = vm.addr(1);

    function setUp() public {
        nft = new TimeManipulation();
    }

    // teste de forja -vv --match-test testMint
    function testMint() public {
        console.log("Condição 1: block.timestamp % 170 != 0")
        // Defina block.timestamp como 169
        vm.warp(169);
        console.log("block.timestamp: %s", block.timestamp)
        // Define o endereço do remetente para todas as chamadas subsequentes como o endereço de entrada
        // até que `stopPrank` seja chamado
        vm.startPrank(alice);
        console.log("saldo de Alice antes da criação: %s", nft.balanceOf(alice))
        nft.luckyMint();
        console.log("saldo de Alice após a criação: %s", nft.balanceOf(alice))

        // Defina block.timestamp como 17000
        console.log("Condição 2: block.timestamp % 170 == 0")
        vm.warp(17000);
        console.log("block.timestamp: %s", block.timestamp)
        console.log("saldo de Alice antes da criação: %s", nft.balanceOf(alice))
        nft.luckyMint();
        console.log("saldo de Alice após a criação: %s", nft.balanceOf(alice))
        vm.stopPrank();
    }
}
