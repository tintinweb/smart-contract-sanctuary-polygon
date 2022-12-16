// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

// SPDX-License-Identifier: MIT
// Pooky Game Contracts (interfaces/IWaitList.sol)
pragma solidity ^0.8.17;

interface IWaitList {
  /**
   * @notice Check if an account is eligible.
   * @param account The account address to lookup.
   * @return If the account is eligible.
   */
  function isEligible(address account) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// Pooky Game Contracts (WaitList.sol)
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/IWaitList.sol";

/**
 * @title WaitList
 * @author Mathieu Bour
 * @notice Basic wait list implementation. The greater the tier is, the higher the privileges should be.
 * @dev Owner can:
 * - change the requiredTier fto be eligible via the `isEligible` function.
 * - add account addresses and their associated tiers to the wait list.
 */
contract WaitList is IWaitList, Ownable {
  /// The account addresses tier mapping
  mapping(address => uint256) public tiers;
  /// The minimum required tier to be considered as "eligible".
  uint public requiredTier;

  /// Emitted when the tier of an address is set.
  event TierSet(address indexed account, uint256 tier);

  /// Thrown when the length of two parameters mismatch. Used in batched functions.
  error ArgumentSizeMismatch(uint256 x, uint256 y);

  /**
   * @param initialTier The initial required tier. Should be the all-time high tier.
   */
  constructor(uint256 initialTier) Ownable() {
    requiredTier = initialTier;
  }

  /**
   * Change the minimum required tier to be considered as "eligible".
   * @param newRequiredTier The new required tier.
   */
  function setRequiredTier(uint256 newRequiredTier) external onlyOwner {
    requiredTier = newRequiredTier;
  }

  /**
   * @notice Set the tier of multiple accounts at the same time.
   * @dev Requirements:
   * - msg.sender is the owner of the contract.
   * - accounts and tiers_ parameters have the same length.
   * @param accounts The account addresses.
   * @param tiers_ The associated tiers.
   */
  function setBatch(address[] memory accounts, uint256[] memory tiers_) external onlyOwner {
    if (accounts.length != tiers_.length) {
      revert ArgumentSizeMismatch(accounts.length, tiers_.length);
    }

    for (uint256 i = 0; i < accounts.length; i++) {
      tiers[accounts[i]] = tiers_[i];
      emit TierSet(accounts[i], tiers_[i]);
    }
  }

  /**
   * @notice Check if an account is eligible.
   * @param account The account address to lookup.
   * @return If the account is eligible.
   */
  function isEligible(address account) external view returns (bool) {
    return tiers[account] >= requiredTier;
  }
}