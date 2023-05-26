// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./SLA.sol";

contract Manager {
    struct SLAContract {
        address slaAddress;
        string name;
        uint256 createdAt;
    }
    address randomContractAddress;
    mapping(address => SLAContract[]) public providerSLAs;
    mapping(address => SLAContract[]) public consumerSLAs;
    uint256 public slaCount;
    SLAContract[] public allSLAs;
    mapping(address => bool) public allSLAsMap;

    // events
    event SLAContractCreated(address indexed newContract);

    constructor(address _randomContractAddress) {
        randomContractAddress = _randomContractAddress;
    }

    // deploy a new SLA contract
    function createSLAContract(string memory _name) public {
        address slaAddress = address(new SLA(_name, randomContractAddress));
        slaCount++;
        SLAContract memory sla = SLAContract(slaAddress, _name, block.timestamp);
        allSLAs.push(sla);
        allSLAsMap[slaAddress] = true;
        providerSLAs[msg.sender].push(sla);
        emit SLAContractCreated(slaAddress);
    }

    // sla can call this function to add a consumer
    function addConsumer(address _consumerAddress, string memory _slaName) public {
        require(allSLAsMap[msg.sender] == true, "Only SLA providers can add consumers");
        SLAContract memory sla = SLAContract(msg.sender, _slaName, block.timestamp);
        consumerSLAs[_consumerAddress].push(sla);
    }

    function getProviderSLAs(address _providerAddress) public view returns (SLAContract[] memory) {
        return providerSLAs[_providerAddress];
    }

    function getConsumerSLAs(address _consumerAddress) public view returns (SLAContract[] memory) {
        return consumerSLAs[_consumerAddress];
    }

    function getAllSLAs() public view returns (SLAContract[] memory) {
        return allSLAs;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "../interfaces/IRandom.sol";
import "../interfaces/IManager.sol";

contract SLA {

    struct Consumer {
        address consumerAddress;
        string ref;
        uint256 contractValidity;
    }

    struct Invite {
        uint256 validity;
        string inviteString;
        string ref;
    }

    string public name;
    address public owner;
    address public manager;
    IRandom randomContract;
    IManager managerContract;
    uint256 public consumersCount;
    Consumer[] public consumers;
    mapping(address => Consumer) consumersMap;
    uint256 public invitesCount;
    Invite[] public invites;
    mapping(string => Invite) public invitesMap;

    event InviteGenerated(string inviteString);

    constructor(string memory _name, address randomContractAddress) {
        owner = tx.origin;
        manager = msg.sender;
        randomContract = IRandom(randomContractAddress);
        managerContract = IManager(manager);
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

    function canConsume(address _consumer) public view returns (bool) {
        return consumersMap[_consumer].contractValidity > block.timestamp;
    }

    function inviteConsumer(string memory _ref) public onlyOwner {
        string memory randomString = randomContract.randomString(7);
        Invite memory invite = Invite(block.timestamp + 1 days, randomString, _ref);
        invitesMap[randomString] = invite;
        invitesCount++;
        invites.push(invite);
        emit InviteGenerated(randomString);
    }

    function acceptInvitation(string memory _inviteString, uint256 _validity) public {
        require(msg.sender != owner, "Provider cannot consume");
        require(invitesMap[_inviteString].validity > block.timestamp, "Invalid invite");
        Consumer memory consumer = Consumer(msg.sender, invitesMap[_inviteString].ref, _validity);
        consumersMap[msg.sender] = consumer;
        consumersCount++;
        consumers.push(consumer);
        delete invitesMap[_inviteString];
        managerContract.addConsumer(msg.sender, name);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;


interface IManager {
    struct SLAContract {
        address slaAddress;
        string name;
        uint256 createdAt;
    }

    function createSLAContract(string memory _name) external;

    function addConsumer(address _consumerAddress, string memory _slaName) external;

    function getProviderSLAs(address _providerAddress) external view returns (SLAContract[] memory);

    function getConsumerSLAs(address _consumerAddress) external view returns (SLAContract[] memory);

    function getAllSLAs() external view returns (SLAContract[] memory);
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