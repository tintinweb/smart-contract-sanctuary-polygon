/**
 *Submitted for verification at polygonscan.com on 2022-09-15
*/

// Sources flattened with hardhat v2.11.0 https://hardhat.org

// File contracts/main/interfaces/IPolyInfFarm.sol

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

/**
 * @dev IPolyInfFarm functions that do not require less than the min timelock
 */
interface IPolyInfFarm {
    function add(
        uint256 _allocPoint,
        address _lpToken,
        uint16 _depositFee,
        bool _withUpdate
    ) external;

    function set(
        uint256 _pid,
        uint256 _allocPoint,
        bool _withUpdate
    ) external;
    /**
     * @notice deposit LP tokens for PIT allocation.
     * @param _pid poolId 
     * @param _amount amount of LP token to deposit
     */
    function deposit(uint256 _pid, uint256 _amount) external;

    /**
     * @notice withdraw LP tokens
     * @param _pid poolId 
     * @param _amount amount of LP token to deposit
     */
    function withdraw(uint256 _pid, uint256 _amount) external;

    /**
     * @notice withdraw without caring about rewards. EMERGENCY ONLY.
     * @param _pid poolId 
     */
    function emergencyWithdraw(uint256 _pid) external;

    /**
     * @notice view function to check user pending pit
     * @param _pid poolId 
     * @param _user address of user 
     */
    function pendingPIT(uint256 _pid, address _user)
        external
        view
        returns (uint256);

    /**
     * @notice view function to check user's deposited LP and rewardDebt
     * @param _pid poolId 
     * @param _user address of user 
     */
    function userInfo(uint256 _pid, address _user)
        external
        view
        returns (uint256 amount, uint256 rewardDebt);

    /**
     * @notice view function to check pool info 
     * @param _pid poolId 
     */
    function poolInfo(uint256 _pid)
        external
        view
        returns (
            address lpToken,
            uint256 allocPoint,
            uint256 lastRewardBlock,
            uint256 accPITPerShare,
            uint16 depositFeeBP
        );

    /**
     * @notice view function to check pit token address registered in craftsman
     */
    function pit() external view returns (address);
}


// File @openzeppelin/contracts/utils/[email protected]



pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


// File contracts/main/libraries/Pausable.sol

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor () internal {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}


// File contracts/main/interfaces/IRewarder.sol

pragma solidity 0.6.12;

interface IRewarder {
    function onPITReward(
        uint256 _pid,
        address _user,
        uint256 _amount
    ) external;

    function pendingToken(uint256 pid, address user) external view returns (address rewardToken, uint256 amount);
}


// File @openzeppelin/contracts/token/ERC20/[email protected]



pragma solidity >=0.6.0 <0.8.0;

