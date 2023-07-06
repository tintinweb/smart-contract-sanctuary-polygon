// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract EmailRegisteration {
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
    address[] private registeredAddresses;

    event EmailRegistered(address indexed walletAddress, string indexed emailAddress);
    event EmailExtensionSet(address indexed walletAddress, string newExtension);
    event EmailRegistrationPriceSet(uint256 newPrice);
    event EmailUnregistered(address indexed walletAddress, string indexed emailAddress);

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

        registeredAddresses.push(msg.sender);

        payable(contractOwner).transfer(emailRegistrationPrice);

        emit EmailRegistered(msg.sender, emailAddress);
    }

    function isEmailRegistered(address walletAddress) public view returns (bool) {
        return (bytes(userEmails[walletAddress].emailName).length != 0);
    }

    function isEmailRegisteredByEmail(string memory email) public view returns (bool) {
        return emailToWallet[email] != address(0);
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

    function unregisterEmail() public {
        require(bytes(userEmails[msg.sender].emailName).length != 0, "Email not registered");

        string memory emailAddress = getEmailAddress(msg.sender);

        delete emailToWallet[emailAddress];
        delete walletToEmail[msg.sender];
        delete userEmails[msg.sender];

        emit EmailUnregistered(msg.sender, emailAddress);
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

    function getAllEmailAddresses() public view onlyOwner returns (string[] memory) {
        uint256 totalAddresses = registeredAddresses.length;
        string[] memory addresses = new string[](totalAddresses);

        for (uint256 i = 0; i < totalAddresses; i++) {
            address walletAddress = registeredAddresses[i];
            addresses[i] = getEmailAddress(walletAddress);
        }

        return addresses;
    }
}