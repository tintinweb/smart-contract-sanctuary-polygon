/**
 *Submitted for verification at polygonscan.com on 2022-12-09
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

// Objetivo: Smart contract que permita a la gente adivinar el equipo que ganará el mundial.
// Fijar sistema de lock de apuestas, no tiene mucho sentido restringirlo solo para la final.

// * emitir eventos necesarios para indexar datos y mostrar en frontend:
contract WorldCupBet {
    address public owner;
    address public treasury = 0x9931F0108A281A0a4B78613156a039e6aEFc59e4;
    uint256 START_WORLDCUP_FINALMATCH = 1671350400;
    uint256 public constant MAX_TEAMS_NUMBER = 8;
    uint256 public FEE = 10;
    uint256 public totalBettedAmount = 0;
    uint256 public winnerId = 100;
    TeamInfo[] public teamList;
    // teamId => user => amount betted
    mapping(uint256 => mapping(address => uint256)) teamUserBets;

    struct TeamInfo {
        uint256 id;
        string name;
        uint256 amountBetted;
        bool defeated;
    }

    //------- EVENTS -------
    event WorldCupBet_newBet(
        uint256 indexed teamId,
        address indexed user,
        uint256 amountBetted
    );

    event WorldCupBet__withdrawEarnings(
        address indexed user,
        uint256 amount,
        uint256 timestamp
    );

    event WorldCupBet__setWinner(uint256 teamId);
    event WorldCup__setDateTheEnd(uint256 newDate);

    constructor(string[] memory _teamList) {
        owner = msg.sender;
        initializeTeams(_teamList);
    }

    //------- MODIFIERS ----------
    modifier onlyOwner() {
        require(msg.sender == owner, "Onlyowner: user not owner");
        _;
    }

    modifier validTeamId(uint256 teamId) {
        require(
            teamId < MAX_TEAMS_NUMBER,
            "team ID must be between 0 and the max teams number"
        );
        require(!teamList[teamId].defeated, "The team has been defeated");
        _;
    }

    modifier isBettingOpen() {
        require(
            block.timestamp <= START_WORLDCUP_FINALMATCH &&
                winnerId > MAX_TEAMS_NUMBER,
            "Bet out of time range"
        );
        _;
    }

    modifier isDateTheEndEnabled(uint256 newDate) {
        require(newDate > block.timestamp, "Bet out of time range");
        _;
    }

    //------- EXTERNAL FUNCTIONS ---------

    function bet(
        uint256 teamId
    ) external payable validTeamId(teamId) isBettingOpen {
        require(msg.value > 0, "nothing to bet");

        teamList[teamId].amountBetted += msg.value;
        teamUserBets[teamId][msg.sender] += msg.value;
        totalBettedAmount += msg.value;
        emit WorldCupBet_newBet(teamId, msg.sender, msg.value);
    }

    //check for reentrancy
    function withdraw() external {
        require(winnerId < MAX_TEAMS_NUMBER);
        if (teamList[winnerId].amountBetted > 0) {
            uint256 userOwedAmount = (teamUserBets[winnerId][msg.sender] *
                totalBettedAmount) / teamList[winnerId].amountBetted;

            require(userOwedAmount > 0, "nothing to withdraw");
            teamUserBets[winnerId][msg.sender] = 0;

            transferEth(treasury, (userOwedAmount * FEE) / 100);
            transferEth(msg.sender, ((userOwedAmount * (100 - FEE)) / 100));

            emit WorldCupBet__withdrawEarnings(
                msg.sender,
                userOwedAmount,
                block.timestamp
            );
        } else {
            transferEth(treasury, totalBettedAmount);
            emit WorldCupBet__withdrawEarnings(
                treasury,
                totalBettedAmount,
                block.timestamp
            );
        }
    }

    function markDefeatedTeam(uint256 teamId, bool defeated) external {
        teamList[teamId].defeated = defeated;
    }

    //------- INTERNAL -------
    function transferEth(address _to, uint256 amount) internal {
        require(amount >= 0);
        (bool success, ) = _to.call{value: amount}("");
        require(success, "something went wrong");
    }

    function initializeTeams(string[] memory _teamList) internal {
        unchecked {
            for (uint256 i = 0; i < _teamList.length; i++) {
                TeamInfo memory team = TeamInfo(i, _teamList[i], 0, false);
                teamList.push(team);
            }
        }
    }

    //------- ADMIN FUNCTIONS -----------

    function setWinner(
        uint256 winnerTeamId
    ) external validTeamId(winnerTeamId) onlyOwner {
        winnerId = winnerTeamId;
        emit WorldCupBet__setWinner(winnerTeamId);
    }

    //------- EDIT FINAL DATE
    function setDateFinish(
        uint256 newDate
    ) external onlyOwner isDateTheEndEnabled(newDate) {
        START_WORLDCUP_FINALMATCH = newDate;
        emit WorldCup__setDateTheEnd(newDate);
    }

    //------- EDIT FEE
    function setFee(uint256 _fee) external onlyOwner {
        FEE = _fee;
    }

    //------- VIEW FUNCTIONS -------

    function getTeamList() public view returns (TeamInfo[] memory) {
        return teamList;
    }

    function getAmountBettedToTeam(
        uint256 _id
    ) public view validTeamId(_id) returns (uint256) {
        return teamList[_id].amountBetted;
    }

    function getUserProceeds(address _user) public view returns (uint256) {
        uint256 userOwedAmount = (teamUserBets[winnerId][_user] *
            totalBettedAmount) / teamList[winnerId].amountBetted;
        unchecked {
            return (userOwedAmount * (100 - FEE)) / 100;
        }
    }
}