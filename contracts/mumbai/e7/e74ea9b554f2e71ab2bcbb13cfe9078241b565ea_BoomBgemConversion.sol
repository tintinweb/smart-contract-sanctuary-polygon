// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "@openzeppelin/contracts/access/Ownable.sol";

interface IERC20Transferable {
  function transferFrom(address from, address to, uint256 amount) external;
}

/// @notice Convert BOOM tokens to BGEM
/// @author zetsub0ii.eth
contract BoomBgemConversion is Ownable {
  /// @dev This assumes that BOOM will have less decimals than BGEM (6 < 18)
  ///      This allows us to have 12 decimal places for the rate
  /// If 1 BOOM is equal to 1 BGEM this amount will be 1 * 10**12
  /// If 1 BOOM is equalt to 2.5 BGEM this amount will be 25 * 10**11
  uint256 public boomToBgemRate;

  /// @dev Max amount of BGEM conversion allowed in a day
  uint256 public dailyMaxAmount;

  /// @dev Current amount of BGEM conversion done in the day
  uint256 public currentAmount;

  /// @dev Last update time on the currentAmount
  uint256 public lastUpdateAt;

  IERC20Transferable boom;
  IERC20Transferable bgem;

  /// @dev Studio has to approve BOOM to this contract
  address studio;

  constructor(
    uint256 startRate,
    uint256 startMaxAmount,
    address _studio,
    address _bgem,
    address _boom
  ) {
    lastUpdateAt = block.timestamp;
    boomToBgemRate = startRate;
    dailyMaxAmount = startMaxAmount;

    studio = _studio;
    boom = IERC20Transferable(_boom);
    bgem = IERC20Transferable(_bgem);
  }

  /// @notice Setter for boom to bgem rate
  function setBoomToBgemRate(uint256 newRate) external onlyOwner {
    boomToBgemRate = newRate;
  }

  /// @notice Setter for max amount
  function setDailyMaxAmount(uint256 newMaxAmount) external onlyOwner {
    dailyMaxAmount = newMaxAmount;
  }

  function convert(uint256 bgemAmount) external {
    // If one day has passed since the last update, reset current amount
    if (block.timestamp - lastUpdateAt > 1 days) {
      lastUpdateAt = block.timestamp;
      currentAmount = 0;
    }

    require(currentAmount + bgemAmount < dailyMaxAmount, "Maximum daily conversion amount reached");

    // Increment current amount
    currentAmount += bgemAmount;

    uint256 boomAmount = bgemAmount / boomToBgemRate;

    bgem.transferFrom(msg.sender, studio, bgemAmount);
    boom.transferFrom(studio, msg.sender, boomAmount);
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