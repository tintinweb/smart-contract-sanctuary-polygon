// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.15;

contract CrowdFactory {
    address[] public publishedProjs;

    event Projectcreated(
        string projTitle,
        uint256 goalAmount,
        address indexed ownerWallet,
        address projAddress,
        uint256 indexed timestamp
    );

    function totalPublishedProjs() public view returns (uint256) {
        return publishedProjs.length;
    }

    function createProject(
        string memory projectTitle,
        uint256 projgoalAmount,
        string memory projDescript,
        address ownerWallet
    ) public {
        CrowdfundingProject newproj = new CrowdfundingProject(
            projectTitle,
            projgoalAmount,
            projDescript,
            ownerWallet
        );
        publishedProjs.push(address(newproj));
        emit Projectcreated(
            projectTitle,
            projgoalAmount,
            msg.sender,
            address(newproj),
            block.timestamp
        );
    }
}

contract CrowdfundingProject {
    string public projTitle;
    string public projDescription;
    uint256 public goalAmount;
    uint256 public raisedAmount;
    address ownerWallet;

    event Funded(
        address indexed donar,
        uint256 indexed amount,
        uint256 indexed timestamp
    );

    constructor(
        string memory projectTitle,
        uint256 projgoalAmount,
        string memory projDescript,
        address ownerWallet_
    ) {
        projTitle = projectTitle;
        goalAmount = projgoalAmount;
        projDescription = projDescript;
        ownerWallet = ownerWallet_;
    }

    function makeDonation() public payable {
        require(goalAmount > raisedAmount, "GOAL ACHIEVED");

        (bool success, ) = payable(ownerWallet).call{value: msg.value}("");
        require(success, "VALUE NOT TRANSFERRED");

        raisedAmount += msg.value;

        emit Funded(msg.sender, msg.value, block.timestamp);
    }
}