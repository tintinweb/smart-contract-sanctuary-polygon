/**
 *Submitted for verification at polygonscan.com on 2023-06-12
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;


error DB_ERROR();
contract Regitration {
    address[] public funders;

    address[] public Verif;

    address my_address = 0xCc385E621274629624EbFdc1E65f02b8b2538654;

    constructor() public {
        Verif.push(my_address);
    }

    function Verification() public payable {
       if (msg.sender != my_address) {
        revert DB_ERROR();
       } else {
        funders.push(msg.sender);
       }
    }
}