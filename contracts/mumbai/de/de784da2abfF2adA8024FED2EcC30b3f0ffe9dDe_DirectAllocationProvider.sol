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
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

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
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
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

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.16;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "contracts/allocation/IAllocationProvider.sol";

/**
 * @title AbstractAllocationProvider
 * @author OpenPad
 * @notice Contract implments allocation provider interface assuming that
 * {_calculateAllocation} function is implemented.
 * @dev Derived contracts must implement {_calculateAllocation} function.
 */
abstract contract AbstractAllocationProvider is IAllocationProvider, Ownable, ReentrancyGuard {
    struct Allocation {
        uint8 generation;
        uint256 amount;
    }

    /// @notice Mapping of accounts to allocations
    mapping(address => Allocation) private _allocations;
    /// @notice Total allocation reserved
    uint256 private _totalAllocation;
    /// @notice Current generation
    uint8 private _generation = 1;

    function allocationOf(address _account) public view returns (uint256) {
        Allocation memory allocation = _allocations[_account];
        if (allocation.generation == _generation) {
            return allocation.amount;
        }
        return 0;
    }

    function totalAllocation() public view returns (uint256) {
        return _totalAllocation;
    }

    /**
     * @notice Function to grant an allocation to an account
     * @dev This function's behavior can be customized by overriding the internal _grantAllocation function.
     * @param account to grant allocation to
     * @param amount allocation amount
     */
    function grantAllocation(address account, uint256 amount) public onlyOwner {
        require(
            account != address(0),
            "AbstractAllocationProvider: beneficiary is the zero address"
        );
        require(amount > 0, "AbstractAllocationProvider: amount is 0");
        uint allocation = allocationOf(account) + amount;
        _setAllocation(account, allocation);
    }

    function takeSnapshot(
        address[] memory accounts
    ) public onlyOwner nonReentrant {
        for (uint256 i = 0; i < accounts.length; i++) {
            uint256 amount = _calculateAllocation(accounts[i]);
            grantAllocation(accounts[i], amount);
        }
    }

    function reset() public onlyOwner {
        _generation += 1;
        _totalAllocation = 0;
    }

    /**
     * @notice Function to revoke an allocation from an account
     * @dev This function can only be called by the owner.
     * @param account The account to revoke the allocation from
     */
    function revokeAllocation(address account) public onlyOwner {
        require(
            account != address(0),
            "AbstractAllocationProvider: beneficiary is the zero address"
        );
        _setAllocation(account, 0);
    }

    /**
     * @notice Internal function to grant an allocation to an account
     * @dev This function can be overridden to add functionality to the granting of an allocation.
     * @param account The account to grant the allocation to
     */
    function _calculateAllocation(address account) internal view virtual returns (uint256);

    function _setAllocation(address account, uint256 amount) private {
        Allocation memory allocation = _allocations[account];
        if (allocation.generation == _generation) {
            _totalAllocation = _totalAllocation - allocation.amount + amount;
        } else {
            _totalAllocation = _totalAllocation + amount;
        }
        _allocations[account] = Allocation(_generation, amount);
    }
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.16;

import "contracts/allocation/AbstractAllocationProvider.sol";

/**
 * @title DirectAllocationProvider
 * @author OpenPad
 */
contract DirectAllocationProvider is AbstractAllocationProvider {

    /**
     * @notice grants allocation to multiple accounts
     * @param accounts accounts to grant allocation to
     * @param allocations allocations to grant
     */
    function grantBatchAllocation(address[] memory accounts, uint256[] memory allocations) external onlyOwner {
        require(accounts.length == allocations.length, "DirectAllocationProvider: accounts and allocations must be the same length");
        for (uint256 i = 0; i < accounts.length; i++) {
            grantAllocation(accounts[i], allocations[i]);
        }
    }

    /**
     * @notice This function is not used in the direct allocation version of allocation provider
     * @param account is the account to calculate in other versions of Allocation providers
     */
    function _calculateAllocation(address account) internal pure override returns (uint256) {
        // ssh - Not used
        account;
        revert("DirectAllocationProvider: cannot calculate allocation on direct allocation provider. Use grantBatchAllocation instead.");
    }
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.16;

interface IAllocationProvider {
    /**
     * @dev Returns allocation in USD of `_account`
     * @param _account Account to check
     * @return Allocation of `_account`
     */
    function allocationOf(address _account) external view returns (uint256);

    /**
     * @dev Returns total allocation in USD
     * @return Total allocation
     */
    function totalAllocation() external view returns (uint256);
}