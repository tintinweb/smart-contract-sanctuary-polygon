// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

// ______ _____________   __
// |  _  \  ___|  ___\ \ / /
// | | | | |__ | |_   \ V /
// | | | |  __||  _|   \ /
// | |/ /| |___| |     | |
// |___/ \____/\_|     \_/
//
// WELCOME TO THE REVOLUTION

contract DEFYAnalytics {
    event DailyCheckIn(address operative);
    event AccountCreation(address operative);

    function dailyCheckIn() external {
        emit DailyCheckIn(msg.sender);
    }

    function accountCreation() external {
        emit AccountCreation(msg.sender);
    }
}