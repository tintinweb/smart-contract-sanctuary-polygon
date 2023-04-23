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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
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
pragma solidity ^0.8.17;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import './interfaces/IRegistry.sol';
import "./Whitelistable.sol";

contract Faucet is Ownable, Whitelistable {
  /**
   * @dev The `Faucet` contract transfers Matic Coins to users who are enrolled to the classroom.
   * The whitelisted users are retrieved from the `Registry` contract which is defined in the abstract
   * contract `Whitelistable`.
   */

  address payable public server;  // the server address
  uint256 public offering = 2e16; // 0.02 MATIC
  bool public locked;  // helpful when we want to lock the faucet itself irrespective of the single address
  uint256 public lockDuration;  // lock duration in seconds
  mapping(address => uint256) public lockTime;

  event RequestedTokens(address indexed _requestor, uint256 _amount);
  event FundReceived(address sender, uint256 amount);
  event FundsWithdrawn(address receiver, uint256 amount);

  constructor(IRegistry registry, address payable _server) Whitelistable(registry) {
    locked = false;
    lockDuration = 1 weeks;
    server = _server;
  }

  modifier onlyUnlocked() {
    require(!locked, 'ERROR: Contract is locked, please wait until owner unlocks the faucet');
    _;
  }

  modifier onlyServer() {
    require(
      msg.sender == server ||
      msg.sender == owner(),
      'ERROR: Only server or owner can call this function');
    _;
  }

  receive() external payable {
    // fallback function
    require(msg.value > 1e18, 'ERROR: Please send more than 1 MATIC to the faucet.');
    emit FundReceived(msg.sender, msg.value);
  }

  function setServer(address payable _server) public onlyOwner {
    // the server address is the address of the server which will send tokens to the users
    server = _server;
  }

  function setOffering(uint _offering) public onlyOwner {
    offering = _offering;
  }

  function updateLockDuration(uint256 _duration) public onlyOwner {
    // the lock duration is in seconds.
    // 1 week = 604800 seconds
    // 1 day = 86400 seconds
    lockDuration = _duration;
  }

  function lock(bool _status) public onlyOwner {
    // locks or unlocks the faucet
    locked = _status;
  }

  function requestTokens(address payable _requestor) public payable onlyUnlocked onlyServer {
    /**
      * @dev The `requestTokens` function transfers MATIC tokens to the user who
      * is enrolled in the classroom.
      * The user can request tokens only after the lock duration is over.
      * The lock duration is set to 1 week by default.
      * The token can be requested only if the faucet has enough funds.
      * Addresses available in registry can get tokens from the faucet.
      **/
    require(registry.isWhitelisted(_requestor), 'INVALID: Receiver is not a student or admin');
    require(
      block.timestamp > lockTime[_requestor] + lockDuration,
      'INVALID: Already received matic coins, please wait until the lock duration is over.'
    );
    require(server.balance > offering, 'ERROR: Not enough funds in the faucet.');
    _requestor.transfer(offering);
    lockTime[_requestor] = block.timestamp;
    emit RequestedTokens(_requestor, offering);
  }

  function getFaucetBalance() public view returns (uint) {
    return server.balance;
  }

  function withdrawFunds() public onlyOwner {
    // the owner can withdraw the funds from the faucet
    // note: the owner should be payable
    require(address(this).balance > 0, 'ERROR: No funds to withdraw.');
    payable(owner()).transfer(address(this).balance);
    emit FundsWithdrawn(owner(), address(this).balance);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

error MemberNotWhitelisted(address member);
error NotWhitelisted();

/// @title IRegistry
/// @notice This is the interface for a registry contract
/// @author thev
interface IRegistry {
  function isWhitelisted(address member) external view returns (bool);

  function areWhitelisted(address[] calldata member) external view returns (bool);

  function bulkAddToWhitelist(address[] calldata members) external;

  function addToWhitelist(address member) external;

  function bulkRemoveFromWhitelist(address[] calldata members) external;

  function removeFromWhitelist(address member) external;

  function grantRoleAdmin(address account) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import './interfaces/IRegistry.sol';

abstract contract Whitelistable {
  IRegistry public registry;

  event RegistryUpdated(IRegistry indexed registry);

  constructor(IRegistry _registry) {
    _setRegistry(_registry);
  }

  modifier onlyWhitelisted() {
    _checkWhitelisted(msg.sender);
    _;
  }

  modifier ifWhitelisted(address account) {
    _checkWhitelisted(account);
    _;
  }

  function updateRegistry(IRegistry _registry) public virtual {
    _setRegistry(_registry);
  }

  function _setRegistry(IRegistry _registry) internal {
    registry = _registry;
    emit RegistryUpdated(_registry);
  }

  function _checkWhitelisted(address account) internal view {
    if (!registry.isWhitelisted(account)) revert MemberNotWhitelisted(msg.sender);
  }

  function _checkWhitelisted(address[] memory accounts) internal view returns (bool) {
    return registry.areWhitelisted(accounts);
  }
}