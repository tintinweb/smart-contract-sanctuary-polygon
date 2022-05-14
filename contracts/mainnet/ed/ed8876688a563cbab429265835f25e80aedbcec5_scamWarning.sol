/**
 *Submitted for verification at polygonscan.com on 2022-05-14
*/

pragma solidity ^0.8.13;

// SPDX-License-Identifier: GPL-3.0-or-later

contract scamWarning  {

/* Copyright Secret Beach Solutions 2022 */
/* John Rigler [email protected] */

address public owner;

constructor() {
    owner = msg.sender;
   }

function scamAlert(

/* 
Add the smart contract address of the suspicious Token on
the Ethereum network. A linkage will naturally get created that would be 
visible in Etherscan if people click on 'click to view address on 
other chains'. Not only does this give the user an action to do
directly from Etherscan, but 3rd Parth Scan alert websites can
monitor this. The obviously unspendable address which is all twos
is now purposed to be a global index for scam warning. Contribute to 
this project by sending Polygon directly to its address.
*/

    string memory message,
    address payable suspectedScam
) public
    {
    payable(0x2222222222222222222222222222222222222222).transfer(1);
    payable(suspectedScam).transfer(1);
     }

function scamReply(

/* 
Just as the accusers of a scammer are exposing their ethereum address in
an irrevocable way, so too can the accused use this option to reply.
*/

    string memory message,
    address payable suspectedScam
) public
    {
    payable(0x2222222222222222222222222222222222222222).transfer(1);
    payable(suspectedScam).transfer(1);
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