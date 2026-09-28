// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

/**
 * @title 整数オーバーフロー脆弱性のデモ
 * @dev このコントラクトは教育目的で整数オーバーフロー脆弱性を含んでいます。
 *      本番環境では絶対に使用しないでください。
 */
contract Token {
  // 各アドレスのトークン残高を記録
  mapping(address => uint) balances;

  // トークンの総供給量
  uint public totalSupply;

  /**
   * @dev コンストラクタ：初期供給量を設定
   * @param _initialSupply 初期トークン供給量
   */
  constructor(uint _initialSupply) {
    balances[msg.sender] = totalSupply = _initialSupply;
  }

  /**
   * @dev トークン送金関数 - 整数オーバーフロー脆弱性あり
   * @param _to 送金先アドレス
   * @param _value 送金額
   * @return 送金成功の可否
   *
   * 脆弱性：uncheckedブロック内で残高チェックが行われているため、
   * 整数アンダーフローにより不正な送金が可能になります。
   */
  function transfer(address _to, uint _value) public returns (bool) {
    unchecked{
        // 危険：整数アンダーフローによりこのチェックを回避可能
        require(balances[msg.sender] - _value >= 0);
        balances[msg.sender] -= _value;
        balances[_to] += _value;
    }
    return true;
  }

  /**
   * @dev 残高照会関数
   * @param _owner 残高を照会するアドレス
   * @return balance 指定アドレスの残高
   */
  function balanceOf(address _owner) public view returns (uint balance) {
    return balances[_owner];
  }
}