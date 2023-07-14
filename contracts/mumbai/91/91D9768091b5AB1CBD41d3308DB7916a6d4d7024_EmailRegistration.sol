// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract EmailRegistration {
    struct Email {
        string emailName;
        string emailExtension;
        uint256 expiryTimestamp;
    }

    mapping(address => Email) private userEmails;
    mapping(string => address) private emailToWallet;
    mapping(address => string) private walletToEmail;
    mapping(string => bool) private registeredExtensions;
    uint256 private emailRegistrationPrice;
    uint256 private emailRenewalPrice;
    uint256 private emailRegistrationDuration;
    uint256 private emailExpiryDuration;
    address private contractOwner;
    address[] private registeredAddresses;

    event EmailRegistered(address indexed walletAddress, string indexed emailAddress, uint256 expiryTimestamp);
    event EmailRenewed(address indexed walletAddress, string indexed emailAddress, uint256 expiryTimestamp);
    event EmailExtensionSet(address indexed walletAddress, string newExtension);
    event EmailRegistrationPriceSet(uint256 newPrice);
    event EmailRenewalPriceSet(uint256 newPrice);
    event EmailUnregistered(address indexed walletAddress, string indexed emailAddress);

    constructor() {
        contractOwner = msg.sender;
        emailRegistrationPrice = 100000000000000000; // 0.1 ether in wei
        emailRenewalPrice = 200000000000000000; // 0.2 ether in wei
        emailRegistrationDuration = 365 days; // Default registration duration
        emailExpiryDuration = emailRegistrationDuration; // Default expiry duration
    }

    function registerEmail(
        string memory emailName,
        string memory emailExtension,
        uint256 expiryDurationInYears
    ) public payable {
        require(bytes(userEmails[msg.sender].emailName).length == 0, "Email already registered");
        require(registeredExtensions[emailExtension], "Invalid email extension");

        uint256 emailDuration = expiryDurationInYears * emailExpiryDuration;
        uint256 registrationPrice = calculateRegistrationPrice(emailDuration);

        require(msg.value == registrationPrice, "Incorrect amount sent");

        uint256 expiryTimestamp = userEmails[msg.sender].expiryTimestamp;
        if (expiryTimestamp < block.timestamp) {
            expiryTimestamp = block.timestamp;
        }
        expiryTimestamp += emailDuration;

        userEmails[msg.sender] = Email({ emailName:toLower( emailName), emailExtension: emailExtension, expiryTimestamp: expiryTimestamp });

        string memory emailAddress = getEmailAddress(msg.sender);
        emailToWallet[emailAddress] = msg.sender;
        walletToEmail[msg.sender] = emailAddress;

        registeredAddresses.push(msg.sender);

        emit EmailRegistered(msg.sender, emailAddress, expiryTimestamp);
        payable(contractOwner).transfer(msg.value);
    }
function toLower(string memory str) private pure returns (string memory) {
    bytes memory strBytes = bytes(str);
    bytes memory result = new bytes(strBytes.length);

    for (uint256 i = 0; i < strBytes.length; i++) {
        if (strBytes[i] >= bytes1(uint8(65)) && strBytes[i] <= bytes1(uint8(90))) {
            result[i] = bytes1(uint8(strBytes[i]) + 32);
        } else {
            result[i] = strBytes[i];
        }
    }

    return string(result);
}


    function calculateRegistrationPrice(uint256 duration) public view returns (uint256) {
        return (emailRegistrationPrice * duration) / emailExpiryDuration;
    }

    function increaseEmailDuration(uint256 additionalDurationInYears) public payable {
        require(bytes(userEmails[msg.sender].emailName).length != 0, "Email not registered");

        uint256 additionalDuration = additionalDurationInYears * emailExpiryDuration;
        uint256 extensionPrice = calculateExtensionPrice(additionalDuration);

        require(msg.value == extensionPrice, "Incorrect amount sent");

        uint256 expiryTimestamp = userEmails[msg.sender].expiryTimestamp;
        if (expiryTimestamp < block.timestamp) {
            expiryTimestamp = block.timestamp;
        }
        expiryTimestamp += additionalDuration;

        userEmails[msg.sender].expiryTimestamp = expiryTimestamp;

        emit EmailRenewed(msg.sender, getEmailAddress(msg.sender), expiryTimestamp);
        payable(contractOwner).transfer(msg.value);
    }

    function calculateExtensionPrice(uint256 duration) private view returns (uint256) {
        return (emailRenewalPrice *  duration) / emailExpiryDuration;
    }
    function getExtensionPrice(uint256 duration) public view returns (uint256) {
        return (emailRenewalPrice *  duration) ;
    }




