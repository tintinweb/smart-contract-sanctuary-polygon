//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

// Test SC - V

contract donateToday {
    address payable owner;

    constructor() {
        owner = payable(msg.sender);
    }

    event Donate(
        address from,
        uint256 amount,
        string message
    );

    function newDonation(string memory note) public payable {
        (bool success,) = owner.call{value: msg.value}("");
        require(success, "Failed to donate!");

        emit Donate(
            msg.sender,
            msg.value,
            note
        );
    }

}