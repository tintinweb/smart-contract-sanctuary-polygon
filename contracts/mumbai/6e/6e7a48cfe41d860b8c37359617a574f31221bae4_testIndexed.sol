/**
 *Submitted for verification at polygonscan.com on 2022-10-11
*/

// SPDX-License-Identifier: MIT
// SPDX-License-Identifier: MIT
pragma solidity  ^0.8.4;

contract testIndexed {
    event Transfer(address  from, address  to, uint256 indexed value);
    
    function callTransfer(address _to) public {
        emit Transfer(msg.sender, _to, 1000000000);
    }
    
}