/**
 *Submitted for verification at polygonscan.com on 2021-09-07
*/

// File: contracts/Config.sol


pragma solidity ^0.6.0;

contract Config {
    // The base amount of percentage function
    uint256 public constant PERCENTAGE_BASE = 1 ether;
}

// File: contracts/lib/LibParam.sol


pragma solidity ^0.6.0;

library LibParam {
    bytes32 private constant STATIC_MASK =
        0x0100000000000000000000000000000000000000000000000000000000000000;
    bytes32 private constant CALLTYPE_MASK =
        0x0200000000000000000000000000000000000000000000000000000000000000;
    bytes32 private constant PARAMS_MASK =
        0x0000000000000000000000000000000000000000000000000000000000000001;
    bytes32 private constant REFS_MASK =
        0x00000000000000000000000000000000000000000000000000000000000000FF;
    bytes32 private constant RETURN_NUM_MASK =
        0x00FF000000000000000000000000000000000000000000000000000000000000;

    uint256 private constant REFS_LIMIT = 22;
    uint256 private constant PARAMS_SIZE_LIMIT = 64;
    uint256 private constant RETURN_NUM_OFFSET = 240;

    function isStatic(bytes32 conf) internal pure returns (bool) {
        if (conf & STATIC_MASK == 0) return true;
        else return false;
    }

    function isReferenced(bytes32 conf) internal pure returns (bool) {
        if (getReturnNum(conf) == 0) return false;
        else return true;
    }

    function isDelegateCall(bytes32 conf) internal pure returns (bool) {
        return (conf & CALLTYPE_MASK == 0);
    }

    function getReturnNum(bytes32 conf) internal pure returns (uint256 num) {
        bytes32 temp = (conf & RETURN_NUM_MASK) >> RETURN_NUM_OFFSET;
        num = uint256(temp);
    }

    function getParams(bytes32 conf)
        internal
        pure
        returns (uint256[] memory refs, uint256[] memory params)
    {
        require(!isStatic(conf), "Static params");
        uint256 n = REFS_LIMIT;
        while (conf & REFS_MASK == REFS_MASK && n > 0) {
            n--;
            conf = conf >> 8;
        }
        require(n > 0, "No dynamic param");
        refs = new uint256[](n);
        params = new uint256[](n);
        for (uint256 i = 0; i < n; i++) {
            refs[i] = uint256(conf & REFS_MASK);
            conf = conf >> 8;
        }
        uint256 i = 0;
        for (uint256 k = 0; k < PARAMS_SIZE_LIMIT; k++) {
            if (conf & PARAMS_MASK != 0) {
                require(i < n, "Location count exceeds ref count");
                params[i] = k * 32 + 4;
                i++;
            }
            conf = conf >> 1;
        }
        require(i == n, "Location count less than ref count");
    }
}

// File: contracts/utils/OwnableAction.sol


pragma solidity ^0.6.0;

/**
 * @dev Create immutable owner for action contract
 */
abstract contract OwnableAction {
    address payable public immutable actionOwner;

    constructor(address payable _owner) internal {
        actionOwner = _owner;
    }
}

// File: contracts/utils/DestructibleAction.sol


pragma solidity ^0.6.0;


/**
 * @dev Can only be destroyed by owner. All funds are sent to the owner.
 */
abstract contract DestructibleAction is OwnableAction {
    constructor(address payable _owner) internal OwnableAction(_owner) {}

    function destroy() external {
        require(
            msg.sender == actionOwner,
            "DestructibleAction: caller is not the owner"
        );
        selfdestruct(actionOwner);
    }
}

// File: contracts/interfaces/ITaskExecutor.sol


pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

interface ITaskExecutor {
    function batchExec(address[] calldata tos, bytes32[] calldata configs, bytes[] memory datas) external payable;
}

// File: @openzeppelin/contracts/utils/Address.sol



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

// File: @openzeppelin/contracts/math/SafeMath.sol



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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol



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

// File: @openzeppelin/contracts/token/ERC20/SafeERC20.sol



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

// File: contracts/TaskExecutor.sol


pragma solidity ^0.6.0;




