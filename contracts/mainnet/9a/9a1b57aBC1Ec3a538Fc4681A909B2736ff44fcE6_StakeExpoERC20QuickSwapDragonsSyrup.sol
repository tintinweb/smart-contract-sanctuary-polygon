// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.14;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

interface IStakingRewards {
    function lastTimeRewardApplicable() external view returns (uint256);
    function rewardPerToken() external view returns (uint256);
    function earned(address account) external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);

    function stake(uint256 amount) external;
    function withdraw(uint256 amount) external;
    function getReward() external;
    function exit() external;
}

abstract contract StakingRewards is IStakingRewards {
    IERC20Metadata public rewardsToken;
    IERC20Metadata public stakingToken;
}

contract StakeExpoERC20QuickSwapDragonsSyrup {
	StakingRewards public stakingContract;
	bool private displayBalance;

	constructor(address _stakingContract, bool _displayBalance) {
		stakingContract = StakingRewards(_stakingContract);
		displayBalance = _displayBalance;
	}

	function rewardsToken() public view returns (IERC20Metadata) {
		return stakingContract.rewardsToken();
	}
	function stakingToken() public view returns (IERC20Metadata) {
		return stakingContract.stakingToken();
	}

    function name() public view returns (string memory) {
		if (displayBalance) {
			return string.concat("Dragon's Syrup: Staked ", stakingToken().symbol(), " in ", rewardsToken().symbol(), " pool");
		} else {
			return string.concat("Dragon's Syrup: Unclaimed ", rewardsToken().symbol());
		}
    }

    function symbol() public view returns (string memory) {
		if (displayBalance) {
			return string.concat(stakingToken().symbol(), " (", rewardsToken().symbol(), ")");
		} else {
			return string.concat("DS-", rewardsToken().symbol());
		}
    }

	function decimals() public view returns (uint8) {
		if (displayBalance) {
			return stakingToken().decimals();
		} else {
			return rewardsToken().decimals();
		}
	}

	function totalSupply() public view returns (uint256) {
		if (displayBalance) {
			return stakingToken().totalSupply();
		} else {
			return rewardsToken().totalSupply();
		}
	}

	function balanceOf(address account) public view returns (uint256)  {
		if (displayBalance) {
			return stakingContract.balanceOf(account);
		} else {
			return stakingContract.earned(account);
		}
	}

	// function transfer(address to, uint256 amount) public override returns (bool) {
	// 	require(false, "Unallowed");
	// }

	// function allowance(address owner, address spender) public view override returns (uint256) {
	// 	return 0;
	// }

	// function approve(address spender, uint256 amount) public override returns (bool) {
	// 	require(false, "Unallowed");
	// }

	// function transferFrom(address from, address to, uint256 amount) public override returns (bool) {
	// 	require(false, "Unallowed");
	// }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

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