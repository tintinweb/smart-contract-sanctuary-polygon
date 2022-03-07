/**
 *Submitted for verification at polygonscan.com on 2022-03-06
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.5;

contract DeployBytecode {
    
    // Create contract from bytecode
    function deployBytecode(bytes memory bytecode) public returns (address) {
        address retval;
        assembly{
            mstore(0x0, bytecode)
            retval := create(0,0xa0, calldatasize())
        }
        return retval;
   }
}