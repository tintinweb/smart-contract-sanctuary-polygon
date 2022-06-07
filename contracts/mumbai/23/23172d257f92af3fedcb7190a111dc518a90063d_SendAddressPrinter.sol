/**
 *Submitted for verification at polygonscan.com on 2022-06-06
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

contract SendAddressPrinter {

    address public lastSender;
   
    function appelleMoi() external{
        lastSender = msg.sender;
    }

}