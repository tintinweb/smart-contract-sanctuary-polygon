// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./Validator.sol";

error MessageRelay__UsernameAlreadyExists();
error MessageRelay__AddressAlreadyRegistered();
error MessageRelay__InvalidUsername();
error MessageRelay__NoUser();
error MessageRelay__NoPublicKey();
error MessageRelay__NoMessage();
error MessageRelay__InvalidMessage();

contract MessageRelay {
    event UserAdded(address indexed userAddress);
    event MessageSent(address indexed fromAddress, string indexed toUsername);
    event MessageDeleted(
        string indexed fromUsername,
        address indexed toAddress
    );
    event PublicKeyUpdated(address indexed userAddress);

    struct Message {
        string content;
        uint256 createdAt;
    }

    mapping(string => address) private usernameToAddress;
    mapping(address => string) private addressToUsername;
    mapping(string => string) private usernameToPublicKey;
    mapping(address => mapping(address => Message))
        private userAddressToMessage;

    function addUser(
        address userAddress,
        string memory username,
        string memory publicKey
    ) public {
        if (!Validator.validateUsername(username)) {
            revert MessageRelay__InvalidUsername();
        }

        string memory addressUsername = addressToUsername[userAddress];
        if (bytes(addressUsername).length != 0) {
            revert MessageRelay__AddressAlreadyRegistered();
        }

        address usernameAddress = usernameToAddress[username];
        if (usernameAddress != address(0x0)) {
            revert MessageRelay__UsernameAlreadyExists();
        }

        usernameToAddress[username] = userAddress;
        addressToUsername[userAddress] = username;
        usernameToPublicKey[username] = publicKey;

        emit UserAdded(userAddress);
    }

    function changeUserPublicKey(address userAddress, string memory publicKey)
        public
        payable
    {
        string memory username = getUsername(userAddress);
        usernameToPublicKey[username] = publicKey;

        emit PublicKeyUpdated(userAddress);
    }

    function getUsername(address userAddress)
        public
        view
        returns (string memory)
    {
        string memory username = addressToUsername[userAddress];
        if (bytes(username).length == 0) {
            revert MessageRelay__NoUser();
        }
        return username;
    }

    function getUserAddress(string memory username)
        private
        view
        returns (address)
    {
        address userAddress = usernameToAddress[username];
        if (userAddress == address(0x0)) {
            revert MessageRelay__NoUser();
        }
        return userAddress;
    }

    function getPublicKey(string memory username)
        public
        view
        returns (string memory)
    {
        string memory publicKey = usernameToPublicKey[username];
        if (bytes(publicKey).length == 0) {
            revert MessageRelay__NoPublicKey();
        }
        return publicKey;
    }

    function sendMessage(
        address userAddress,
        string memory username,
        string memory content
    ) public {
        if (!Validator.validateMessage(content)) {
            revert MessageRelay__InvalidMessage();
        }

        address receiverAddress = getUserAddress(username);
        Message memory message = Message(content, block.timestamp * 1000);
        userAddressToMessage[receiverAddress][userAddress] = message;

        emit MessageSent(userAddress, username);
    }

    function getMessage(address userAddress, string memory fromUsername)
        public
        view
        returns (Message memory)
    {
        address from = getUserAddress(fromUsername);
        Message memory message = userAddressToMessage[userAddress][from];
        if (bytes(message.content).length == 0) {
            revert MessageRelay__NoMessage();
        }

        return message;
    }

    function deleteMessageFrom(address userAddress, string memory fromUsername)
        public
        payable
    {
        address from = getUserAddress(fromUsername);
        Message memory message = userAddressToMessage[userAddress][from];
        if (bytes(message.content).length == 0) {
            revert MessageRelay__NoMessage();
        }
        delete userAddressToMessage[userAddress][from];

        emit MessageDeleted(fromUsername, userAddress);
    }

    function hasMessageFrom(address userAddress, string memory fromUsername)
        public
        view
        returns (bool)
    {
        address from = getUserAddress(fromUsername);
        Message memory message = userAddressToMessage[userAddress][from];
        return bytes(message.content).length > 0;
    }

    function hasMessageTo(address userAddress, string memory toUsername)
        public
        view
        returns (bool)
    {
        address to = getUserAddress(toUsername);
        Message memory message = userAddressToMessage[to][userAddress];
        return bytes(message.content).length > 0;
    }
}