// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

/**
 * @title 安全なトークンコントラクト - 整数オーバーフロー保護あり
 * @dev このコントラクトは適切な整数オーバーフロー保護を実装しています。
 *      Solidity 0.8.0以降の内蔵SafeMath機能を活用しています。
 */
contract SafeToken {
    // 各アドレスの残高を記録するマッピング
    mapping(address => uint) balances;

    // トークンの総供給量
    uint public totalSupply;

    // イベント：送金が発生した際に発行
    event Transfer(address indexed from, address indexed to, uint value);

    /**
     * @dev コンストラクタ - トークンの初期供給量を設定
     * @param _initialSupply トークンの初期総供給量
     */
    constructor(uint _initialSupply) {
        // デプロイヤーに全ての初期供給量を割り当て
        balances[msg.sender] = totalSupply = _initialSupply;
        emit Transfer(address(0), msg.sender, _initialSupply);
    }

    /**
     * @dev 安全なトークン送金関数 - 方法1: Solidity 0.8.0+の内蔵保護を使用
     * @param _to 送金先のアドレス
     * @param _value 送金するトークン量
     * @return 送金が成功したかどうか
     *
     * 安全性の説明：
     * - uncheckedブロックを使用していないため、Solidity 0.8.0+の
     *   内蔵オーバーフロー/アンダーフローチェックが有効
     * - 残高不足の場合、減算時に自動的にリバートされる
     * - 明示的な残高チェックも追加でセキュリティを強化
     */
    function transfer(address _to, uint _value) public returns (bool) {
        // 明示的な残高チェック（内蔵チェックに加えた追加保護）
        require(balances[msg.sender] >= _value, "残高不足です");
        require(_to != address(0), "無効なアドレスです");

        // Solidity 0.8.0+では、これらの計算で自動的にオーバーフローチェックされる
        balances[msg.sender] -= _value; // 残高不足の場合、ここで自動的にリバート
        balances[_to] += _value;

        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    /**
     * @dev uncheckedブロックを安全に使用する送金関数の例
     * @param _to 送金先のアドレス
     * @param _value 送金するトークン量
     * @return 送金が成功したかどうか
     *
     * 注意：uncheckedを使用する場合は、事前に十分なチェックが必要
     */
    function transferWithUnchecked(address _to, uint _value) public returns (bool) {
        // uncheckedブロックを使用する前に、必要なチェックを実行
        require(_to != address(0), "無効なアドレスです");
        require(balances[msg.sender] >= _value, "残高不足です");

        unchecked {
            // 事前チェックにより、ここでのオーバーフローは発生しないことが保証されている
            balances[msg.sender] -= _value;
            balances[_to] += _value;
        }

        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    /**
     * @dev 指定されたアドレスの残高を照会
     * @param _owner 残高を照会するアドレス
     * @return balance そのアドレスのトークン残高
     */
    function balanceOf(address _owner) public view returns (uint balance) {
        return balances[_owner];
    }

    /**
     * @dev 承認機能付きの送金（ERC-20標準に近い実装）
     * @param _from 送金元のアドレス
     * @param _to 送金先のアドレス
     * @param _value 送金するトークン量
     * @return 送金が成功したかどうか
     */
    mapping(address => mapping(address => uint)) public allowance;

    function approve(address _spender, uint _value) public returns (bool) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }

    function transferFrom(address _from, address _to, uint _value) public returns (bool) {
        require(_to != address(0), "無効なアドレスです");
        require(balances[_from] >= _value, "送金元の残高不足です");
        require(allowance[_from][msg.sender] >= _value, "承認額不足です");

        // すべてのチェックが完了してから状態を更新
        balances[_from] -= _value;
        balances[_to] += _value;
        allowance[_from][msg.sender] -= _value;

        emit Transfer(_from, _to, _value);
        return true;
    }

    /**
     * @dev 安全性テスト関数 - 様々な境界値での動作を確認
     */
    function securityTest() public view returns (bool) {
        // 最大値近くでの計算をテスト
        uint maxUint = type(uint).max;

        // これらの計算は安全で、オーバーフローする場合はリバートされる
        try this.testOverflow(maxUint, 1) {
            return false; // オーバーフローが発生しなかった場合（予期しない）
        } catch {
            return true; // 正常にオーバーフローが検出されリバートした
        }
    }

    function testOverflow(uint a, uint b) external pure returns (uint) {
        return a + b; // オーバーフローする場合はリバート
    }
}