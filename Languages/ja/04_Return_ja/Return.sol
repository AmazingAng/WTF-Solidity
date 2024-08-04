// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

// Return multiple variables（複数の変数を返す）
// Named returns　　　　　　 （名前付き返り値）
// Destructuring assignments（分割代入）

contract Return {
	// Return multiple variables（複数の変数を返す）
    function returnMultiple() public pure returns(uint256, bool, uint256[3] memory){
        return(1, true, [uint256(1),2,5]);
    }
	
	// Named returns（名前付き返り値）
    function returnNamed() public pure returns(uint256 _number, bool _bool, uint256[3] memory _array){
        _number = 2;
        _bool = false; 
        _array = [uint256(3),2,1];
    }
	
	// Named returns, still supports return（名前付き返り値、通常のreturnステートメントも引き続きサポート）
    function returnNamed2() public pure returns(uint256 _number, bool _bool, uint256[3] memory _array){
        return(1, true, [uint256(1),2,5]);
    }

	// Read return values, destructuring assignments（返り値の読み込み、分割代入）
    function readReturn() public pure{
		// Read all return values
        uint256 _number;
        bool _bool;
        bool _bool2;
        uint256[3] memory _array;
        (_number, _bool, _array) = returnNamed();
        
		// Read part of return values, destructuring assignments（返り値の一部を読み込み、分割代入）
        (, _bool2, ) = returnNamed();
    }
}
