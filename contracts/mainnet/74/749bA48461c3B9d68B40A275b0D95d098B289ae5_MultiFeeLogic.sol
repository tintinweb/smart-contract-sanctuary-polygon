// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IMultiFeeDistribution {
	function stake(uint256 amount, address user) external;

	function withdraw(uint256 amount, address user) external;

	function getReward(address[] memory _rewardTokens, address user) external;

	function exit(address user) external;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IMultiFeeDistribution.sol";

contract MultiFeeResolver {
	/**
	 * @dev claim rewards from the MultiFeeDistribution.
	 * @param multiFeeContract address of the contract to claim the rewards.
	 * @param user address of the user to claim the rewards.
	 */
	function claim(
		address multiFeeContract,
		address user,
		address[] calldata rewardTokens
	) external {
		require(
			multiFeeContract != address(0),
			"MultiFeeLogic: multifee contract cannot be address 0"
		);
		require(user != address(0), "MultiFeeLogic: user cannot be address 0");
		require(
			rewardTokens.length > 0,
			"MultiFeeLogic: rewardTokens should be greater than 0"
		);

		IMultiFeeDistribution(multiFeeContract).getReward(rewardTokens, user);
	}
}

contract MultiFeeLogic is MultiFeeResolver {
	receive() external payable {}
}