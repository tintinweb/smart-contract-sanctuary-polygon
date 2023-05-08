// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract TournamentManagerV1 {
    constructor() {}

    struct Tournament {
        address owner;
        string title;
        uint256 entryFee;
        uint256 prizePool;
        address[] allowList;
        mapping(address => bool) userJoined;
    }

    struct ReadTournament {
        address owner;
        string title;
        uint256 entryFee;
        uint256 prizePool;
    }

    mapping(uint256 => Tournament) public tournaments;

    // Tournament Count
    //
    uint256 public tournamentCount;

    // Events
    //
    event TournamentJoined(uint256 tournamentId, address participant);

    // Create Tournament
    //
    function createTournament(
        address _owner,
        string memory _title,
        uint256 _entryFee
    ) public returns (uint256) {
        Tournament storage tournament = tournaments[tournamentCount];

        tournament.owner = _owner;
        tournament.title = _title;
        tournament.entryFee = _entryFee;
        tournament.prizePool = 0;
        tournament.allowList = new address[](0);

        tournamentCount++;

        return tournamentCount - 1;
    }

    // Join Tournaments
    //
    function joinTournament(uint256 _tournamentId) public payable {
        Tournament storage tournament = tournaments[_tournamentId];

        require(
            tournament.userJoined[msg.sender] == false,
            "Player already joined!"
        );

        if (tournament.userJoined[msg.sender] == false) {
            require(msg.value == tournament.entryFee, "Invalid entry fee");
            tournament.allowList.push(payable(msg.sender));
            tournament.userJoined[msg.sender] = true;
        }

        // uint256 amount = tournament.entryFee;
        // (bool sent,) = payable(tournament.owner).call{value: amount}("");

        // if(sent) {
        //     tournament.prizePool = tournament.prizePool + amount;
        // }
    }

    // Get data of a tournament
    //
    function getSingleTournament(
        uint256 _tournamentId
    ) public view returns (ReadTournament memory) {
        ReadTournament memory readData = ReadTournament(
            tournaments[_tournamentId].owner,
            tournaments[_tournamentId].title,
            tournaments[_tournamentId].entryFee,
            tournaments[_tournamentId].prizePool
        );

        return readData;
    }

    // Get the allowlist of a tournament
    //
    function getSingleAllowList(
        uint256 _tournamentId
    ) external view returns (address[] memory) {
        return tournaments[_tournamentId].allowList;
    }
}