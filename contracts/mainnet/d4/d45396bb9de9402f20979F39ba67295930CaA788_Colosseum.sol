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
        string name;
        uint256 entryFee;
        uint8 maxUsers;
        uint8 maxTeams;
        address[] users;
    }

    struct ApexQueuesInit {
        uint32[] ids;
        string[] names;
        uint256[] entryFees;
        uint8[] maxUsers;
        uint8[] maxTeams;
    }

    address payable public owner;
    mapping(uint32 => ApexQueue) public apexQueues;
    mapping(address => ApexUser) public apexUsers;

    event ApexQueueJoin(uint32 id, ApexUser apexUser, uint256 entryFee);

    constructor(ApexQueuesInit memory apexQueuesInit) payable {
        owner = payable(msg.sender);
        for (uint256 i = 0; i < apexQueuesInit.ids.length; i++) {
            ApexQueue storage r = apexQueues[apexQueuesInit.ids[i]];
            require(r.id == 0, "Queue already exists");
            r.id = apexQueuesInit.ids[i];
            r.name = apexQueuesInit.names[i];
            r.entryFee = apexQueuesInit.entryFees[i];
            r.maxUsers = apexQueuesInit.maxUsers[i];
            r.maxTeams = apexQueuesInit.maxTeams[i];
            r.users = new address[](0);
        }
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
        apexQueues[id].users.push(msg.sender);

        ApexUser memory newUser = ApexUser(
            payable(msg.sender),
            apexUsername,
            discorId
        );

        apexUsers[msg.sender] = newUser;

        emit ApexQueueJoin(id, newUser, msg.value);
    }

    function getApexUser(address wallet) public view returns (ApexUser memory) {
        return apexUsers[wallet];
    }

    function getApexQueue(uint32 id) public view returns (ApexQueue memory) {
        return apexQueues[id];
    }
}