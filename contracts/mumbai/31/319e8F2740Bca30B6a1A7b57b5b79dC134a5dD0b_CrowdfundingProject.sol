// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.15;

//contract to record all crowdfunding projects
contract CrowdFactory {
    address[] public publishedProjs;

    event Projectcreated(
        string projTitle,
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
        string memory founders,
        string memory categories,
        string memory image,
        string memory social,
        string memory mail,
        uint256 projgoalAmount,
        string memory projDescript,
        address ownerWallet
    ) public {
        //initializing CrowdfundingProject contract
        CrowdfundingProject newproj = new CrowdfundingProject(
            //passing arguments from constructor function
            projectTitle,
            founders,
            categories,
            image,
            social,
            mail,
            projgoalAmount,
            projDescript,
            ownerWallet
        );

        //pushing project address
        publishedProjs.push(address(newproj));

        //calling Projectcreated (event above)
        emit Projectcreated(
            projectTitle,
            founders,
            categories,
            image,
            social,
            mail,
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
    string public founders;
    string public categories;
    string public image;
    string public social;
    string public mail;
    string public projDescription;
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
        string memory founders,
        string memory categories,
        string memory image,
        string memory social,
        string memory mail,
        uint256 projgoalAmount,
        string memory projDescript,
        address ownerWallet_
    ) {
        //mapping values
        projTitle = projectTitle;
        founders = founders;
        categories = categories;
        image = image;
        social = social;
        mail = mail;
        goalAmount = projgoalAmount;
        projDescription = projDescript;
        ownerWallet = ownerWallet_;
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