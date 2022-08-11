// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SplitRevenue {
    address public owner;
    address public collaborator;
    uint8 private collaborator_percentage;


    /// percentage: 1-100
    constructor(address _collaborator, uint8 _collaborator_percentage) {
        owner = msg.sender;
        collaborator = _collaborator;
        collaborator_percentage = _collaborator_percentage;
    }

    function setOwnerPercentage(uint8 _owner_percentage) public onlyOwner {
        collaborator_percentage = _owner_percentage;
    }

    function setCollaborator(address _newAddress) public onlyOwner {
        collaborator = _newAddress;
    }

    function withdraw() public payable onlyCollaborators {
        uint256 _balance = address(this).balance;
        require(
            _balance > 0,
            "No balance."
        );

        uint256 _share1 = _balance * (collaborator_percentage/100);
        payable(collaborator).transfer(_share1);

        uint256 _share2 = _balance - _share1;       // get remaining balance for owner
        payable(owner).transfer(_share2);
    }

    modifier onlyOwner() {
        require(
            (msg.sender == owner),
            "Only owner can run function."
        );
        _;
    }

    modifier onlyCollaborators() {
        require(
            (msg.sender == owner) || (msg.sender == collaborator),
            "Only owner can send transfers."
        );
        _;
    }
}