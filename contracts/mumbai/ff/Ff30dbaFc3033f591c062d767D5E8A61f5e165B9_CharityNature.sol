// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IPosup {
    function safeMint(address to, uint _campCounter) external;

    function closeCamp(uint _campCounter) external;
}

contract CharityNature {
    address payable public owner;

    constructor() payable {
        owner = payable(msg.sender);
    }

    uint max_donation_pool = 1000;

    uint total_reached;

    address posupAddress;

    function donate(
        uint _campId,
        address _to,
        address _posup
    ) public payable {
        require(max_donation_pool >= total_reached, "maximum donation reached");
        require(msg.value > 0, "the donation needs to be higher than 0");

        posupAddress = _posup;

        total_reached = total_reached + msg.value;

        return IPosup(posupAddress).safeMint(_to, _campId);
    }

    function withdraw(uint _campId) public {
        require(msg.sender == owner, "Not a contract owner");

        //if withdraw, the campaigning is closed in the Posup contract
        IPosup(posupAddress).closeCamp(_campId);

        uint amount = address(this).balance;

        (bool success, ) = owner.call{value: amount}("");
        require(success, "Failed to send Ether");
    }
}