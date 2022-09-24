//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.16;

import { Ownable } from '@openzeppelin/contracts/access/Ownable.sol';
import { Context } from '@openzeppelin/contracts/utils/Context.sol';
import { Fundable } from './Fundable.sol';

struct Info {
  string encryptedData;
  string campaign;
  uint addDate;
  bool exists;
}

contract FanList is Ownable, Fundable {
  mapping(address => Info) private infos;
  address[] private list;
  string public publicKey;
  string public artistName;
  string public version = "1.0.0";

  event Added(address indexed account, uint listNumber);
  event Updated(address indexed account);

  constructor(string memory _artistName, string memory _publicKey, address _initialFunder) {
    artistName = _artistName;
    publicKey = _publicKey;
    _transferFunder(_initialFunder);
  }

  function add(address _address, string memory _campaign, string memory _encryptedData) public returns(uint listNumber) {
    require(_address == _msgSender() || _msgSender() == owner() || _msgSender() == funder(), 'Cannot add others.');
    require(!isListed(_address), 'Already listed.');
    infos[_address].encryptedData = _encryptedData;
    infos[_address].campaign = _campaign;
    infos[_address].addDate = block.timestamp;
    infos[_address].exists = true;
    list.push(_address);
    emit Added(_address, list.length - 1);
    return list.length - 1;
  }

  function update(address _address, string memory _encryptedData) public returns(bool success) {
    require(_address == _msgSender() || _msgSender() == owner() || _msgSender() == funder(), 'Cannot update others.');
    require(isListed(_address), 'Not on list.');
    infos[_address].encryptedData = _encryptedData;
    emit Updated(_address);
    return true;
  }

  // item utility functions
  function isListed(address _address) public view returns(bool) {
    return infos[_address].exists;
  }
  function getIndex(address _address) public view returns(uint) {
    for (uint i = 0; i < list.length; i++) {
      if (list[i] == _address) {
        return i;
      }
    }
    revert('Not Found');
  }
  function getData(address _address) public view returns(Info memory) {
    return infos[_address];
  }
  function getListCount() public view returns(uint) {
    return list.length;
  }

  // list utility functions
  function getList() public view returns(address[] memory) {
    return list;
  }
  function getFullList() public view returns(address[] memory, Info[] memory) {
    Info[] memory out = new Info[](list.length);
    for (uint i = 0; i < list.length; i++) {
      out[i] = infos[list[i]];
    }
    return (list, out);
  }
}

// SPDX-License-Identifier: MIT
// Based on OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import { Context } from '@openzeppelin/contracts/utils/Context.sol';

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an funder) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the funder account will be the one that deploys the contract. This
 * can later be changed with {transferFunder}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyFunder`, which can be applied to your functions to restrict their use to
 * the funder.
 */
abstract contract Fundable is Context {
    address private _funder;

    event FunderTransferred(address indexed previousFunder, address indexed newFunder);

    /**
     * @dev Throws if called by any account other than the funder.
     */
    modifier onlyFunder() {
        _checkFunder();
        _;
    }

    /**
     * @dev Returns the address of the current funder.
     */
    function funder() public view virtual returns (address) {
        return _funder;
    }

    /**
     * @dev Throws if the sender is not the funder.
     */
    function _checkFunder() internal view virtual {
        require(funder() == _msgSender(), "Fundable: caller is not the funder");
    }

    /**
     * @dev Leaves the contract without funder. It will not be possible to call
     * `onlyFunder` functions anymore. Can only be called by the current funder.
     *
     * NOTE: Renouncing funder will leave the contract without an funder,
     * thereby removing any functionality that is only available to the funder.
     */
    function renounceFunder() public virtual onlyFunder {
        _transferFunder(address(0));
    }

    /**
     * @dev Transfers funder of the contract to a new account (`newFunder`).
     * Can only be called by the current funder.
     */
    function transferFunder(address newFunder) public virtual onlyFunder {
        require(newFunder != address(0), "Fundable: new funder is the zero address");
        _transferFunder(newFunder);
    }

    /**
     * @dev Transfers funder of the contract to a new account (`newFunder`).
     * Internal function without access restriction.
     */
    function _transferFunder(address newFunder) internal virtual {
        address oldFunder = _funder;
        _funder = newFunder;
        emit FunderTransferred(oldFunder, newFunder);
    }
}

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