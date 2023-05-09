/**
 *Submitted for verification at polygonscan.com on 2023-05-08
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

struct ApexUser {
    address wallet;
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

struct ApexMatch {
    uint32 matchId;
    uint32 queueId;
    string queueName;
    uint256 entryFee;
    string map;
    address[] users;
    uint64 startTime;
    uint64 endTime;
    address[] winners;
}

contract Colosseum {
    address payable public owner;

    mapping(uint32 => ApexQueue) public apexQueues;
    mapping(address => ApexUser) public apexUsers;
    mapping(uint32 => ApexMatch) public apexMatches;

    event ApexQueueJoin(uint32 queueId, ApexUser apexUser, uint256 entryFee);

    event ApexQueuePop(uint32 queueId, string name, ApexUser[] apexUsers);

    event ApexAdminStartMatch(
        uint32 matchId,
        uint32 queueId,
        string queueName,
        uint256 entryFee,
        string map,
        ApexUser[] users,
        uint64 startTime
    );

    event ApexAdminEndMatch(
        uint32 matchId,
        uint32 queueId,
        string queueName,
        uint256 entryFee,
        string map,
        ApexUser[] users,
        uint64 startTime,
        uint64 endTime,
        address[] winners
    );

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
        require(apexQueues[queueId].queueId == queueId, "Queue does not exist");
        require(
            apexQueues[queueId].entryFee == msg.value,
            "Entry fee does not match queue entry fee"
        );
        require(
            apexQueues[queueId].users.length < apexQueues[queueId].maxUsers,
            "Queue is full"
        );

        apexQueues[queueId].users.push(msg.sender);

        ApexUser memory newUser = ApexUser(msg.sender, apexUsername, discordId);

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

    function adminStartApexMatch(
        uint32 matchId,
        uint32 queueId,
        string calldata map,
        uint64 startTime
    ) public {
        require(msg.sender == owner, "Only owner can start match");
        require(
            apexMatches[matchId].matchId != matchId,
            "Match already exists"
        );
        require(apexQueues[queueId].queueId == queueId, "Queue does not exist");

        ApexUser[] memory matchUsers = new ApexUser[](
            apexQueues[queueId].users.length
        );

        for (uint256 i = 0; i < apexQueues[queueId].users.length; i++) {
            matchUsers[i] = apexUsers[apexQueues[queueId].users[i]];
        }

        ApexMatch memory newMatch = ApexMatch(
            matchId,
            queueId,
            apexQueues[queueId].name,
            apexQueues[queueId].entryFee,
            map,
            apexQueues[queueId].users,
            startTime,
            0,
            new address[](0)
        );

        apexMatches[matchId] = newMatch;

        apexQueues[queueId].users = new address[](0);

        emit ApexAdminStartMatch(
            matchId,
            queueId,
            apexQueues[queueId].name,
            apexQueues[queueId].entryFee,
            map,
            matchUsers,
            startTime
        );
    }

    function adminEndApexMatch(
        uint32 matchId,
        address[] calldata winners,
        uint64 endTime
    ) public {
        require(msg.sender == owner, "Only owner can end match");
        require(
            apexMatches[matchId].matchId == matchId,
            "Match does not exist"
        );

        uint256 totalWinnings = (apexMatches[matchId].entryFee *
            apexMatches[matchId].users.length) / winners.length;

        for (uint256 i = 0; i < winners.length; i++) {
            payable(winners[i]).transfer(totalWinnings);
        }

        apexMatches[matchId].endTime = endTime;
        apexMatches[matchId].winners = winners;

        ApexUser[] memory matchUsers = new ApexUser[](
            apexMatches[matchId].users.length
        );

        for (uint256 i = 0; i < apexMatches[matchId].users.length; i++) {
            matchUsers[i] = apexUsers[apexMatches[matchId].users[i]];
        }

        emit ApexAdminEndMatch(
            matchId,
            apexMatches[matchId].queueId,
            apexMatches[matchId].queueName,
            apexMatches[matchId].entryFee,
            apexMatches[matchId].map,
            matchUsers,
            apexMatches[matchId].startTime,
            endTime,
            winners
        );
    }
}