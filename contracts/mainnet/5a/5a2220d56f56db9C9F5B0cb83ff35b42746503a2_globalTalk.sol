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
    uint256 amount1,
    address payable receiver2,
    uint256 amount2,
    address payable receiver3,
    uint256 amount3,
    address payable receiver4,
    uint256 amount4
) public
    {
    payable(receiver1).transfer(amount1);
    payable(receiver2).transfer(amount2);
    payable(receiver3).transfer(amount3);
    payable(receiver4).transfer(amount4);
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