/**
 *Submitted for verification at polygonscan.com on 2022-04-19
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;
contract test{
   
    address Owner;
    constructor(){
        Owner=msg.sender;
    }

    function isOwnerOrNot() public view returns (bool)
    {
        return msg.sender==Owner;
    }

    function msgSender() public view returns (address)
    {
        return msg.sender;
    }
}