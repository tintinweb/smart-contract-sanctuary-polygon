// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import './interfaces/IDataMigratableAttester.sol';
import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';

contract AttesterDataMigration is Ownable {
  constructor() {}

  function migrateData(
    address _oldContract,
    address _newContract,
    uint256[] calldata attestationIds,
    address[] calldata sources
  ) external onlyOwner {
    require(
      attestationIds.length == sources.length,
      'DataMigration: attestationIds and sources length mismatch'
    );

    IDataMigratableAttester oldContract = IDataMigratableAttester(_oldContract);
    IDataMigratableAttester newContract = IDataMigratableAttester(_newContract);
    for (uint256 i = 0; i < attestationIds.length; i++) {
      uint256 attestationId = attestationIds[i];
      address source = sources[i];

      address oldDestination = oldContract.getDestinationOfSource(attestationId, source);
      if (oldDestination != address(0)) {
        newContract.setDestinationForSource(attestationId, source, oldDestination);
      }
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

interface IDataMigratableAttester {
    function getDestinationOfSource(uint256 attestationId, address source) external view returns (address);
    function setDestinationForSource(uint256 attestationId, address source, address destination) external;
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