/**
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


// File @openzeppelin/contracts/math/[email protected]



pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}


// File @openzeppelin/contracts/utils/[email protected]



pragma solidity >=0.6.2 <0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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


// File @openzeppelin/contracts/token/ERC20/[email protected]



pragma solidity >=0.6.0 <0.8.0;



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
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
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
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}


// File @openzeppelin/contracts/access/[email protected]



pragma solidity >=0.6.0 <0.8.0;

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
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


// File contracts/main/PolyInfFarmV2.sol



pragma solidity 0.6.12;






/// PolyInfFarmV2 is the new master of PIT.
///
/// Note that it is similar to PolyInf with the ability to attach rewarders (optional)
/// to each pid. User will have to withdraw from PolyInf and redeposit in PolyInfFarmV2
/// if rewarder is attached to an existing pid such as MATIC-BTC
///
/// Have fun reading it. Hopefully it's bug-free. God bless.
contract PolyInfFarmV2 is Ownable, Pausable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    /// Info of each user.
    struct UserInfo {
        uint256 amount; // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt - See explaination from PolyInf
    }

    /// Info of each pool.
    struct PoolInfo {
        IERC20 lpToken; // Address of LP token contract.
        IRewarder[] rewarders; // list of rewarder for the pool
        uint256 accPITPerShare; // Accumulated PITs per share, times 1e12.
    }

    /// Mapping of pid to poolInfo
    mapping(uint256 => PoolInfo) public poolInfo;

    /// Info of each pool.
    uint256[] public poolIds;

    /// Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;

    IPolyInfFarm public immutable pitFarm;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event SetPid(uint256 indexed pid, address lpToken, IRewarder[] rewarders, bool withUpdate);
    event AddRewarder(uint256 indexed pid, IRewarder rewarder);
    event RemoveRewarder(uint256 indexed pid, IRewarder rewarder);
    event Panic(uint256 pid);

    constructor(IPolyInfFarm _pitFarm) public {
        pitFarm = _pitFarm;
    }

    function deposit(uint256 _pid, uint256 _amount) external whenNotPaused {
        require(_pid != 0, "deposit PIT by PolyInf");

        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        updatePool(_pid);

        uint256 pending = user.amount.mul(pool.accPITPerShare).div(1e12).sub(user.rewardDebt);
        if (pending > 0) {
            safePITTransfer(msg.sender, pending);
        }

        // Get rewarder rewards
        uint256 newAmt = user.amount.add(_amount);
        IRewarder[] memory _rewarders = pool.rewarders;
        for (uint256 i = 0; i < _rewarders.length; i++) {
            _rewarders[i].onPITReward(_pid, msg.sender, newAmt);
        }

        if (_amount > 0) {
            uint256 beforeDeposit = pool.lpToken.balanceOf(address(this));
            pool.lpToken.safeTransferFrom(msg.sender, address(this), _amount);
            uint256 afterDeposit = pool.lpToken.balanceOf(address(this));
            _amount = afterDeposit.sub(beforeDeposit); // real amount of LP transfer to this address
            // pool.lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);

            pool.lpToken.approve(address(pitFarm), _amount);
            pitFarm.deposit(_pid, _amount);
        }

        // Check deposit fee in pool of polyFarm
        (, , , , uint16 depositFeeBP) = pitFarm.poolInfo(_pid);
        if (depositFeeBP > 0) {
            uint256 depositFee = _amount.mul(depositFeeBP).div(1e4);
            user.amount = user.amount.add(_amount).sub(depositFee);
        }
        else {
            user.amount = user.amount.add(_amount);
        }

        user.rewardDebt = user.amount.mul(pool.accPITPerShare).div(1e12);
        emit Deposit(msg.sender, _pid, _amount);
    }

    function withdraw(uint256 _pid, uint256 _amount) external {
        require(_pid != 0, "withdraw PIT by PolyInf");

        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "withdraw amount greater than balanace");

        updatePool(_pid);

        uint256 pending = user.amount.mul(pool.accPITPerShare).div(1e12).sub(user.rewardDebt);
        if (pending > 0) {
            safePITTransfer(msg.sender, pending);
        }

        // Get rewarder rewards
        uint256 newAmt = user.amount.sub(_amount);
        IRewarder[] memory rewarders = pool.rewarders;
        for (uint256 i = 0; i < rewarders.length; i++) {
            rewarders[i].onPITReward(_pid, msg.sender, newAmt);
        }

        if (_amount > 0) {
            user.amount = user.amount.sub(_amount);
            pitFarm.withdraw(_pid, _amount);
            pool.lpToken.safeTransfer(address(msg.sender), _amount);
        }

        user.rewardDebt = user.amount.mul(pool.accPITPerShare).div(1e12);
        emit Withdraw(msg.sender, _pid, _amount);
    }

    /// @notice withdraw without caring about rewards. EMERGENCY ONLY.
    /// @dev if the issue comes from pitFarm token, call panic() before asking user to emergencyWithdraw()
    function emergencyWithdraw(uint256 _pid) external {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        uint256 amount = user.amount;
        user.amount = 0;
        user.rewardDebt = 0;

        /// Paused implies pitFarm is stuck. Owner should have called panic() for all pids
        // and all LP token should be in PolyInfFarmV2, thus skip pitFarm.withdraw(_pid, amount)
        if (!paused()) {
            // Not paused implies pitFarm is fine while rewarder is stuck. Withdraw from pitFarm
            // and split user's pending pit reward with the remaining stakers. However if user
            // was the only staker, pending pit will remain with this contract
            uint256 pending = pitFarm.pendingPIT(_pid, address(this));
            pitFarm.withdraw(_pid, amount);

            (uint256 lpSupply, ) = pitFarm.userInfo(_pid, address(this));
            if (pending > 0 && lpSupply > 0) {
                pool.accPITPerShare = pool.accPITPerShare.add(pending.mul(1e12).div(lpSupply));
            }
        }

        pool.lpToken.safeTransfer(address(msg.sender), amount);
        emit EmergencyWithdraw(msg.sender, _pid, amount);
    }

    /// @notice pauses deposit and withdraws all fund from pitFarm
    /// @dev only call this function if pitFarm reward is stuck
    function panic(uint256 _pid) external onlyOwner {
        if (!paused()) {
            _pause();
        }

        pitFarm.emergencyWithdraw(_pid);

        emit Panic(_pid);
    }

    /// @dev only unpause if the panic pid has no deposits prior. If the pids had deposits, it
    ///         would mean users cannot call withdraw() as the LP are already withdrawn to PolyInfFarmV2
    function unpause() external onlyOwner {
        _unpause();
    }

    /// @notice Update reward variables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        uint256 length = poolIds.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    /// @dev Update pool.accPITPerShare by claiming any pendingPIT
    function updatePool(uint256 _pid) public {
        (uint256 lpSupply, ) = pitFarm.userInfo(_pid, address(this));
        if (lpSupply == 0) {
            return;
        }

        uint256 pending = pitFarm.pendingPIT(_pid, address(this));
        pitFarm.deposit(_pid, 0); // deposit to triger pit reward

        PoolInfo storage pool = poolInfo[_pid];
        pool.accPITPerShare = pool.accPITPerShare.add(pending.mul(1e12).div(lpSupply));
    }

    /// @notice Add a new pid with rewarder
    /// @dev txn will fail if PolyinfFarm does not have pool set
    /// @param _pid pid to update
    /// @param _rewarders the list of rewarder to set
    /// @param _withUpdate True if massUpdatePools should be called prior to pool updates.
    function add(
        uint256 _pid,
        IRewarder[] memory _rewarders,
        bool _withUpdate
    ) external onlyOwner {
        require(address(poolInfo[_pid].lpToken) == address(0), "pool has been added");

        if (_withUpdate) {
            massUpdatePools();
        }

        (address lpToken, , , ,) = pitFarm.poolInfo(_pid);
        poolInfo[_pid].lpToken = IERC20(lpToken);
        poolInfo[_pid].rewarders = _rewarders;

        poolIds.push(_pid);

        emit SetPid(_pid, lpToken, _rewarders, _withUpdate);
    }

    /// @notice add a rewarder to the pid
    /// @param _pid pid to add rewarder
    /// @param _rewarder address of rewarder to add
    function addRewarder(uint256 _pid, IRewarder _rewarder) external onlyOwner {
        (bool found, ) = isRewarderInPool(_pid, _rewarder);
        require(found == false, "Rewarder exist");

        poolInfo[_pid].rewarders.push(_rewarder);
        emit AddRewarder(_pid, _rewarder);
    }

    /// @notice remove a rewarder from the pid, removing rewarder will save gas for user
    /// @dev removing rewarder removes any user unclaimed rewarder reward!
    /// @param _pid pid to remove rewarder
    /// @param _rewarder address of rewarder to remove
    function removeRewarder(uint256 _pid, IRewarder _rewarder) external onlyOwner {
        (bool found, uint256 foundIndex) = isRewarderInPool(_pid, _rewarder);
        require(found, "No rewarder found");

        PoolInfo storage pool = poolInfo[_pid];
        for (uint256 i = foundIndex; i < pool.rewarders.length - 1; i++) {
            pool.rewarders[i] = pool.rewarders[i + 1];
        }

        pool.rewarders.pop();

        emit RemoveRewarder(_pid, _rewarder);
    }

    /// @notice returns all pending token reward for the user
    /// @dev Checks pending token from PolyInf and iterate through each rewarder
    /// @return array of (token address, pending token amount)
    function pendingTokens(uint256 _pid, address _user) external view returns (address[] memory, uint256[] memory) {
        PoolInfo memory pool = poolInfo[_pid];

        // +1 in array to include PIT reward from pitFarm
        uint256 rewardLength = pool.rewarders.length;
        address[] memory rewardTokens = new address[](rewardLength + 1);
        uint256[] memory pendingAmounts = new uint256[](rewardLength + 1);

        // Check on PIT reward
        rewardTokens[0] = pitFarm.pit();
        pendingAmounts[0] = pendingPIT(_pid, _user);

        // Check from each rewarder
        IRewarder[] memory rewarders = pool.rewarders;
        for (uint256 i = 0; i < rewarders.length; i++) {
            (address token, uint256 amount) = rewarders[i].pendingToken(_pid, _user);

            rewardTokens[i + 1] = token;
            pendingAmounts[i + 1] = amount;
        }

        return (rewardTokens, pendingAmounts);
    }

    /// @notice check if rewarder is in pool
    /// @return bool if rewarder is found
    /// @return uint256 index of rewarder if found
    function isRewarderInPool(uint256 _pid, IRewarder _rewarder) public view returns (bool, uint256) {
        PoolInfo memory pool = poolInfo[_pid];
        for (uint256 i = 0; i < pool.rewarders.length; i++) {
            if (address(pool.rewarders[i]) == address(_rewarder)) {
                return (true, i);
            }
        }

        return (false, 0);
    }

    function pendingPIT(uint256 _pid, address _user) public view returns (uint256) {
        PoolInfo memory pool = poolInfo[_pid];
        UserInfo memory user = userInfo[_pid][_user];

        uint256 accPITPerShare = pool.accPITPerShare;
        (uint256 lpSupply, ) = pitFarm.userInfo(_pid, address(this));
        if (lpSupply != 0) {
            uint256 pending = pitFarm.pendingPIT(_pid, address(this));
            accPITPerShare = pool.accPITPerShare.add(pending.mul(1e12).div(lpSupply));
        }

        uint256 userPendingPIT = user.amount.mul(accPITPerShare).div(1e12).sub(user.rewardDebt);
        return userPendingPIT;
    }

    /// @param _pid pool to check
    /// @return rewarders for the pool
    function poolRewarders(uint256 _pid) public view returns (IRewarder[] memory) {
        return poolInfo[_pid].rewarders;
    }

    /// Safe pit transfer function, just in case if rounding error causes pool to not have enough PITs.
    function safePITTransfer(address _to, uint256 _amount) internal {
        IERC20 pit = IERC20(pitFarm.pit());
        pit.safeTransfer(_to, _amount);
    }
}