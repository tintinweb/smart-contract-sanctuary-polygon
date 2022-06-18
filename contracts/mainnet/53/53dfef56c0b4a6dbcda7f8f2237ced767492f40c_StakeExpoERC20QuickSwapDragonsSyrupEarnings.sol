// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.14;

import "./Base.sol";

contract StakeExpoERC20QuickSwapDragonsSyrupEarnings is StakeExpoERC20QuickSwapDragonsSyrup {
	constructor(address _owner, StakingRewards _stakingContract) StakeExpoERC20QuickSwapDragonsSyrup(_owner, _stakingContract) {

	}

    function name() public override view returns (string memory) {
		return string.concat("Dragon's Syrup: Unclaimed ", rewardsToken().symbol());
    }

    function symbol() public override view returns (string memory) {
		return string.concat("DS-", rewardsToken().symbol());
    }

	function decimals() public override view returns (uint8) {
		return rewardsToken().decimals();
	}

	function totalSupply() public override view returns (uint256) {
		return rewardsToken().totalSupply();
	}

	function balanceOf(address account) public override view returns (uint256)  {
		return stakingContract.earned(account);
	}
}