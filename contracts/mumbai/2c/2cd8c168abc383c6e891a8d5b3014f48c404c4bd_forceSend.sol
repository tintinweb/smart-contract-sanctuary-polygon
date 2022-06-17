/**
 *Submitted for verification at polygonscan.com on 2022-06-16
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract forceSend {
    mapping (address => uint256) public amountFrom;

    function force(address payable _victim) external{
        selfdestruct(_victim);
    }


    function deposit() external payable {
        amountFrom[msg.sender] += msg.value;
    }
}