/**
 *Submitted for verification at polygonscan.com on 2022-10-30
*/

// SPDX-License-Identifier: UNLICENSED
// MYBATTERY.TODAY V2
pragma solidity ^0.8.16;

contract BPower2 {
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

    function addCoins(address ref) public payable {
        uint256 coins = msg.value / 1e15;
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
        uint256 amount = money * 2e14;
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
        batterys[user].coins -= getUpgradePrice(batteryId, Cells);
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
        if (cellId == 1) return [400, 1100, 1820, 2700][batteryId];
        if (cellId == 2) return [600, 1260, 1980, 2850][batteryId];
        if (cellId == 3) return [690, 1420, 2200, 3200][batteryId];
        if (cellId == 4) return [801, 1580, 2370, 3340][batteryId];
        if (cellId == 5) return [1000, 1780, 2500, 3640][batteryId];
        revert("Incorrect batteryId");
    }

    function getYield(uint256 batteryId, uint256 cellId) internal pure returns (uint256) {
        if (cellId == 1) return [9, 30, 56, 90][batteryId];
        if (cellId == 2) return [14, 36, 63, 98][batteryId];
        if (cellId == 3) return [17, 41, 72, 115][batteryId];
        if (cellId == 4) return [20, 46, 78, 125][batteryId];
        if (cellId == 5) return [25, 52, 83, 137][batteryId];
        revert("Incorrect batteryId");
    }
}