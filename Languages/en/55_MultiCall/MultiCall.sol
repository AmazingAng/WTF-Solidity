// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract Multicall {
     // Call structure, including target contract target, whether to allow call failure allowFailure, and call data
     struct Call {
         address target;
         bool allowFailure;
         bytes callData;
     }

     // Result structure, including whether the call is successful and return data
     struct Result {
         bool success;
         bytes returnData;
     }

     /// @notice merges multiple calls (supporting different contracts/different methods/different parameters) into one call
     /// @param calls Array composed of Call structure
     /// @return returnData An array composed of Result structure
     function multicall(Call[] calldata calls) public returns (Result[] memory returnData) {
         uint256 length = calls.length;
         returnData = new Result[](length);
         Call calldata calli;
        
         // Called sequentially in the loop
         for (uint256 i = 0; i < length; i++) {
             Result memory result = returnData[i];
             calli = calls[i];
             (result.success, result.returnData) = calli.target.call(calli.callData);
             // If calli.allowFailure and result.success are both false, revert
             if (!(calli.allowFailure || result.success)){
                 revert("Multicall: call failed");
             }
         }
     }
}
