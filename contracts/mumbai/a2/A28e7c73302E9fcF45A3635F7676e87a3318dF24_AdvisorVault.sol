// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract AdvisorVault is Ownable {
  address public token;

  uint256 public lockPeriod = 4 weeks;
  uint256 public lockPeriodStart;

  uint256 public unlockPeriod = 1 weeks;
  uint256 public unlockAmountPerPeriod = 10; // 10%
  uint256 public unlockAmountPerPeriodDenominator = 100;

  address public treasury;

  struct AdvisorInfo {
    uint256 lockedAmount;
    uint256 lastClaimAt;
    uint256 totalClaimedAmount;
  }

  mapping(address => AdvisorInfo) public advisorInfos;
  mapping(address => bool) public isAdvisor;

  constructor(address _token) {
    require(_token != address(0x0), "Zero address detected");

    token = _token;
  }

  /************************************
  | Advisor functions
  |************************************/

  function claim() public onlyAdvisor {
    require(lockPeriodStart > 0, "Lock period not finished");
    require(lockPeriodStart + lockPeriod <= block.timestamp, "Can not claim for now");

    AdvisorInfo storage infos = advisorInfos[msg.sender];
    require(infos.totalClaimedAmount < infos.lockedAmount, "Empty vault");

    uint256 amount = claimableAmount();
    require(amount > 0, "Nothing to claim for now" );

    infos.lastClaimAt = block.timestamp;
    infos.totalClaimedAmount += amount;

    bool success = IERC20(token).transfer(msg.sender, amount);
    require(success, "Failed to send tokens");

    emit Claim(msg.sender, amount);
  }

  function claimableAmount() public view onlyAdvisor returns (uint256) {
    AdvisorInfo memory infos = advisorInfos[msg.sender];

    // If advisor already claimed everything
    if(infos.totalClaimedAmount >= infos.lockedAmount) {
      return 0;
    }

    // If the initial lock period didn't end yet
    if(lockPeriodStart + lockPeriod < block.timestamp) {
      return 0;
    }

    uint256 currentEpochStartAt = (lockPeriodStart + lockPeriod) + (currentEpoch() - 1) * unlockPeriod;

    // If advisor already claimed for current epoch
    if(infos.lastClaimAt >= currentEpochStartAt) {
      return 0;
    }

    uint256 periodToClaim = (currentEpochStartAt - infos.lastClaimAt) / unlockPeriod + 1;
    uint256 amountToUnlock = periodToClaim * unlockAmountPerPeriod;
    uint256 amount = infos.lockedAmount * amountToUnlock / unlockAmountPerPeriodDenominator;

    return amount;
  }

  function currentEpoch() public view returns (uint) {
    if(block.timestamp < lockPeriodStart + lockPeriod) {
      return 0;
    }

    return ((block.timestamp - (lockPeriodStart + lockPeriod)) / unlockPeriod) + 1;
  }

  function nextClaimAt() public view returns (uint256) {
    if(currentEpoch() == 0) {
      return lockPeriodStart + lockPeriod;
    }
    
    return lockPeriodStart + lockPeriod + (currentEpoch() + 1) * unlockPeriod;
  }

  /************************************
  | Admin functions
  |************************************/

  function setLockPeriodStartAt(uint256 _startAt) public onlyOwner {
    require(_startAt >= block.timestamp, "Can not start in past");
    lockPeriodStart = _startAt;
  }

  function addAdvisor(address _addr, uint256 _amount) public onlyOwner {
    require(_addr != address(0x0), "Zero address detected");
    require(lockPeriodStart > 0, "Lock period start not set");

    AdvisorInfo storage infos = advisorInfos[_addr];
    infos.lockedAmount = _amount;

    isAdvisor[_addr] = true;
  }

  function setTreasury(address _addr) public onlyOwner {
    require(_addr != address(0x0), "Zero address detected");
    treasury = _addr;
  }

  function setLockInfos(uint256 _lockPeriodStart, uint256 _lockPeriod, uint256 _unlockPeriod) public onlyOwner {
    require(_lockPeriodStart > 0, "Invalid lock period start");
    require(_lockPeriod > 0, "Invalid lock period");
    require(_unlockPeriod > 0, "Invalid unlock period");

    lockPeriodStart = _lockPeriodStart;
    lockPeriod = _lockPeriod;
    unlockPeriod = _unlockPeriod;
  }

  /************************************
  | Modifiers
  |************************************/

  modifier onlyAdvisor {
    require(isAdvisor[msg.sender], "Not allowed");
    _;
  }

  /************************************
  | Withdraw
  |************************************/

  function withdraw() external onlyOwner {
    require(treasury != address(0), "Treasury is set to zero");
    uint256 balance = address(this).balance;
    (bool success,) = payable(treasury).call{value: balance}("");
    require(success, "Withdraw failed");
  }

  function withdraw(address _token) external onlyOwner {
    require(treasury != address(0), "Treasury address to zero");
    bool success = IERC20(_token).transfer(treasury, IERC20(_token).balanceOf(address(this)));
    require(success, "Error while withdrawing funds");
  }

  /************************************
  | Fallback
  |************************************/

  receive() external payable {}

  /************************************
  | Events
  |************************************/

  event Claim(address, uint256);
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