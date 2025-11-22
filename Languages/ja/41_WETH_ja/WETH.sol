// SPDX-License-Identifier: MIT
// author: 0xAA
// original contract on ETH: https://rinkeby.etherscan.io/token/0xc778417e063141139fce010982780140aa0cd5ab?a=0xe16c1623c1aa7d919cd2241d8b36d9e79c1be2a2#code
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract WETH is ERC20{
    // イベント：預金と引出
    event  Deposit(address indexed dst, uint wad);
    event  Withdrawal(address indexed src, uint wad);

    // コンストラクタ、ERC20の名前とシンボルを初期化
    constructor() ERC20("WETH", "WETH"){
    }

    // フォールバック関数、ユーザーがWETHコントラクトにETHを送金すると、deposit()関数がトリガーされる
    fallback() external payable {
        deposit();
    }
    // リシーブ関数、ユーザーがWETHコントラクトにETHを送金すると、deposit()関数がトリガーされる
    receive() external payable {
        deposit();
    }

    // 預金関数、ユーザーがETHを預けると、等量のWETHをミントする
    function deposit() public payable {
        _mint(msg.sender, msg.value);
        emit Deposit(msg.sender, msg.value);
    }

    // 引出関数、ユーザーがWETHを破棄し、等量のETHを取り戻す
    function withdraw(uint amount) public {
        require(balanceOf(msg.sender) >= amount);
        _burn(msg.sender, amount);
        payable(msg.sender).transfer(amount);
        emit Withdrawal(msg.sender, amount);
    }
}