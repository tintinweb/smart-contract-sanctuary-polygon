/**
 *Submitted for verification at polygonscan.com on 2023-07-07
*/

// SPDX-License-Identifier: MIT
// File: BKG/contracts/utils/Address.sol

// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly
                /// @solidity memory-safe-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}
// File: BKG/contracts/token/ERC20/extensions/draft-IERC20Permit.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}
// File: BKG/contracts/token/ERC20/IERC20.sol


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
// File: BKG/contracts/token/ERC20/utils/SafeERC20.sol


// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;




/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}
// File: BKG/contracts/utils/Context.sol


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
// File: BKG/contracts/access/Ownable.sol


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
// File: BKG/BarbarianKingGame.sol

pragma solidity ^0.8.0;




contract BarbarianKingGame is Ownable {
    using SafeERC20 for IERC20;

    enum Status {
        OPENED,
        COOLING
    }

    uint16 private constant UNIT = 10000;

    address public immutable barToken;
    /// @notice Last bidded account
    address public lastBidder;
    /// @notice Injector account who can inject tokens to the game
    address private _injector;

    /// @notice Winner reward portion, default 60%
    uint16 private _winPortion = 6000;
    /// @notice Next round transmission portion, default 40%
    uint16 private _nextRoundPortion = 4000;

    /// @notice Current round will be finished when there is no bid after `endDelay` from the last bid, default 1 mins
    uint64 private _endDelay = 1 minutes;
    /// @notice New round will be started after `coolDownTime` after the round finished
    uint64 private _coolDownTime = 24 hours; // default 24 Hours
    /// @notice Last bid time
    uint64 public lastBidTime;
    /// @notice Whether the winner of the latest round is decided or not
    bool public isWinnerDecided;

    /// @notice Bid price
    uint256 private _bidPrice = 10 ether;
    uint256 public potAmount = 0;

    /// @notice Rewards accumlated per winner, but not claimed yet. It would be cleared when the winner claims
    mapping(address => uint256) public accRewards;

    event BidPriceUpdated(uint256 bidPrice);
    event FundsInjected(address injector, uint256 amount);
    event InjectorUpdated(address injector);
    event NewBid(address account, uint64 timestamp, uint256 amount);
    event WinnerDecided(
        address winner,
        uint256 winAmount,
        uint256 nextRoundAmount
    );
    event RewardClaimed(address account, uint256 amount);
    event PortionsUpdated(uint16 winPortion, uint16 nextRoundPortion);
    event TimeConfigurationsUpdated(uint64 endDelay, uint64 coolDownTime);

    error BidDisabledInCoolDownTime();
    error InvalidAmount();
    error InvalidPortions();
    error InvalidPrice();
    error NoReward();
    error UnableToRecoverUserFunds();
    error Unpermitted();

    constructor(address barToken_) {
        barToken = barToken_;
    }

    /// @notice Bid in the game round
    /// @dev Users can not bid in the cool down time
    function bid() external {
        uint64 blockTime = uint64(block.timestamp);
        uint64 lastBidTime_ = lastBidTime;
        uint64 roundEndTime_ = lastBidTime_ + _endDelay;
        if (
            blockTime > roundEndTime_ &&
            blockTime < roundEndTime_ + _coolDownTime
        ) revert BidDisabledInCoolDownTime();
        _decideWinner(lastBidTime_, roundEndTime_);

        uint256 bidAmount = _bidPrice;
        IERC20 barToken_ = IERC20(barToken);
        uint256 balanceBefore = barToken_.balanceOf(address(this));
        barToken_.safeTransferFrom(_msgSender(), address(this), bidAmount);
        bidAmount = barToken_.balanceOf(address(this)) - balanceBefore;

        potAmount += bidAmount;
        lastBidTime = blockTime;
        lastBidder = _msgSender();
        isWinnerDecided = false;

        emit NewBid(_msgSender(), blockTime, bidAmount);
    }

    /// @notice Claim reward from the game rounds
    function claimReward() external {
        uint64 lastBidTime_ = lastBidTime;
        _decideWinner(lastBidTime_, lastBidTime_ + _endDelay);

        uint256 rewardAmount = accRewards[_msgSender()];
        if (rewardAmount == 0) revert NoReward();

        IERC20(barToken).safeTransfer(_msgSender(), rewardAmount);

        accRewards[_msgSender()] = 0;

        emit RewardClaimed(_msgSender(), rewardAmount);
    }

    /// @notice Update game at the moment of calling
    /// @dev This function determines winner in case of the current round is finished
    function _decideWinner(uint64 lastBidTime_, uint64 roundEndTime_) internal {
        // If the round is still opened, just return
        if (block.timestamp <= roundEndTime_) return;
        // If the winner was already decided, just return
        if (isWinnerDecided) return;
        // If no one bets in the current round, just return
        if (lastBidTime_ == 0) return;

        uint256 potAmount_ = potAmount;
        // If the current round is finished, determines the winner and amount portions
        // Last bidder is the winner of the current round
        uint256 winAmount = (potAmount_ * _winPortion) / UNIT;
        uint256 nextRoundAmount = potAmount_ - winAmount;
        accRewards[lastBidder] += winAmount;
        potAmount = nextRoundAmount;
        isWinnerDecided = true;
        emit WinnerDecided(lastBidder, winAmount, nextRoundAmount);
    }

    /// @notice Get current game status
    /// @return - Opened or Cooling status
    function gameStatus() public view returns (Status) {
        uint256 blockTime = block.timestamp;
        uint64 lastBidTime_ = lastBidTime;
        uint64 endDelay_ = _endDelay;
        if (
            blockTime - lastBidTime_ <= endDelay_ ||
            blockTime - lastBidTime_ >= endDelay_ + _coolDownTime
        ) return Status.OPENED;
        return Status.COOLING;
    }

    /// @notice Get current round end time based on the last bid time
    function roundEndTime() external view returns (uint64) {
        return lastBidTime + _endDelay;
    }

    /// @notice Get next round time based on the last bid time
    function nextRoundTime() external view returns (uint64) {
        return lastBidTime + _endDelay + _coolDownTime;
    }

    /// @notice Get reward amount of the given `account`
    /// @return - Rewards accumlated so far including the current round
    function getReward(address account_) external view returns (uint256) {
        uint256 accReward = accRewards[account_];
        uint64 blockTime = uint64(block.timestamp);
        uint64 lastBidTime_ = lastBidTime;
        uint64 roundEndTime_ = lastBidTime_ + _endDelay;
        // If its cooldown time now, and the winner is not yet decided but the account is candidator
        if (
            blockTime > roundEndTime_ &&
            blockTime < roundEndTime_ + _coolDownTime &&
            lastBidder == account_ &&
            !isWinnerDecided
        ) {
            uint256 winAmount = (potAmount * _winPortion) / UNIT;
            accReward += winAmount;
        }

        return accReward;
    }

    /// @notice Update portion for the winner and the next round
    /// @dev Only owner is allowed to call this function
    function updatePortions(
        uint16 winPortion_,
        uint16 nextRoundPortion_
    ) external onlyOwner {
        if (winPortion_ + nextRoundPortion_ != UNIT) revert InvalidPortions();
        _winPortion = winPortion_;
        _nextRoundPortion = nextRoundPortion_;

        emit PortionsUpdated(winPortion_, nextRoundPortion_);
    }

    function winPortion() external view returns (uint16) {
        return _winPortion;
    }

    function nextRoundPortion() external view returns (uint16) {
        return _nextRoundPortion;
    }

    /// @notice Update time configuration - end delay and cool down time
    /// @dev Only owner is allowed to call this function
    function updateTimeConfiguration(
        uint64 endDelay_,
        uint64 coolDownTime_
    ) external onlyOwner {
        _endDelay = endDelay_;
        _coolDownTime = coolDownTime_;

        emit TimeConfigurationsUpdated(endDelay_, coolDownTime_);
    }

    function endDelay() external view returns (uint64) {
        return _endDelay;
    }

    function coolDownTime() external view returns (uint64) {
        return _coolDownTime;
    }

    /// @notice Update bid price in CANDY token
    /// @dev Only owner is allowed to call this function
    function updateBidPrice(uint256 price_) external onlyOwner {
        if (price_ == 0) revert InvalidPrice();
        _bidPrice = price_;

        emit BidPriceUpdated(price_);
    }

    /// @notice View bid price
    function bidPrice() external view returns (uint256) {
        return _bidPrice;
    }

    /// @notice Update injector account
    /// @dev Only owner is allowed to call this function
    function updateInjector(address injector_) external onlyOwner {
        _injector = injector_;

        emit InjectorUpdated(injector_);
    }

    function injector() external view returns (address) {
        return _injector;
    }

    /// @notice Inject funds into the game
    /// @dev Only injector is allowed to call this function
    function injectFunds(uint256 amount_) external {
        if (_msgSender() != _injector) revert Unpermitted();
        if (amount_ == 0) revert InvalidAmount();

        IERC20 barToken_ = IERC20(barToken);
        uint256 balanceBefore = barToken_.balanceOf(address(this));
        barToken_.safeTransferFrom(_msgSender(), address(this), amount_);
        amount_ = barToken_.balanceOf(address(this)) - balanceBefore;

        potAmount += amount_;

        emit FundsInjected(_msgSender(), amount_);
    }

    /// @notice Recover tokens in the contract
    /// @dev It should not withdraw tokens which users made bids
    function recoverTokens(
        address token_,
        address to_,
        uint amount_
    ) public onlyOwner {
        if (token_ == barToken) {
            uint256 balanceInContract = IERC20(token_).balanceOf(address(this));
            if (balanceInContract < amount_ + potAmount)
                revert UnableToRecoverUserFunds();
        }
        IERC20(token_).safeTransfer(to_, amount_);
    }
}