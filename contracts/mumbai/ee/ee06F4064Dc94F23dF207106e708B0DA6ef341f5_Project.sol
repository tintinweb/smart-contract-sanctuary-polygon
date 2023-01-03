// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.15;

//contract to record all crowdfunding projects
contract Project {
    address[] public publishedProjs;

    event ProjectCreated(
        string title,
        string description,
        string founders,
        string categories,
        string image,
        string social,
        string mail,
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
        string memory projDescription,
        string memory projFounders,
        string memory projCategories,
        string memory projImage,
        string memory projSocial,
        string memory projMail,
        uint256 projGoalAmount // address ownerWallet
    ) public {
        //initializing FundProject contract
        FundProject newproj = new FundProject(
            //passing arguments from constructor function
            projectTitle,
            projDescription,
            projFounders,
            projCategories,
            projImage,
            projSocial,
            projMail,
            projGoalAmount
            // ownerWallet
        );

        //pushing project address
        publishedProjs.push(address(newproj));

        //calling ProjectCreated (event above)
        emit ProjectCreated(
            projectTitle,
            projDescription,
            projFounders,
            projCategories,
            projImage,
            projSocial,
            projMail,
            projGoalAmount,
            msg.sender,
            address(newproj),
            block.timestamp
        );
    }
}

contract FundProject {
    //defining state variables
    string public title;
    string public description;
    string public founders;
    string public categories;
    string public image;
    string public social;
    string public mail;
    uint256 public goalAmount;
    uint256 public raisedAmount;
    address ownerWallet; //address where amount to be transfered

    event Funded(
        address indexed donar,
        uint256 indexed amount,
        uint256 indexed timestamp
    );

    constructor(
        string memory projectTitle,
        string memory projDescription,
        string memory projFounders,
        string memory projCategories,
        string memory projImage,
        string memory projSocial,
        string memory projMail,
        uint256 projGoalAmount
    ) {
        //mapping values
        title = projectTitle;
        description = projDescription;
        founders = projFounders;
        categories = projCategories;
        image = projImage;
        social = projSocial;
        mail = projMail;
        goalAmount = projGoalAmount;
    }

    //donation function
    function makeDonation() public payable {
        //if goal amount is achieved, close the proj
        require(goalAmount > raisedAmount, "GOAL ACHIEVED");

        //record walletaddress of donor
        (bool success, ) = payable(ownerWallet).call{value: msg.value}("");
        require(success, "VALUE NOT TRANSFERRED");

        //calculate total amount raised
        raisedAmount += msg.value;

        emit Funded(msg.sender, msg.value, block.timestamp);
    }
}