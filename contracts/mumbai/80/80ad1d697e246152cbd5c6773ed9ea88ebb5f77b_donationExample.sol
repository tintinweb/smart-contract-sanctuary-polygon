/**
 *Submitted for verification at polygonscan.com on 2022-08-08
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract donationExample {
    
    address payable owner;

    constructor() {
        owner = payable(msg.sender);
    }

    event Donate (
        address from,
        uint256 amount,
        string messg
    );

    function newDonation(string memory note) public payable{
        (bool success, ) = owner.call{value: msg.value}("");
        require(success, "Failed to send money");
        emit Donate(
            msg.sender,
            msg.value,
            note
        );
    }

}