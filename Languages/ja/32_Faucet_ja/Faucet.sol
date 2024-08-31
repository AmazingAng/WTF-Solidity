// SPDX-License-Identifier: MIT
// By 0xAA
pragma solidity ^0.8.21;

import "./IERC20.sol"; //import IERC20

contract ERC20 is IERC20 {
    mapping(address => uint256) public override balanceOf;

    mapping(address => mapping(address => uint256)) public override allowance;

    uint256 public override totalSupply; // token total supply

    string public name; // 名称
    string public symbol; // シンボル

    uint8 public decimals = 18; // 小数点以下桁数

    constructor(string memory name_, string memory symbol_) {
        name = name_;
        symbol = symbol_;
    }

    // @dev  `transfer`関数の実装、トークンのトランスファロジック
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        balanceOf[msg.sender] -= amount;
        balanceOf[recipient] += amount;
        emit Transfer(msg.sender, recipient, amount);
        return true;
    }

    // @dev `approve`関数の実装、トークンの権限委任ロジック
    function approve(address spender, uint256 amount) public override returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    // @dev `transferFrom`関数の実装、トークンの委任トランスファロジック
    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        allowance[sender][msg.sender] -= amount;
        balanceOf[sender] -= amount;
        balanceOf[recipient] += amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }

    // @dev トークンのミント、`0`アドレスからcallerアドレスへトークンを転送
    function mint(uint256 amount) external {
        balanceOf[msg.sender] += amount;
        totalSupply += amount;
        emit Transfer(address(0), msg.sender, amount);
    }

    // @dev トークンをバーンする。 callerアドレスから`0`アドレスへトークンを転送
    function burn(uint256 amount) external {
        balanceOf[msg.sender] -= amount;
        totalSupply -= amount;
        emit Transfer(msg.sender, address(0), amount);
    }
}

// ERC20トークンのフォーセットコントラクト
contract Faucet {
    uint256 public amountAllowed = 100; // 一回のリクエストで送るトークン数量
    address public tokenContract; // tokenコントラクトアドレス
    mapping(address => bool) public requestedAddress; // リクエスト済みアドレスの記録

    // SendTokenイベント
    event SendToken(address indexed Receiver, uint256 indexed Amount);

    // デプロイ時にtokenコントラクトアドレスを設定
    constructor(address _tokenContract) {
        tokenContract = _tokenContract; // set token contract
    }

    // ユーザーがトークンをリクエストする関数
    function requestTokens() external {
        require(!requestedAddress[msg.sender], "Can't Request Multiple Times!"); // アドレスごとに一回だけリクエスト可能
        IERC20 token = IERC20(tokenContract); // 创建IERC20合约对象
        require(token.balanceOf(address(this)) >= amountAllowed, "Faucet Empty!"); // フォーセットの残高が足りない

        token.transfer(msg.sender, amountAllowed); // tokenを送る
        requestedAddress[msg.sender] = true; // 受け取ったアドレスを記録

        emit SendToken(msg.sender, amountAllowed); // SendTokenイベントを放出
    }
}
