// SPDX-License-Identifier: MIT

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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

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

//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/IVotingEscrow.sol";

contract VoteEscrowAdapter is Ownable {
	IVotingEscrow public veETHA =
		IVotingEscrow(0x6bb60a941FAa77DD6204BE98Cb9b715D59e70D0a);

	function getGlobalData()
		external
		view
		returns (
			uint256 minLocked,
			uint256 withdrawFee,
			uint256 supply,
			uint256 minDays,
			uint256 maxDays
		)
	{
		minLocked = veETHA.minLockedAmount();
		withdrawFee = veETHA.earlyWithdrawPenaltyRate();
		supply = veETHA.supply();
		minDays = veETHA.MINDAYS();
		maxDays = veETHA.MAXDAYS();
	}

	function getUserData(address user)
		external
		view
		returns (
			uint256 amountLocked,
			uint256 lockEnd,
			uint256 veETHABal
		)
	{
		(amountLocked, lockEnd) = veETHA.locked(user);
		veETHABal = veETHA.balanceOf(user);
	}

	function setVoteEscrowContract(IVotingEscrow _veETHA) external onlyOwner {
		veETHA = _veETHA;
	}
}

// SPDX-License-Identifier: MIT

// Standard Curvefi voting escrow interface
// We want to use a standard iface to allow compatibility
pragma solidity ^0.8.0;

interface IVotingEscrow {
	// Following are used in Fee distribution contracts e.g.
	/*
        https://etherscan.io/address/0x74c6cade3ef61d64dcc9b97490d9fbb231e4bdcc#code
    */
	// struct Point {
	//     int128 bias;
	//     int128 slope;
	//     uint256 ts;
	//     uint256 blk;
	// }

	// function user_point_epoch(address addr) external view returns (uint256);

	// function epoch() external view returns (uint256);

	// function user_point_history(address addr, uint256 loc) external view returns (Point);

	// function checkpoint() external;

	/*
    https://etherscan.io/address/0x2e57627ACf6c1812F99e274d0ac61B786c19E74f#readContract
    */
	// Gauge proxy requires the following. inherit from ERC20
	// balanceOf
	// totalSupply

	function deposit_for(address _addr, uint256 _value) external;

	function create_lock(uint256 _value, uint256 _unlock_time) external;

	function increase_amount(uint256 _value) external;

	function increase_unlock_time(uint256 _unlock_time) external;

	function withdraw() external;

	function emergencyWithdraw() external;

	// Extra required views
	function balanceOf(address) external view returns (uint256);

	function supply() external view returns (uint256);

	function minLockedAmount() external view returns (uint256);

	function earlyWithdrawPenaltyRate() external view returns (uint256);

	function MINDAYS() external view returns (uint256);

	function MAXDAYS() external view returns (uint256);

	function MAXTIME() external view returns (uint256);

	function locked(address) external view returns (uint256, uint256);

	// function transferOwnership(address addr) external;
}