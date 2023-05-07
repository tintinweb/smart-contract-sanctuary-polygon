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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IRoyaltyBalancer {
  function addMinterShare(address minter, uint256 amount) external;
  function pendingReward(address minter) external view returns (uint256);
  function claimReward() external;
  function userInfo(address) external view returns (uint256 shares, uint256 debt);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {IRoyaltyBalancer} from "./IRoyaltyBalancer.sol";
import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";

// @title ....
// @author ....
// @notice .....

contract RoyaltyBalancer is IRoyaltyBalancer, Ownable {

  /* ****** */
  /* ERRORS */
  /* ****** */

  error OnlyCollection();

  /* ******* */
  /* STORAGE */
  /* ******* */

  address public collection;

  // @notie UserInfo struct to keep track of his shares and debt
  struct UserInfo {
    uint256 shares;
    uint256 debt; // in wei
  }

  uint256 public totalShares;
  uint256 public accRewardPerShare;

  modifier onlyCollection() {
    if (msg.sender != collection) {
      revert OnlyCollection();
    }
    _;
  }

  // @notice Used instead of require() to check that address calling 'addMinterShare' function is 'collection'
  mapping(address => UserInfo) public userInfo;

  /* *********** */
  /* CONSTRUCTOR */
  /* *********** */

  constructor() {}

  /* *********** */
  /*  FUNCTIONS  */
  /* *********** */

  // @notice Allows owner() to set collection's contract address
  function setCollectionAddress(address _collection) public onlyOwner {
    collection = _collection;
  }

  // @notice Adds minter shares to the state
  function addMinterShare(address minter, uint256 amount) external onlyCollection {
    totalShares = totalShares + amount;
    userInfo[minter].shares += amount;
    userInfo[minter].debt = accRewardPerShare * userInfo[minter].shares;
  }

  // @notice Allows to see how many rewards minter has (in wei)
  function pendingReward(address minter) public view returns (uint256) {
    UserInfo storage user = userInfo[minter];
    return accRewardPerShare * user.shares - user.debt;
  }

  // @notice Allows any user that has 'shares' to claim his rewards 
  function claimReward() external /* can be executed by any user */ {
    UserInfo storage user = userInfo[msg.sender];
    if (user.shares == 0) {
      return;
    }
    uint256 pending = pendingReward(msg.sender);
    user.debt = accRewardPerShare * user.shares;
    (bool success, ) = msg.sender.call{value: pending}("");
    require(success, "Couldn't send minter claiming funds");
  }

  // @notice When someone (supposed to be marketplace) sends funds to this contract (which is set as royalty receiver), 
  // reward per 1 share for each minter increases
  receive() external payable {
    accRewardPerShare = accRewardPerShare + msg.value / totalShares;
  }
}