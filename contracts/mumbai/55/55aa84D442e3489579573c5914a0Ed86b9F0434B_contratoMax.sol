// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.10;

contract contratoMax {

    mapping (address => address[]) public registro;
    
    function registroAddress(address _address) public returns (uint256) {
        registro[msg.sender].push(_address);
        return 11111111111111111111222;
    }
}