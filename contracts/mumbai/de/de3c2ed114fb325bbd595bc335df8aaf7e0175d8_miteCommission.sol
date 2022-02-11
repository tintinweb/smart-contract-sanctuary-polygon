/**
 *Submitted for verification at polygonscan.com on 2022-01-30
*/

pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT

interface IMite {
    function comTransfer(address, address, uint256) external returns (bool);
}

contract miteCommission {
    address owner;
    address tokenAddress;    
    
    constructor () {
        owner = msg.sender;
    }

    function setTokenAddr(address _tokAdd) public {
        require(msg.sender == owner);
        tokenAddress = _tokAdd;
    }

    function transfer(address recipient, uint256 amount) public returns (bool) {
        return IMite(tokenAddress).comTransfer(msg.sender, recipient, amount);
    }

    function decimals() public view virtual returns (uint8) {
        return 18;
    }
}