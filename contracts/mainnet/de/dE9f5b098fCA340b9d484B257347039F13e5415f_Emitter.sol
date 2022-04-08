// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract Emitter {
    string public constant name = "Emitter";
    string public constant symbol = "EM";
    uint256 public constant decimals = 2;

    event Transfer(address,uint256,uint256);
    function transfer(address x, uint256 y, uint256 z) external {
        emit Transfer(x, y, z);
    }

    
}