// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SupplyChainManagement {
    enum UserType { Farmer, Manufacturer, Distributor, Retailer, Consumer }

    struct User {
        string name;
        address ethereumAddress;
        UserType userType;
    }

    mapping(address => User) public users;
    mapping(address => bool) public isUserRegistered;

    address public owner;

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the contract owner can call this function");
        _;
    }

    modifier onlyRegisteredUser() {
        require(isUserRegistered[msg.sender], "User is not registered");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function registerUser(string memory _name, string memory _userType) public {
        require(!isUserRegistered[msg.sender], "User is already registered");

        UserType userType = parseUserType(_userType);
        require(userType != UserType(0), "Invalid user type");

        User storage newUser = users[msg.sender];
        newUser.name = _name;
        newUser.ethereumAddress = msg.sender;
        newUser.userType = userType;

        isUserRegistered[msg.sender] = true;
    }

    function parseUserType(string memory _userType) private pure returns (UserType) {
    if (equalsIgnoreCase(_userType, "Farmer")) {
        return UserType.Farmer;
    } else if (equalsIgnoreCase(_userType, "Manufacturer")) {
        return UserType.Manufacturer;
    } else if (equalsIgnoreCase(_userType, "Distributor")) {
        return UserType.Distributor;
    } else if (equalsIgnoreCase(_userType, "Retailer")) {
        return UserType.Retailer;
    } else if (equalsIgnoreCase(_userType, "Consumer")) {
        return UserType.Consumer;
    } else {
        revert("Invalid user type");
    }
}

function equalsIgnoreCase(string memory a, string memory b) private pure returns (bool) {
    return (keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b)));
}


    function compareStrings(string memory a, string memory b) private pure returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }

    function getUserDetails() public view onlyRegisteredUser returns (string memory, address, UserType) {
        User storage user = users[msg.sender];
        return (user.name, user.ethereumAddress, user.userType);
    }

    function addfarmproduce(string memory /*_farmproduceName*/, string memory /*_quantity*/,string memory /*_quanlity*/) public view onlyRegisteredUser {
        require(users[msg.sender].userType == UserType.Farmer, "Only farmers can add farmproduce");

        // Add farmproduce logic
    }

    function manufactureProduct(string memory /*_productName*/, uint256 /*_quantity*/) public view onlyRegisteredUser {
        require(users[msg.sender].userType == UserType.Manufacturer, "Only manufacturers can manufacture products");

        // Manufacture product logic
    }

    function distributeProduct(address /*_manufacturer*/, address /*_retailer*/, address /*_consumer*/, string memory /*_productName*/, uint256 /*_quantity*/) public view onlyRegisteredUser {
        require(users[msg.sender].userType == UserType.Distributor, "Only distributors can distribute products");

        // Distribute product logic
    }

    function sellProduct(address /*_farmer*/,address /*_manufacturer*/, address /*_retailer*/, string memory /*_productName*/, uint256 /*_quantity*/) public view onlyRegisteredUser {
        require(
            users[msg.sender].userType == UserType.Farmer ||
            users[msg.sender].userType == UserType.Manufacturer ||
            users[msg.sender].userType == UserType.Retailer,
            "Only farmers,manufacturers, retailers can sell products");

        // Sell product logic
    }
  
    function purchaseProduct(address /*_manufacturer*/, address /*_retailer*/, address /*_consumer*/, string memory/*_productName*/, string memory /*_quantity*/) public view onlyRegisteredUser {
        require(
            users[msg.sender].userType == UserType.Manufacturer||
            users[msg.sender].userType == UserType.Retailer||
            users[msg.sender].userType == UserType.Consumer ,"Only manufacturer,retailer,consumers can purchase products");


        // Purchase product logic
    }
  }