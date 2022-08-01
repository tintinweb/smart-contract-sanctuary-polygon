// contracts/StakingToken.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


import "./stakeable.sol";

contract StakeTokenv7 is StakingRewards {
    constructor(uint256 initialSupply, address[] memory defaultOperators, address payable _stakingToken, address payable _rewardsToken)
        StakingRewards("Stakingv7", "Sk7", defaultOperators, _stakingToken, _rewardsToken)
    {
        _mint(msg.sender, initialSupply, "", "");
    }
}