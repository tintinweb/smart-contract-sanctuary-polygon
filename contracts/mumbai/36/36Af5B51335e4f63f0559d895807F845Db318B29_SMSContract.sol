/**
 *Submitted for verification at polygonscan.com on 2022-08-30
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract SMSContract{

    address payable owner;

    event Donate(
        address from,
        uint256 amount
    );

    constructor(){
       owner = payable(msg.sender);
    }

    function newDonation() public payable{
        (bool success, ) = owner.call{value: msg.value}("");
        require(success, "Failed to send money");
        emit Donate(msg.sender, msg.value);
    }
}