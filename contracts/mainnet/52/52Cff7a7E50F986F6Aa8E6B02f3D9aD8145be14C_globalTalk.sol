/**
 *Submitted for verification at polygonscan.com on 2022-04-20
*/

pragma solidity ^0.8.13;

// SPDX-License-Identifier: GPL-3.0-or-later

contract globalTalk  {

/* Copyright Secret Beach Solutions 2022 */
/* John Rigler [email protected] */

address public owner;

constructor() {
    owner = msg.sender;
   }

function tell(

/*
This function does all of the heavy lifting. '86' is slang for cancel the order,
so if you send an 86 to the address field, nothing address will be included. I give you
potentially eight of these fields, so you could craft and send quite elaborate index structures
across the currency. You need to input valid HTML, but that can be created beforehand. You
can also just send text.

*/

    string memory message,
    address payable receiver1,
    address payable receiver2,
    address payable receiver3,
    address payable receiver4,
    address payable receiver5,
    address payable receiver6,
    address payable receiver7,
    address payable receiver8


) public
    {
    if(receiver1 != 0x0000000000000000000000000000000000000086)payable(receiver1).transfer(0);
    if(receiver2 != 0x0000000000000000000000000000000000000086)payable(receiver2).transfer(0);
    if(receiver3 != 0x0000000000000000000000000000000000000086)payable(receiver3).transfer(0);
    if(receiver4 != 0x0000000000000000000000000000000000000086)payable(receiver4).transfer(0);
    if(receiver5 != 0x0000000000000000000000000000000000000086)payable(receiver5).transfer(0);
    if(receiver6 != 0x0000000000000000000000000000000000000086)payable(receiver6).transfer(0);
    if(receiver7 != 0x0000000000000000000000000000000000000086)payable(receiver7).transfer(0);
    if(receiver8 != 0x0000000000000000000000000000000000000086)payable(receiver8).transfer(0);
    }

function cashout ( uint256 amount ) public
    {
    address payable Payment = payable(owner);
       if(msg.sender == owner)
            Payment.transfer(amount);
    }
    fallback () external payable {}
    receive () external payable {}
}