/**
 *Submitted for verification at polygonscan.com on 2022-08-01
*/

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

contract AlertTest{
    uint256 public count;

    mapping(address => uint256) private _count;

    event Count(address owner, uint256 counter);

    function increaseCount() public{
        ++_count[msg.sender];
        count++;
        emit Count(msg.sender, count);
    }
}