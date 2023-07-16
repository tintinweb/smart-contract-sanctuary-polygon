/**
 *Submitted for verification at polygonscan.com on 2023-07-16
*/

// SPDX-License-Identifier: MIT
/*
  ____  _   _ _     _     ___ _____ ____  
 | __ )| | | | |   | |   |_ _| ____/ ___| 
 |  _ \| | | | |   | |    | ||  _| \___ \ 
 | |_) | |_| | |___| |___ | || |___ ___) |
 |____/ \___/|_____|_____|___|_____|____/ 
                                          
          By Devko.dev#7286
*/
// File: @openzeppelin/contracts/utils/Context.sol

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

// File: @openzeppelin/contracts/access/Ownable.sol

// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

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

// File: contract.sol

pragma solidity ^0.8.7;

interface IBONES {
  function burnFrom(address _from, uint256 _value) external;

  function allowance(address owner, address spender) external view returns (uint256);
}

contract BulliesBAYC is Ownable {
  IBONES public BONES_CONTRACT = IBONES(0xa7c192364D44Eb664161A997822a7243112b47C0);
  uint256 public maxEntries = 10000000;

  struct ticket {
    uint256 quantity;
    address buyer;
  }
  ticket[] public ticketsTracker;
  uint256 public entriesBought;
  uint256 public entryCost = 10 ether;

  constructor() {}

  modifier notContract() {
    require((!_isContract(msg.sender)) && (msg.sender == tx.origin), "CONTRACTS_NOT_ALLOWED");
    _;
  }

  function _isContract(address addr) internal view returns (bool) {
    uint256 size;
    assembly {
      size := extcodesize(addr)
    }
    return size > 0;
  }

  function changePaymentToken(address newToken) external onlyOwner {
    BONES_CONTRACT = IBONES(newToken);
  }

  function changeMaxEntries(uint256 newMaxTickets) external onlyOwner {
    maxEntries = newMaxTickets;
  }

  function changeEntryCost(uint256 newCost) external onlyOwner {
    entryCost = newCost;
  }

  function buyTickets(uint256 quantity) external notContract {
    require(maxEntries >= entriesBought + quantity, "NO_ENOUGH_QUANTITY");
    require(BONES_CONTRACT.allowance(msg.sender, address(this)) >= entryCost * quantity, "NO_ENOUGH_SPENDING_ALLOWED");
    BONES_CONTRACT.burnFrom(msg.sender, entryCost * quantity);

    ticketsTracker.push(ticket(quantity, msg.sender));
    entriesBought += quantity;
  }

  function getEntriesFor(address buyer) external view returns (uint256) {
    uint256 totalEntries = 0;
    for (uint i = 0; i < ticketsTracker.length; i++) {
      if (ticketsTracker[i].buyer == buyer) {
        totalEntries += ticketsTracker[i].quantity;
      }
    }
    return totalEntries;
  }

  function getTotalEntries() external view returns (uint256) {
    uint256 totalEntries = 0;
    for (uint i = 0; i < ticketsTracker.length; i++) {
      totalEntries += ticketsTracker[i].quantity;
    }
    return totalEntries;
  }
}