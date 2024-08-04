// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;
contract FunctionTypes{
    uint256 public number = 5;
    
    constructor() payable {}

    // function type（関数型）
    // function (<parameter types>) {internal|external} [pure|view|payable] [returns (<return types>)]
    // default function（デフォルトの関数）
    function add() external{
        number = number + 1;
    }

    // pure: not only does the function not save any data to the blockchain, but it also doesn't read any data from the blockchain.
    //（pure: 関数がブロックチェーンにどんなデータも保存しないだけでなく、ブロックチェーンからデータを読み込むこともない）
    function addPure(uint256 _number) external pure returns(uint256 new_number){
        new_number = _number+1;
    }
    
    // view: no data will be changed
    //（view: 何もデータが変更されない）
    function addView() external view returns(uint256 new_number) {
        new_number = number + 1;
    }

    // internal: the function can only be called within the contract itself and any derived contracts
    //（internal: 関数は、コントラクトそのものの中か、あらゆる派生したコントラクト内でのみ呼び出されることが出来る）
    function minus() internal {
        number = number - 1;
    }

    // external: function can be called by EOA/other contract
    //（external: 関数はEOAか他のコントラクトによって呼び出されることが出来る）
    function minusCall() external {
        minus();
    }

    // payable: money (ETH) can be sent to the contract via this function
    //（payable: 関数を経由してお金（イーサリアム）をコントラクトに送金することが出来る）
    function minusPayable() external payable returns(uint256 balance) {
        minus();    
        balance = address(this).balance;
    }
}