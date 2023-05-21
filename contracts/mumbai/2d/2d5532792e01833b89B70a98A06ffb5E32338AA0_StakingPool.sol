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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
import "../../../utils/Address.sol";

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
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
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

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./StakingPool.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./StakingPool.sol";

contract BtcitrumLens {

    using SafeMath for uint256;

    struct Txhash {
        uint256 totalHash;
        uint256 totalStake;
        uint256 userHash;
        uint256 userStake;
    }

    function getUser(StakingPool stakingPool,address user) public view returns(Txhash memory){
        uint256 totalHash = stakingPool.totalHash();
        (,,,,uint256 tokenAmount) = stakingPool.poolInfo(1);
        uint256 totalStaking = tokenAmount;
        uint256 userTotalHash = stakingPool.userTotalHash(user);
        (uint256 userAmount,,) = stakingPool.userInfo(1,user);
        uint256 userStakeing = userAmount;
        return Txhash({
            totalHash:totalHash,
            totalStake:totalStaking,
            userHash:userTotalHash,
            userStake: userStakeing
        });
    }


    struct Rewards{
        uint256 pendingAllRewards;
        uint256 allRewards;
    }

    function rewards(StakingPool stakingPool,address user) public view returns (Rewards memory) {
        uint256 pendingAllRewards = 0;
        uint256 allReceivedRewards = 0;
        uint256 userAllDebt = 0;
        for(uint256 i=0;i< 2;i++){
            (uint256 pendingBtcAmount, ) = stakingPool.pending(i,user);
            pendingAllRewards = pendingAllRewards.add(pendingBtcAmount);

            (,,uint256 receivedRewards) = stakingPool.userInfo(i,user);
            allReceivedRewards = allReceivedRewards.add(receivedRewards);
        }
        uint256 allRewards = pendingAllRewards.add(allReceivedRewards);
        return Rewards({
            pendingAllRewards: pendingAllRewards,
            allRewards: allRewards
        });
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import {IERC20 as SIERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IBtc is SIERC20 {
    function mint(address to, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

interface IBtcitrumPair {

    function factory() external view returns (address);

    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);

    function mint(address to) external returns (uint liquidity);

    function burn(address to) external returns (uint amount0, uint amount1);

    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;

    function skim(address to) external;

    function sync() external;

    function price(address token, uint256 baseDecimal) external view returns (uint256);

    function initialize(address, address) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./interface/IBtc.sol";
import "./interface/IBtcitrumPair.sol";

interface IStakingPool {
    function deposit(uint256 pid, uint256 amount) external;

    function withdraw(uint256 pid, uint256 amount) external;
}

contract StakingPool is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    bytes32 public constant HashEIP712Domain = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");

    bytes32 public constant HashOrderStruct = keccak256(
        "WithdrawRequest(address user,uint256 nonce,uint256 amount,uint256 expirationTime,address verifyingContract)"
    );


    bytes32 public HashEIP712Version;
    bytes32 public HashEIP712Name;

    string public name = "StakingPool";
    string public version = "1.0.0";

    // Info of each user.
    struct UserInfo {
        uint256 amount;     // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt.
        uint256 receivedRewards;
    }

    // Info of each pool.
    struct PoolInfo {
        IERC20 token;           // Address of LP token contract.
        uint256 hashRate;       // How many allocation points assigned to this pool. BTCs to distribute per block.
        uint256 lastRewardBlock;  // Last block number that BTCs distribution occurs.
        uint256 accBtcPerShare; // Accumulated BTCs per share, times 1e12.
        uint256 totalAmount;    // Total amount of current pool deposit.
    }

    struct Sig {
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    struct WithdrawRequest {
        address user;
        uint256 nonce;
        uint256 amount;
        uint256 expirationTime;
        address verifyingContract;
    }

    mapping(address => address) public inviteMapping;
    mapping(address => bool) public inviteList;

    // The BTC Token!
    IBtc public btc;
    IERC20 public usdt;

    address public pair;

    address public admin;

    address public operator;

    address public dynamicRewards;

    address public manager;

    // BTC tokens created per block.
    uint256 public btcPerBlock;
    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    // pid corresponding address
    mapping(address => uint256) public LpOfPid;

    mapping(address => uint256) public userNonceMapping;
    // Control mining
    bool public paused = false;
    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;
    // The block number when BTC mining starts.
    uint256 public startBlock;
    // How many blocks are halved
    uint256 public halvingPeriod = 210000 * 200;

    event Invite(address indexed inviter,address indexed invitee);
    event Mintblock(uint256 blockNumber,uint256 rewards);
    event ExsitBtc(uint256 blockNumber,uint256 btcTotalSupply);
    event DepositInvalid(address indexed user, uint256 indexed pid, uint256 amount);
    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event WithdrawApply(address indexed user, uint256 indexed pid, uint256 amount,uint256 startBlockNumber);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);

    constructor(
        IBtc _btc,
        IERC20 _usdt,
        uint256 _btcPerBlock,
        address _operator,
        address _dynamicRewards,
        address _manager
    ) public {
        btc = _btc;
        usdt = _usdt;
        btcPerBlock = _btcPerBlock;
        startBlock = block.number;
        operator = _operator;
        dynamicRewards = _dynamicRewards;
        manager = _manager;
        admin = msg.sender;

        HashEIP712Name = keccak256(bytes(name));
        HashEIP712Version = keccak256(bytes(version));
    }


    modifier onlyAdmin() {
        require(msg.sender == admin ,"user is not admin");
        _;
    }


    function setHalvingPeriod(uint256 _block) public onlyAdmin {
        halvingPeriod = _block;
    }

    function setPair(address _pair) public onlyAdmin {
        pair = _pair;
    }

    function setStartBlock(uint256 blockNumber) public onlyAdmin{
        startBlock = blockNumber;
    }


    function poolLength() public view returns (uint256) {
        return poolInfo.length;
    }


    function setPause() public onlyAdmin {
        paused = !paused;
        if(paused == true){
            startBlock = block.number;
        }
    }

    function invite(address inviter) public {
        require(inviteList[msg.sender]== false,"inviter is exist");

        require((inviter == dynamicRewards && !inviteList[msg.sender]) || (inviteList[inviter] && !inviteList[msg.sender]),"inviter is invalid");
        inviteMapping[msg.sender]=inviter;

        inviteList[msg.sender]=true;
        emit Invite(inviter,msg.sender);
    }

    // pid = 1need USDT,
    // pid = 2 need BTC
    function add(IERC20 _token,uint256 _hashRate, bool _withUpdate) public onlyAdmin {
        require(address(_token) != address(0), "_token is the zero address");
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardBlock = block.number > startBlock ? block.number : startBlock;
        poolInfo.push(PoolInfo({
            token : _token,
            hashRate : _hashRate,
            lastRewardBlock : lastRewardBlock,
            accBtcPerShare : 0,
            totalAmount : 0
            }));
        LpOfPid[address(_token)] = poolLength() - 1;
    }

    function mintblock(uint256 blockNumber,uint256 rewards) public onlyAdmin{
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
        uint256 btcTotalSupply = btc.totalSupply();
        emit ExsitBtc(block.number,btcTotalSupply);
        emit Mintblock(blockNumber,rewards);
    }

    function phase(uint256 blockNumber) public view returns (uint256) {
        if (halvingPeriod == 0) {
            return 0;
        }
        if (blockNumber > startBlock) {
            return (blockNumber.sub(startBlock).sub(1)).div(halvingPeriod);
        }
        return 0;
    }

    function reward(uint256 blockNumber) public view returns (uint256) {
        uint256 _phase = phase(blockNumber);
        return btcPerBlock.div(2 ** _phase);
    }

    function getBtcBlockReward(uint256 _lastRewardBlock) public view returns (uint256) {
        uint256 blockReward = 0;
        uint256 n = phase(_lastRewardBlock);
        uint256 m = phase(block.number);
        while (n < m) {
            n++;
            uint256 r = n.mul(halvingPeriod).add(startBlock);
            blockReward = blockReward.add((r.sub(_lastRewardBlock)).mul(reward(r)));
            _lastRewardBlock = r;
        }
        blockReward = blockReward.add((block.number.sub(_lastRewardBlock)).mul(reward(block.number)));
        return blockReward;
    }

    // Update reward variables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; pid++) {
            updatePool(pid);
        }
        uint256 btcTotalSupply = btc.totalSupply();
        emit ExsitBtc(block.number,btcTotalSupply);
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        //uint256 lpSupply = pool.token.balanceOf(address(this));
        uint256 lpSupply = pool.totalAmount;
        if (lpSupply == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 blockReward = getBtcBlockReward(pool.lastRewardBlock);
        if (blockReward <= 0) {
            return;
        }
        uint256 btcReward = blockReward.mul(pidOfHash(_pid)).div(totalHash());
        bool minRet = btc.mint(address(this), btcReward);
        if (minRet) {
            pool.accBtcPerShare = pool.accBtcPerShare.add(btcReward.mul(1e12).div(lpSupply));
        }
        pool.lastRewardBlock = block.number;
    }

    function pidOfHash(uint256 _pid) public view returns(uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        return pool.totalAmount.mul(pool.hashRate).div(1e17);
    }

    function userTotalHash(address user) public view returns(uint256){
        uint256 totalHashs = 0;
        for(uint256 i = 0;i <= poolLength()-1;i++){
            UserInfo storage userInfo = userInfo[i][user];
            PoolInfo storage poolId = poolInfo[i];
            totalHashs = totalHashs.add(userInfo.amount.mul(poolId.hashRate).div(1e17));
        }
        return totalHashs;
    }

    function totalHash() public view returns(uint256){
        uint256 totalHashs = 0;
        for(uint256 i = 0;i <= poolLength()-1;i++){
            PoolInfo storage poolId = poolInfo[i];
            totalHashs = totalHashs.add(poolId.totalAmount.mul(poolId.hashRate).div(1e17));
        }
        return totalHashs;
    }

    function pendingRewards(address _user) external view returns (uint256, uint256){
        uint256 totalAmount = 0;
        for(uint256 i=0;i<2;i++){
            uint256 userAmount = pendingBtc(i, _user);
            totalAmount+=userAmount;
        }
        return (totalAmount, 0);
    }

    function claim() public {
        massUpdatePools();
        for(uint256 i = 0;i < poolLength();i++){
            UserInfo storage user = userInfo[i][msg.sender];
            PoolInfo storage pool = poolInfo[i];
            if (user.amount > 0) {
                uint256 pendingAmount = user.amount.mul(pool.accBtcPerShare).div(1e12).sub(user.rewardDebt);
                if (pendingAmount > 0) {
                    user.receivedRewards = user.receivedRewards.add(pendingAmount);
                    safeBtcTransfer(msg.sender, pendingAmount);
                }
            }
        }
    }


    // View function to see pending BTCs on frontend.
    function pending(uint256 _pid, address _user) external view returns (uint256, uint256){
        uint256 btcAmount = pendingBtc(_pid, _user);
        return (btcAmount, 0);
    }

    function pendingBtc(uint256 _pid, address _user) private view returns (uint256){
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accBtcPerShare = pool.accBtcPerShare;
        uint256 lpSupply = pool.totalAmount;
        if (user.amount > 0) {
            if (block.number > pool.lastRewardBlock) {
                uint256 blockReward = getBtcBlockReward(pool.lastRewardBlock);
                uint256 btcReward = blockReward.mul(pidOfHash(_pid)).div(totalHash());
                accBtcPerShare = accBtcPerShare.add(btcReward.mul(1e12).div(lpSupply));
                return user.amount.mul(accBtcPerShare).div(1e12).sub(user.rewardDebt);
            }
            if (block.number == pool.lastRewardBlock) {
                return user.amount.mul(accBtcPerShare).div(1e12).sub(user.rewardDebt);
            }
        }
        return 0;
    }

    function depositInvalid(uint256 _pid,address _user,uint256 _amount) public onlyAdmin {
        UserInfo storage userInfo = userInfo[_pid][_user];
        userInfo.amount = userInfo.amount.sub(_amount);
        PoolInfo storage pool = poolInfo[_pid];
        pool.totalAmount = pool.totalAmount.sub(_amount);
        emit DepositInvalid(_user,_pid,_amount);
    }

    // Deposit LP tokens to HecoPool for BTC allocation.
    function deposit(uint256 _pid, uint256 _amount) public notPause {
        PoolInfo storage pool = poolInfo[_pid];
        require(inviteMapping[msg.sender]!= address(0),"The user is not invited");
        depositToken(_pid, _amount, msg.sender);
    }


    function allowBtc(address user) public view returns(uint256){
        UserInfo storage usdtUser = userInfo[0][user];
        UserInfo storage btcUser = userInfo[1][user];
        uint256 btcPrice = IBtcitrumPair(pair).price(address(btc),100);
        uint256 allowBalance = usdtUser.amount.mul(30).div(btcPrice).sub(btcUser.amount);
        return allowBalance;
    }

    function depositToken(uint256 _pid, uint256 _amount, address _user) private {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        massUpdatePools();
        if(_pid == 0){
            require(_amount>=1e21 && _amount%1e21==0 ,"deposit usdt amount is invalid");
        }
        if(_pid == 1){
            require(_amount>=1e16 ,"deposit btc amount is invalid");
            uint256 btcPrice = IBtcitrumPair(pair).price(address(btc),100);
            UserInfo storage usdtUser = userInfo[0][_user];
            uint256 allowBalance = usdtUser.amount.mul(30).div(btcPrice);
            require(allowBalance>=_amount,"deposit USDT is too low");
        }

        //auto transfer rewards
        if (user.amount > 0) {
            uint256 pendingAmount = user.amount.mul(pool.accBtcPerShare).div(1e12).sub(user.rewardDebt);
            if (pendingAmount > 0) {
                user.receivedRewards = user.receivedRewards.add(pendingAmount);
                safeBtcTransfer(_user, pendingAmount);
            }
        }
        if (_amount > 0) {
            if(_pid == 0){
                pool.token.safeTransferFrom(_user, operator, _amount.mul(10).div(100));
                pool.token.safeTransferFrom(_user, dynamicRewards, _amount.mul(20).div(100));
                pool.token.safeTransferFrom(_user,manager, _amount.mul(70).div(100));
            }else{
                pool.token.safeTransferFrom(_user, address(this), _amount);
            }
            user.amount = user.amount.add(_amount);
            pool.totalAmount = pool.totalAmount.add(_amount);
        }
        user.rewardDebt = user.amount.mul(pool.accBtcPerShare).div(1e12);
        emit Deposit(_user, _pid, _amount);
    }

    function checkWithdrawReuest(address user,WithdrawRequest memory withdrawRequest,Sig memory withdrawSig) public view returns(bool){
        require(user == withdrawRequest.user, "WithdrawRequest user is not correct user");

        require(withdrawRequest.expirationTime == 0 || withdrawRequest.expirationTime >= block.timestamp,"WithdrawRequest is expiration");

        uint256 currentUserNonce = userNonceMapping[user];
        require(currentUserNonce.add(1) == withdrawRequest.nonce,"User nonce is invalid");

        require(withdrawRequest.verifyingContract == address(this),"withdraw request is invalid");

        bytes memory withdrawRequestBytes = matchWithdrawEIP1155Encode(withdrawRequest);

        bytes32 withdrawRequestDigest = _hashTypedDataV4(keccak256(withdrawRequestBytes));

        require(admin == ecrecover(withdrawRequestDigest,withdrawSig.v,withdrawSig.r,withdrawSig.s),"Signer is invalid");

        return true;
    }

    function withdraw(WithdrawRequest memory withdrawRequest,Sig memory sig) public notPause {
        uint256 _pid = 1;
        address _user = msg.sender;
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];

        bool result = checkWithdrawReuest(msg.sender,withdrawRequest,sig);
        uint256 _amount = withdrawRequest.amount;
        massUpdatePools();

        uint256 pendingAmount = user.amount.mul(pool.accBtcPerShare).div(1e12).sub(user.rewardDebt);
        if (pendingAmount > 0) {
            user.receivedRewards = user.receivedRewards.add(pendingAmount);
            safeBtcTransfer(_user, pendingAmount);
        }
        if (_amount > 0) {
            pool.token.safeTransfer(_user, _amount);
        }
        user.rewardDebt = user.amount.mul(pool.accBtcPerShare).div(1e12);
        emit Withdraw(_user, _pid, _amount);
    }

    //后面做到这里增加验签
    function withdrawApply(uint256 amount) public {
        massUpdatePools();
        UserInfo storage userInfo = userInfo[1][msg.sender];
        userInfo.amount = userInfo.amount.sub(amount);
        PoolInfo storage poolInfo = poolInfo[1];
        poolInfo.totalAmount = poolInfo.totalAmount.sub(amount);
        emit WithdrawApply(msg.sender,1,amount,block.number);
    }


    // Safe BTC transfer function, just in case if rounding error causes pool to not have enough BTCs.
    function safeBtcTransfer(address _to, uint256 _amount) internal {
        uint256 btcBal = btc.balanceOf(address(this));
        if (_amount > btcBal) {
            btc.transfer(_to, btcBal);
        } else {
            btc.transfer(_to, _amount);
        }
    }

    modifier notPause() {
        require(paused == false, "Mining has been suspended");
        _;
    }

    function matchWithdrawEIP1155Encode(WithdrawRequest memory withdrawRequest) internal pure returns(bytes memory) {
        bytes memory withdrawRequestBytes = abi.encode(
            HashOrderStruct,
                withdrawRequest.user,
                withdrawRequest.nonce,
                withdrawRequest.amount,
                withdrawRequest.expirationTime,
                withdrawRequest.verifyingContract
        );
        return withdrawRequestBytes;
    }

    function _hashTypedDataV4(bytes32 structHash) internal view returns (bytes32) {
        // return ECDSAUpgradeable.toTypedDataHash(_domainSeparatorV4(), structHash);
        return _toTypedDataHash(_domainSeparatorV4(), structHash);
    }

    function _toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }

    function _domainSeparatorV4() internal view returns (bytes32) {
        return keccak256(abi.encode(HashEIP712Domain, HashEIP712Name, HashEIP712Version, block.chainid, address(this)));
    }
}