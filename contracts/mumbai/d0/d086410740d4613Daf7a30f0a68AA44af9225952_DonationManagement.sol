// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract DonationManagement {
    //MODIFIERS

    modifier onlyOwner() {
        require(msg.sender == i_owner, "caller is not owner");
        _;
    }

    // STRUCTS
    struct Donation {
        uint donatedAt;
        uint amount;
        address donator;
        string details;
    }

    // EVENTS

    event NewDonation(address donator, uint amount, uint donatedAt);

    // STATE VARIABLES
    Donation[] private s_donations;
    address payable immutable i_owner;

    // FUNCTIONS

    constructor() {
        i_owner = payable(msg.sender);
    }

    function donate(string memory details) public payable {
        require(msg.value > 0, "amount should be greater than zero");
        s_donations.push(
            Donation(block.timestamp, msg.value, msg.sender, details)
        );
        emit NewDonation(msg.sender, msg.value, block.timestamp);
    }

    function withdraw() external onlyOwner {
        require(address(this).balance > 0, "Insufficient balance");
        (bool success, ) = i_owner.call{value: address(this).balance}("");
        require(success, "transaction failes");
    }

    // VIEW FUNCTIONS

    function getDonations() public view returns(Donation[] memory){
        return s_donations;
    }

    function getOwner() public view returns(address){
        return i_owner;
    }
}