// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

/**
 * @title 脆弱なトークンコントラクト - 整数オーバーフロー脆弱性のデモ
 * @dev このコントラクトには意図的に整数オーバーフロー脆弱性が含まれています。
 *      教育目的でのみ使用し、本番環境では使用しないでください。
 */
contract VulnerableToken {
    // 各アドレスの残高を記録するマッピング
    mapping(address => uint) balances;

    // トークンの総供給量
    uint public totalSupply;

    /**
     * @dev コンストラクタ - トークンの初期供給量を設定
     * @param _initialSupply トークンの初期総供給量
     */
    constructor(uint _initialSupply) {
        // デプロイヤーに全ての初期供給量を割り当て
        balances[msg.sender] = totalSupply = _initialSupply;
    }

    /**
     * @dev トークン送金関数 - 整数オーバーフロー脆弱性あり
     * @param _to 送金先のアドレス
     * @param _value 送金するトークン量
     * @return 送金が成功したかどうか
     *
     * 脆弱性の説明：
     * uncheckedブロック内では整数オーバーフローチェックが無効になります。
     * balances[msg.sender] - _value の計算で、
     * 送信者の残高が_valueより少ない場合、アンダーフローが発生し、
     * 非常に大きな数値（2^256に近い値）になります。
     * この大きな値は >= 0 の条件を満たすため、requireチェックを通過してしまいます。
     */
    function transfer(address _to, uint _value) public returns (bool) {
        unchecked {
            // 危険：整数アンダーフローによりこのチェックが無効化される
            // 例：残高が100で、1000を送金しようとすると、
            // 100 - 1000 = アンダーフロー → 非常に大きな正の数
            require(balances[msg.sender] - _value >= 0);

            // 送信者の残高を減らす（アンダーフローが発生する可能性）
            balances[msg.sender] -= _value;

            // 受信者の残高を増やす
            balances[_to] += _value;
        }
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
     * @dev 攻撃のデモンストレーション関数
     * @notice この関数は脆弱性がどのように悪用されるかを示します
     */
    function demonstrateAttack() public {
        // 攻撃者の初期残高を確認（通常は0またはごく少量）
        uint initialBalance = balances[msg.sender];

        // 実際の残高を超える大量のトークンを送金しようと試みる
        // 例：残高が0でも1000トークンを送金
        transfer(address(0x1), 1000);

        // 攻撃後の残高を確認（非常に大きな値になる）
        uint finalBalance = balances[msg.sender];

        // この時点で、攻撃者の残高は約2^256 - 1000になっている
    }
}