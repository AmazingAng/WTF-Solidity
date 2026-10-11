// SPDX-License-Identifier: MIT
pragma solidity ^0.8.34;

import "forge-std/Test.sol";
import "../33_Airdrop/Airdrop.sol";

contract AirdropTest is Test {
    Airdrop private airdrop;
    ERC20 private token;
    address private constant ALICE = address(0xA11CE);
    address private constant BOB = address(0xB0B);

    function setUp() public {
        airdrop = new Airdrop();
        token = new ERC20("Test Token", "TST");
        token.mint(3 ether);
        token.approve(address(airdrop), 3 ether);
    }

    function testMultiTransferTokenAllowsExactAllowance() public {
        address[] memory recipients = new address[](2);
        recipients[0] = ALICE;
        recipients[1] = BOB;
        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 1 ether;
        amounts[1] = 2 ether;

        airdrop.multiTransferToken(address(token), recipients, amounts);

        assertEq(token.balanceOf(ALICE), 1 ether);
        assertEq(token.balanceOf(BOB), 2 ether);
        assertEq(token.allowance(address(this), address(airdrop)), 0);
    }

    function testMultiTransferTokenRejectsInsufficientAllowance() public {
        address[] memory recipients = new address[](1);
        recipients[0] = ALICE;
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 4 ether;

        vm.expectRevert(bytes("Need Approve ERC20 token"));
        airdrop.multiTransferToken(address(token), recipients, amounts);
    }

    function testMultiTransferTokenRejectsMismatchedArrays() public {
        address[] memory recipients = new address[](1);
        recipients[0] = ALICE;
        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 1 ether;
        amounts[1] = 2 ether;

        vm.expectRevert(bytes("Lengths of Addresses and Amounts NOT EQUAL"));
        airdrop.multiTransferToken(address(token), recipients, amounts);
    }
}
