/**
 *Submitted for verification at polygonscan.com on 2023-05-19
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Destructor {
    address payable owner = payable(msg.sender);
    receive() external payable{}
    
    function retrieve() external {
        selfdestruct(owner);
    }
}