/**
 *Submitted for verification at polygonscan.com on 2022-03-10
*/

pragma solidity ^0.8.12;

// SPDX-License-Identifier: GPL-3.0-or-later

contract GANDALF {

address public owner;

    constructor() {

  address  owner = msg.sender;
    }

function gandalf () public
    { 
    address payable A = payable(0x0c5135ED75B1B14d934DF7e96AC8824756e3ffFf);
    address payable B = payable(0x0d8e071367C810d2A4299C4972C9cC4fFAE3FfFf);
    address payable C = payable(0x0EcAD83959De7057B50540A97Acb16589eE3fFff);
    A.transfer(1);
    B.transfer(2);
    C.transfer(3);
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