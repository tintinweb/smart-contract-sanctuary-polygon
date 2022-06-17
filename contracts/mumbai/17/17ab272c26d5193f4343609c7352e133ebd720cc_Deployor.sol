/**
 *Submitted for verification at polygonscan.com on 2022-06-16
*/

// SPDX-License-Identifier: Unlicensed

pragma solidity 0.8.7;

contract Deployor {
    event Deployed(address _contract);
    // Create contract from bytecode
    function deployBytecode(bytes memory bytecode) public payable returns (address) {
        address retval;

        assembly{
            mstore(0x0, bytecode)
            retval := create(callvalue(),0xa0, calldatasize())
        }
        emit Deployed(retval);
        return retval;
   }
}