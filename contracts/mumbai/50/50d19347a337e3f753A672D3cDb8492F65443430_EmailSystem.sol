// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract EmailSystem {
    struct Email {
        string emailName;
        string emailExtension;
    }

    mapping(address => Email) private userEmails;
    mapping(string => address) private emailToWallet;
    mapping(address => string) private walletToEmail;
    mapping(string => bool) private registeredExtensions;
    uint256 private emailRegistrationPrice;
    address private contractOwner;

    event EmailRegistered(address indexed walletAddress, string indexed emailAddress);
    event EmailExtensionSet(address indexed walletAddress, string newExtension);
    event EmailRegistrationPriceSet(uint256 newPrice);

    constructor() {
        contractOwner = msg.sender;
        emailRegistrationPrice = 0.1 ether; // Default registration price
    }

    function registerEmail(string memory emailName, string memory emailExtension) public payable {
        require(msg.value == emailRegistrationPrice, "Incorrect amount sent");
        require(bytes(userEmails[msg.sender].emailName).length == 0, "Email already registered");
        require(registeredExtensions[emailExtension], "Invalid email extension");

        userEmails[msg.sender] = Email({
            emailName: emailName,
            emailExtension: emailExtension
        });

        string memory emailAddress = getEmailAddress(msg.sender);
        emailToWallet[emailAddress] = msg.sender;
        walletToEmail[msg.sender] = emailAddress;

        payable(contractOwner).transfer(emailRegistrationPrice);

        emit EmailRegistered(msg.sender, emailAddress);
    }

    function isEmailRegistered(address walletAddress) public view returns (bool) {
        return (bytes(userEmails[walletAddress].emailName).length != 0);
    }

    function isEmailAddressRegistered(string memory emailAddress) public view returns (bool) {
        address walletAddress = emailToWallet[emailAddress];
        return (walletAddress != address(0));
    }

    function getEmail(address walletAddress) public view returns (string memory) {
        return getEmailAddress(walletAddress);
    }

    function getWalletAddress(string memory email) public view returns (address) {
        return emailToWallet[email];
    }

    function setEmailExtension(string memory newExtension) public onlyOwner {
        userEmails[contractOwner].emailExtension = newExtension;

        emit EmailExtensionSet(contractOwner, newExtension);
    }

    function registerEmailExtension(string memory emailExtension) public onlyOwner {
        registeredExtensions[emailExtension] = true;
    }

    function unregisterEmailExtension(string memory emailExtension) public onlyOwner {
        registeredExtensions[emailExtension] = false;
    }

    function isEmailExtensionRegistered(string memory emailExtension) public view returns (bool) {
        return registeredExtensions[emailExtension];
    }

    function setEmailRegistrationPrice(uint256 price) public onlyOwner {
        emailRegistrationPrice = price;

        emit EmailRegistrationPriceSet(price);
    }

    function withdrawFunds() public onlyOwner {
        require(address(this).balance > 0, "No funds available for withdrawal");

        payable(contractOwner).transfer(address(this).balance);
    }

    modifier onlyOwner() {
        require(msg.sender == contractOwner, "Only the contract owner can perform this action");
        _;
    }

    function getEmailAddress(address walletAddress) private view returns (string memory) {
        string memory emailName = userEmails[walletAddress].emailName;
        string memory emailExtension = userEmails[walletAddress].emailExtension;

        return string(abi.encodePacked(emailName, emailExtension));
    }
}