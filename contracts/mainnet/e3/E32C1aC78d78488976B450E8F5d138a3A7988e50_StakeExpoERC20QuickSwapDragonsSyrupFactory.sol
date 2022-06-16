// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.14;

import "@openzeppelin/contracts/access/Ownable.sol";

import "./vendor/StakingRewardsFactory.sol";

import "./Balance.sol";
import "./Earnings.sol";

contract StakeExpoERC20QuickSwapDragonsSyrupFactory is Ownable {
	StakingRewardsFactory public factory;

	struct Addresses {
		address balance;
		address earnings;
	}
	mapping(address => Addresses) public deployedRewardTokens;

	constructor(StakingRewardsFactory _factory) Ownable() {
		factory = _factory;
	}

	function deploy(address rewardToken) external {
        require(deployedRewardTokens[rewardToken].balance == address(0) && deployedRewardTokens[rewardToken].earnings == address(0), 'Specified reward token does not have a contract');
        (address stakingRewards,,) = factory.stakingRewardsInfoByRewardToken(rewardToken);
        require(stakingRewards != address(0), 'Specified reward token does not have a contract');
		address balance = address(new StakeExpoERC20QuickSwapDragonsSyrupBalance(owner(), StakingRewards(stakingRewards)));
		address earnings = address(new StakeExpoERC20QuickSwapDragonsSyrupEarnings(owner(), StakingRewards(stakingRewards)));
		deployedRewardTokens[rewardToken] = Addresses(balance, earnings);
	}

	function deployMany(uint256 index, uint256 lastIndex) external {
		for (; index <= lastIndex; index++) {
			address rewardToken = factory.rewardTokens(index);
			this.deploy(rewardToken);
		}
	}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.14;


abstract contract StakingRewardsFactory {
    address[] public rewardTokens;

	struct StakingRewardsInfo {
		address stakingRewards;
		uint rewardAmount;
		uint duration;
	}

    mapping(address => StakingRewardsInfo) public stakingRewardsInfoByRewardToken;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.14;

import "./Base.sol";

contract StakeExpoERC20QuickSwapDragonsSyrupBalance is StakeExpoERC20QuickSwapDragonsSyrup {
	constructor(address _owner, StakingRewards _stakingContract) StakeExpoERC20QuickSwapDragonsSyrup(_owner, _stakingContract) {

	}

    function name() public override view returns (string memory) {
		return string.concat("Dragon's Syrup: Staked ", stakingToken().symbol(), " in ", rewardsToken().symbol(), " pool");
    }

    function symbol() public override view returns (string memory) {
		return string.concat(stakingToken().symbol(), " (", rewardsToken().symbol(), ")");
    }

	function decimals() public override view returns (uint8) {
		return stakingToken().decimals();
	}

	function totalSupply() public override view returns (uint256) {
		return stakingToken().totalSupply();
	}

	function balanceOf(address account) public override view returns (uint256)  {
		return stakingContract.balanceOf(account);
	}
}

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.14;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./vendor/StakingRewards.sol";

abstract contract StakeExpoERC20QuickSwapDragonsSyrup is Ownable {
	StakingRewards public stakingContract;

    // modifier isOwner {
    //     require(msg.sender == owner, "Method must be called by owner");
    //     _;
    // }

	constructor(address _owner, StakingRewards _stakingContract) {
        _transferOwnership(_owner);
		stakingContract = _stakingContract;
	}

	function rewardsToken() public view returns (IERC20Metadata) {
		return stakingContract.rewardsToken();
	}
	function stakingToken() public view returns (IERC20Metadata) {
		return stakingContract.stakingToken();
	}

    function name() public virtual view returns (string memory);
	function symbol() public virtual view returns (string memory);
	function decimals() public virtual view returns (uint8);
	function totalSupply() public virtual view returns (uint256);
	function balanceOf(address account) public virtual view returns (uint256);

	function transferValueToOwner() external {
		payable(owner()).transfer(address(this).balance);
	}

	function transferTokenToOwner(IERC20 token) external {
		uint256 balance = token.balanceOf(address(this));
		bool success = token.transfer(owner(), balance);
		if (success) return;

		token.transferFrom(address(this), owner(), balance);
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

// SPDX-License-Identifier: GPL-3.0

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