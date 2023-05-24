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
        require(invitesMap[_inviteString].validity < block.timestamp, "Invalid invite");
        delete invitesMap[_inviteString];
        Consumer memory consumer = Consumer(msg.sender, invitesMap[_inviteString].ref, _validity);
        consumersMap[msg.sender] = consumer;
        consumersCount++;
        consumers.push(consumer);
        managerContract.addConsumer(msg.sender);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;


interface IManager {
    function createSLAContract(string memory _name) external;
    function addConsumer(address _consumerAddress) external;
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