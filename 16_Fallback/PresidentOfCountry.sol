pragma solidity ^0.4.10;

contract PresidentOfCountry {
    address public president;
    uint256 price;

    function PresidentOfCountry(uint256 _price) {
        require(_price > 0);
        price = _price;
        president = msg.sender;
    }

    function becomePresident() payable {
        require(msg.value >= price); // 金额必须高于当前价格，才能成为国王
        president.transfer(price);   // 给前任国王打钱
        president = msg.sender;      // 当选现任国王
        price = price * 2;           // 当前价格更新为上次的两倍
    }
}