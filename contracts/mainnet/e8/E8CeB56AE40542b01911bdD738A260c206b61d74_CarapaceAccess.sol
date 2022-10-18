// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./Interfaces/ICarapaceAccess.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title Carapace Access Contract
/// @notice Manages the possible caller addresses for each contract
contract CarapaceAccess is ICarapaceAccess, Ownable {
    mapping(address => mapping(address => bool)) private contractAccess;

    /// @inheritdoc ICarapaceAccess
    function setAccess(address _caller, address _called) override external onlyOwner() { 
        contractAccess[_caller][_called] = true;
    }

    /// @inheritdoc ICarapaceAccess
    function getAccess(address _caller) override external view returns (bool) { 
        return contractAccess[_caller][msg.sender];
    }

    // for testing purposes only (remove to Mainnet)
    function setFalse(address _caller, address _called) override external onlyOwner() { 
        contractAccess[_caller][_called] = false;
    }

    function getAccessTemp(address _caller, address _called) override external view returns (bool) {
        return contractAccess[_caller][_called];
    }
    
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

/// @title The interface for the Carapace Access contract
/// @notice The Carapace Access sets the permissions for a contract to be called only from specific trusted addresses (other Carapace contracts)
interface ICarapaceAccess {
    /// @notice Whitelists the callers for a called contract
    /// @param _caller The contract address to be whitelisted
    /// @param _called The contract address to be called
    function setAccess(address _caller, address _called) external;

    /// @notice Verifies if the caller address is whitelisted for the called address (contract that asks for verification)
    /// @param _caller The contract address of the original call
    /// @return _permission False for not permitted, True if permission was granted
    function getAccess(address _caller) external view returns (bool _permission);
    
    // for testing purposes only (remove to Mainnet)
    function setFalse(address _caller, address _called) external;
    function getAccessTemp(address _caller, address _called) external view returns (bool);
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