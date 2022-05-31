// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "../interfaces/IStakingRewards.sol";
import "../interfaces/IDragonLair.sol";
import "../interfaces/IDistributionFactory.sol";

contract StakingAdapter {
	IDragonLair public constant DQUICK =
		IDragonLair(0xf28164A485B0B2C90639E47b0f377b4a438a16B1);

	IDistributionFactory public constant QUICK_FACTORY =
		IDistributionFactory(0x8aAA5e259F74c8114e0a471d9f2ADFc66Bfe09ed);

	struct Data {
		address stakingContract;
		uint256 totalSupply;
		uint256 rewardsRate;
		uint256 periodFinish;
		uint256 quickBalance;
	}

	function getStakingInfo(address[] calldata lpTokens)
		external
		view
		returns (Data[] memory)
	{
		Data[] memory _datas = new Data[](lpTokens.length);

		IStakingRewards instance;
		address stakingContract;
		uint256 periodFinish;
		uint256 rewardRate;
		uint256 quickBalance;

		for (uint256 i = 0; i < _datas.length; i++) {
			stakingContract = QUICK_FACTORY.stakingRewardsInfoByStakingToken(
				lpTokens[i]
			);
			instance = IStakingRewards(stakingContract);

			periodFinish = instance.periodFinish();
			quickBalance = DQUICK.dQUICKForQUICK(
				DQUICK.balanceOf(stakingContract)
			);
			rewardRate = DQUICK.dQUICKForQUICK(instance.rewardRate());

			_datas[i] = Data(
				stakingContract,
				instance.totalSupply(),
				rewardRate,
				periodFinish,
				quickBalance
			);
		}

		return _datas;
	}
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IDistributionFactory {
	function stakingRewardsInfoByStakingToken(address erc20)
		external
		view
		returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IDragonLair is IERC20 {
	function enter(uint256 _quickAmount) external;

	function leave(uint256 _dQuickAmount) external;

	function QUICKBalance(address _account)
		external
		view
		returns (uint256 quickAmount_);

	function dQUICKForQUICK(uint256 _dQuickAmount)
		external
		view
		returns (uint256 quickAmount_);

	function QUICKForDQUICK(uint256 _quickAmount)
		external
		view
		returns (uint256 dQuickAmount_);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IStakingRewards {
	// Views
	function lastTimeRewardApplicable() external view returns (uint256);

	function rewardPerToken() external view returns (uint256);

	function earned(address account) external view returns (uint256);

	function getRewardForDuration() external view returns (uint256);

	function totalSupply() external view returns (uint256);

	function claimDate() external view returns (uint256);

	function balanceOf(address account) external view returns (uint256);

	function rewardsToken() external view returns (address);

	function stakingToken() external view returns (address);

	function rewardRate() external view returns (uint256);

	function periodFinish() external view returns (uint256);

	// Mutative

	function stake(uint256 amount) external;

	function withdraw(uint256 amount) external;

	function getReward() external;

	function exit() external;
}