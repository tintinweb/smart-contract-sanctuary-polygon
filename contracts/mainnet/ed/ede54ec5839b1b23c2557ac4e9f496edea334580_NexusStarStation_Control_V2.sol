/**
 *Submitted for verification at polygonscan.com on 2023-06-09
*/

// File: @openzeppelin/contracts/utils/Address.sol


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

// File: @openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol


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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


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

// File: @openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol


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

// File: @openzeppelin/contracts/utils/math/SafeMath.sol


// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
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
        return a + b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
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
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
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
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// File: @openzeppelin/contracts/utils/Counters.sol


// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


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

// File: Star Stations/NexusStarStations/NexusStarStationControl_V2.sol


/*

🅂🅃🄰🅁🅂🄴🄴🄳🅂


░██████╗██████╗░░█████╗░░█████╗░███████╗░██████╗████████╗░█████╗░████████╗██╗░█████╗░███╗░░██╗░██████╗
██╔════╝██╔══██╗██╔══██╗██╔══██╗██╔════╝██╔════╝╚══██╔══╝██╔══██╗╚══██╔══╝██║██╔══██╗████╗░██║██╔════╝
╚█████╗░██████╔╝███████║██║░░╚═╝█████╗░░╚█████╗░░░░██║░░░███████║░░░██║░░░██║██║░░██║██╔██╗██║╚█████╗░
░╚═══██╗██╔═══╝░██╔══██║██║░░██╗██╔══╝░░░╚═══██╗░░░██║░░░██╔══██║░░░██║░░░██║██║░░██║██║╚████║░╚═══██╗
██████╔╝██║░░░░░██║░░██║╚█████╔╝███████╗██████╔╝░░░██║░░░██║░░██║░░░██║░░░██║╚█████╔╝██║░╚███║██████╔╝
╚═════╝░╚═╝░░░░░╚═╝░░╚═╝░╚════╝░╚══════╝╚═════╝░░░░╚═╝░░░╚═╝░░╚═╝░░░╚═╝░░░╚═╝░╚════╝░╚═╝░░╚══╝╚═════╝░

Token Rewarding NFT platform.


*/

pragma solidity ^0.8.13;






// Interface with the SpaceStation NFT contracts functions
abstract contract spaceStationInterface {
    function safeMint(address account, string memory uri, uint256 weight) virtual external returns (uint256);
    function transferOwnership(address newOwner) virtual external;
    function updateWeight(uint256 tokenId, uint256 increase) virtual external;
    function ownerOf(uint256 tokenId) virtual external view returns (address owner);
    function weightOf(uint256 tokenId)external virtual view returns(uint256 weight);
}

