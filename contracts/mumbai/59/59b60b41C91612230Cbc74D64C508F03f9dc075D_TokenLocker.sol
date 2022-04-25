pragma solidity 0.8.11;

import "./dependencies/Ownable.sol";
import "./dependencies/SafeERC20.sol";
import "./interfaces/IERC20.sol";


contract TokenLocker is Ownable {
    using SafeERC20 for IERC20;

    struct StreamData {
        uint256 start;
        uint256 amount;
        uint256 claimed;
    }

    // `weeklyTotalWeight` and `weeklyWeightOf` track the total lock weight for each week,
    // calculated as the sum of [number of tokens] * [weeks to unlock] for all active locks.
    // The array index corresponds to the number of the epoch week.
    uint256[9362] public weeklyTotalWeight;
    mapping(address => uint256[9362]) public weeklyWeightOf;

    // `weeklyUnlocksOf` tracks the actual deposited token balances. Any non-zero value
    // stored at an index < `getWeek` is considered unlocked and may be withdrawn
    mapping(address => uint256[9362]) public weeklyUnlocksOf;

    // `withdrawnUntil` tracks the most recent week for which each user has withdrawn their
    // expired token locks. Values in `weeklyUnlocksOf` with an index less than the related
    // value within `withdrawnUntil` have already been withdrawn.
    mapping(address => uint256) withdrawnUntil;

    // After a lock expires, a user calls to `initiateExitStream` and the withdrawable tokens
    // are streamed out linearly over the following week. This array is used to track data
    // related to the exit stream.
    mapping(address => StreamData) public exitStream;

    IERC20 public SEX;
    uint256 public immutable startTime;

    uint256 constant WEEK = 86400 * 7;

    uint256 public immutable MAX_LOCK_WEEKS;

    event NewLock(address indexed user, uint256 amount, uint256 lockWeeks);
    event ExtendLock(
        address indexed user,
        uint256 amount,
        uint256 oldWeeks,
        uint256 newWeeks
    );
    event NewExitStream(
        address indexed user,
        uint256 startTime,
        uint256 amount
    );
    event ExitStreamWithdrawal(
        address indexed user,
        uint256 claimed,
        uint256 remaining
    );

    constructor(
        uint256 _maxLockWeeks
    ) {
        MAX_LOCK_WEEKS = _maxLockWeeks;
        startTime = block.timestamp / WEEK * WEEK;
    }

    function setAddresses(IERC20 _sex) external onlyOwner {
        SEX = _sex;

        renounceOwnership();
    }

    function getWeek() public view returns (uint256) {
        return (block.timestamp - startTime) / WEEK;
    }

    /**
        @notice Get the current lock weight for a user
     */
    function userWeight(address _user) external view returns (uint256) {
        return weeklyWeightOf[_user][getWeek()];
    }

    /**
        @notice Get the total balance held in this contract for a user,
                including both active and expired locks
     */
    function userBalance(address _user)
        external
        view
        returns (uint256 balance)
    {
        uint256 i = withdrawnUntil[_user] + 1;
        uint256 finish = getWeek() + MAX_LOCK_WEEKS + 1;
        while (i < finish) {
            balance += weeklyUnlocksOf[_user][i];
            i++;
        }
        return balance;
    }

    /**
        @notice Get the current total lock weight
     */
    function totalWeight() external view returns (uint256) {
        return weeklyTotalWeight[getWeek()];
    }

    /**
        @notice Get the user lock weight and total lock weight for the given week
     */
    function weeklyWeight(address _user, uint256 _week) external view returns (uint256, uint256) {
        return (weeklyWeightOf[_user][_week], weeklyTotalWeight[_week]);
    }

    /**
        @notice Get data on a user's active token locks
        @param _user Address to query data for
        @return lockData dynamic array of [weeks until expiration, balance of lock]
     */
    function getActiveUserLocks(address _user)
        external
        view
        returns (uint256[2][] memory lockData)
    {
        uint256 length = 0;
        uint256 week = getWeek();
        for (uint256 i = week + 1; i < week + MAX_LOCK_WEEKS + 1; i++) {
            if (weeklyUnlocksOf[_user][i] > 0) length++;
        }
        lockData = new uint256[2][](length);
        uint256 x = 0;
        for (uint256 i = week + 1; i < week + MAX_LOCK_WEEKS + 1; i++) {
            if (weeklyUnlocksOf[_user][i] > 0) {
                lockData[x] = [i - week, weeklyUnlocksOf[_user][i]];
                x++;
            }
        }
        return lockData;
    }

    /**
        @notice Deposit tokens into the contract to create a new lock.
        @dev A lock is created for a given number of weeks. Minimum 1, maximum `MAX_LOCK_WEEKS`.
             A user can have more than one lock active at a time. A user's total "lock weight"
             is calculated as the sum of [number of tokens] * [weeks until unlock] for all
             active locks. Fees are distributed porportionally according to a user's lock
             weight as a percentage of the total lock weight. At the start of each new week,
             each lock's weeks until unlock is reduced by 1. Locks that reach 0 week no longer
             receive any weight, and tokens may be withdrawn by calling `initiateExitStream`.
        @param _user Address to create a new lock for (does not have to be the caller)
        @param _amount Amount of SEX to lock. This balance transfered from the caller.
        @param _weeks The number of weeks for the lock.
     */
    function lock(
        address _user,
        uint256 _amount,
        uint256 _weeks
    ) external returns (bool) {
        require(_weeks > 0, "Min 1 week");
        require(_weeks <= MAX_LOCK_WEEKS, "Exceeds MAX_LOCK_WEEKS");
        require(_amount > 0, "Amount must be nonzero");

        SEX.safeTransferFrom(msg.sender, address(this), _amount);

        uint256 start = getWeek();
        _increaseAmount(weeklyTotalWeight, start, _amount, _weeks, 0);
        _increaseAmount(weeklyWeightOf[_user], start, _amount, _weeks, 0);

        uint256 end = start + _weeks;
        weeklyUnlocksOf[_user][end] = weeklyUnlocksOf[_user][end] + _amount;

        emit NewLock(_user, _amount, _weeks);
        return true;
    }

    /**
        @notice Extend the length of an existing lock.
        @param _amount Amount of SEX to extend the lock for. When the value given equals
                       the total size of the existing lock, the entire lock is moved.
                       If the amount is less, then the lock is effectively split into
                       two locks, with a portion of the balance extended to the new length
                       and the remaining balance at the old length.
        @param _weeks The number of weeks for the lock that is being extended.
        @param _newWeeks The number of weeks to extend the lock until.
     */
    function extendLock(
        uint256 _amount,
        uint256 _weeks,
        uint256 _newWeeks
    ) external returns (bool) {
        require(_weeks > 0, "Min 1 week");
        require(_newWeeks <= MAX_LOCK_WEEKS, "Exceeds MAX_LOCK_WEEKS");
        require(_weeks < _newWeeks, "newWeeks must be greater than weeks");
        require(_amount > 0, "Amount must be nonzero");

        uint256[9362] storage unlocks = weeklyUnlocksOf[msg.sender];
        uint256 start = getWeek();
        uint256 end = start + _weeks;
        unlocks[end] = unlocks[end] - _amount;
        end = start + _newWeeks;
        unlocks[end] = unlocks[end] + _amount;

        _increaseAmount(weeklyTotalWeight, start, _amount, _newWeeks, _weeks);
        _increaseAmount(
            weeklyWeightOf[msg.sender],
            start,
            _amount,
            _newWeeks,
            _weeks
        );

        emit ExtendLock(msg.sender, _amount, _weeks, _newWeeks);
        return true;
    }

    /**
        @notice Create an exit stream, to withdraw tokens in expired locks over 1 week
     */
    function initiateExitStream() external returns (bool) {
        StreamData storage stream = exitStream[msg.sender];
        uint256 streamable = streamableBalance(msg.sender);
        require(streamable > 0, "No withdrawable balance");

        uint256 amount = stream.amount - stream.claimed + streamable;
        exitStream[msg.sender] = StreamData({
            start: block.timestamp,
            amount: amount,
            claimed: 0
        });
        withdrawnUntil[msg.sender] = getWeek();

        emit NewExitStream(msg.sender, block.timestamp, amount);
        return true;
    }

    /**
        @notice Withdraw tokens from an active or completed exit stream
     */
    function withdrawExitStream() external returns (bool) {
        StreamData storage stream = exitStream[msg.sender];
        uint256 amount;
        if (stream.start > 0) {
            amount = claimableExitStreamBalance(msg.sender);
            if (stream.start + WEEK < block.timestamp) {
                delete exitStream[msg.sender];
            } else {
                stream.claimed = stream.claimed + amount;
            }
            SEX.safeTransfer(msg.sender, amount);
        }
        emit ExitStreamWithdrawal(
            msg.sender,
            amount,
            stream.amount - stream.claimed
        );
        return true;
    }

    /**
        @notice Get the amount of SEX in expired locks that is
                eligible to be released via an exit stream.
     */
    function streamableBalance(address _user) public view returns (uint256) {
        uint256 finishedWeek = getWeek();

        uint256[9362] storage unlocks = weeklyUnlocksOf[_user];
        uint256 amount;

        for (
            uint256 last = withdrawnUntil[_user] + 1;
            last <= finishedWeek;
            last++
        ) {
            amount = amount + unlocks[last];
        }
        return amount;
    }

    /**
        @notice Get the amount of SEX available to withdraw
                from the active exit stream.
     */
    function claimableExitStreamBalance(address _user)
        public
        view
        returns (uint256)
    {
        StreamData storage stream = exitStream[_user];
        if (stream.start == 0) return 0;
        if (stream.start + WEEK < block.timestamp) {
            return stream.amount - stream.claimed;
        } else {
            uint256 claimable = stream.amount * (block.timestamp - stream.start) / WEEK;
            return claimable - stream.claimed;
        }
    }

    /**
        @dev Increase the amount within a lock weight array over a given time period
     */
    function _increaseAmount(
        uint256[9362] storage _record,
        uint256 _start,
        uint256 _amount,
        uint256 _rounds,
        uint256 _oldRounds
    ) internal {
        uint256 oldEnd = _start + _oldRounds;
        uint256 end = _start + _rounds;
        for (uint256 i = _start; i < end; i++) {
            uint256 amount = _amount * (end - i);
            if (i < oldEnd) {
                amount -= _amount * (oldEnd - i);
            }
            _record[i] += amount;
        }
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
abstract contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(msg.sender);
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
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
        address oldOwner = owner;
        owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../interfaces/IERC20.sol";
import "./Address.sol";

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

// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

/**
 * Based on the OpenZeppelin IER20 interface:
 * https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol
 *
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

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