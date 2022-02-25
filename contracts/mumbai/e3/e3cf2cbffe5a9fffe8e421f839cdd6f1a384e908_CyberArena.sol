/**
 *Submitted for verification at polygonscan.com on 2022-02-24
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

contract CyberArena {
    
    bool public isRegistered;

    //Counters
    uint256 private powerBoostCount = 0;
    uint256 private energyReactorCount = 0;
    uint256 private totalRegisters = 0;
    uint256 private totalPowerBoostUsed = 0;
    uint256 private totalEnergyUsed = 0;

    //League
    enum League {
        Mythic,
        Heroes
    }

    //Player stats.
    struct PlayerStats {
        bool isRegistered;
        League league;
        uint256 gameEndTime;
        uint256 battlePassId;
        uint256 powerBoostCount;
        uint256 energyReactorCount;
        uint256 totalRegisters;
        uint256 totalPowerBoostUsed;
        uint256 totalEnergyUsed;
    }

    //Events
    event PlayerStatsEvent(
        bool isRegistered,
        League league,
        uint256 gameEndTime,
        uint256 battlePassId,
        uint256 powerBoostCount,
        uint256 energyReactorCount,
        uint256 totalRegisters,
        uint256 totalPowerBoostUsed,
        uint256 totalEnergyUsed
    );
    //Mapping
    mapping(address => PlayerStats) private allPlayersStats;

    //FUNCTIONS ////////////////////////
    //Register to New Game
    function registerUser (
        uint256 _gameEndTime,
        uint256 _battlePassId,
        League _league,
        uint256 _powerBoostCount,
        uint256 _energyReactorCount,
        uint256 _totalRegisters,
        uint256 _totalPowerBoostUsed,
        uint256 _totalEnergyUsed
    ) external {
       //Game must be endeded to allow user to register
        require(block.timestamp > _gameEndTime, "Game has not ended");
        //User cannot register twice during game
        require(!allPlayersStats[msg.sender].isRegistered, "User has already registered");       
       //Define Player stats using params 
        PlayerStats memory newPlayerStats = PlayerStats({
            isRegistered: true,
            league: _league,
            gameEndTime: _gameEndTime,
            battlePassId: _battlePassId,
            powerBoostCount: _powerBoostCount,
            energyReactorCount: _energyReactorCount,
            totalRegisters: _totalRegisters,
            totalPowerBoostUsed: _totalPowerBoostUsed,
            totalEnergyUsed: _totalEnergyUsed
        });
        //New user struct mapped to allPlayerStats
        allPlayersStats[msg.sender] = newPlayerStats;
        //Event emit
        emit PlayerStatsEvent(
            newPlayerStats.isRegistered,
            newPlayerStats.league,
            newPlayerStats.gameEndTime,
            newPlayerStats.battlePassId,
            newPlayerStats.powerBoostCount,
            newPlayerStats.energyReactorCount,
            newPlayerStats.totalRegisters,
            newPlayerStats.totalPowerBoostUsed,
            newPlayerStats.totalEnergyUsed
        );
    }

    //Get Player Info (Triggeres by User)
    function getPlayerInfo() public view returns (PlayerStats memory) {
        //User must be registered
        require(allPlayersStats[msg.sender].isRegistered, "User is not registered");
       
        return allPlayersStats[msg.sender];
    }

    //Increment PowerBoost
    function incrementPowerBoostCount() public {
        //User must be registered
        require(allPlayersStats[msg.sender].isRegistered, "User is not registered");
        //Increment boost count
        allPlayersStats[msg.sender].powerBoostCount++;
        //Event emit
        emit PlayerStatsEvent(
            allPlayersStats[msg.sender].isRegistered,
            allPlayersStats[msg.sender].league,
            allPlayersStats[msg.sender].gameEndTime,
            allPlayersStats[msg.sender].battlePassId,
            allPlayersStats[msg.sender].powerBoostCount,
            allPlayersStats[msg.sender].energyReactorCount,
            allPlayersStats[msg.sender].totalRegisters,
            allPlayersStats[msg.sender].totalPowerBoostUsed,
            allPlayersStats[msg.sender].totalEnergyUsed
        );
    }

    //Increment PowerBoost
    function incrementEnergyReactorCount() public {
        //User must be registered
        require(allPlayersStats[msg.sender].isRegistered, "User is not registered");
        //Increment boost count
        allPlayersStats[msg.sender].energyReactorCount++;
        //Event emit
        emit PlayerStatsEvent(
            allPlayersStats[msg.sender].isRegistered,
            allPlayersStats[msg.sender].league,
            allPlayersStats[msg.sender].gameEndTime,
            allPlayersStats[msg.sender].battlePassId,
            allPlayersStats[msg.sender].powerBoostCount,
            allPlayersStats[msg.sender].energyReactorCount,
            allPlayersStats[msg.sender].totalRegisters,
            allPlayersStats[msg.sender].totalPowerBoostUsed,
            allPlayersStats[msg.sender].totalEnergyUsed
        );
    }
}