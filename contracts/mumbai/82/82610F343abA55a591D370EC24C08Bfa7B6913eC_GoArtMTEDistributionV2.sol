// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.14;

import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/security/Pausable.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

/**
 * @title GoArtCampaign
 * @dev Distribute MATIC tokens in exchange for GoArt MTE Points collected within in the GoArt game.
 */
contract GoArtMTEDistributionV2 is ReentrancyGuard, Pausable, Ownable {
	uint256 public maxRewardTotal = 40000 ether;
	uint256 public totalDistributedReward;

	// participant counter
	uint256 private participantCounter;

	// used coupon counter
	uint256 public usedCouponCounter;

	// Store coupons
	struct Coupon {
		address claimer;
		string couponId;
		uint256 amount;
		uint256 claimedAt;
	}

	// Store the used coupons in an array
	Coupon[] public coupons;

	// Listing all admins
	address[] public admins;

	// Modifier for easier checking if user is admin
	mapping(address => bool) public isAdmin;

	// mappings to store usedCoupons to prevent replay attacks
	mapping(string => bool) usedCoupons;

	// store users' coupons here
	mapping(address => Coupon[]) userCoupons;

	// event for EVM logging
	event AdminAdded(address adminAddress);
	event AdminRemoved(address adminAddress);
	event RewardClaimed(address partipantWalletAddress, uint256 withdrawnAmount);
	event MaxRewardUpdated(uint256 maxReward);
	event FundsWithdrawn(address from, address to, uint256 amount);
	event Funded(address from, uint256 amount);

	// Modifier restricting access to only admin
	modifier onlyAdmin() {
		require(isAdmin[msg.sender], 'Only admin can call.');
		_;
	}

	/**
	 * @dev Constructor to set initial admins during deployment
	 *
	 */
	constructor() {
		admins.push(msg.sender);
		isAdmin[msg.sender] = true;
	}

	// ***************** ADMIN OPERATIONS *****************
	/**
	 * @dev register a new admin with the given wallet address
	 *
	 * @param _adminAddress admin address to be added
	 */
	function addAdmin(address _adminAddress) external onlyAdmin {
		// Can't add 0x address as an admin
		require(_adminAddress != address(0x0), '[RBAC] : Admin must be != than 0x0 address');
		// Can't add existing admin
		require(!isAdmin[_adminAddress], '[RBAC] : Admin already exists.');
		// Add admin to array of admins
		admins.push(_adminAddress);
		// Set mapping
		isAdmin[_adminAddress] = true;
		emit AdminAdded(_adminAddress);
	}

	/**
	 * @dev remove an existing admin address
	 *
	 * @param _adminAddress admin address to be removed
	 */
	function removeAdmin(address _adminAddress) external onlyAdmin {
		// Admin has to exist
		require(isAdmin[_adminAddress]);
		require(admins.length > 1, 'Can not remove all admins since contract becomes unusable.');
		uint256 i = 0;

		while (admins[i] != _adminAddress) {
			if (i == admins.length) {
				revert('Passed admin address does not exist');
			}
			i++;
		}

		// Copy the last admin position to the current index
		admins[i] = admins[admins.length - 1];

		isAdmin[_adminAddress] = false;

		// Remove the last admin, since it's double present
		admins.pop();
		emit AdminRemoved(_adminAddress);
	}

	// fund the contract
	function fundContract() external payable onlyAdmin {
		emit Funded(msg.sender, msg.value);
	}

	/// destroy the contract and reclaim the leftover funds.
	function shutdown() external onlyAdmin {
		selfdestruct(payable(msg.sender));
	}

	function pauseContract() external onlyAdmin {
		_pause();
	}

	function unpauseContract() external onlyAdmin {
		_unpause();
	}

	function withdrawContractFunds() external onlyAdmin {
		address payable to = payable(msg.sender);
		uint256 amount = getBalance();
		to.transfer(amount);
		emit FundsWithdrawn(msg.sender, msg.sender, amount);
	}

	function withdrawContractFundsTo(address payable _to) external onlyAdmin {
		uint256 amount = getBalance();
		_to.transfer(amount);
		emit FundsWithdrawn(msg.sender, _to, amount);
	}

	/**
	 * @dev Transfer MATIC to given address.
	 *
	 * @param wallet recepient
	 * @param amount amount to be sent
	 */
	function sendMatic(address payable wallet, uint256 amount) internal {
		(bool success, ) = wallet.call{value: amount}('');
		require(success, 'Transfer failed during sending Matic tokens');
	}

	/**
	 * @dev Change the contract's max reward amount
	 *
	 * @param _maxReward new max reward
	 */
	function changeMaxReward(uint256 _maxReward) external onlyAdmin {
		maxRewardTotal = _maxReward;
		emit MaxRewardUpdated(_maxReward);
	}

	// ***************** USER OPERATIONS *****************

	/**
	 * @dev Withdraw MATIC tokens for the given user
	 *
	 */
	function claimRewards(
		uint256 _amount,
		string memory coupon,
		bytes memory signature
	) external whenNotPaused nonReentrant {
		require(!usedCoupons[coupon], 'This coupon has been redeemed earlier.');

		// set it as used
		usedCoupons[coupon] = true;

		// this recreates the message that was signed on the client
		bytes32 message = prefixed(keccak256(abi.encodePacked(msg.sender, _amount, coupon, this)));

		require(recoverSigner(message, signature) == owner(), 'Invalid signature.');

		require(
			totalDistributedReward + _amount <= maxRewardTotal,
			'Given amount exceeds the total reward to be distributed from this contract'
		);

		Coupon memory _coupon = Coupon(msg.sender, coupon, _amount, block.timestamp);
		coupons.push(_coupon);
		userCoupons[msg.sender].push(_coupon);

		// update the total amount
		totalDistributedReward += _amount;

		// transfer the funds
		sendMatic(payable(msg.sender), _amount);

		emit RewardClaimed(msg.sender, _amount);
	}

	// ***************** SIGNATURE METHODS *****************

	/// signature methods.
	function splitSignature(bytes memory sig)
		internal
		pure
		returns (
			uint8 v,
			bytes32 r,
			bytes32 s
		)
	{
		require(sig.length == 65);

		assembly {
			// first 32 bytes, after the length prefix.
			r := mload(add(sig, 32))
			// second 32 bytes.
			s := mload(add(sig, 64))
			// final byte (first byte of the next 32 bytes).
			v := byte(0, mload(add(sig, 96)))
		}

		return (v, r, s);
	}

	function recoverSigner(bytes32 message, bytes memory sig) internal pure returns (address) {
		(uint8 v, bytes32 r, bytes32 s) = splitSignature(sig);

		return ecrecover(message, v, r, s);
	}

	/// builds a prefixed hash to mimic the behavior of eth_sign.
	function prefixed(bytes32 hash) internal pure returns (bytes32) {
		return keccak256(abi.encodePacked('\x19Ethereum Signed Message:\n32', hash));
	}

	// ***************** GETTERS *****************

	// get maximum reward total
	function getMaxRewardTotal() public view returns (uint256) {
		return maxRewardTotal;
	}

	// get total distributed reward
	function getTotalDisributedReward() public view returns (uint256) {
		return totalDistributedReward;
	}

	// Helper function to check the balance of this contract
	function getBalance() public view returns (uint256) {
		return address(this).balance;
	}

	function getUserCoupons(address _userAddress) public view returns (Coupon[] memory) {
		return userCoupons[_userAddress];
	}

	function getAllCoupons() public view returns (Coupon[] memory) {
		return coupons;
	}

	// Fetch all admins
	function getAllAdmins() external view returns (address[] memory) {
		return admins;
	}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
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