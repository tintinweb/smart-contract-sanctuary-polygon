// SPDX-License-Identifier: UNLICENSED 
pragma solidity ^0.8.0;

contract AddressValidator {
    
    function isContract(address _address) public view returns (bool) {
        uint32 size;
        assembly {
            size := extcodesize(_address)
        }
        return (size > 0);
    }
}