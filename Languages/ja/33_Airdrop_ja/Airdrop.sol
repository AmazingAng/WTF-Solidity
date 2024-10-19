// SPDX-License-Identifier: MIT
// By 0xAA
pragma solidity ^0.8.21;

import "./IERC20.sol"; //import IERC20

/// @notice 複数のアドレスに対してトークンをエアドロするコントラクト
contract Airdrop {
    mapping(address => uint256) failTransferList;

    /// @notice 複数のアドレスに対してERC20トークンをエアドロする。使用前に承認が必要
    ///
    /// @param _token エアドロップするERC20トークンのアドレス
    /// @param _addresses エアドロップするアドレスの配列
    /// @param _amounts トークンの数量の配列（各アドレスにエアドロップするトークンの数量）
    function multiTransferToken(address _token, address[] calldata _addresses, uint256[] calldata _amounts) external {
        // チェック：_addressesと_amounts配列の長さが等しいこと
        require(_addresses.length == _amounts.length, "Lengths of Addresses and Amounts NOT EQUAL");
        IERC20 token = IERC20(_token); // IERC20コントラクトインスタンスを宣言
        uint256 _amountSum = getSum(_amounts); // エアドロップするトークンの総量を計算
        // チェック：承認されたトークン数 > エアドロップするトークンの総量
        require(token.allowance(msg.sender, address(this)) > _amountSum, "Need Approve ERC20 token");

        // forループを使用し、transferFrom関数でエアドロップを送信
        for (uint256 i; i < _addresses.length; i++) {
            token.transferFrom(msg.sender, _addresses[i], _amounts[i]);
        }
    }

    /// 複数のアドレスにETHを送金する
    function multiTransferETH(address payable[] calldata _addresses, uint256[] calldata _amounts) public payable {
        // チェック：_addressesと_amounts配列の長さが等しいこと
        require(_addresses.length == _amounts.length, "Lengths of Addresses and Amounts NOT EQUAL");
        uint256 _amountSum = getSum(_amounts); // エアドロップするETHの総量を計算
        // 送金されたETHがエアドロップの総量と等しいことをチェック
        require(msg.value == _amountSum, "Transfer amount error");
        // forループを使用し、call関数でETHを送信
        for (uint256 i = 0; i < _addresses.length; i++) {
            // コメントアウトされたコードにはDoS攻撃のリスクがあり、transferも推奨されない書き方です
            // DoS攻撃については https://github.com/AmazingAng/WTF-Solidity/blob/main/S09_DoS/readme.md を参照してください
            // _addresses[i].transfer(_amounts[i]);
            (bool success,) = _addresses[i].call{value: _amounts[i]}("");
            if (!success) {
                failTransferList[_addresses[i]] = _amounts[i];
            }
        }
    }

    // エアドロップ失敗に対して能動的な操作の機会を提供
    function withdrawFromFailList(address _to) public {
        uint256 failAmount = failTransferList[msg.sender];
        require(failAmount > 0, "You are not in failed list");
        failTransferList[msg.sender] = 0;
        (bool success,) = _to.call{value: failAmount}("");
        require(success, "Fail withdraw");
    }

    // 配列の合計を計算する関数
    function getSum(uint256[] calldata _arr) public pure returns (uint256 sum) {
        for (uint256 i = 0; i < _arr.length; i++) {
            sum = sum + _arr[i];
        }
    }
}

// ERC20トークンコントラクト
contract ERC20 is IERC20 {
    mapping(address => uint256) public override balanceOf;

    mapping(address => mapping(address => uint256)) public override allowance;

    uint256 public override totalSupply; // トークンのトータルサプライ（総供給量）

    string public name; // 名前
    string public symbol; // シンボル

    uint8 public decimals = 18; // 小数点以下の桁数

    constructor(string memory name_, string memory symbol_) {
        name = name_;
        symbol = symbol_;
    }

    // @dev `transfer`関数を実装、トークン転送ロジック
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        balanceOf[msg.sender] -= amount;
        balanceOf[recipient] += amount;
        emit Transfer(msg.sender, recipient, amount);
        return true;
    }

    // @dev `approve`関数を実装、トークン承認ロジック
    function approve(address spender, uint256 amount) public override returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    // @dev `transferFrom`関数を実装、トークン承認転送ロジック
    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        allowance[sender][msg.sender] -= amount;
        balanceOf[sender] -= amount;
        balanceOf[recipient] += amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }

    // @dev トークンをミントする。`0`アドレスから呼び出し元アドレスに転送
    function mint(uint256 amount) external {
        balanceOf[msg.sender] += amount;
        totalSupply += amount;
        emit Transfer(address(0), msg.sender, amount);
    }

    // @dev トークンをバーン。呼び出し元アドレスから`0`アドレスに転送
    function burn(uint256 amount) external {
        balanceOf[msg.sender] -= amount;
        totalSupply -= amount;
        emit Transfer(msg.sender, address(0), amount);
    }
}
