/**
 *Submitted for verification at polygonscan.com on 2022-11-30
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.0;

contract TestMsgSender {
    
    function whoAmI() external view returns(address) {
        return msg.sender;
    }
}