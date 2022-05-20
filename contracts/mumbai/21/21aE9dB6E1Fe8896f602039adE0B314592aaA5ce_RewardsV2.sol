//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

contract RewardsV2 {
    bool initialized;
    uint256 rewards;
    event RewardsChanged(uint256 newRewards);

    function initialize() public {
        require(!initialized, "already initialized");

        rewards = 0x64;
        initialized = true;
    }
    // set rewards based on number of points with 50% increement
    function setRewardsPoints(uint256 _points) public {
        rewards = _points + (_points * 50) / 100;
        emit RewardsChanged(rewards);
    }

    function getRewardsPoints() public view returns (uint256) {
        return rewards;
    }
}