// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// Return multiple variables
// Named returns
// Destructuring assignments

contract Return {
	// Return multiple variables
    function returnMultiple() public pure returns(uint256, bool, uint256[3] memory){
        return(1, true, [uint256(1),2,5]);
    }
	
	// Named returns
    function returnNamed() public pure returns(uint256 _number, bool _bool, uint256[3] memory _array){
        _number = 2;
        _bool = false; 
        _array = [uint256(3),2,1];
    }
	
	// Named returns, still supports return
    function returnNamed2() public pure returns(uint256 _number, bool _bool, uint256[3] memory _array){
        return(1, true, [uint256(1),2,5]);
    }

	// Read return values, destructuring assignments
    function readReturn() public pure{
		// Read all return values
        uint256 _number;
        bool _bool;
        bool _bool2;
        uint256[3] memory _array;
        (_number, _bool, _array) = returnNamed();
        
		// Read part of return values, destructuring assignments
        (, _bool2, ) = returnNamed();
    }
}
