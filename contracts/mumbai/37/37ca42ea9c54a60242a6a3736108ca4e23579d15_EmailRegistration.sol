// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract EmailRegistration {
    struct Email {
        string emailName;
        string emailExtension;
        uint256 registrationTimestamp;
        uint256 expiryTimestamp;
        bool isRegistered;
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
    mapping(string => address) private emailToAddress;

    event EmailRegistered(address indexed walletAddress, string indexed emailAddress, uint256 registrationTimestamp, uint256 expiryTimestamp);
    event EmailRenewed(address indexed walletAddress, string indexed emailAddress, uint256 expiryTimestamp);
    event EmailExtensionSet(address indexed walletAddress, string newExtension);
    event EmailRegistrationPriceSet(uint256 newPrice);
    event EmailRenewalPriceSet(uint256 newPrice);
    event EmailUnregistered(address indexed walletAddress, string indexed emailAddress);

    constructor() {
        contractOwner = msg.sender;
        emailRegistrationPrice = 1000000000000000000; // 0.1 ether in wei
        emailRenewalPrice = 2000000000000000000; // 0.2 ether in wei
        emailRegistrationDuration = 2592000; // Default registration duration
        emailExpiryDuration = 5184000 ; // Default expiry duration
    }

    function registerEmail(
        string memory emailName,
        string memory emailExtension,
        uint256 expiryDurationInYears
    ) public payable {
        string memory emailAddress = string(abi.encodePacked(emailName, emailExtension));
        address walletAddress = getWalletAddress(emailAddress);

        // Check if email is already registered
        if (!isEmailRegistered(walletAddress)) {
            require(registeredExtensions[emailExtension], "Invalid email extension");
            require(bytes(emailName).length >= 3, "Email name should be at least 3 characters");
            uint256 emailDuration = expiryDurationInYears * emailExpiryDuration;
            uint256 registrationPrice = getRegistrationPrice(expiryDurationInYears);

            require(msg.value >= registrationPrice, "Incorrect amount sent");

            uint256 expiryTimestamp = block.timestamp + emailDuration;

            // Unregister email if it has already expired
            if (isEmailRegistered(msg.sender) && userEmails[msg.sender].expiryTimestamp < block.timestamp) {
                unregisterEmail();
            }

            userEmails[msg.sender] = Email({
                emailName: toLower(emailName),
                emailExtension: emailExtension,
                registrationTimestamp: block.timestamp,
                expiryTimestamp: expiryTimestamp,
                isRegistered: true
            });

            emailToWallet[emailAddress] = msg.sender;
            walletToEmail[msg.sender] = emailAddress;
            emailToAddress[emailAddress] = msg.sender;

            registeredAddresses.push(msg.sender);

            emit EmailRegistered(msg.sender, emailAddress, block.timestamp, expiryTimestamp);
            payable(contractOwner).transfer(msg.value);
        } else {
            revert("Email already registered");
        }
    }

    function unregisterEmail() public {
        require(userEmails[msg.sender].isRegistered, "Email not registered");

        string memory emailAddress = getEmailAddress(msg.sender);

        delete emailToWallet[emailAddress];
        delete walletToEmail[msg.sender];
        delete userEmails[msg.sender];
        delete emailToAddress[emailAddress];

        emit EmailUnregistered(msg.sender, emailAddress);
    }

    function increaseEmailDuration(uint256 additionalDurationInYears) public payable {
        require(isEmailRegistered(msg.sender), "Email not already registered");
        require(bytes(userEmails[msg.sender].emailName).length != 0, "Email not registered");

        uint256 additionalDuration = additionalDurationInYears * emailExpiryDuration;
        uint256 extensionPrice = getRenewalPrice(msg.sender, additionalDurationInYears);

        require(msg.value >= extensionPrice, "Incorrect amount sent");

        uint256 expiryTimestamp = userEmails[msg.sender].expiryTimestamp;
        if (expiryTimestamp < block.timestamp) {
            expiryTimestamp = block.timestamp;
        }
        expiryTimestamp += additionalDuration;

        userEmails[msg.sender].expiryTimestamp = expiryTimestamp;

        emit EmailRenewed(msg.sender, getEmailAddress(msg.sender), expiryTimestamp);
        payable(contractOwner).transfer(msg.value);
    }

    function renewEmail(uint256 renewalDurationInYears) public payable {
        require(bytes(userEmails[msg.sender].emailName).length != 0, "Email not registered");

        uint256 emailDuration = renewalDurationInYears * emailExpiryDuration;
        uint256 renewalPrice = getRenewalPrice(msg.sender, renewalDurationInYears);

        require(msg.value >= renewalPrice, "Incorrect amount sent");

        // Unregister email if it has already expired
        if (isEmailRegistered(msg.sender) && userEmails[msg.sender].expiryTimestamp < block.timestamp) {
            unregisterEmail();
        }

        string memory emailAddress = getEmailAddress(msg.sender);
        emailToWallet[emailAddress] = msg.sender;
        walletToEmail[msg.sender] = emailAddress;
        emailToAddress[emailAddress] = msg.sender;

        

        Email storage email = userEmails[msg.sender];
        email.expiryTimestamp += emailDuration;

        emit EmailRenewed(msg.sender, getEmailAddress(msg.sender), email.expiryTimestamp);
        payable(contractOwner).transfer(msg.value);
    }

    function getEmailExpiry(address walletAddress) public view returns (
        uint256,
        string memory,
        string memory,
        string memory,
        uint256,
        uint256
    ) {
        require(userEmails[walletAddress].isRegistered, "Email not registered");

        Email memory email = userEmails[walletAddress];
        uint256 registrationTimestamp = email.registrationTimestamp;
        uint256 expiryTimestamp = email.expiryTimestamp;
        uint256 daysRemaining = (expiryTimestamp - block.timestamp) / (1 days);
        string memory registrationDate = timestampToDate(registrationTimestamp);
        string memory expiryDate = timestampToDate(expiryTimestamp);
        string memory expiryTime = timestampToTime(expiryTimestamp);

        return (
            daysRemaining,
            registrationDate,
            expiryDate,
            expiryTime,
            registrationTimestamp,
            expiryTimestamp
        );
    }

    function getEmailAddresses() public view returns (string[] memory) {
        uint256 validCount = 0;
        string[] memory addresses;

        for (uint256 i = 0; i < registeredAddresses.length; i++) {
            address walletAddress = registeredAddresses[i];
            if (isEmailRegistered(walletAddress)) {
                validCount++;
            }
        }

        addresses = new string[](validCount);
        validCount = 0;

        for (uint256 i = 0; i < registeredAddresses.length; i++) {
            address walletAddress = registeredAddresses[i];
            if (isEmailRegistered(walletAddress)) {
                addresses[validCount] = getEmailAddress(walletAddress);
                validCount++;
            }
        }

        return addresses;
    }

    function getEmailDetails(address walletAddress) public view returns (
        string memory,
        string memory,
        uint256,
        uint256,
        bool
    ) {
        Email memory email = userEmails[walletAddress];
        bool isRegistered = isEmailRegistered(walletAddress);

        return (
            getEmailAddress(walletAddress),
            email.emailExtension,
            email.registrationTimestamp,
            email.expiryTimestamp,
            isRegistered
        );
    }

    function getEmailDetailsByEmail(string memory email) public view returns (
        string memory,
        string memory,
        uint256,
        uint256,
        bool,
        address
    ) {
        address walletAddress = getWalletAddress(email);
        (
            string memory emailAddress,
            string memory emailExtension,
            uint256 registrationTimestamp,
            uint256 expiryTimestamp,
            bool isRegistered
        ) = getEmailDetails(walletAddress);

        return (
            emailAddress,
            emailExtension,
            registrationTimestamp,
            expiryTimestamp,
            isRegistered,
            walletAddress
        );
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

    function getRegistrationPrice(uint256 duration) public view returns (uint256) {
        if (duration == 1) {
            return emailRegistrationPrice * duration;
        } else {
            return emailRegistrationPrice * duration + (duration - 1) * emailRenewalPrice;
        }
    }

    function getRenewalPrice(address walletAddress, uint256 duration) public view returns (uint256) {
        require(bytes(userEmails[walletAddress].emailName).length != 0, "Email not registered");

        if (duration == 1) {
            return emailRegistrationPrice * duration;
        } else {
            return emailRenewalPrice * duration + (duration - 1) * emailRenewalPrice;
        }
    }

    function isEmailRegistered(address walletAddress) public view returns (bool) {
        Email memory email = userEmails[walletAddress];
        if (bytes(email.emailName).length == 0) {
            return false; // Email not registered
        }
        if (block.timestamp >= email.expiryTimestamp) {
            return false; // Email has expired
        }
        return true; // Email is registered and not expired
    }

    function isEmailRegisteredByEmail(string memory email) public view returns (bool) {
        address walletAddress = emailToAddress[toLower(email)];
        return isEmailRegistered(walletAddress);
    }

    function getEmail(address walletAddress) public view returns (string memory) {
        if (isEmailRegistered(walletAddress)) {
            return getEmailAddress(walletAddress);
        }
        return ""; // Email is not registered or expired
    }

    function getWalletAddress(string memory email) public view returns (address) {
        address walletAddress = emailToAddress[toLower(email)];
        if (isEmailRegistered(walletAddress)) {
            return walletAddress;
        }
        return address(0); // Email is not registered or expired
    }
    function getEmailRegistrationDuration() public view returns (uint256) {
    return emailRegistrationDuration;
}

function getEmailExpiryDuration() public view returns (uint256) {
    return emailExpiryDuration;
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
        function countRegisteredEmails() public view returns (uint256) {
        uint256 count = 0;
        
        for (uint256 i = 0; i < registeredAddresses.length; i++) {
            address walletAddress = registeredAddresses[i];
            if (isEmailRegistered(walletAddress)) {
                count++;
            }
        }
        
        return count;
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
            if (timestamp == monthTimestamp) {
                return day;
            }

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
}