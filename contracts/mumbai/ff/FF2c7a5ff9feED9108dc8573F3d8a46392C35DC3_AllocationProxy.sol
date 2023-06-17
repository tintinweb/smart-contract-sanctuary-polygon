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

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.16;

import "@openzeppelin/contracts/access/Ownable.sol";
import "contracts/allocation/IAllocationProxy.sol";
import "contracts/allocation/IAllocationProvider.sol";

contract AllocationProxy is IAllocationProxy, Ownable {
    IAllocationProvider private immutable _creditProvider;
    IAllocationProvider private immutable _directProvider;
    IAllocationProvider private immutable _relativeProvider;

    uint256 private _totalAllocation;
    uint256 private _remainingAllocation;

    constructor(address creditProvider, address directProvider, address relativeProvider, uint256 newTotalAllocation) {
        require(creditProvider != address(0), "AllocationProxy: must have a credit provider");
        require(directProvider != address(0), "AllocationProxy: must have a direct provider");
        require(relativeProvider != address(0), "AllocationProxy: must have a relative provider");
        
        _creditProvider = IAllocationProvider(creditProvider);
        _directProvider = IAllocationProvider(directProvider);
        _relativeProvider = IAllocationProvider(relativeProvider);
        _setAllocation(newTotalAllocation);
    }

    function resetAllocation(uint256 _newAllocation) external onlyOwner {
        _setAllocation(_newAllocation);
    }

    function allocationOf(address account) external view override returns (uint256) {
        uint256 _allocation = 0;
        _allocation += _creditProvider.allocationOf(account);
        _allocation += _directProvider.allocationOf(account);
        
        if(_relativeProvider.totalAllocation() == 0) {
            return _allocation;
        }
        _allocation +=
            (_relativeProvider.allocationOf(account) * _remainingAllocation) /
            _relativeProvider.totalAllocation();
        return _allocation;
    }

    function creditAllocationOf(address account) external view returns (uint256) {
        return _creditProvider.allocationOf(account);
    }

    function directAllocationOf(address account) external view returns (uint256) {
        return _directProvider.allocationOf(account);
    }

    function relativeAllocationOf(address account) external view returns (uint256) {
        if(_relativeProvider.totalAllocation() == 0) {
            return 0;
        }
        return _relativeProvider.allocationOf(account) * _remainingAllocation / _relativeProvider.totalAllocation();
    }

    function totalAllocation() external view override returns (uint256) {
        return _totalAllocation;
    }

    function _setAllocation(uint256 newTotalAllocation) internal {
        uint256 _allocation = 0;
        _allocation += _creditProvider.totalAllocation();
        _allocation += _directProvider.totalAllocation();
        _totalAllocation = newTotalAllocation;
        require(_totalAllocation >= _allocation, "AllocationProxy: Snapshot balances exceeds allocation.");
        _remainingAllocation = _totalAllocation - _allocation;
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

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.16;

interface IAllocationProxy {
    /**
     * @dev Returns total allocation in USD of `_account`
     * @param _account Account to check
     * @return Allocation of `_account`
     */
    function allocationOf(address _account) external view returns (uint256);

    /**
     * @dev Returns credit allocation in USD
     * @return Credit allocation
     */
    function creditAllocationOf(address account) external view returns (uint256);

    /**
     * @dev Returns direct allocation in USD
     * @return Direct allocation
     */
    function directAllocationOf(address account) external view returns (uint256);

    /**
     * @dev Returns relative(staking) allocation in USD
     * @return Relative allocation
     */
    function relativeAllocationOf(address account) external view returns (uint256);

    /**
     * @dev Returns total allocation in USD
     * @return Total allocation
     */
    function totalAllocation() external view returns (uint256);
}