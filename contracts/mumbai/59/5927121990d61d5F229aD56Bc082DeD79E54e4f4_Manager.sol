// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./SLA.sol";

contract Manager {
    address randomContractAddress;
    mapping(address => address[]) providerSLAs;
    mapping(address => address[]) consumerSLAs;
    uint256 public slaCount;
    address[] public allSLAs;

    // events
    event SLAContractCreated(address indexed newContract);

    constructor(address _randomContractAddress) {
        randomContractAddress = _randomContractAddress;
    }

    function getProviderSLAs(address _provider) public view returns (address[] memory) {
        return providerSLAs[_provider];
    }

    function getConsumerSLAs(address _consumer) public view returns (address[] memory) {
        return consumerSLAs[_consumer];
    }

    function getAllSLAs() public view returns (address[] memory) {
        return allSLAs;
    }

    // deploy a new SLA contract
    function createSLAContract(string memory _name) public {
        address slaAddress = address(new SLA(_name, randomContractAddress));
        allSLAs.push(slaAddress);
        slaCount++;
        providerSLAs[msg.sender].push(slaAddress);
        emit SLAContractCreated(slaAddress);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "../interfaces/IRandom.sol";

contract SLA {
    string public name;
    address public owner;
    address public manager;
    mapping(address => bool) consumers;
    // struct invites => validity, inviteString, ref
    // strcut consumer => address, ref, validity
    mapping(string => bool) public invites;
    IRandom random;

    event InviteGenerated(string inviteString);

    constructor(string memory _name, address randomContractAddress) {
        owner = tx.origin;
        manager = msg.sender;
        random = IRandom(randomContractAddress); // remove this
        name = _name;
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
        require(invites[randomString] == false, "Duplicate invite"); // Need to change approach
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IRandom {
    function random(
        uint256 number,
        uint256 counter
    ) external view  returns (uint256);

    function randomString(uint256 length) external view returns (string memory);
}