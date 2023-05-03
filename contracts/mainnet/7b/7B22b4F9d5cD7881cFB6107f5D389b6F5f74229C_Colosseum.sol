// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract Colosseum {
    struct ApexUser {
        address payable wallet;
        string apexUsername;
        uint64 discordId;
    }

    struct ApexQueue {
        uint32 id;
        uint256 entryFee;
        ApexUser[] users;
    }

    address payable public owner;
    mapping(uint32 => ApexQueue) public apexQueues;

    event ApexQueueJoin(uint32 id, ApexUser apexUser, uint256 entryFee);

    constructor() payable {
        owner = payable(msg.sender);
    }

    function joinApexQueue(
        uint32 id,
        uint64 discorId,
        string calldata apexUsername
    ) public payable {
        require(msg.value > 0, "Entry fee must be greater than 0");
        require(apexQueues[id].id != 0, "Queue does not exist");
        require(
            apexQueues[id].entryFee == msg.value,
            "Entry fee does not match queue entry fee"
        );
        apexQueues[id].users.push(
            ApexUser(payable(msg.sender), apexUsername, discorId)
        );
        emit ApexQueueJoin(
            id,
            ApexUser(payable(msg.sender), apexUsername, discorId),
            msg.value
        );
    }

    function getApexQueue(uint32 id) public view returns (ApexQueue memory) {
        return apexQueues[id];
    }
}