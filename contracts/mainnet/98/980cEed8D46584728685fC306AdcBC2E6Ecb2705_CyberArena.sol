/**
 *Submitted for verification at polygonscan.com on 2022-02-25
 */

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

contract CyberArena {
    //League
    enum League {
        Mythic,
        Hero
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

    //Address registered
    // address[] private registeredAddress;
    //Mapping
    mapping(address => PlayerStats) private allPlayersStats;

    // FUNCTIONS //

    //Register to New Game
    function registerUser(
        League _league,
        uint256 _gameEndTime,
        uint256 _battlePassId
    ) external {
        //if user exists
        if (allPlayersStats[msg.sender].isRegistered) {
            require(
                block.timestamp < allPlayersStats[msg.sender].gameEndTime,
                "Previous game is still in progress"
            );

            //Define Player stats using params
            PlayerStats memory newPlayerStats = PlayerStats({
                isRegistered: allPlayersStats[msg.sender].isRegistered,
                league: _league,
                gameEndTime: _gameEndTime,
                battlePassId: _battlePassId,
                powerBoostCount: 0,
                energyReactorCount: 0,
                totalRegisters: allPlayersStats[msg.sender].totalRegisters + 1,
                totalPowerBoostUsed: 0,
                totalEnergyUsed: 0
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
            //User is not registered
        } else {
            require(block.timestamp < _gameEndTime, "Game time is past due");

            //Define Player stats using params
            PlayerStats memory newPlayerStats = PlayerStats({
                isRegistered: true,
                league: _league,
                gameEndTime: _gameEndTime,
                battlePassId: _battlePassId,
                powerBoostCount: 0,
                energyReactorCount: 0,
                totalRegisters: 1,
                totalPowerBoostUsed: 0,
                totalEnergyUsed: 0
            });
            //New user struct mapped to allPlayerStats
            allPlayersStats[msg.sender] = newPlayerStats;
        }
    }

    //Get Player Info (Triggered by User)
    function getPlayerInfo() public view returns (PlayerStats memory) {
        //User must be registered
        require(
            allPlayersStats[msg.sender].isRegistered,
            "User is not registered"
        );

        return allPlayersStats[msg.sender];
    }

    //Increment PowerBoost
    function incrementPowerBoostCount() public {
        //User must be registered
        require(
            allPlayersStats[msg.sender].isRegistered,
            "User is not registered"
        );
        //Increment boost count and total
        allPlayersStats[msg.sender].powerBoostCount++;
        allPlayersStats[msg.sender].totalPowerBoostUsed++;
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
        require(
            allPlayersStats[msg.sender].isRegistered,
            "User is not registered"
        );
        //Increment boost count
        allPlayersStats[msg.sender].energyReactorCount++;
        allPlayersStats[msg.sender].totalEnergyUsed++;
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