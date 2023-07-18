/**
 *Submitted for verification at polygonscan.com on 2023-07-18
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract WalletLocking{
    mapping(address => uint256) private walletsLocked;

    event Lock(address indexed owner, uint256 lockedUntil);

    function lock() external {
        walletsLocked[msg.sender] = block.timestamp;
        emit Lock(msg.sender, block.timestamp);
    }

    function getWalletLock(address owner) public view returns(uint256){
        return walletsLocked[owner];
    }


}