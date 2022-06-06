/**
 *Submitted for verification at polygonscan.com on 2022-06-05
*/

// File: xvmc-contracts/libs/poolLibraries.sol



pragma solidity 0.6.12;
//openZeppelin contracts(also used by Pancakeswap).
//modified IERC20 and SafeERC20(using transferXVMC instead of standard transferFrom)

// File: @openzeppelin/contracts/utils/Context.sol

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

    constructor () internal {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// File: @openzeppelin/contracts/math/SafeMath.sol


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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
    
	//transfers XVMC without allowance
    function transferXVMC(address _sender, address _recipient, uint256 _amount) external returns (bool);
	
	//returns owner address
	function owner() external view returns (address);

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



// File: @openzeppelin/contracts/utils/Address.sol

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
        assembly {
            size := extcodesize(account)
        }
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
        (bool success, ) = recipient.call{value: amount}("");
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

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value: value}(data);
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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
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
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
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

// File: @openzeppelin/contracts/token/ERC20/SafeERC20.sol

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
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferXVMC.selector, from, to, value));
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
        // solhint-disable-next-line max-line-length
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
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance =
            token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
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
        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// File: xvmc-contracts/pools/3year.sol



pragma solidity 0.6.12;


interface IMasterChef {
    function deposit(uint256 _pid, uint256 _amount) external;
    function withdraw(uint256 _pid, uint256 _amount) external;
    function pendingEgg(uint256 _pid, address _user) external view returns (uint256);
    function userInfo(uint256 _pid, address _user) external view returns (uint256, uint256);
    function emergencyWithdraw(uint256 _pid) external;
    function feeAddress() external view returns (address);
    function owner() external view returns (address);
}

interface IacPool {
    function hopDeposit(uint256 _amount, address _recipientAddress, uint256 previousLastDepositedTime, uint256 _mandatoryTime) external;
    function getUserShares(address wallet) external view returns (uint256);
    function getNrOfStakes(address _user) external view returns (uint256);
	function giftDeposit(uint256 _amount, address _toAddress, uint256 _minToServeInSecs) external;
}

interface IGovernance {
    function costToVote() external view returns (uint256);
    function rebalancePools() external;
    function getRollBonus(address _bonusForPool) external view returns (uint256);
    function stakeRolloverBonus(address _toAddress, address _depositToPool, uint256 _bonusToPay, uint256 _stakeID) external;
	function treasuryWallet() external view returns (address);
}

interface IVoting {
    function addCredit(uint256 amount, address _beneficiary) external;
}

/**
 * XVMC time-locked deposit
 * Auto-compounding pool
 * !!! Warning: !!! Licensed under Business Source License 1.1 (BSL 1.1)
 */
