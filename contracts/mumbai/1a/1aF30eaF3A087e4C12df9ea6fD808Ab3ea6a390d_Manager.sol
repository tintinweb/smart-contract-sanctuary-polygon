// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./SLA.sol";

contract Manager {
    mapping(address => address[]) providerSLAs;
    mapping(address => address[]) consumerSLAs;
    address[] public allSLAs;

    // events
    event SLAContractCreated(address indexed newContract);

    constructor() {}

    function getMyProviders() public view returns (address[] memory) {
        return providerSLAs[msg.sender];
    }

    function getMyConsumers() public view returns (address[] memory) {
        return consumerSLAs[msg.sender];
    }

    // deploy a new SLA contract
    function createSLAContract() public {
        address slaAddress = address(new SLA());
        allSLAs.push(slaAddress);
        providerSLAs[msg.sender].push(slaAddress);
        emit SLAContractCreated(slaAddress);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract Random {
    //Random Number Generator
    function random(
        uint256 number,
        uint256 counter
    ) public view returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encodePacked(
                        block.timestamp,
                        block.difficulty,
                        msg.sender,
                        counter
                    )
                )
            ) % number;
    }

    //Random String Generator (Max length 14)

    function randomString(uint256 length) public view returns (string memory) {
        require(length <= 14, "Length cannot be greater than 14");
        require(length >= 1, "Length cannot be Zero");
        bytes memory randomWord = new bytes(length);
        // since we have 62 Characters
        bytes memory chars = new bytes(62);
        chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
        for (uint256 i = 0; i < length; i++) {
            uint256 randomNumber = random(62, i);
            // Index access for string is not possible
            randomWord[i] = chars[randomNumber];
        }
        return string(randomWord);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./Random.sol";

contract SLA {
    address public owner;
    address public manager;
    mapping(address => bool) consumers;
    // struct invites => validity, inviteString, ref
    // strcut consumer => address, ref, validity
    mapping(string => bool) public invites;
    Random random;

    event InviteGenerated(string inviteString);

    constructor() {
        owner = tx.origin;
        manager = msg.sender;
        random = new Random();
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "You are not the provider");
        _;
    }

    modifier onlyManager() {
        require(msg.sender == manager, "You are not the manager");
        _;
    }

    function canConsume() public view returns (bool) {
        return consumers[msg.sender];
    }

    function inviteConsumer() public onlyOwner {
        string memory randomString = random.randomString(7);
        // check if randomString is already in use
        invites[randomString] = true;
        emit InviteGenerated(randomString);
    }

    function acceptInvitation(string memory _inviteString) public {
        require(msg.sender != owner, "Provider cannot consume");
        require(invites[_inviteString] == true, "Invalid invite");
        delete invites[_inviteString];
        consumers[msg.sender] = true;
        // add consumer to manager
    }
}