/**
 *Submitted for verification at polygonscan.com on 2022-11-03
*/

// SPDX-License-Identifier: UNLICENSED
// MYBATTERY.TODAY V2
pragma solidity ^0.8.16;

contract BatteryDappv2 {
    struct Battery {
        uint256 coins;
        uint256 money;
        uint256 money2;
        uint256 yield;
        uint256 timestamp;
        uint256 hrs;
        address ref;
        uint256 refs;
        uint256 refDeps;
        uint8[5] Cells;
    }
    mapping(address => Battery) public batterys;
    uint256 public totalCell;
    uint256 public totalBattery;
    uint256 public totalInvested;
    address public manager = msg.sender;
    uint256 immutable public denominator = 10;
  

    function addCoins(address ref) public payable {
        uint256 coins = msg.value / 2e17;
        require(coins > 0, "Zero coins");
        address user = msg.sender;
        totalInvested += msg.value;
        if (batterys[user].timestamp == 0) {
            totalBattery++;
            ref = batterys[ref].timestamp == 0 ? manager : ref;
            batterys[ref].refs++;
            batterys[user].ref = ref;
            batterys[user].timestamp = block.timestamp;
        }
        ref = batterys[user].ref;
        batterys[ref].coins += (coins * 7) / 100;
        batterys[ref].money += (coins * 100 * 3) / 100;
        batterys[ref].refDeps += coins;
        batterys[user].coins += coins;
        payable(manager).transfer((msg.value * 5) / 100);
    }

    function withdrawMoney() public {
        address user = msg.sender;
        uint256 money = batterys[user].money;
        batterys[user].money = 0;
        uint256 amount = money * 2e15;
        payable(user).transfer(address(this).balance < amount ? address(this).balance : amount);
        
    }

    function collectMoney() public {
        address user = msg.sender;
        syncBattery(user);
        batterys[user].hrs = 0;
        batterys[user].money += batterys[user].money2;
        batterys[user].money2 = 0;
    }

    function upgradeBattery(uint256 batteryId) public {
        require(batteryId < 4, "Max 4 batterys");
        address user = msg.sender;
        syncBattery(user);
        batterys[user].Cells[batteryId]++;
        totalCell++;
        uint256 Cells = batterys[user].Cells[batteryId];
        batterys[user].coins -= getUpgradePrice(batteryId, Cells) / denominator;
        batterys[user].yield += getYield(batteryId, Cells);
    }

    function sellBattery() public {
        collectMoney();
        address user = msg.sender;
        uint8[5] memory Cells = batterys[user].Cells;
        totalCell -= Cells[0] + Cells[1] + Cells[2] + Cells[3] + Cells[4];
        batterys[user].money += batterys[user].yield * 24 * 14;
        batterys[user].Cells = [0, 0, 0, 0, 0];
        batterys[user].yield = 0;
    }

    function getCells(address addr) public view returns (uint8[5] memory) {
        return batterys[addr].Cells;
    }

    function syncBattery(address user) internal {
        require(batterys[user].timestamp > 0, "User is not registered");
        if (batterys[user].yield > 0) {
            uint256 hrs = block.timestamp / 3600 - batterys[user].timestamp / 3600;
            if (hrs + batterys[user].hrs > 24) {
                hrs = 24 - batterys[user].hrs;
            }
            batterys[user].money2 += hrs * batterys[user].yield;
            batterys[user].hrs += hrs;
        }
        batterys[user].timestamp = block.timestamp;
    }

    function getUpgradePrice(uint256 batteryId, uint256 cellId) internal pure returns (uint256) {
        if (cellId == 1) return [400, 4000, 26000, 39000][batteryId];
        if (cellId == 2) return [600, 6000, 31300, 47500][batteryId];
        if (cellId == 3) return [900, 9000, 33200, 57000][batteryId];
        if (cellId == 4) return [1360, 13500, 33400, 64600][batteryId];
        if (cellId == 5) return [2040, 20260, 36000, 109000][batteryId];
        revert("Incorrect batteryId");
    }

    function getYield(uint256 batteryId, uint256 cellId) internal pure returns (uint256) {
        if (cellId == 1) return [9, 110, 830, 1350][batteryId];
        if (cellId == 2) return [14, 168, 1010, 1650][batteryId];
        if (cellId == 3) return [22, 265, 1080, 2010][batteryId];
        if (cellId == 4) return [36, 401, 1100, 2300][batteryId];
        if (cellId == 5) return [56, 645, 1200, 4100][batteryId];
        revert("Incorrect batteryId");
    }

    
}