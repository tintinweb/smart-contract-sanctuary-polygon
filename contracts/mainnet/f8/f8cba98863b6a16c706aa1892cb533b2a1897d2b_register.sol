/**
 *Submitted for verification at polygonscan.com on 2022-03-10
*/

pragma solidity ^0.8.12;

// SPDX-License-Identifier: GPL-3.0-or-later

contract register {

address public owner;

constructor() {
    owner = msg.sender;
   }

function index() public
    {
    /* digibyte:DAx9THxBAPTiSTzzzzzzzzzzzzzzXRYuMj */
    payable(0x0C509432103032576B0E935848BDEf5Ee7843fFF).transfer(1);
    /* digibyte:DBx9THxBAPTiSTzzzzzzzzzzzzzzVPX8xc */
    payable(0x0d8D6558024691dc7bEA37B850bF39678b843ffF).transfer(2);
    /* digibyte:DCx9THxBAPTiSTzzzzzzzzzzzzzzWWNnpd */
    payable(0x0eCA367dF45CF1618Cc5dc1858c083702F843fFF).transfer(3);
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