contract TaskExecutor is ITaskExecutor, Config, DestructibleAction {
    using Address for address;
    using SafeERC20 for IERC20;
    using LibParam for bytes32;

    address private immutable self;

    modifier delegateCallOnly() {
        require(self != address(this), "TaskExecutor: Delegate call only");
        _;
    }

    constructor(address payable _owner) public DestructibleAction(_owner) {
        self = address(this);
    }

    /**
     * @notice task execution function.
     * @param tos The address of action.
     * @param configs The configurations of executing actions.
     * @param datas The action datas.
     */
    function batchExec(
        address[] calldata tos,
        bytes32[] calldata configs,
        bytes[] memory datas
    ) external payable override delegateCallOnly {
        _execs(tos, configs, datas);
    }

    /**
     * @notice The execution phase.
     * @param tos The address of action.
     * @param configs The configurations of executing actions.
     * @param datas The action datas.
     */
    function _execs(
        address[] memory tos,
        bytes32[] memory configs,
        bytes[] memory datas
    ) internal {
        bytes32[256] memory localStack;
        uint256 index = 0;

        require(
            tos.length == datas.length,
            "TaskExecutor: Tos and datas length inconsistent"
        );
        require(
            tos.length == configs.length,
            "TaskExecutor: Tos and configs length inconsistent"
        );

        for (uint256 i = 0; i < tos.length; i++) {
            bytes32 config = configs[i];

            if (config.isDelegateCall()) {
                // Delegate call case

                // Trim params from local stack depend on config
                _trimParams(datas[i], config, localStack, index);

                // Execute action by delegate call
                bytes memory result =
                    tos[i].functionDelegateCall(
                        datas[i],
                        "TaskExecutor: low-level delegate call failed"
                    );

                // Store return data from action to local stack
                index = _parseReturn(result, config, localStack, index);
            } else {
                // Function Call case

                // Decode eth value from data
                (uint256 ethValue, bytes memory _data) =
                    _decodeEthValue(datas[i]);

                // Trim params from local stack depend on config
                _trimParams(_data, config, localStack, index);

                // Execute action by call
                bytes memory result =
                    tos[i].functionCallWithValue(
                        _data,
                        ethValue,
                        "TaskExecutor: low-level call with value failed"
                    );

                // Store return data from action to local stack depend on config
                index = _parseReturn(result, config, localStack, index);
            }
        }
    }

    /**
     * @notice Trimming the execution parameter if needed.
     * @param data The execution data.
     * @param config The configuration.
     * @param localStack The stack the be referenced.
     * @param index Current element count of localStack.
     */
    function _trimParams(
        bytes memory data,
        bytes32 config,
        bytes32[256] memory localStack,
        uint256 index
    ) internal pure {
        if (config.isStatic()) {
            // Don't need to trim parameters if static
            return;
        }

        // Trim the execution data base on the configuration and stack content if dynamic
        // Fetch the parameter configuration from config
        (uint256[] memory refs, uint256[] memory params) = config.getParams();

        // Trim the data with the reference and parameters
        for (uint256 i = 0; i < refs.length; i++) {
            require(
                refs[i] < index,
                "TaskExecutor: Reference to out of localStack"
            );
            bytes32 ref = localStack[refs[i]];
            uint256 offset = params[i];
            uint256 base = PERCENTAGE_BASE;
            assembly {
                let loc := add(add(data, 0x20), offset)
                let m := mload(loc)
                // Adjust the value by multiplier if a dynamic parameter is not zero
                if iszero(iszero(m)) {
                    // Assert no overflow first
                    let p := mul(m, ref)
                    if iszero(eq(div(p, m), ref)) {
                        revert(0, 0)
                    } // require(p / m == ref)
                    ref := div(p, base)
                }
                mstore(loc, ref)
            }
        }
    }

    /**
     * @notice Parse the execution return data to the local stack if needed.
     * @param ret The return data.
     * @param config The configuration.
     * @param localStack The local stack to place the return values.
     * @param index The current tail.
     */
    function _parseReturn(
        bytes memory ret,
        bytes32 config,
        bytes32[256] memory localStack,
        uint256 index
    ) internal pure returns (uint256) {
        if (config.isReferenced()) {
            // If so, parse the output and place it into local stack
            uint256 num = config.getReturnNum();
            uint256 newIndex = _parse(localStack, ret, index);
            require(
                newIndex == index + num,
                "TaskExecutor: Return num and parsed return num not matched"
            );
            index = newIndex;
        }
        return index;
    }

    /**
     * @notice Parse the return data to the local stack.
     * @param localStack The local stack to place the return values.
     * @param ret The return data.
     * @param index The current tail.
     */
    function _parse(
        bytes32[256] memory localStack,
        bytes memory ret,
        uint256 index
    ) internal pure returns (uint256 newIndex) {
        uint256 len = ret.length;
        // The return value should be multiple of 32-bytes to be parsed.
        require(len % 32 == 0, "TaskExecutor: Illegal length for _parse");
        // Estimate the tail after the process.
        newIndex = index + len / 32;
        require(newIndex <= 256, "TaskExecutor: Stack overflow");
        assembly {
            let offset := shl(5, index)
            // Store the data into localStack
            for {
                let i := 0
            } lt(i, len) {
                i := add(i, 0x20)
            } {
                mstore(
                    add(localStack, add(i, offset)),
                    mload(add(add(ret, i), 0x20))
                )
            }
        }
    }

    /**
     * @notice decode eth value from the execution data.
     * @param data The execution data.
     */
    function _decodeEthValue(bytes memory data)
        internal
        pure
        returns (uint256, bytes memory)
    {
        return abi.decode(data, (uint256, bytes));
    }
}