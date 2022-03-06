/**
 *Submitted for verification at polygonscan.com on 2022-03-06
*/

pragma solidity ^0.8.12;

// SPDX-License-Identifier: GPL-3.0-or-later

contract DAx9THxBAPTiSTzzzzzzzzzzzzzzXRYuMj {

address public owner;

constructor() {
    owner = msg.sender;
   }


// Created for [email protected]
// Co-chain transactions:
// https://digibyteblockexplorer.com/tx/f9db015188351765e536c77fe9aff17826692bee5334a5cbf0b036902457ef60
// https://digibyteblockexplorer.com/address/DKjAs9k5zDPgmAKx7boKJco39dew6FrGrr
//
// The board of directors has met and assessed our donations.
// The board of directors has voted to assign these founding
// members and friends a 'clergy' status and awards to them
// the following payment:

function tax_exempt_parsonage_stipend() public
    {
    // unspendable Ax9THxBAPTiSTzzzzzzzzzzzzzz
    payable(0x0C509432103032576B0E935848BDEf5Ee7843fFF).transfer(0);
    // church founders
    payable(0x2Ccc96B3690F88F05b1B99319c4eCfce033Dddd5).transfer(22000000100000039692);
    payable(0xE46E46Bc205DF560874C18F2430C18a604253120).transfer(22000000200000039692);
    payable(0xE439E7045ff541Ba3a4fCf798aF26781685Df33d).transfer(22000000300000039692);
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