contract XVMCtimeDeposit is ReentrancyGuard {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    struct UserInfo {
        uint256 shares; // number of shares for a user
        uint256 lastDepositedTime; // keeps track of deposited time for potential penalty
        uint256 xvmcAtLastUserAction; // keeps track of XVMC deposited at the last user action
        uint256 lastUserActionTime; // keeps track of the last user action time
        uint256 mandatoryTimeToServe; // optional: disables early withdraw
    }
	//allows stakes to be transferred, similar to token transfers
	struct StakeTransfer {
		uint256 shares; // ALLOWANCE of shares
        uint256 lastDepositedTime;
        uint256 mandatoryTimeToServe; 
	}

    IERC20 public immutable token; // XVMC token
	
	IERC20 public immutable oldToken = IERC20(0x6d0c966c8A09e354Df9C48b446A474CE3343D912);
    
    IERC20 public immutable dummyToken; 

    IMasterChef public masterchef;  
    
    uint256 public immutable withdrawFeePeriod = 1095 days;
    uint256 public immutable gracePeriod = 14 days;

    mapping(address => UserInfo[]) public userInfo;
    mapping(address => uint256) public userVote; //the ID the user is voting for
    mapping(uint256 => uint256) public totalVotesForID; //total votes for a given ID
	mapping(address => address) public userDelegate; //user can delegate their voting to another wallet
	
	mapping(address => bool) public trustedSender; //Pools with shorter lockup duration(trustedSender(contracts) can transfer into this pool)
	mapping(address => bool) public trustedPool; //Pools with longer lockup duration(can transfer from this pool into trustedPool(contracts))
	
	mapping(address => mapping(address => StakeTransfer[])) private _stakeAllowances; 
	//similar to token allowances, difference being it's not for amount of tokens, but for a specific stake defined by shares, latdeposittime and mandatorytime

	uint256 public poolID; 
    uint256 public totalShares;
    address public admin; //admin = governing contract!
    address public treasury; //penalties go to this address
    address public migrationPool; //if pools are to change
	
	address public votingCreditAddress;
	
	uint256 public minimumGift = 1000000 * 1e18;
	bool public updateMinGiftGovernor = true; //allows automatic update by anybody to costToVote from governing contract
    
    uint256 public callFee = 5; // call fee paid for rebalancing pools
	
	bool public allowStakeTransfer = true; //enable/disable transferring of stakes to another wallet
	bool public allowStakeTransferFrom = false; //allow third party transfers(disabled initially)
	
	bool public partialWithdrawals = true; //partial withdrawals from stakes
	bool public partialTransfers = true; //allows transferring a portion of  a stake
	
	bool public allowOrigin = true; //(dis)allows tx.origin for voting
	//safe to use tx.origin IMO. Can be disabled and use msg.sender instead
	//it allows the voting and delegating in a single transaction for all pools through a proxy contract
	
	// Easier to verify (opposed to checking event logs)
	uint256 public trustedSenderCount;
	uint256 public trustedPoolCount;

    event Deposit(address indexed sender, uint256 amount, uint256 shares, uint256 lastDepositedTime);
    event GiftDeposit(address indexed sender, address indexed recipient, uint256 amount, uint256 shares, uint256 lastDepositedTime);
    event AddAndExtendStake(address indexed sender, address indexed recipient, uint256 amount, uint256 stakeID, uint256 shares, uint256 lastDepositedTime);
    event Withdraw(address indexed sender, uint256 amount, uint256 penalty, uint256 shares);
    
	event TransferStake(address indexed sender, address indexed recipient, uint256 shares, uint256 stakeID);
    event HopPool(address indexed sender, uint256 XVMCamount, uint256 shares, address indexed newPool);
    event MigrateStake(address indexed goodSamaritan, uint256 XVMCamount, uint256 shares, address indexed recipient);
   
    event HopDeposit(address indexed recipient, uint256 amount, uint256 shares, uint256 previousLastDepositedTime, uint256 mandatoryTime);
	
    event RemoveVotes(address indexed voter, uint256 proposalID, uint256 change);
    event AddVotes(address indexed voter, uint256 proposalID, uint256 change);
	
	event TrustedSender(address contractAddress, bool setting);
	event TrustedPool(address contractAddress, bool setting);
	
	event StakeApproval(address owner, address spender, uint256 allowanceID, uint256 shareAllowance, uint256 lastDeposit, uint256 mandatoryTime);
	event StakeAllowanceRevoke(address owner, address spender, uint256 allowanceID);
	event TransferStakeFrom(address _from, address _to, uint256 _stakeID, uint256 _allowanceID);
	
	event SetDelegate(address userDelegating, address delegatee);

    /**
     * @notice Constructor
     * @param _token: XVMC token contract
     * @param _dummyToken: Dummy token contract
     * @param _masterchef: MasterChef contract
     * @param _admin: address of the admin
     * @param _treasury: address of the treasury (collects fees)
     */
    constructor(
        IERC20 _token,
        IERC20 _dummyToken,
        IMasterChef _masterchef,
        address _admin,
        address _treasury,
        uint256 _poolID
    ) public {
        token = _token;
        dummyToken = _dummyToken;
        masterchef = _masterchef;
        admin = _admin;
        treasury = _treasury;
        poolID = _poolID;

        IERC20(_dummyToken).safeApprove(address(_masterchef), uint256(-1));
    }
    
    /**
     * @notice Checks if the msg.sender is the admin
     */
    modifier adminOnly() {
        require(msg.sender == admin, "admin: wut?");
        _;
    }
	
    /**
     * @notice Deposits funds into the XVMC time-locked vault
     * @param _amount: number of tokens to deposit (in XVMC)
     * 
     * Creates a NEW stake
     */
    function deposit(uint256 _amount) external nonReentrant {
    	require(_amount > 0, "Nothing to deposit");
	
        uint256 pool = balanceOf();
        token.safeTransferFrom(msg.sender, address(this), _amount);
        uint256 currentShares = 0;
        if (totalShares != 0) {
            currentShares = (_amount.mul(totalShares)).div(pool);
        } else {
            currentShares = _amount;
        }
        
        totalShares = totalShares.add(currentShares);
        
        userInfo[msg.sender].push(
                UserInfo(currentShares, block.timestamp, _amount, block.timestamp, 0)
            );
        
		uint256 votingFor = userVote[msg.sender];
        if(votingFor != 0) {
            _updateVotingAddDiff(msg.sender, votingFor, currentShares);
        }

        emit Deposit(msg.sender, _amount, currentShares, block.timestamp);
    }

    /**
     * Equivalent to Deposit
     * Instead of crediting the msg.sender, it credits custom recipient
     * A mechanism to gift a time-locked stake to another wallet
     * Users can withdraw at any time(but will pay a penalty)
     * Optionally stake can be irreversibly locked for a minimum period of time(minToServe)
     */
    function giftDeposit(uint256 _amount, address _toAddress, uint256 _minToServeInSecs) external nonReentrant {
        require(_amount >= minimumGift, "Below Minimum Gift");

        uint256 pool = balanceOf();
        token.safeTransferFrom(msg.sender, address(this), _amount);
        uint256 currentShares = 0;
        if (totalShares != 0) {
            currentShares = (_amount.mul(totalShares)).div(pool);
        } else {
            currentShares = _amount;
        }
        
        totalShares = totalShares.add(currentShares);
        
        userInfo[_toAddress].push(
                UserInfo(currentShares, block.timestamp, _amount, block.timestamp, _minToServeInSecs)
            );
			
        uint256 votingFor = userVote[_toAddress];
        if(votingFor != 0) {
            _updateVotingAddDiff(_toAddress, votingFor, currentShares);
        }

        emit GiftDeposit(msg.sender, _toAddress, _amount, currentShares, block.timestamp);
    }
    
    /**
     * @notice Deposits funds into the XVMC time-locked vault
     * @param _amount: number of tokens to deposit (in XVMC)
     * 
     * Deposits into existing stake, effectively extending the stake
     * It's used for rolling over stakes by the governor(admin) as well
     * Mandatory Lock Up period can only be Increased
	 * It can be Decreased if stake is being extended(after it matures)
     */
    function addAndExtendStake(address _recipientAddr, uint256 _amount, uint256 _stakeID, uint256 _lockUpTokensInSeconds) external nonReentrant {
        require(_amount > 0, "Nothing to deposit");
        require(userInfo[_recipientAddr].length > _stakeID, "wrong Stake ID");
        
        if(msg.sender != admin) { require(_recipientAddr == msg.sender, "can only extend your own stake"); }

        uint256 pool = balanceOf();
        token.safeTransferFrom(msg.sender, address(this), _amount);
        uint256 currentShares = 0;
        if (totalShares != 0) {
            currentShares = (_amount.mul(totalShares)).div(pool);
        } else {
            currentShares = _amount;
        }
        UserInfo storage user = userInfo[_recipientAddr][_stakeID];

        user.shares = user.shares.add(currentShares);
        totalShares = totalShares.add(currentShares);
        
        if(_lockUpTokensInSeconds > user.mandatoryTimeToServe || 
				block.timestamp > user.lastDepositedTime.add(withdrawFeePeriod)) { 
			user.mandatoryTimeToServe = _lockUpTokensInSeconds; 
		}
		
        user.xvmcAtLastUserAction = user.shares.mul(balanceOf()).div(totalShares);
        user.lastUserActionTime = block.timestamp;
		user.lastDepositedTime = block.timestamp;
        
		uint256 votingFor = userVote[_recipientAddr];
        if(votingFor != 0) {
            _updateVotingAddDiff(_recipientAddr, votingFor, currentShares);
        }

        emit AddAndExtendStake(msg.sender, _recipientAddr, _amount, _stakeID, currentShares, block.timestamp);
    }
 

    function withdrawAll(uint256 _stakeID) external {
        withdraw(userInfo[msg.sender][_stakeID].shares, _stakeID);
    }

	
    /**
     * Harvest pending rewards from masterchef
	 * Governor pays the rewards for harvesting and rebalancing
     */
    function harvest() external {
        IMasterChef(masterchef).withdraw(poolID, 0);
    }

    
    /**
     * @notice Sets admin address and treasury
     * If new governor is set, anyone can pay the gas to update the addresses
	 * Masterchef owns the token, the governor owns the Masterchef
	 * Treasury is feeAddress from masterchef(which collects fees from deposits into masterchef)
	 * Currently all penalties are going to fee address(currently governing contract)
	 * Alternatively, fee address can be set as a separate contract, which would re-distribute
	 * The tokens back into pool(so honest stakers would directly receive penalties from prematurely ended stakes)
	 * Alternatively could also split: a portion to honest stakers, a portion into governing contract. 
	 * With initial setting, all penalties are going towards governing contract
     */
    function setAdmin() external {
        admin = IMasterChef(masterchef).owner();
        treasury = IMasterChef(masterchef).feeAddress();
    }
	
	//updates minimum gift to costToVote from Governing contract
	function updateMinimumGift() external {
		require(updateMinGiftGovernor, "automatic update disabled");
		minimumGift = IGovernance(admin).costToVote();
	}

    /**
     * @notice Withdraws from funds from the XVMC time-locked vault
     * @param _shares: Number of shares to withdraw
     */
    function withdraw(uint256 _shares, uint256 _stakeID) public {
        require(_stakeID < userInfo[msg.sender].length, "invalid stake ID");
        UserInfo storage user = userInfo[msg.sender][_stakeID];
        require(_shares > 0, "Nothing to withdraw");
        require(_shares <= user.shares, "Withdraw amount exceeds balance");
        require(block.timestamp > user.lastDepositedTime.add(user.mandatoryTimeToServe), "must serve mandatory time");
        if(!partialWithdrawals) { require(_shares == user.shares, "must transfer full stake"); }

        uint256 currentAmount = (balanceOf().mul(_shares)).div(totalShares);
        user.shares = user.shares.sub(_shares);
        totalShares = totalShares.sub(_shares);

        uint256 currentWithdrawFee = 0;
        
        if (block.timestamp < user.lastDepositedTime.add(withdrawFeePeriod)) {
            uint256 withdrawFee = uint256(6900).sub(((block.timestamp - user.lastDepositedTime).div(86400)).mul(629).div(100));
            currentWithdrawFee = currentAmount.mul(withdrawFee).div(10000);
            token.safeTransfer(treasury, currentWithdrawFee); 
            currentAmount = currentAmount.sub(currentWithdrawFee);
        } else if(block.timestamp > user.lastDepositedTime.add(withdrawFeePeriod).add(gracePeriod)) {
            uint256 withdrawFee = block.timestamp.sub(user.lastDepositedTime.add(withdrawFeePeriod)).div(86400).mul(629).div(100);
            if(withdrawFee > 6900) { withdrawFee = 6900; }
            currentWithdrawFee = currentAmount.mul(withdrawFee).div(10000);
            token.safeTransfer(treasury, currentWithdrawFee); 
            currentAmount = currentAmount.sub(currentWithdrawFee);
        }

        if (user.shares > 0) {
            user.xvmcAtLastUserAction = user.shares.mul(balanceOf().sub(currentAmount)).div(totalShares);
            user.lastUserActionTime = block.timestamp;
        } else {
            _removeStake(msg.sender, _stakeID); //delete the stake
        }
        
		uint256 votingFor = userVote[msg.sender];
        if(votingFor != 0) {
            _updateVotingSubDiff(msg.sender, votingFor, _shares);
        }

		emit Withdraw(msg.sender, currentAmount, currentWithdrawFee, _shares);
		
        token.safeTransfer(msg.sender, currentAmount);
    } 
    
    /**
     * Users can transfer their stake to another pool
     * Can only transfer to pool with longer lock-up period(trusted pools)
     * Equivalent to withdrawing, but it deposits the stake into another pool as hopDeposit
     * Users can transfer stake without penalty
     * Time served gets transferred 
     * The pool is "registered" as a "trustedSender" to another pool
     */
    function hopStakeToAnotherPool(uint256 _shares, uint256 _stakeID, address _poolAddress) public {
        require(_shares > 0, "Nothing to withdraw");
		require(_stakeID < userInfo[msg.sender].length, "wrong stake ID");
		
        UserInfo storage user = userInfo[msg.sender][_stakeID];
		require(_shares <= user.shares, "Withdraw amount exceeds balance");
        if(!partialWithdrawals) { require(_shares == user.shares, "must transfer full stake"); } 
        
		uint256 _lastDepositedTime = user.lastDepositedTime;
        if(trustedPool[_poolAddress]) { 
			if(block.timestamp > _lastDepositedTime.add(withdrawFeePeriod).add(gracePeriod)) {
				_lastDepositedTime = block.timestamp; //if after grace period, resets timer
			}
        } else { 
			//can only hop into trusted Pools or into trusted sender(lower pool) after time has been served within grace period
			//only meant for stakeRollover. After hop, stake is extended and timer reset
            require(trustedSender[_poolAddress] && block.timestamp > _lastDepositedTime.add(withdrawFeePeriod) &&
                                block.timestamp < _lastDepositedTime.add(withdrawFeePeriod).add(gracePeriod),
                                        "can only hop into pre-set Pools");
		}

        uint256 currentAmount = (balanceOf().mul(_shares)).div(totalShares);
        user.shares = user.shares.sub(_shares);
        totalShares = totalShares.sub(_shares);
		
		uint256 votingFor = userVote[msg.sender];
        if(votingFor != 0) {
            _updateVotingSubDiff(msg.sender, votingFor, _shares);
        }
		
		IacPool(_poolAddress).hopDeposit(currentAmount, msg.sender, _lastDepositedTime, user.mandatoryTimeToServe);
		//_poolAddress can only be trusted pool(contract)

        if (user.shares > 0) {
            user.xvmcAtLastUserAction = user.shares.mul(balanceOf()).div(totalShares);
            user.lastUserActionTime = block.timestamp;
        } else {
            _removeStake(msg.sender, _stakeID); //delete the stake
        }
        
        emit HopPool(msg.sender, currentAmount, _shares, _poolAddress);
    }

    
    /**
     * hopDeposit is equivalent to gift deposit, exception being that the time served can be passed
     * The msg.sender can only be a trusted contract
     * The checks are already made in the hopStakeToAnotherPool function
     * msg sender can only be trusted senders
     */
     
    function hopDeposit(uint256 _amount, address _recipientAddress, uint256 previousLastDepositedTime, uint256 _mandatoryTime) external {
        require(trustedSender[msg.sender] || trustedPool[msg.sender], "only trusted senders(other pools)");
		//only trustedSenders allowed. TrustedPools are under condition that the stake has matured(hopStake checks condition)
        
        uint256 pool = balanceOf();
        token.safeTransferFrom(msg.sender, address(this), _amount);
        uint256 currentShares = 0;
        if (totalShares != 0) {
            currentShares = (_amount.mul(totalShares)).div(pool);
        } else {
            currentShares = _amount;
        }
        
        totalShares = totalShares.add(currentShares);
        
        userInfo[_recipientAddress].push(
                UserInfo(currentShares, previousLastDepositedTime, _amount,
                    block.timestamp, _mandatoryTime)
            );

		uint256 votingFor = userVote[_recipientAddress];
        if(votingFor != 0) {
            _updateVotingAddDiff(_recipientAddress, votingFor, currentShares);
        }

        emit HopDeposit(_recipientAddress, _amount, currentShares, previousLastDepositedTime, _mandatoryTime);
    }
	
    /**
     * Users are encouraged to keep staking
     * Governor pays bonuses to re-commit and roll over your stake
     * Higher bonuses available for hopping into pools with longer lockup period
     */
    function stakeRollover(address _poolInto, uint256 _stakeID) external {
        require(userInfo[msg.sender].length > _stakeID, "invalid stake ID");
        
        UserInfo storage user = userInfo[msg.sender][_stakeID];
        
        require(block.timestamp > user.lastDepositedTime.add(withdrawFeePeriod), "stake not yet mature");
        
        uint256 currentAmount = (balanceOf().mul(user.shares)).div(totalShares); 
        uint256 toPay = currentAmount.mul(IGovernance(admin).getRollBonus(_poolInto)).div(10000);

        require(IERC20(token).balanceOf(admin) >= toPay, "governor reserves are currently insufficient");
        
        if(_poolInto == address(this)) {
            IGovernance(admin).stakeRolloverBonus(msg.sender, _poolInto, toPay, _stakeID); //gov sends tokens to extend the stake
        } else {
			hopStakeToAnotherPool(user.shares, _stakeID, _poolInto); //will revert if pool is wrong
			IGovernance(admin).stakeRolloverBonus(msg.sender, _poolInto, toPay, IacPool(_poolInto).getNrOfStakes(msg.sender) - 1); //extends latest stake
        }
    }
    
    /**
     * Transfer stake to another account(another wallet address)
     */
    function transferStakeToAnotherWallet(uint256 _shares, uint256 _stakeID, address _recipientAddress) external {
        require(allowStakeTransfer, "transfers disabled");
		require(_recipientAddress != msg.sender, "can't transfer to self");
        require(_stakeID < userInfo[msg.sender].length, "wrong stake ID");
        UserInfo storage user = userInfo[msg.sender][_stakeID];
		uint256 _tokensTransferred = _shares.mul(balanceOf()).div(totalShares);
        require(_tokensTransferred >= minimumGift, "Below minimum threshold");
        require(_shares <= user.shares, "Withdraw amount exceeds balance");
        if(!partialTransfers) { require(_shares == user.shares, "must transfer full stake"); }
        
        user.shares = user.shares.sub(_shares);

		uint256 votingFor = userVote[msg.sender];
        if(votingFor != 0) {
            _updateVotingSubDiff(msg.sender, votingFor, _shares);
        }
		votingFor = userVote[_recipientAddress];
        if(votingFor != 0) {
            _updateVotingAddDiff(_recipientAddress, votingFor, _shares);
        }
        
        userInfo[_recipientAddress].push(
                UserInfo(_shares, user.lastDepositedTime, _tokensTransferred, block.timestamp, user.mandatoryTimeToServe)
            );

        if (user.shares > 0) {
            user.xvmcAtLastUserAction = user.shares.mul(balanceOf()).div(totalShares);
            user.lastUserActionTime = block.timestamp;
        } else {
            _removeStake(msg.sender, _stakeID); //delete the stake
        }

        emit TransferStake(msg.sender, _recipientAddress, _shares, _stakeID);
    }

    /**
     * user delegates their shares to cast a vote on a proposal
     * casting to proposal ID = 0 is basically neutral position (not voting)
	 * Is origin is allowed, proxy contract can be used to vote in all pools in a single tx
     */
    function voteForProposal(uint256 proposalID) external {
        address _wallet;
		allowOrigin ? _wallet = tx.origin : _wallet = msg.sender;
        uint256 votingFor = userVote[_wallet]; //the ID the user is voting for(before change)
		
        if(proposalID != votingFor) { // do nothing if false(already voting for that ID)
	
			uint256 userTotalShares = getUserTotalShares(_wallet);
			if(userTotalShares > 0) { //if false, no shares, thus just assign proposal ID to userVote
				if(proposalID != 0) { // Allocates vote to an ID
					if(votingFor == 0) { //starts voting, adds votes
						_updateVotingAddDiff(_wallet, proposalID, userTotalShares);
					} else { //removes from previous vote, adds to new
						_updateVotingSubDiff(_wallet, votingFor, userTotalShares);
						_updateVotingAddDiff(_wallet, proposalID, userTotalShares);
					}
				} else { //stops voting (previously voted, now going into neutral (=0)
					_updateVotingSubDiff(_wallet, votingFor, userTotalShares);
				}
			}
			userVote[_wallet] = proposalID;
		}
    }
	
	/*
	* delegatee can vote with shares of another user
	*/
    function delegateeVote(address[] calldata votingAddress, uint256 proposalID) external {
        for(uint256 i = 0; i < votingAddress.length; i++) {
			if(userDelegate[votingAddress[i]] == msg.sender) {
				uint256 votingFor = userVote[votingAddress[i]]; //the ID the user is voting for(before change)
				
				if(proposalID != votingFor){
				
					uint256 userTotalShares = getUserTotalShares(votingAddress[i]);
					if(userTotalShares > 0) {
						if(proposalID != 0) { 
							if(votingFor == 0) {
								_updateVotingAddDiff(votingAddress[i], proposalID, userTotalShares);
							} else {
								_updateVotingSubDiff(votingAddress[i], votingFor, userTotalShares);
								_updateVotingAddDiff(votingAddress[i], proposalID, userTotalShares);
							}
						} else {
							_updateVotingSubDiff(votingAddress[i], votingFor, userTotalShares);
						}
					}
					userVote[votingAddress[i]] = proposalID;
				}
			}
		}
    }
	
     /**
     * Users can delegate their shares
     */
    function setDelegate(address _delegate) external {
        address _wallet;
		allowOrigin ? _wallet=tx.origin : _wallet=msg.sender;
        userDelegate[_wallet] = _delegate;
        
		emit SetDelegate(_wallet, _delegate);
    }
	
	//allows third party stake transfer(stake IDs can be changed, so instead of being identified through ID, it's identified by shares, lastdeposit and mandatory time
    function giveStakeAllowance(address spender, uint256 _stakeID) external {
		UserInfo storage user = userInfo[msg.sender][_stakeID];
		require(user.shares.mul(balanceOf()).div(totalShares) >= minimumGift, "below minimum threshold");
		
		uint256 _allowanceID = _stakeAllowances[msg.sender][spender].length;

		_stakeAllowances[msg.sender][spender].push(
			StakeTransfer(user.shares, user.lastDepositedTime, user.mandatoryTimeToServe)
		);
		
		emit StakeApproval(msg.sender, spender, _allowanceID, user.shares, user.lastDepositedTime, user.mandatoryTimeToServe);
    }
	
    //Note: allowanceID (and not ID of the stake!)
	function revokeStakeAllowance(address spender, uint256 allowanceID) external {
		StakeTransfer[] storage allowances = _stakeAllowances[msg.sender][spender];
        uint256 lastAllowanceID = allowances.length.sub(1);
        
        if(allowanceID != lastAllowanceID) {
            allowances[allowanceID] = allowances[lastAllowanceID];
        }
        
        allowances.pop();
		
		emit StakeAllowanceRevoke(msg.sender, spender, allowanceID);
	}
	
    function nrOfstakeAllowances(address owner, address spender) public view returns (uint256) {
        return _stakeAllowances[owner][spender].length;
    }
	
    function stakeAllowances(address owner, address spender, uint256 allowanceID) public view returns (uint256, uint256, uint256) {
        StakeTransfer storage stakeStore = _stakeAllowances[owner][spender][allowanceID];
        return (stakeStore.shares, stakeStore.lastDepositedTime, stakeStore.mandatoryTimeToServe);
    }
	
    /**
     * A third party can transfer the stake(allowance required)
	 * Allows smart contract inter-operability similar to how regular tokens work
	 * Can only transfer full stake (You can split the stake through other methods)
	 * Bad: makes illiquid stakes liquid
	 * I think best is to have the option, but leave it unavailable unless desired
     */
    function transferStakeFrom(address _from, uint256 _stakeID, uint256 allowanceID, address _to) external returns (bool) {
        require(allowStakeTransferFrom, "third party stake transfers disabled");
		
		require(_from != _to, "can't transfer to self");
        require(_stakeID < userInfo[_from].length, "wrong stake ID");
        UserInfo storage user = userInfo[_from][_stakeID];
		
		(uint256 _shares, uint256 _lastDeposit, uint256 _mandatoryTime) = stakeAllowances(_from, msg.sender, allowanceID);

		//since stake ID can change, the stake to transfer is identified through number of shares, last deposit and mandatory time
		//checks if stake allowance(for allowanceID) matches the actual stake of a user
		require(_shares == user.shares, "incorrect stake or allowance");
		require(_lastDeposit == user.lastDepositedTime, "incorrect stake or allowance");
		require(_mandatoryTime == user.mandatoryTimeToServe, "incorrect stake or allowance");
     
		uint256 votingFor = userVote[_from];
        if(votingFor != 0) {
            _updateVotingSubDiff(_from, votingFor, _shares);
        }
		votingFor = userVote[_to];
        if(votingFor != 0) {
            _updateVotingAddDiff(_to, votingFor, _shares);
        }

        _removeStake(_from, _stakeID); //transfer from must transfer full stake
		_revokeStakeAllowance(_from, allowanceID);
		
        userInfo[_to].push(
                UserInfo(_shares, _lastDeposit, _shares.mul(balanceOf()).div(totalShares),
                    block.timestamp, _mandatoryTime)
            );

        emit TransferStakeFrom(_from, _to, _stakeID, allowanceID);
		
		return true;
    }

    /**
     * Ability to withdraw tokens from the stake, and add voting credit
     * At the time of launch there is no option(voting with credit), but can be added later on
    */
	function votingCredit(uint256 _shares, uint256 _stakeID) public {
        require(votingCreditAddress != address(0), "disabled");
        require(_stakeID < userInfo[msg.sender].length, "invalid stake ID");
        UserInfo storage user = userInfo[msg.sender][_stakeID];
        require(_shares > 0, "Nothing to withdraw");
        require(_shares <= user.shares, "Withdraw amount exceeds balance");

        uint256 currentAmount = (balanceOf().mul(_shares)).div(totalShares);
        user.shares = user.shares.sub(_shares);
        totalShares = totalShares.sub(_shares);

        if (user.shares > 0) {
            user.xvmcAtLastUserAction = user.shares.mul(balanceOf().sub(currentAmount)).div(totalShares);
            user.lastUserActionTime = block.timestamp;
        } else {
            _removeStake(msg.sender, _stakeID); //delete the stake
        }

		uint256 votingFor = userVote[msg.sender];
        if(votingFor != 0) {
            _updateVotingSubDiff(msg.sender, votingFor, _shares);
        }

		emit Withdraw(votingCreditAddress, currentAmount, 0, _shares);

        token.safeTransfer(votingCreditAddress, currentAmount);
		IVoting(votingCreditAddress).addCredit(currentAmount, msg.sender); //in the votingCreditAddress regulate how much is credited, depending on where it's coming from (msg.sender)
    } 
	
    /**
	 * Allows the pools to be changed to new contracts
     * if migration Pool is set
     * anyone can be a "good Samaritan"
     * and transfer the stake of another user to the new pool
     */
    function migrateStake(address _staker, uint256 _stakeID) public {
        require(migrationPool != address(0), "migration not activated");
        require(_stakeID < userInfo[_staker].length, "invalid stake ID");
        UserInfo storage user = userInfo[_staker][_stakeID];
		require(user.shares > 0, "no balance");
        
        uint256 currentAmount = (balanceOf().mul(user.shares)).div(totalShares);
        totalShares = totalShares.sub(user.shares);
		
        user.shares = 0; // equivalent to deleting the stake. Pools are no longer to be used,
						//setting user shares to 0 is sufficient
		
		IacPool(migrationPool).hopDeposit(currentAmount, _staker, user.lastDepositedTime, user.mandatoryTimeToServe);

        emit MigrateStake(msg.sender, currentAmount, user.shares, _staker);
    }

    /**
     * loop and migrate all user stakes
     * could run out of gas if too many stakes
     */
    function migrateAllStakes(address _staker) external {
        UserInfo[] storage user = userInfo[_staker];
        uint256 userStakes = user.length;
        
        for(uint256 i=0; i < userStakes; i++) {
            migrateStake(_staker, i);
        }
    }
	
    
    /**
     * Returns number of stakes for a user
     */
    function getNrOfStakes(address _user) external view returns (uint256) {
        return userInfo[_user].length;
    }
    
    /**
     * Returns all shares for a user
     */
    function getUserTotalShares(address _user) public view returns (uint256) {
        UserInfo[] storage _stake = userInfo[_user];
        uint256 nrOfUserStakes = _stake.length;

		uint256 countShares = 0;
		
		for(uint256 i=0; i < nrOfUserStakes; i++) {
			countShares += _stake[i].shares;
		}
		
		return countShares;
    }
	
    /**
     * @notice Calculates the expected harvest reward from third party
     * @return Expected reward to collect in XVMC
     */
    function calculateHarvestXVMCRewards() external view returns (uint256) {
        uint256 amount = IMasterChef(masterchef).pendingEgg(poolID, address(this));
        uint256 currentCallFee = amount.mul(callFee).div(10000);

        return currentCallFee;
    }

    /**
     * @return Returns total pending xvmc rewards
     */
    function calculateTotalPendingXVMCRewards() external view returns (uint256) {
        uint256 amount = IMasterChef(masterchef).pendingEgg(poolID, address(this));

        return amount;
    }

    /**
     * @notice Calculates the price per share
     */
    function getPricePerFullShare() external view returns (uint256) {
        return totalShares == 0 ? 1e18 : balanceOf().mul(1e18).div(totalShares);
    }
    
    /**
     * @notice returns number of shares for a certain stake of an user
     */
    function getUserShares(address _wallet, uint256 _stakeID) public view returns (uint256) {
        return userInfo[_wallet][_stakeID].shares;
    }
	
    /**
     * @notice Calculates the total underlying tokens
     * @dev It includes tokens held by the contract and held in MasterChef
     */
    function balanceOf() public view returns (uint256) {
        uint256 amount = IMasterChef(masterchef).pendingEgg(poolID, address(this)); 
        return token.balanceOf(address(this)).add(amount); 
    }
	
    
	//enables or disables ability to draw stake from another wallet(allowance required)
	function enableDisableStakeTransferFrom(bool _setting) external adminOnly {
		allowStakeTransferFrom = _setting;
	}

    /**
     * @notice Sets call fee 
     * @dev Only callable by the contract admin.
     */
    function setCallFee(uint256 _callFee) external adminOnly {
        callFee = _callFee;
    }

     /*
     * set trusted senders, other pools that we can receive from (that can hopDeposit)
     * guaranteed to be trusted (they rely lastDepositTime)
     */
	function setTrustedSender(address _sender, bool _setting) external adminOnly {
        if(trustedSender[_sender] != _setting) {
			trustedSender[_sender] = _setting;
			
			_setting ? trustedSenderCount++ : trustedSenderCount--;

			emit TrustedSender(_sender, _setting);
		}
    }
    
     /**
     * set trusted pools, the smart contracts that we can send the tokens to without penalty
	 * NOTICE: new pool must be set as trusted contract(to be able to draw balance without allowance)
     */
    function setTrustedPool(address _pool, bool _setting) external adminOnly {
        if(trustedPool[_pool] != _setting) {
			trustedPool[_pool] = _setting;
			
			_setting ? trustedPoolCount++ : trustedPoolCount--;

			emit TrustedPool(_pool, _setting);
		}
    }


     /**
     * set address of new pool that we can migrate into
	 * !!! NOTICE !!!
     *  new pool must be set as trusted contract in the token contract by the governor(to be able to draw balance without allowance)
     */
    function setMigrationPool(address _newPool) external adminOnly {
		migrationPool = _newPool;
    }
    
     /**
     * Enable or disable partial withdrawals from stakes
     */
    function modifyPartialWithdrawals(bool _decision) external adminOnly {
        partialWithdrawals = _decision;
    }
	function modifyPartialTransfers(bool _decision) external adminOnly {
        partialTransfers = _decision;
    }
	
	function enableDisableStakeTransfer(bool _setting) external adminOnly {
		allowStakeTransfer = _setting;
	}

    /**
     * @notice Withdraws from MasterChef to Vault without caring about rewards.
     * @dev EMERGENCY ONLY. Only callable by the contract admin.
     */
    function emergencyWithdraw() external adminOnly {
        IMasterChef(masterchef).emergencyWithdraw(poolID);
        token.safeTransfer(admin, token.balanceOf(address(this)));
    }
	
	/*
	 * Unlikely, but Masterchef can be changed if needed to be used without changing pools
	 * masterchef = IMasterChef(token.owner());
	 * Must stop earning first(withdraw tokens from old chef)
	*/
	function setMasterChefAddress(IMasterChef _masterchef, uint256 _newPoolID) external adminOnly {
		masterchef = _masterchef;
		poolID = _newPoolID; //in case pool ID changes
		
		uint256 _dummyAllowance = IERC20(dummyToken).allowance(address(this), address(masterchef));
		if(_dummyAllowance == 0) {
			IERC20(dummyToken).safeApprove(address(_masterchef), type(uint256).max);
		}
	}
	
    /**
     * When contract is launched, dummyToken shall be deposited to start earning rewards
     */
    function startEarning() external adminOnly {
		IMasterChef(masterchef).deposit(poolID, dummyToken.balanceOf(address(this)));
    }
	
    /**
     * Dummy token can be withdrawn if ever needed(allows for flexibility)
     */
	function stopEarning(uint256 _withdrawAmount) external adminOnly {
		if(_withdrawAmount == 0) { 
			IMasterChef(masterchef).withdraw(poolID, dummyToken.balanceOf(address(masterchef)));
		} else {
			IMasterChef(masterchef).withdraw(poolID, _withdrawAmount);
		}
	}
	
    /**
     * Withdraws dummyToken to owner(who can burn it if needed)
     */
    function withdrawDummy(uint256 _amount) external adminOnly {	
        if(_amount == 0) { 
			dummyToken.safeTransfer(admin, dummyToken.balanceOf(address(this)));
		} else {
			dummyToken.safeTransfer(admin, _amount);
		}
    }
	
	function allowTxOrigin(bool _setting) external adminOnly {
		allowOrigin = _setting;
	}
	
	//sets minimum amount(for sending gift, transferring to another wallet,...)
	//if setting is enabled, minimumGift can be auto-updated to costToVote from governor by anybody
	function setMinimumGiftDeposit(uint256 _amount, bool _setting) external adminOnly {
		minimumGift = _amount;
		updateMinGiftGovernor = _setting;
	}
	
    function regulateVotingCredit(address _newAddress) external adminOnly {
        votingCreditAddress = _newAddress;
    }
	
	/**
	 * option to withdraw wrongfully sent tokens(but requires change of the governing contract to do so)
	 * If you send wrong tokens to the contract address, consider them lost. Though there is possibility of recovery
	 */
	function withdrawStuckTokens(address _tokenAddress) external adminOnly {
		require(_tokenAddress != address(token), "wrong token");
		require(_tokenAddress != address(dummyToken), "wrong token");
		
		IERC20(_tokenAddress).safeTransfer(IGovernance(admin).treasuryWallet(), IERC20(_tokenAddress).balanceOf(address(this)));
	}
	
	
    //Note: allowanceID (and not ID of the stake!)
	function _revokeStakeAllowance(address owner, uint256 allowanceID) private {
		StakeTransfer[] storage allowances = _stakeAllowances[owner][msg.sender];
        uint256 lastAllowanceID = allowances.length.sub(1);
        
        if(allowanceID != lastAllowanceID) {
            allowances[allowanceID] = allowances[lastAllowanceID];
        }
        
        allowances.pop();
		
		emit StakeAllowanceRevoke(owner, msg.sender, allowanceID);
	}
	
    /**
     * updates votes(whenever there is transfer of funds)
     */
    function _updateVotingAddDiff(address voter, uint256 proposalID, uint256 diff) private {
        totalVotesForID[proposalID] = totalVotesForID[proposalID].add(diff);
        
        emit AddVotes(voter, proposalID, diff);
    }
    function _updateVotingSubDiff(address voter, uint256 proposalID, uint256 diff) private {
        totalVotesForID[proposalID] = totalVotesForID[proposalID].sub(diff);
        
        emit RemoveVotes(voter, proposalID, diff);
    }
    
    /**
     * removes the stake
     */
    function _removeStake(address _staker, uint256 _stakeID) private {
        UserInfo[] storage stakes = userInfo[_staker];
        uint256 lastStakeID = stakes.length - 1;
        
        if(_stakeID != lastStakeID) {
            stakes[_stakeID] = stakes[lastStakeID];
        }
        
        stakes.pop();
    }
}