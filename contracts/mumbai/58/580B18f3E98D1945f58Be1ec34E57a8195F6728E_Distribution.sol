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
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
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

/**
 * SPDX-License-Identifier: MIT
 */
pragma solidity 0.8.18;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';

/**
 * @author Accubits
 * @title DISTRIBUTION
 * @dev Implements a distribution contract to stake ERC20 token
 * Receive rewards on ERC20 token according to the amount staked and time period.
 */
contract Distribution is Ownable, ReentrancyGuard {
  /**
   * @dev Struct representing a user account in the contract.
   * @param balance The current token balance staked by the user.
   * @param forecastedCredits The amount of credits that the user is expected to get.
   * @param lastUpdatedTimestamp The timestamp when the user details were last updated.
   * @param lastClaimedTimestamp The timestamp when the user last claimed their rewards.
   */

  struct User {
    uint256 balance;
    uint256 forecastedCredits;
    uint256 lastUpdatedTimestamp;
    uint256 lastClaimedTimestamp;
  }

  /**
   * @dev Struct representing the history of profit distribution.
   * @param startTime The timestamp when the profit distribution period started.
   * @param endTime The timestamp when the profit distribution period ended.
   * @param monthlyProfit The total profit for each month.
   * @param totalCredits The total credits distributed in the current distribution.
   * @param remainingTokensToClaim The number of tokens remaining to be claimed by users.
   */

  struct DistributionHistory {
    uint256 startTime;
    uint256 endTime;
    uint256 monthlyProfit;
    uint256 totalCredits;
    uint256 remainingTokensToClaim;
  }

  /// The ERC20 token used to stake.
  IERC20 private immutable _token;

  /// Stores the distribution period in hours.
  uint256 private _slot;

  /// Stores the start timestamp of the current distribution period.
  uint256 private _currentSlotStart;

  /// Stores the end timestamp of the current distribution period.
  uint256 private _currentSlotEnd;

  /// Current credits accumulated.
  uint256 private _totalCredits = 0;

  /// The total amount of tokens staked on the contract.
  uint256 private _totalAmount = 0;

  /// The wallet address where tokens collected as withdrawal fees.
  address private _treasuryWallet;

  /// The withdrawal fee charged when tokens are withdrawn from the contract.
  uint256 private _withdrawalFee;

  /// Mapping of user addresses to their associated User struct.
  mapping(address => User) private _users;

  /// A mapping indicating whether an address is a registered user or not.
  mapping(address => bool) private _isUser;

  /// An array of all registered user addresses.
  address[] private _userAddresses;

  /// An array of DistributionHistory structs representing the profit distribution history.
  DistributionHistory[] private _distributionHistory;

  /// The admin claim period for rewards claimed by the contract owner.
  uint256 private _adminClaimPeriod;

  /**
   * @dev Event emitted when a user account is deposited with tokens.
   * @param user The address of the user whose account was deposited.
   * @param amount The amount of tokens deposited.
   */
  event Deposit(address indexed user, uint256 amount);

  /**
   * @dev Event emitted when a user account withdraws tokens.
   * @param user The address of the user whose account was withdrawn.
   * @param amount The amount of tokens withdrawn.
   */
  event Withdraw(address indexed user, uint256 amount);

  /**
   * @dev Event emitted when profits are distributed among users.
   * @param amount The total amount of tokens distributed as profits.
   */
  event Distribute(uint256 amount);

  /**
   * @dev Event emitted when a user claims their credits.
   * @param user The address of the user claiming credits.
   * @param amount The amount of credits claimed.
   */
  event Claim(address indexed user, uint256 amount);

  /**
   * @dev Event emitted when the admin claims expired rewards.
   * @param admin The address of the admin claiming rewards.
   * @param amount The amount of credits claimed.
   */
  event AdminClaim(address indexed admin, uint256 amount);

  /**
   * @dev Event emitted when the withdrawal fee is updated.
   * @param fee The new withdrawal fee.
   */
  event WithdrawalFeeUpdated(uint256 fee);

  /**
   * @dev Event emitted when the treasury wallet is updated.
   * @param account The new treasury wallet address.
   */
  event TreasuryWalletUpdated(address account);

  /**
   * @dev Event emitted when the current slot value is updated.
   * @param slot The new slot value.
   */
  event SlotUpdated(uint256 slot);

  /**
   * @dev Event emitted when the admin claim period is updated.
   * @param adminClaimPeriod The new admin claim period.
   */
  event AdminClaimPeriodUpdated(uint256 adminClaimPeriod);

  /**
   * @dev Contract constructor function, sets initial values for various parameters
   * @param admin Address of the owner of the contract
   * @param treasuryWallet Address of the wallet to which fees are sent
   * @param tokenAddress Address of the ERC20 token being used
   * @param slot The time duration of a slot in hours
   * @param adminClaimPeriod The duration within which Admin can claim their tokens after expiration, in hours
   * @param fee Withdrawal fee in basis points (10000 = 100%)
   */
  constructor(
    address admin,
    address treasuryWallet,
    address tokenAddress,
    uint256 slot,
    uint256 adminClaimPeriod,
    uint256 fee
  ) {
    require(treasuryWallet != address(0), 'LINGO: Zero Address');

    _token = IERC20(tokenAddress);
    _slot = slot;
    _currentSlotStart = block.timestamp / 3600;
    _currentSlotEnd = _currentSlotStart + _slot;
    _adminClaimPeriod = adminClaimPeriod;
    _treasuryWallet = treasuryWallet;
    setWithdrawalFee(fee);

    _transferOwnership(admin);
  }

  /**
   * @dev Modifier to check that the user is an active user
   */
  modifier isUser() {
    require(_isUser[msg.sender], 'LINGO: Not an active user');
    _;
  }

  /**
   * @dev Modifier to check that the current time slot is active and distribution is not on hold
   */

  modifier isActive() {
    require(
      (block.timestamp / 3600) <= _currentSlotEnd && (block.timestamp / 3600) >= _currentSlotStart,
      'LINGO: Distribution is on hold. Please contact admin'
    );
    _;
  }

  /**
   * @dev Modifier to check if the user have any unclaimed tokens before depositing or withdrawing
   */

  modifier havePendingClaim() {
    User memory senderDetails = _users[_msgSender()];

    if (_distributionHistory.length > 0) {
      DistributionHistory memory lastDistributionDetails = _distributionHistory[
        _distributionHistory.length - 1
      ];
      require(
        senderDetails.lastClaimedTimestamp >= lastDistributionDetails.endTime,
        'LINGO: User have unclaimed tokens. Please claim it before deposit or withdraw'
      );
    }
    _;
  }

  /**
   * @dev Sets the treasury wallet address to a new value.
   * @param account The new address for the treasury wallet.
   */
  function setTreasuryWalletAddress(address account) external onlyOwner {
    /// The treasury wallet address cannot be set to the zero-address.
    require(account != address(0), 'LINGO: Zero Address');
    _treasuryWallet = account;
    /// Emits an event when `_treasuryWallet` is updated using this function.
    emit TreasuryWalletUpdated(account);
  }

  /**
   * @dev Updates the slot number to a new value.
   * @param newSlot The new value for the slot.
   */
  function updateSlot(uint256 newSlot) external onlyOwner {
    require(newSlot > 0, 'LINGO: Slot cannot be zero');
    _slot = newSlot;
    /// Emits an event when `_slot` is updated using this function.
    emit SlotUpdated(_slot);
  }

  /**
   * @dev Updates the admin claim period to a new value.
   * @param newAdminClaimPeriod The new value for the admin claim period.
   */
  function updateAdminClaimPeriod(uint256 newAdminClaimPeriod) external onlyOwner {
    _adminClaimPeriod = newAdminClaimPeriod;
    /// Emits an event when `_adminClaimPeriod` is updated using this function.
    emit AdminClaimPeriodUpdated(_adminClaimPeriod);
  }

  /**
   * @dev Allows user to deposit tokens for staking, and earn rewards for doing so.
   * @param amount Amount of tokens being deposited by the user.
   */
  function deposit(uint256 amount) external isActive havePendingClaim nonReentrant {
    require(amount > 0, 'LINGO: Amount cannot be zero');

    address sender = _msgSender();
    uint256 allowance = _token.allowance(sender, address(this));
    require(allowance >= amount, 'LINGO: Insufficient allowance');

    User storage userDetails = _users[sender];

    /// Subtract the forecasted credits from the total credits before updating the forecasted credits.
    _totalCredits -= _totalCredits > 0 ? userDetails.forecastedCredits : 0;
    /// Update forecasted credits by decreasing old value and adding new earned credits.
    userDetails.forecastedCredits -= userDetails.forecastedCredits > 0
      ? userDetails.balance * (_currentSlotEnd - block.timestamp / 3600)
      : 0;

    /// Add deposited amount to the user's balance.
    userDetails.balance += amount;
    /// Calculate forecasted credits for the user based on the updated balance.
    userDetails.forecastedCredits +=
      userDetails.balance *
      (_currentSlotEnd - block.timestamp / 3600);
    /// Update last updated timestamp to current hour.
    userDetails.lastUpdatedTimestamp = block.timestamp / 3600;

    /// Add the new forecasted credits to the total credits.
    _totalCredits += userDetails.forecastedCredits;
    /// Add deposited amount to the total amount.
    _totalAmount += amount;

    /// If user is depositing for the first time, set their last claimed timestamp.
    if (!_isUser[sender]) {
      _isUser[sender] = true;
      _userAddresses.push(sender);
      userDetails.lastClaimedTimestamp = block.timestamp / 3600;
    }

    bool txnStatus = _token.transferFrom(sender, address(this), amount);
    require(txnStatus, 'LINGO: Token transfer failed');

    /// Emit deposit event with user's address and deposited amount.
    emit Deposit(sender, amount);
  }

  /**
   * @dev Allows user to withdraw tokens from their account, and deducts applicable withdrawal fee.
   * @notice Users can only withdraw if they have previously deposited tokens for staking.
   * @param amount Amount of tokens being withdrawn by the user.
   */
  function withdraw(uint256 amount) external isUser isActive havePendingClaim nonReentrant {
    require(amount > 0, 'LINGO: Amount cannot be zero');

    address sender = _msgSender();
    User storage userDetails = _users[sender];

    require(userDetails.balance >= amount, 'LINGO: Insufficient balance');

    /// Subtract forecasted credits from total credits before updating the forecasted credits for user.
    _totalCredits -= userDetails.forecastedCredits;

    /// Update user's forecasted credits after withdrawal.
    userDetails.forecastedCredits -=
      userDetails.balance *
      (_currentSlotEnd - block.timestamp / 3600);

    /// Deduct the withdrawn amount from user's balance.
    userDetails.balance -= amount;
    /// Calculate new forecasted credits based on updated balance.
    userDetails.forecastedCredits +=
      userDetails.balance *
      (_currentSlotEnd - block.timestamp / 3600);
    /// Update last updated timestamp to current hour.
    userDetails.lastUpdatedTimestamp = block.timestamp / 3600;

    /// Add the new forecasted credits to the total credits.
    _totalCredits += userDetails.forecastedCredits;
    /// Deduct withdrawn amount from total amount.
    _totalAmount -= amount;

    uint256 fee = (amount * _withdrawalFee) / 10000;

    /// Transfer the withdrawal fee to the treasury wallet.
    bool feeCollectionStatus = _transferTokens(_treasuryWallet, fee);
    require(feeCollectionStatus, 'LINGO: Fee collection failed');

    /// Transfer the withdrawn amount after deducting the withdrawal fee.
    bool txnStatus = _transferTokens(sender, amount - fee);
    require(txnStatus, 'LINGO: Token transfer failed');

    /// Emit withdraw event with user's address and withdrawn amount.
    emit Withdraw(sender, amount);
  }

  /**
   * @dev Distributes tokens to the contract for last slot.
   * @notice The current month's slot must have expired before distribution can occur and only owner can call this function.
   * @param amount Amount of tokens being distributed.
   */
  function distribute(uint256 amount) external onlyOwner {
    require(amount > 0, 'LINGO: Amount cannot be zero');
    /// Check if the previous slot has expired before distributing tokens for the new slot.
    require(_currentSlotEnd <= (block.timestamp / 3600), 'LINGO: Current slot is active');

    uint256 allowance = _token.allowance(owner(), address(this));
    /// Ensure that the contract has sufficient token allowance from the owner.
    require(allowance >= amount, 'LINGO: Insufficient allowance');

    _distributionHistory.push(
      DistributionHistory({
        startTime: _currentSlotStart,
        endTime: _currentSlotEnd,
        monthlyProfit: amount,
        totalCredits: _totalCredits,
        remainingTokensToClaim: amount
      })
    );

    /// Update current slot start and end times for the next distribution.
    _currentSlotStart = _currentSlotEnd;
    _currentSlotEnd = _currentSlotEnd + _slot;

    /// Calculate the new total credits based on updated slot end time and total amount.
    _totalCredits = _totalAmount * (_currentSlotEnd - _currentSlotStart);

    /// Emit distribute event with the distributed amount.
    emit Distribute(amount);

    bool txnStatus = _token.transferFrom(owner(), address(this), amount);
    require(txnStatus, 'LINGO: Token transfer failed');
  }

  /**
   * @dev Allows user to claim their monthly rewards if any.
   * @notice User must be active, and cannot claim rewards before current slot has started.
   */
  function claimRewards() external isUser isActive nonReentrant {
    address sender = _msgSender();
    User storage userDetails = _users[sender];

    /// Ensure that the user has not already claimed rewards for the current slot.
    require(_currentSlotStart > userDetails.lastClaimedTimestamp, 'LINGO: Already claimed');

    uint256 totalClaim = 0;
    uint256 credits = 0;
    uint256 claim = 0;

    /// If no distribution history exists or user has to claim rewards in the last slot only. calculate claim for the last slot.
    if (
      _distributionHistory.length == 1 ||
      (_distributionHistory.length > 1 &&
        (userDetails.lastClaimedTimestamp >=
          _distributionHistory[_distributionHistory.length - 1].startTime))
    ) {
      if (_distributionHistory[_distributionHistory.length - 1].totalCredits > 0) {
        credits = userDetails.forecastedCredits;
        claim =
          (credits * _distributionHistory[_distributionHistory.length - 1].monthlyProfit) /
          _distributionHistory[_distributionHistory.length - 1].totalCredits;
        totalClaim += claim;

        /// Reduce remaining tokens in the distribution history for the corresponding claim.
        _distributionHistory[_distributionHistory.length - 1].remainingTokensToClaim -= claim;
      }
    } else {
      //Calculate claim for all slots till last claimed timestamp by user.
      for (uint256 i = 0; i < _distributionHistory.length; i++) {
        if (
          _distributionHistory[i].endTime >= userDetails.lastClaimedTimestamp &&
          _distributionHistory[i].totalCredits > 0
        ) {
          credits = 0;
          claim = 0;
          /// Calculate credits obtained by the user in the current distribution history slot.
          if (_distributionHistory[i].startTime <= userDetails.lastClaimedTimestamp) {
            credits = userDetails.forecastedCredits;
          } else {
            credits =
              userDetails.balance *
              (_distributionHistory[i].endTime - _distributionHistory[i].startTime);
          }
          /// Calculate user's claim for the current distribution history slot.
          claim =
            (credits * _distributionHistory[i].monthlyProfit) /
            _distributionHistory[i].totalCredits;
          totalClaim += claim;

          /// Reduce remaining tokens in the distribution history for the corresponding claim.
          _distributionHistory[i].remainingTokensToClaim -= claim;
        }
      }
    }

    /// Ensure that the total claim amount is greater than zero.
    require(totalClaim > 0, 'LINGO: Zero rewards');

    /// Update user and global forecasted credits based on the current slot end time.
    _totalCredits -= _totalCredits > 0 ? userDetails.forecastedCredits : 0;
    userDetails.forecastedCredits = userDetails.balance * (_currentSlotEnd - _currentSlotStart);
    _totalCredits += userDetails.forecastedCredits;

    /// Update last claimed timestamp for the user.
    userDetails.lastClaimedTimestamp = block.timestamp / 3600;

    /// Transfer tokens to the user account.
    bool txnStatus = _transferTokens(sender, totalClaim);
    require(txnStatus, 'LINGO: Token transfer failed');

    /// Emit claim event with the claimed amount.
    emit Claim(sender, totalClaim);
  }

  /**
   * @dev Claims tokens that were not claimed by users during their distribution period for the owner.
   * @notice The caller must be the contract owner, Only tokens from distribution periods that ended at least `_adminClaimPeriod` hours ago will be claimed,
   * There must be available tokens to claim.
   *
   */
  function adminClaim() external onlyOwner nonReentrant {
    uint256 totalClaim = 0;

    /// Calculates the total amount of tokens that can be claimed by the owner.
    for (uint256 i = 0; i < _distributionHistory.length; i++) {
      if (((block.timestamp / 3600) - _distributionHistory[i].endTime) >= _adminClaimPeriod) {
        totalClaim += _distributionHistory[i].remainingTokensToClaim;
        _distributionHistory[i].remainingTokensToClaim = 0;
      }
    }

    /// Makes sure there are tokens available to claim.
    require(totalClaim > 0, 'LINGO: Zero tokens available to claim');

    /// Transfers the claimed tokens to the owner's address.
    bool txnStatus = _transferTokens(owner(), totalClaim);
    require(txnStatus, 'LINGO: Failed to transfer claimed tokens');

    /// Emits an event indicating that the owner has successfully claimed some tokens.
    emit AdminClaim(owner(), totalClaim);
  }

  /**
   * @dev Returns the address of the wallet that receives treasury funds.
   * @return The Ethereum address of the wallet receiving treasury funds from the contract.
   */
  function getTreasuryWalletAddress() external view returns (address) {
    return _treasuryWallet;
  }

  /**
   * @dev Returns an array of `DistributionHistory` structures containing information about the token distributions.
   * @return An array of `DistributionHistory` structures, each describing a specific token distribution instance.
   */
  function getDistributionHistory() external view returns (DistributionHistory[] memory) {
    return _distributionHistory;
  }

  /**
   * @dev Returns an array of user addresses that staked tokens on the contract.
   * @return An array of Ethereum addresses representing the users who staked tokens on the contract.
   */
  function getUserAddresses() external view returns (address[] memory) {
    return _userAddresses;
  }

  /**
   * @dev Returns the current slot length for token distribution calculations.
   * @return An unsigned integer representing the current slot length for token distribution calculations.
   */
  function getSlot() external view returns (uint256) {
    return _slot;
  }

  /**
   * @dev Returns the duration in hours after which unclaimed tokens can be claimed by the owner.
   * @return An unsigned integer representing the number of hours after which unclaimed tokens can be claimed.
   */
  function getAdminClaimPeriod() external view returns (uint256) {
    return _adminClaimPeriod;
  }

  /**
   * @dev Returns the percentage fee charged on withdrawals from the contract.
   * @return An unsigned integer representing the percentage fee charged on withdrawals from the contract.
   */
  function getWithdrawalFee() external view returns (uint256) {
    return _withdrawalFee;
  }

  /**
   * @dev Returns various pieces of state information about the contract.
   * @return startTime - The start time of the current slot.
   * @return endTime - The end time of the current slot.
   * @return totalAmount - The total amount of funds deposited in the contract.
   * @return totalCredits - The total number of credits allocated to users.
   */
  function getContractState()
    external
    view
    returns (uint256 startTime, uint256 endTime, uint256 totalAmount, uint256 totalCredits)
  {
    return (_currentSlotStart, _currentSlotEnd, _totalAmount, _totalCredits);
  }

  /**
   * @dev Returns the address of the token that the contract is distributing.
   * @return The Ethereum address of the token being distributed by this contract.
   */
  function getTokenAddress() external view returns (address) {
    return address(_token);
  }

  /**
   * @dev Returns status information about a specific user account.
   *
   * Requirements:
   * - `account` must be a valid Ethereum address.
   *
   * @param account The Ethereum address of the account to retrieve status information for.
   * @return A `User` struct with details about the specified user's activity on the contract.
   */
  function getUserStatus(address account) external view returns (User memory) {
    return _users[account];
  }

  /**
   * @dev Sets the withdrawal fee charged on withdrawals from the contract.
   *
   * Requirements:
   * - Only callable by the owner of the contract.
   * - `fee` must be less than or equal to 5%.
   *
   * @param fee An unsigned integer representing the percentage fee charged on withdrawals from the contract.
   */
  function setWithdrawalFee(uint256 fee) public onlyOwner {
    require(fee <= 500, 'LINGO: Withdrawal Fee should be between 0% - 5%');
    _withdrawalFee = fee;
    /// Emitted when `fee` is updated using this function.
    emit WithdrawalFeeUpdated(fee);
  }

  /**
   * @dev Transfers tokens to a specified account address.
   *
   * Requirements:
   * - `_token` must be a valid ERC20 token contract.
   * - `to` must be a valid Ethereum address.
   * - `amount` must be greater than zero and less than or equal to the current balance of the contract.
   *
   * @param to The Ethereum address of the account that will receive tokens from the contract.
   * @param amount An unsigned integer representing the amount of tokens to transfer to `to`.
   * @return A boolean indicating whether or not the token transfer was successful.
   */
  function _transferTokens(address to, uint256 amount) internal returns (bool) {
    bool txnStatus = _token.transfer(to, amount);
    return txnStatus;
  }
}