function getRegistrationPrice(uint256 duration) public view returns (uint256) {
    return emailRegistrationPrice * duration ;
}

    function isEmailRegistered(address walletAddress) public view returns (bool) {
        return (bytes(userEmails[walletAddress].emailName).length != 0);
    }

    function isEmailRegisteredByEmail(string memory email) public view returns (bool) {
        return emailToWallet[toLower(email)] != address(0);
    }

    function getEmail(address walletAddress) public view returns (string memory) {
        return getEmailAddress(walletAddress);
    }

    function getWalletAddress(string memory email) public view returns (address) {
        return emailToWallet[toLower(email)];
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

    function setEmailRenewalPrice(uint256 price) public onlyOwner {
        emailRenewalPrice = price;

        emit EmailRenewalPriceSet(price);
    }

    function setEmailRegistrationDuration(uint256 duration) public onlyOwner {
        emailRegistrationDuration = duration;
    }

    function setEmailExpiryDuration(uint256 duration) public onlyOwner {
        emailExpiryDuration = duration;
    }

    function unregisterEmail() public {
        require(bytes(userEmails[msg.sender].emailName).length != 0, "Email not registered");

        string memory emailAddress = getEmailAddress(msg.sender);

        delete emailToWallet[emailAddress];
        delete walletToEmail[msg.sender];
        delete userEmails[msg.sender];

        emit EmailUnregistered(msg.sender, emailAddress);
    }

function renewEmail(uint256 renewalDurationInYears) public payable {
    require(bytes(userEmails[msg.sender].emailName).length != 0, "Email not registered");

    uint256 emailDuration = renewalDurationInYears * emailExpiryDuration;
    uint256 renewalPrice = getRenewalPrice(msg.sender, emailDuration);

    require(msg.value == renewalPrice, "Incorrect amount sent");

    Email storage email = userEmails[msg.sender];
    email.expiryTimestamp += emailDuration;

    payable(contractOwner).transfer(msg.value);

    emit EmailRenewed(msg.sender, getEmailAddress(msg.sender), email.expiryTimestamp);
    payable(contractOwner).transfer(msg.value);
}

function getRenewalPrice(address walletAddress, uint256 duration) public view returns (uint256) {
    require(bytes(userEmails[walletAddress].emailName).length != 0, "Email not registered");

    uint256 yearsSinceRegistration = (block.timestamp - userEmails[walletAddress].expiryTimestamp) / emailExpiryDuration;
    uint256 currentRenewalPrice = emailRenewalPrice;

    for (uint256 i = 0; i < yearsSinceRegistration; i++) {
        currentRenewalPrice = (currentRenewalPrice * 3) / 2; // Increase renewal price by 50%
    }

    return currentRenewalPrice * duration / emailExpiryDuration;
}


function getEmailExpiry(address walletAddress) public view returns (uint256, string memory, string memory) {
    require(bytes(userEmails[walletAddress].emailName).length != 0, "Email not registered");

    uint256 expiryTimestamp = userEmails[walletAddress].expiryTimestamp;
    uint256 daysRemaining = (expiryTimestamp - block.timestamp) / (1 days);
    string memory expiryDate = timestampToDate(expiryTimestamp);
    string memory expiryTime = timestampToTime(expiryTimestamp);

    return (daysRemaining, expiryDate, expiryTime);
}

function timestampToDate(uint256 timestamp) private pure returns (string memory) {
    uint256 unixTimestamp = timestamp;
    uint256 year = getYear(unixTimestamp);
    uint256 month = getMonth(unixTimestamp);
    uint256 day = getDay(unixTimestamp);

    return string(abi.encodePacked(uint2str(day), "-", uint2str(month), "-", uint2str(year)));
}

function timestampToTime(uint256 timestamp) private pure returns (string memory) {
    uint256 unixTimestamp = timestamp;
    uint256 hour = (unixTimestamp / 3600) % 24;
    uint256 minute = (unixTimestamp / 60) % 60;

    return string(abi.encodePacked(uint2str(hour), ":", uint2str(minute)));
}

function getYear(uint256 timestamp) private pure returns (uint256) {
    uint256 secondsInYear = 31536000;
    uint256 year = 1970 + (timestamp / secondsInYear);

    while (timestamp >= getYearTimestamp(year + 1)) {
        year++;
    }

    return year;
}

function getMonth(uint256 timestamp) private pure returns (uint256) {
    uint256 year = getYear(timestamp);
    uint256 yearTimestamp = getYearTimestamp(year);
    uint256 secondsInMonth = 2592000;
    uint256 month = 1;

    while (timestamp >= yearTimestamp + (secondsInMonth * month)) {
        month++;
    }

    return month;
}

function getDay(uint256 timestamp) private pure returns (uint256) {
    uint256 year = getYear(timestamp);
    uint256 month = getMonth(timestamp);
    uint256 yearTimestamp = getYearTimestamp(year);
    uint256 monthTimestamp = yearTimestamp + (2592000 * (month - 1));
    uint256 secondsInDay = 86400;
    uint256 day = 1;

    while (timestamp >= monthTimestamp + (secondsInDay * day)) {
        day++;
    }

    return day;
}

function getYearTimestamp(uint256 year) private pure returns (uint256) {
    uint256 secondsInYear = 31536000;
    return (year - 1970) * secondsInYear;
}

function uint2str(uint256 number) private pure returns (string memory) {
    if (number == 0) {
        return "0";
    }

    uint256 temp = number;
    uint256 digits;

    while (temp != 0) {
        digits++;
        temp /= 10;
    }

    bytes memory buffer = new bytes(digits);

    while (number != 0) {
        digits--;
        buffer[digits] = bytes1(uint8(48 + (number % 10)));
        number /= 10;
    }

    return string(buffer);
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
    function getCurrentRenewalPrice(address walletAddress) public view returns (uint256) {
        require(bytes(userEmails[walletAddress].emailName).length != 0, "Email not registered");

        uint256 yearsSinceRegistration = (block.timestamp - userEmails[walletAddress].expiryTimestamp) / emailExpiryDuration;
        uint256 currentRenewalPrice = emailRenewalPrice;

        for (uint256 i = 0; i < yearsSinceRegistration; i++) {
            currentRenewalPrice = (currentRenewalPrice * 3) / 2; // Increase renewal price by 50%
        }

        return currentRenewalPrice;
    }
}