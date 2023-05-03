// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

struct ApexUser {
    address payable wallet;
    string apexUsername;
    uint64 discordId;
}

struct ApexQueue {
    uint32 queueId;
    string name;
    uint256 entryFee;
    uint8 maxUsers;
    uint8 maxTeams;
    address[] users;
}

struct ApexQueuesInit {
    uint32[] queueIds;
    string[] names;
    uint256[] entryFees;
    uint8[] maxUsers;
    uint8[] maxTeams;
}

contract Colosseum {
    address payable public owner;
    mapping(uint32 => ApexQueue) public apexQueues;
    mapping(address => ApexUser) public apexUsers;

    event ApexQueueJoin(uint32 queueId, ApexUser apexUser, uint256 entryFee);
    event ApexQueuePop(uint32 queueId, string name, ApexUser[] apexUsers);

    constructor(ApexQueuesInit memory apexQueuesInit) payable {
        owner = payable(msg.sender);
        for (uint256 i = 0; i < apexQueuesInit.queueIds.length; i++) {
            ApexQueue memory r = apexQueues[apexQueuesInit.queueIds[i]];
            require(r.queueId == 0, "Queue already exists");
            r.queueId = apexQueuesInit.queueIds[i];
            r.name = apexQueuesInit.names[i];
            r.entryFee = apexQueuesInit.entryFees[i];
            r.maxUsers = apexQueuesInit.maxUsers[i];
            r.maxTeams = apexQueuesInit.maxTeams[i];
            r.users = new address[](0);
            apexQueues[apexQueuesInit.queueIds[i]] = r;
        }
    }

    function joinApexQueue(
        uint32 queueId,
        uint64 discordId,
        string calldata apexUsername
    ) public payable {
        require(msg.value > 0, "Entry fee must be greater than 0");
        require(apexQueues[queueId].queueId != 0, "Queue does not exist");
        require(
            apexQueues[queueId].entryFee == msg.value,
            "Entry fee does not match queue entry fee"
        );
        apexQueues[queueId].users.push(msg.sender);

        ApexUser memory newUser = ApexUser(
            payable(msg.sender),
            apexUsername,
            discordId
        );

        apexUsers[msg.sender] = newUser;

        emit ApexQueueJoin(queueId, newUser, msg.value);

        if (apexQueues[queueId].users.length == apexQueues[queueId].maxUsers) {
            ApexUser[] memory users = new ApexUser[](
                apexQueues[queueId].users.length
            );
            for (uint256 i = 0; i < apexQueues[queueId].users.length; i++) {
                users[i] = apexUsers[apexQueues[queueId].users[i]];
            }
            emit ApexQueuePop(queueId, apexQueues[queueId].name, users);
            apexQueues[queueId].users = new address[](0);
        }
    }

    function getApexUser(address wallet) public view returns (ApexUser memory) {
        return apexUsers[wallet];
    }

    function getApexQueue(
        uint32 queueId
    ) public view returns (ApexQueue memory) {
        return apexQueues[queueId];
    }
}