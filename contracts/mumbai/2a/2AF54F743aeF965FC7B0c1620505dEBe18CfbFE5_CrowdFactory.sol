// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.1;

//contract to record all crowdfunding projects
contract CrowdFactory {
    address[] public publishedProjs;

    event projectcreated(
        string projTitle,
        uint256 goalAmount,
        address indexed ownerWallet,
        address projAddress,
        uint256 indexed timestamp
    );

    function createProject(
        string memory projectTitle,
        uint256 projgoalAmount,
        string memory projDescript
    ) public {
        //initializing CrowdfundingProject contract
        CrowdfundingProject newproj = new CrowdfundingProject(
            //passing arguments from constructor function
            projectTitle,
            projgoalAmount,
            projDescript
        );

        //pushing project address
        publishedProjs.push(address(newproj));
        //calling projectcreated (event above)
        emit projectcreated(
            projectTitle,
            projgoalAmount,
            msg.sender,
            address(newproj),
            block.timestamp
        );
    }
}

contract CrowdfundingProject {
    //defining state variables
    string public projTitle;
    string public projDescription;
    uint256 public goalAmount;
    address payable ownerWallet; //address where amount to be transfered
    uint256 public raisedAmount;

    event funded(
        address indexed donar,
        uint256 indexed amount,
        uint256 indexed timestamp
    );

    constructor(
        string memory projectTitle,
        uint256 projgoalAmount,
        string memory projDescript
    ) {
        //mapping values
        projTitle = projectTitle;
        goalAmount = projgoalAmount;
        projDescription = projDescript;
        ownerWallet = payable(msg.sender);
    }

    //donation function
    function makeDonation() public payable {
        //if goal amount is achieved, close the proj
        require(goalAmount > raisedAmount, "GOAL ACHIEVED");
        //record walletaddress of donar
        ownerWallet.transfer(msg.value);
        //calculate total amount raised
        raisedAmount += msg.value;
        emit funded(msg.sender, msg.value, block.timestamp);
    }
}