contract NexusStarStation_Control_V2 is Context, Ownable{
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    struct SpaceStations{
        uint256 tokenId;            // Id of the SpaceStation NFT
        uint256 class;              // Class of the SpaceStation
        uint256 APR;                // APR of the SpaceStation
        uint256 lastUpdate;         // number of Stations when last updated.
    }

    struct StationClass{
        uint256 startingAPR;        // Initial APR used for new mints
        uint256 upgradeRate;        // Rate the weight is increased when more stations are minted
        uint256 price;              // Star cost to mint Space Station with base point of 1000
        uint256 maxAPR;             // Max APR for the class
        string uri;                 // Metadata uri
    }
    struct transferInfo{
        address to;
        uint256 amount;
    }

    uint256 totalMinted = 0;        // Total number of nfts minted. Used as a tracker for all space station classes and used for calculating station upgrades.
    address rewardPool;             // Address for reward pool. Set at deployment    
    address constant star = 0x8440178087C4fd348D43d0205F4574e0348a06F0;
    address rewardToken;
    address private immutable deadAddress = 0x000000000000000000000000000000000000dEaD;
    address StarStationAddress;     // Address of the starstation nft contract
    spaceStationInterface spaceStationContract;//interface to Stations NFT contract
    uint256 burnRate = 15;            // % of purchase cost burnt
    StationClass[] private stationClasses;  // Array of all the Sation Classes
    SpaceStations[] private spaceStations;   // Tracker for stations used for rewards
    uint256 lastPayout = 0;

    event MintNFT(address user, uint256 tokenId, uint256 class);
    event BuyGift(address user, uint256 class);
    event RedeemGift(address user, uint256 tokenId, uint256 class, string giftCode);

    constructor(address _stationAddress, address _rewardPool, uint256[] memory stations) {
        rewardToken = star;
        totalMinted = stations.length;
        StarStationAddress = _stationAddress;
        rewardPool = _rewardPool;
        spaceStationContract = spaceStationInterface(_stationAddress);   //initialize an interface to Stations NFT contract

        //Freighter STATION
        stationClasses.push(StationClass({
            startingAPR:22000,
            upgradeRate:1,
            price:2000,
            maxAPR:29810,
            uri:"https://storageapi.fleek.co/aeb85deb-410a-4c50-8834-96486196b392-bucket/Nexus Star Stations/Nexus Star Station Freighter Class.json"
        }));
        //METEOR STATION
        stationClasses.push(StationClass({
            startingAPR:28100,
            upgradeRate:10,
            price:11000,
            maxAPR:37940,
            uri:"https://storageapi.fleek.co/aeb85deb-410a-4c50-8834-96486196b392-bucket/Nexus Star Stations/Nexus Star Station Meteor Class.json"
        }));
        //CITY STATION
        stationClasses.push(StationClass({
            startingAPR:29440,
            upgradeRate:30,
            price:33000,
            maxAPR:39740,
            uri:"https://storageapi.fleek.co/aeb85deb-410a-4c50-8834-96486196b392-bucket/Nexus Star Stations/Nexus Star Station City Class.json"
        }));
        //PLANET STATION
        stationClasses.push(StationClass({
            startingAPR:30500,
            upgradeRate:100,
            price:111000,
            maxAPR:41180,
            uri:"https://storageapi.fleek.co/aeb85deb-410a-4c50-8834-96486196b392-bucket/Nexus Star Stations/Nexus Star Station Planet Class.json"
        }));
        //Guardian STATION
        stationClasses.push(StationClass({
            startingAPR:30473,
            upgradeRate:1000,
            price:1111000,
            maxAPR:41140,
            uri:"https://storageapi.fleek.co/aeb85deb-410a-4c50-8834-96486196b392-bucket/Nexus Star Stations/Nexus Star Station Planet Class.json"
        }));

        for(uint256 id = 0; id <stations.length; id++){
            spaceStations.push(SpaceStations({
                tokenId:id,          // Id of the SpaceStation NFT
                class:stations[id],              // Class of the SpaceStation
                APR:0,                // APR of the SpaceStation
                lastUpdate:0
            }));
        }
    }

    // Update the weight of existing SpaceStations
    function updateAPR() public {
        for (uint256 pid = 0; pid <spaceStations.length; pid++) {                                       // Cycle through all Spacestations
            SpaceStations storage SpaceStation = spaceStations[pid];                                    // Get instance of spaceStation
            StationClass memory stationClass = stationClasses[SpaceStation.class];                      // Get the Station Calsses stats
            if(SpaceStation.lastUpdate < totalMinted){                                                  // Check that new Nfts have been minted since stations last update
                if(SpaceStation.APR < stationClass.maxAPR){                                             // Check that station weight is less then max weight
                    uint256 newStations = totalMinted.sub(SpaceStation.lastUpdate);                     // Get the number of new nfts minted since last update
                    uint256 currentAPR = SpaceStation.APR;                                              // Get the current weight of the Station
                    uint256 upgradeRate = stationClass.upgradeRate;                                     // Fetch upgrade rate for current station
                    uint256 newAPR = (currentAPR.add(upgradeRate.mul(newStations)));                // Calculate the new weight.
                    if(newAPR <= stationClass.maxAPR){
                        SpaceStation.APR = currentAPR.add(newAPR);                                      // Update the ships weight.
                    }
                    else{
                        SpaceStation.APR = stationClass.maxAPR;                                         // Update the ships weight.
                    }
                }
                SpaceStation.lastUpdate = totalMinted;                                                  // Update the lastUpdated ot the new total.
            }
        }
    }

    // Mint requested NFT
    function mintNFT(uint256 _classPID) external returns(uint256){
        StationClass memory station = stationClasses[_classPID];                                    // Fetch stats for the requested NFT
        uint256 price = station.price*10**15;                                                       // Convert price to wei
        uint256 burnAmount = (price.mul(burnRate)).div(100);                                        // calcualte amout of star to burn  
        (bool success) = IERC20(star).transferFrom(_msgSender(), rewardPool, price.sub(burnAmount));// Pay for the NFT
        require(success, "Payment failed.");                                                        // Ensure transfer completed successfully
        success = IERC20(star).transferFrom(_msgSender(),deadAddress, burnAmount);                  // Burn the burn amount
        require(success, "Burn failed.");                                                           // Ensure transfer completed successfully
        uint256 tokenId = spaceStationContract.safeMint(_msgSender(),station.uri,station.startingAPR);  // Mint the NFT
        totalMinted ++;                                                                             // Increase mint count by 1
        spaceStations.push(SpaceStations({                                                          // Add new station to the station array
            tokenId:tokenId,                                                                        // Set new stations tokenId
            class:_classPID,                                                                        // Set the calss of the Station
            APR:station.startingAPR,                                                                // Set the weight of the Station
            lastUpdate:totalMinted                                                                  // Set lastUpdate to the current toal minted stations
        }));
        emit MintNFT(_msgSender(), tokenId, _classPID);                                             // Emit MintNFT event with users address, token id, and class id
        return tokenId;
    }

    // Buy Gift Card NFT
    function buyGift(uint256 _classPID) external {                                                      // Buy a Gift card.
        StationClass memory station = stationClasses[_classPID];                                        // Fetch stats for the requested NFT
        uint256 price = station.price*10**15;                                                           // Convert price to wei
        uint256 burnAmount = (price.mul(burnRate)).div(100);                                            // calcualte amout of star to burn  
        (bool success) = IERC20(star).transferFrom(_msgSender(), rewardPool, price.sub(burnAmount));    // Pay for the NFT
        require(success, "Payment failed.");                                                            // Ensure transfer completed successfully
        success = IERC20(star).transferFrom(_msgSender(),deadAddress, burnAmount);                      // Burn the burn amount
        require(success, "Burn failed.");                                                               // Ensure transfer completed successfullyer
        emit BuyGift(_msgSender(), _classPID);                                                          // Emit RedeemGift event with users address, token id, and class id
    }

    // Redeem Gift Card NFT
    function redeemGift(address _recipient, uint256 _classPID, string memory _giftCode) external onlyOwner returns(uint256){ // onlyOwner means it can only be called by the contract owner (us) this guarantees we verify the code before we can redeem.
        StationClass memory station = stationClasses[_classPID];                                            // Fetch stats for the requested NFT
        uint256 tokenId = spaceStationContract.safeMint(_recipient,station.uri,station.startingAPR);     // Mint the NFT
        totalMinted ++;                                                                                     // Increase mint count by 1
        spaceStations.push(SpaceStations({                                                                  // Add new station to the station array
            tokenId:tokenId,                                                                                // Set new stations tokenId
            class:_classPID,                                                                                // Set the calss of the Station
            APR:station.startingAPR,                                                                  // Set the weight of the Station
            lastUpdate:totalMinted                                                                          // Set lastUpdate to the current toal minted stations
        }));
        emit RedeemGift(_msgSender(), tokenId, _classPID,_giftCode);                                        // Emit RedeemGift event with users address, token id, and class id
        return tokenId;
    }

    // Add anew class of Station to the SpaceStation System
    function addClass(StationClass calldata _station )external onlyOwner{
        stationClasses.push(StationClass({                      // Add new station to the SpaceStations array
            startingAPR:_station.startingAPR,             // Set classess starting weight
            upgradeRate:_station.upgradeRate,                   // Set classess upgrade rate
            price:_station.price,                               // Set classess mint price
            maxAPR:_station.maxAPR,                     // Set Max weight for class
            uri:_station.uri                                    // set metadata uri
        }));
    }

    //Update a calsses stats
    function updateClassAPR(uint256 _classPid, uint256 _startingAPR)external onlyOwner{
        stationClasses[_classPid].startingAPR = _startingAPR;                             // Update the Starting weight for the class
    }

    function updateClassUpgradeRate(uint256 _classPid, uint256 _upgradeRate)external onlyOwner{
        stationClasses[_classPid].upgradeRate = _upgradeRate;                                   // Update the Upgrade Rate for the class
    }

    function updateClassPrice(uint256 _classPid, uint256 _price)external onlyOwner{
        stationClasses[_classPid].price = _price;                                               // Update the Price for the class
    }

    // Fetch array of existing stations (used by controller)
    function getStations()external view returns(SpaceStations[] memory){
        return spaceStations;
    }

    function getStationClasses()external view returns(StationClass[] memory){
        return stationClasses;
    }

    // Allow for owner of stations contract change incase of new controller
    function setStationOwner(address _newOwner)external onlyOwner {
        spaceStationContract.transferOwnership(_newOwner);                      // Set the owner for the Stations NFT Contract.
    }

    // Allow for station weight to be updated on nft
    function updateNftWeight(uint256 tokenId)external returns(uint256){
        uint256 currentWeight = spaceStationContract.weightOf(tokenId);                                         // Get the current weight for the nft
        SpaceStations storage SpaceStation = spaceStations[tokenId];                                            // Get instance of spaceStation
        uint256 increase = SpaceStation.APR.sub(currentWeight);                                              // Calculate the increase amount
        require(increase > 0, "NFT weight is upto date.");                                                      // check that an update is needed.
        spaceStationContract.updateWeight(tokenId,increase);                                                    // Update the NFT
        return(SpaceStation.APR);
    }

    function setMaxIncrease(uint256 _increase) external onlyOwner{
        for(uint256 pid; pid < stationClasses.length; pid++){                                                   // Cycle through all station classes
            StationClass storage class = stationClasses[pid];                                                   // Get instance of the class
            class.maxAPR = class.startingAPR.mul(_increase);                                             // Update the max weight for the class
        }
    }

    function setRewardPool(address _poolAddress)external onlyOwner{
        rewardPool = _poolAddress;
    }

    function setRewardToken(address _tokenAddress)external onlyOwner{
        rewardToken = _tokenAddress;
    }

    function setBurnRate(uint256 _burnRate)external onlyOwner{
        burnRate = _burnRate;
    }

    function payReward() external {
        require((block.timestamp - lastPayout) >= 1 days, "Too soon for payout");
        updateAPR();
        transferInfo[] memory payouts;
        payouts = new transferInfo[](spaceStations.length);
        for (uint256 i = 0; i < spaceStations.length; i++) {
            uint256 stationPrice = stationClasses[spaceStations[i].class].price;
            payouts[i] = transferInfo({
                to: spaceStationContract.ownerOf(i),
                amount: (stationPrice * spaceStations[i].APR)
            });
        }
        multiTransfer(payouts);
        lastPayout = block.timestamp;
    }

    function payBonus(uint256 numDays) external onlyOwner{
        updateAPR();
        transferInfo[] memory payouts;
        payouts = new transferInfo[](spaceStations.length);
        for (uint256 i = 0; i < spaceStations.length; i++) {
            uint256 stationPrice = stationClasses[spaceStations[i].class].price;
            payouts[i] = transferInfo({
                to: spaceStationContract.ownerOf(i),
                amount: ((stationPrice * spaceStations[i].APR)*numDays)
            });
        }
        multiTransfer(payouts);
    }

    function multiTransfer(transferInfo[] memory transfers ) public{
        IERC20 token = IERC20(star);
        for(uint256 count = 0; count < transfers.length; count++){
            token.safeTransferFrom(rewardPool,transfers[count].to, transfers[count].amount);
        }
    }
}