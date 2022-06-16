// contracts/StakingToken.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


import "./stakeable.sol";

contract V3Stake is StakingRewards {
    constructor(uint256 initialSupply, address[] memory defaultOperators, address _stakingToken, address _rewardsToken)
        StakingRewards("V3Stake", "SKT3", defaultOperators, _stakingToken, _rewardsToken)
    {
        _mint(msg.sender, initialSupply, "", "");
    }
}