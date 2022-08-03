// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.13;

import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';

/// @title Child registry for EthPlays
/// @author olias.eth
/// @notice This is experimental software, use at your own risk.
contract RegistryReceiverV0 is Ownable {
  /* -------------------------------------------------------------------------- */
  /*                                   STORAGE                                  */
  /* -------------------------------------------------------------------------- */

  /// @notice [State] Registered account addresses by burner account address
  mapping(address => address) public accounts;
  /// @notice [State] Burner account addresses by registered account address
  mapping(address => address) public burnerAccounts;

  /* -------------------------------------------------------------------------- */
  /*                                   EVENTS                                   */
  /* -------------------------------------------------------------------------- */

  event NewRegistration(address account, address burnerAccount);
  event UpdatedRegistration(address account, address burnerAccount, address previousBurnerAccount);

  /* -------------------------------------------------------------------------- */
  /*                                REGISTRATION                                */
  /* -------------------------------------------------------------------------- */

  /// @notice Returns true if the specified burner account is registered.
  /// @param burnerAccount The address of the players burner account
  /// @return isRegistered True if the burner account is registered
  function isRegistered(address burnerAccount) public view returns (bool) {
    return accounts[burnerAccount] != address(0);
  }

  /* -------------------------------------------------------------------------- */
  /*                                REGISTRATION                                */
  /* -------------------------------------------------------------------------- */

  /// @notice Registers a new account to burner account mapping. Owner only.
  /// @param account The address of the players main account
  /// @param burnerAccount The address of the players burner account
  function submitRegistration(address account, address burnerAccount) external onlyOwner {
    address previousBurnerAccount = burnerAccounts[account];

    if (previousBurnerAccount != address(0)) {
      emit UpdatedRegistration(account, burnerAccount, previousBurnerAccount);
    } else {
      emit NewRegistration(account, burnerAccount);
    }

    accounts[burnerAccount] = account;
    burnerAccounts[account] = burnerAccount;
  }
}

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