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
pragma solidity ^0.8.6;

import { Lottery, Round, Rule, TicketView, OrderTicket } from "../lib/QulotLotteryStructs.sol";

interface IQulotLottery {
    /**
     * @notice Set the random generator
     * @dev The calls to functions are used to verify the new generator implements them properly.
     * Callable only by the contract owner
     * @param _randomGeneratorAddress: address of the random generator
     * @dev Callable by operator
     */
    function setRandomGenerator(address _randomGeneratorAddress) external;

    /**
     *
     * @notice Add new lottery. Only call when deploying smart contact for the first time
     * @param _lotteryId lottery id
     * @param _lottery lottery data
     * @dev Callable by operator
     */
    function addLottery(string calldata _lotteryId, Lottery calldata _lottery) external;

    /**
     *
     * @notice Update exists lottery
     * @param _lotteryId lottery id
     * @param _lottery lottery data
     * @dev Callable by operator
     */
    function updateLottery(string calldata _lotteryId, Lottery calldata _lottery) external;

    /**
     * @notice Add more rule reward for lottery payout. Only call when deploying smart contact for the first time
     * @param _lotteryId Lottery id
     * @param _rules Rule list of lottery
     */
    function addRewardRules(string calldata _lotteryId, Rule[] calldata _rules) external;

    /**
     *
     * @notice Buy tickets for the multi rounds
     * @param _buyer Address of buyer
     * @param _ordersTicket Round id
     * @dev Callable by users
     */
    function buyTickets(address _buyer, OrderTicket[] calldata _ordersTicket) external;

    /**
     * @notice Claim a set of winning tickets for a lottery
     * @param _ticketIds: array of ticket ids
     * @dev Callable by users only, not contract!
     */
    function claimTickets(uint256[] calldata _ticketIds) external;

    /**
     *
     * @notice Open new round for lottery
     * @param _lotteryId lottery id
     */
    function open(string calldata _lotteryId) external;

    /**
     *
     * @notice Close current round for lottery
     * @param _lotteryId lottery id
     */
    function close(string calldata _lotteryId) external;

    /**
     *
     * @notice Draw round by id
     * @param _lotteryId lottery id
     * @dev Callable by operator
     */
    function draw(string calldata _lotteryId) external;

    /**
     *
     * @notice Reward round by id
     * @param _lotteryId round id
     * @dev Callable by operator
     */
    function reward(string calldata _lotteryId) external;

    /**
     * @notice Return a list of lottery ids
     */
    function getLotteryIds() external view returns (string[] memory lotteryIds);

    /**
     * @notice Return lottery by id
     * @param _lotteryId Id of lottery
     */
    function getLottery(string calldata _lotteryId) external view returns (Lottery memory lottery);

    /**
     * @notice Return a list of round ids
     */
    function getRoundIds() external view returns (uint256[] memory roundIds);

    /**
     * @notice Return round by id
     * @param _roundId Id of round
     */
    function getRound(uint256 _roundId) external view returns (Round memory round);

    /**
     * @notice Return a length of ticket ids
     */
    function getTicketsLength() external view returns (uint256);

    /**
     * @notice Return a length of ticket ids by user address
     */
    function getTicketsByUserLength(address _user) external view returns (uint256);

    /**
     * @notice Return ticket by id
     * @param _ticketId Id of round
     */
    function getTicket(uint256 _ticketId) external view returns (TicketView memory ticket);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

interface IRandomNumberGenerator {
    /**
     *
     * @param _roundId Request id combine lotteryProductId and lotteryroundId
     * @param _numbersOfItems Numbers of items
     * @param _minValuePerItems Min value per items
     * @param _maxValuePerItems Max value per items
     */
    function requestRandomNumbers(
        uint256 _roundId,
        uint32 _numbersOfItems,
        uint32 _minValuePerItems,
        uint32 _maxValuePerItems
    ) external;

    /**
     * @param _roundId Request id combine lotteryProductId and lotteryroundId
     */
    function getRandomResult(uint256 _roundId) external view returns (uint32[] memory);

    /**
     * @notice Set the address for the Qulot
     * @param _qulotLottery: address of the Qulot lottery
     */
    function setQulotLottery(address _qulotLottery) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

enum RoundStatus {
    Open,
    Draw,
    Close,
    Reward
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import { RoundStatus } from "./QulotLotteryEnums.sol";

struct Lottery {
    string verboseName;
    string picture;
    uint32 numberOfItems;
    uint32 minValuePerItem;
    uint32 maxValuePerItem;
    // day of the week (0 - 6) (Sunday-to-Saturday)
    uint[] periodDays;
    // hour (0 - 23)
    uint periodHourOfDays;
    uint32 maxNumberTicketsPerBuy;
    uint256 pricePerTicket;
    uint32 treasuryFeePercent;
    uint32 amountInjectNextRoundPercent;
    uint32 discountPercent;
}

struct Round {
    string lotteryId;
    uint32[] winningNumbers;
    uint256 endTime;
    uint256 openTime;
    uint256 totalAmount;
    uint256 totalTickets;
    uint256 firstRoundId;
    RoundStatus status;
}

struct RoundView {
    string lotteryId;
    uint32[] winningNumbers;
    uint256 endTime;
    uint256 openTime;
    uint256 totalAmount;
    uint256 totalTickets;
    uint256 firstRoundId;
    RoundStatus status;
}

struct Rule {
    uint matchNumber;
    uint256 rewardValue;
}

struct Ticket {
    uint256 ticketId;
    uint32[] numbers;
    address owner;
    uint256 roundId;
    bool clamStatus;
    mapping(uint32 => bool) contains;
}

struct TicketView {
    uint256 ticketId;
    uint32[] numbers;
    address owner;
    uint256 roundId;
    bool winStatus;
    uint winRewardRule;
    uint256 winAmount;
    bool clamStatus;
}

struct OrderTicket {
    uint256 roundId;
    uint32[][] tickets;
}

struct OrderTicketResult {
    uint256 orderId;
    uint256 roundId;
    uint256[] ticketIds;
    uint256 orderAmount;
    uint256 timestamp;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import { Address } from "@openzeppelin/contracts/utils/Address.sol";
import { Counters } from "@openzeppelin/contracts/utils/Counters.sol";
import { SafeMath } from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import { IQulotLottery } from "./interfaces/IQulotLottery.sol";
import { IRandomNumberGenerator } from "./interfaces/IRandomNumberGenerator.sol";
import { RoundStatus } from "./lib/QulotLotteryEnums.sol";
import { String } from "./utils/StringUtils.sol";
import { Subsets } from "./utils/Subsets.sol";
import { Sort } from "./utils/Sort.sol";
import {
    Lottery,
    Round,
    Ticket,
    Rule,
    OrderTicket,
    OrderTicketResult,
    TicketView
} from "./lib/QulotLotteryStructs.sol";

contract QulotLottery is ReentrancyGuard, IQulotLottery, Ownable {
    using SafeERC20 for IERC20;
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    event MultiRoundsTicketsPurchase(address indexed buyer, OrderTicketResult[] ordersResult);
    event TicketsClaim(address indexed claimer, uint256 amount, uint256[] ticketIds);
    event NewLottery(string lotteryId, Lottery lottery);
    event ModifiedLottery(string lotteryId, Lottery lottery);
    event NewRewardRule(uint ruleIndex, string lotteryId, Rule rule);
    event RoundOpen(uint256 roundId, string lotteryId, uint256 totalAmount, uint256 startTime, uint256 firstRoundId);
    event RoundClose(uint256 roundId, uint256 totalAmount, uint256 totalTickets);
    event RoundDraw(uint256 roundId, uint32[] numbers);
    event RoundReward(uint256 roundId, uint256 amountTreasury, uint256 amountInjectNextRound, uint256 endTime);
    event RoundInjection(uint256 roundId, uint256 injectedAmount);
    event NewRandomGenerator(address randomGeneratorAddress);
    event NewAutomationTrigger(address automationTriggerAddress);
    event AdminTokenRecovery(address token, uint256 amount);

    // Mapping lotteryId to lottery info
    string[] public lotteryIds;
    mapping(string => Lottery) public lotteries;

    // Mapping roundId to round info
    uint256[] public roundIds;
    mapping(uint256 => Round) public rounds;
    mapping(uint256 => mapping(uint => uint256)) public roundRewardsBreakdown;
    mapping(uint256 => mapping(bytes32 => uint32)) private roundTicketsSubsetCounter;

    // Mapping ticketId to ticket info
    uint256[] public ticketIds;
    mapping(uint256 => Ticket) public tickets;

    // Keep track of user ticket ids for a given roundId
    mapping(address => uint256[]) public ticketsPerUserId;
    mapping(uint256 => uint256[]) public ticketsPerRoundId;

    mapping(string => uint256) public currentRoundIdPerLottery;
    mapping(string => uint256) public amountInjectNextRoundPerLottery;

    // Mapping reward rule to lottery id
    mapping(string => mapping(uint => Rule)) public rulesPerLotteryId;
    mapping(string => uint) private limitSubsetPerLottery;

    // Mapping order result to user
    mapping(address => OrderTicketResult[]) public orderResults;

    // The lottery scheduler account used to run regular operations.
    address public operatorAddress;
    address public treasuryAddress;
    address public triggerAddress;

    IERC20 public immutable token;
    IRandomNumberGenerator public randomGenerator;
    uint256 public bulkTicketsDiscountApply = 3;

    Counters.Counter private counterTicketId;
    Counters.Counter private counterRoundId;
    Counters.Counter private counterOrderId;

    /* solhint-disable avoid-tx-origin */
    modifier notContract() {
        require(!Address.isContract(msg.sender), "ERROR_CONTRACT_NOT_ALLOWED");
        require(msg.sender == tx.origin, "ERROR_PROXY_CONTRACT_NOT_ALLOWED");
        _;
    }
    /* solhint-enable */

    modifier onlyOperator() {
        require(_isOperator(), "ERROR_ONLY_OPERATOR");
        _;
    }

    modifier onlyOperatorOrTrigger() {
        require(_isTrigger() || _isOperator(), "ERROR_ONLY_TRIGGER_OR_OPERATOR");
        _;
    }

    function _isTrigger() internal view returns (bool) {
        return msg.sender == triggerAddress;
    }

    function _isOperator() internal view returns (bool) {
        return msg.sender == operatorAddress;
    }

    constructor(address _tokenAddress) {
        token = IERC20(_tokenAddress);
    }

    function addLottery(string calldata _lotteryId, Lottery calldata _lottery) external override onlyOperator {
        _setLottery(_lotteryId, _lottery);
        lotteryIds.push(_lotteryId);
        emit NewLottery(_lotteryId, _lottery);
    }

    function updateLottery(string calldata _lotteryId, Lottery calldata _lottery) external override onlyOperator {
        _setLottery(_lotteryId, _lottery);
        emit ModifiedLottery(_lotteryId, _lottery);
    }

    function addRewardRules(string calldata _lotteryId, Rule[] calldata _rules) external override onlyOperator {
        _addRewardRules(_lotteryId, _rules);
    }

    function buyTickets(
        address _buyer,
        OrderTicket[] calldata _ordersTicket
    ) external override notContract nonReentrant {
        _buyTickets(_buyer, _ordersTicket);
    }

    function claimTickets(uint256[] calldata _ticketIds) external override notContract nonReentrant {
        _claimTickets(_ticketIds);
    }

    function open(string calldata _lotteryId) external override onlyOperatorOrTrigger {
        _open(_lotteryId);
    }

    function close(string calldata _lotteryId) external override onlyOperatorOrTrigger {
        _close(_lotteryId);
    }

    function draw(string calldata _lotteryId) external override onlyOperatorOrTrigger {
        _draw(_lotteryId);
    }

    function reward(string calldata _lotteryId) external override onlyOperatorOrTrigger {
        _reward(_lotteryId);
    }

    function injectFunds(uint256 _roundId, uint256 _amount) external onlyOwner {
        require(rounds[_roundId].status == RoundStatus.Open, "ERROR_ROUND_NOT_OPEN");
        token.safeTransferFrom(address(msg.sender), address(this), _amount);
        rounds[_roundId].totalAmount += _amount;
        emit RoundInjection(_roundId, _amount);
    }

    function recoverWrongTokens(address _tokenAddress, uint256 _tokenAmount) external onlyOwner {
        require(_tokenAddress != address(token), "ERROR_WRONG_TOKEN_ADDRESS");
        IERC20(_tokenAddress).safeTransfer(address(msg.sender), _tokenAmount);
        emit AdminTokenRecovery(_tokenAddress, _tokenAmount);
    }

    function setRandomGenerator(address _randomGeneratorAddress) external override onlyOwner {
        randomGenerator = IRandomNumberGenerator(_randomGeneratorAddress);
        emit NewRandomGenerator(_randomGeneratorAddress);
    }

    function setOperatorTreasuryAddress(address _operatorAddress, address _treasuryAddress) external onlyOwner {
        require(_operatorAddress != address(0) && _treasuryAddress != address(0), "ERROR_INVALID_ZERO_ADDRESS");
        operatorAddress = _operatorAddress;
        treasuryAddress = _treasuryAddress;
    }

    function setTriggerAddress(address _triggerAddress) external onlyOwner {
        require(_triggerAddress != address(0), "ERROR_INVALID_ZERO_ADDRESS");
        triggerAddress = _triggerAddress;
        emit NewAutomationTrigger(_triggerAddress);
    }

    function setBulkTicketsDiscountApply(uint256 _numberOfTicket) external onlyOperator {
        bulkTicketsDiscountApply = _numberOfTicket;
    }

    function getLotteryIds() external view override returns (string[] memory) {
        return lotteryIds;
    }

    function getLottery(string calldata _lotteryId) external view override returns (Lottery memory) {
        return lotteries[_lotteryId];
    }

    function getRoundIds() external view override returns (uint256[] memory) {
        return roundIds;
    }

    function getRound(uint256 _roundId) external view override returns (Round memory) {
        return rounds[_roundId];
    }

    function getTicketsLength() external view override returns (uint256) {
        return ticketIds.length;
    }

    function getTicketsByUserLength(address _user) external view override returns (uint256) {
        return ticketsPerUserId[_user].length;
    }

    function getTicket(uint256 _ticketId) external view override returns (TicketView memory ticketResult) {
        (bool isWin, uint winRewardRule, uint256 winAmount) = _checkWinTicket(_ticketId);
        ticketResult = TicketView({
            ticketId: tickets[_ticketId].ticketId,
            numbers: tickets[_ticketId].numbers,
            owner: tickets[_ticketId].owner,
            roundId: tickets[_ticketId].roundId,
            winStatus: isWin,
            winRewardRule: winRewardRule,
            winAmount: winAmount,
            clamStatus: tickets[_ticketId].clamStatus
        });
    }

    function caculateAmountForBulkTickets(
        uint256 _roundId,
        uint256 _numberTickets
    ) external view returns (uint256 totalAmount, uint256 finalAmount, uint256 discount) {
        string storage lotteryId = rounds[_roundId].lotteryId;
        totalAmount = lotteries[lotteryId].pricePerTicket * _numberTickets;
        finalAmount = _caculateTotalPriceForBulkTickets(lotteryId, _numberTickets);
        discount = ((totalAmount.sub(finalAmount)).mul(100)).div(totalAmount);
    }

    function _setLottery(string calldata _lotteryId, Lottery calldata _lottery) internal {
        require(!String.isEmpty(_lotteryId), "ERROR_INVALID_LOTTERY_ID");
        require(!String.isEmpty(_lottery.picture), "ERROR_INVALID_LOTTERY_PICTURE");
        require(!String.isEmpty(_lottery.verboseName), "ERROR_INVALID_LOTTERY_VERBOSE_NAME");
        require(_lottery.numberOfItems > 0 && _lottery.numberOfItems <= 6, "ERROR_INVALID_LOTTERY_NUMBER_OF_ITEMS");
        require(_lottery.minValuePerItem > 0, "ERROR_INVALID_LOTTERY_MIN_VALUE_PER_ITEMS");
        require(
            _lottery.maxValuePerItem > 0 && _lottery.maxValuePerItem < type(uint32).max,
            "ERROR_INVALID_LOTTERY_MAX_VALUE_PER_ITEMS"
        );
        require(_lottery.periodDays.length > 0, "ERROR_INVALID_LOTTERY_PERIOD_DAYS");
        require(
            _lottery.periodHourOfDays > 0 && _lottery.periodHourOfDays <= 24,
            "ERROR_INVALID_LOTTERY_PERIOD_HOUR_OF_DAYS"
        );
        require(
            _lottery.maxNumberTicketsPerBuy > 0 && _lottery.maxNumberTicketsPerBuy < type(uint32).max,
            "ERROR_INVALID_LOTTERY_MAX_NUMBER_TICKETS_PER_BUY"
        );
        require(_lottery.pricePerTicket > 0, "ERROR_INVALID_LOTTERY_PRICE_PER_TICKET");
        require(
            _lottery.treasuryFeePercent >= 0 && _lottery.treasuryFeePercent <= 100,
            "ERROR_INVALID_LOTTERY_TREASURY_FEE_PERCENT"
        );
        require(
            _lottery.discountPercent >= 0 && _lottery.discountPercent <= 100,
            "ERROR_INVALID_LOTTERY_DISCOUNT_PERCENT"
        );

        lotteries[_lotteryId] = _lottery;
    }

    function _addRewardRules(string calldata _lotteryId, Rule[] calldata _rules) internal {
        require(_rules.length > 0, "ERROR_INVALID_RULES");

        uint limitSubset = lotteries[_lotteryId].numberOfItems > 1 ? lotteries[_lotteryId].numberOfItems - 1 : 0;
        for (uint i; i < _rules.length; i++) {
            Rule calldata rule = _rules[i];
            require(rule.matchNumber > 0 && rule.rewardValue > 0, "ERROR_INVALID_RULE");
            rulesPerLotteryId[_lotteryId][rule.matchNumber] = rule;
            if (limitSubset > rule.matchNumber - 1) {
                limitSubset = rule.matchNumber - 1;
            }
            emit NewRewardRule(rule.matchNumber, _lotteryId, rule);
        }

        limitSubsetPerLottery[_lotteryId] = limitSubset;
    }

    function _open(string calldata _lotteryId) internal {
        uint256 currentRoundId = currentRoundIdPerLottery[_lotteryId];
        if (_isTrigger()) {
            require(
                ((currentRoundId == 0) || (rounds[currentRoundId].status == RoundStatus.Reward)),
                "ERROR_NOT_TIME_OPEN_LOTTERY"
            );
        }
        // Increment current round id of lottery to one
        counterRoundId.increment();
        uint256 nextRoundId = counterRoundId.current();
        // Keep track lottery id and round id
        require(nextRoundId > currentRoundIdPerLottery[_lotteryId], "ERROR_ROUND_ID_LESS_THAN_CURRENT");
        currentRoundIdPerLottery[_lotteryId] = nextRoundId;
        // Create new round
        uint256 totalAmount = amountInjectNextRoundPerLottery[_lotteryId];
        Round storage round = rounds[nextRoundId];
        round.lotteryId = _lotteryId;
        round.firstRoundId = currentRoundId;
        round.winningNumbers = new uint32[](lotteries[_lotteryId].numberOfItems);
        round.openTime = block.timestamp;
        round.totalAmount = totalAmount;
        round.status = RoundStatus.Open;

        roundIds.push(nextRoundId);
        // Reset amount injection for next round
        amountInjectNextRoundPerLottery[_lotteryId] = 0;
        // Emit round open
        emit RoundOpen(nextRoundId, _lotteryId, totalAmount, block.timestamp, currentRoundId);
    }

    function _close(string calldata _lotteryId) internal {
        uint256 currentRoundId = currentRoundIdPerLottery[_lotteryId];
        if (_isTrigger()) {
            require(
                (currentRoundId != 0) && rounds[currentRoundId].status == RoundStatus.Open,
                "ERROR_NOT_TIME_CLOSE_LOTTERY"
            );
        }
        rounds[currentRoundId].status = RoundStatus.Close;
        // Request new random number
        Lottery storage lottery = lotteries[_lotteryId];
        randomGenerator.requestRandomNumbers(
            currentRoundId,
            lottery.numberOfItems,
            lottery.minValuePerItem,
            lottery.maxValuePerItem
        );
        // Emit round close
        emit RoundClose(currentRoundId, rounds[currentRoundId].totalAmount, rounds[currentRoundId].totalTickets);
    }

    function _draw(string calldata _lotteryId) internal {
        uint256 currentRoundId = currentRoundIdPerLottery[_lotteryId];
        if (_isTrigger()) {
            require(
                (currentRoundId != 0) && rounds[currentRoundId].status == RoundStatus.Close,
                "ERROR_NOT_TIME_DRAW_LOTTERY"
            );
        }
        // get randomResult generated by ChainLink's fallback
        uint32[] memory winningNumbers = randomGenerator.getRandomResult(currentRoundId);
        // check winning numbers is valid or not
        require(_isValidNumbers(winningNumbers, _lotteryId), "ERROR_INVALID_WINNING_NUMBERS");
        Sort.quickSort(winningNumbers, 0, winningNumbers.length - 1);
        rounds[currentRoundId].status = RoundStatus.Draw;
        rounds[currentRoundId].winningNumbers = winningNumbers;
        // Emit round Draw
        emit RoundDraw(currentRoundIdPerLottery[_lotteryId], winningNumbers);
    }

    function _reward(string calldata _lotteryId) internal {
        uint256 currentRoundId = currentRoundIdPerLottery[_lotteryId];
        Round storage round = rounds[currentRoundId];
        if (_isTrigger()) {
            require((currentRoundId != 0) && round.status == RoundStatus.Draw, "ERROR_NOT_TIME_REWARD_LOTTERY");
        }
        // Set round status to reward
        round.status = RoundStatus.Reward;
        round.endTime = block.timestamp;
        // Estimate
        (uint256 amountTreasury, uint256 amountInject, uint256 rewardAmount) = _estimateReward(
            _lotteryId,
            currentRoundId
        );

        uint256 outRewardValue = _calcluateRewardsBreakdown(_lotteryId, currentRoundId, rewardAmount);

        amountInject += outRewardValue;
        amountInjectNextRoundPerLottery[_lotteryId] = amountInject;
        // Transfer token to treasury address
        token.safeTransfer(treasuryAddress, amountTreasury);
        // Emit round Draw
        emit RoundReward(currentRoundId, amountTreasury, amountInject, block.timestamp);
    }

    function _buyTickets(address _buyer, OrderTicket[] calldata _ordersTicket) internal {
        // check list tickets is emptyidx
        require(_ordersTicket.length != 0, "ERROR_TICKETS_EMPTY");
        OrderTicketResult[] memory ordersResult = new OrderTicketResult[](_ordersTicket.length);
        // calculate total price to pay to this contract
        uint256 amountToTransfer;
        OrderTicketResult memory orderTicketResult;
        for (uint orderIdx; orderIdx < _ordersTicket.length; ) {
            orderTicketResult = _processOrder(_buyer, _ordersTicket[orderIdx]);
            amountToTransfer += orderTicketResult.orderAmount;
            ordersResult[orderIdx] = orderTicketResult;
            unchecked {
                orderIdx++;
            }
        }
        // transfer tokens to this contract
        token.safeTransferFrom(address(msg.sender), address(this), amountToTransfer);
        emit MultiRoundsTicketsPurchase(_buyer, ordersResult);
    }

    function _claimTickets(uint256[] calldata _ticketIds) internal {
        require(_ticketIds.length != 0, "ERROR_TICKETS_EMPTY");
        // Initializes the rewardAmountToTransfer
        uint256 rewardAmountToTransfer;
        Ticket storage ticket;
        for (uint i; i < _ticketIds.length; ) {
            // Check ticket valid to claim reward
            ticket = tickets[_ticketIds[i]];
            require(ticket.owner == msg.sender, "ERROR_ONLY_OWNER");

            (bool isWin, , uint256 winAmount) = _checkWinTicket(_ticketIds[i]);
            require(isWin, "ERROR_TICKET_NOT_WIN");
            require(!ticket.clamStatus, "ERROR_ONLY_CLAIM_PRIZE_ONCE");

            // Set claim status to true value
            ticket.clamStatus = true;

            rewardAmountToTransfer += winAmount;
            unchecked {
                i++;
            }
        }
        // Transfer money to msg.sender
        token.safeTransfer(msg.sender, rewardAmountToTransfer);
        emit TicketsClaim(msg.sender, rewardAmountToTransfer, _ticketIds);
    }

    function _calcluateRewardsBreakdown(
        string calldata _lotteryId,
        uint256 _roundId,
        uint256 rewardAmount
    ) internal returns (uint256 outRewardValue) {
        outRewardValue = rewardAmount;

        Round storage round = rounds[_roundId];
        Lottery storage lottery = lotteries[_lotteryId];
        Subsets.Result[] memory subsets = Subsets.getHashSubsets(
            round.winningNumbers,
            limitSubsetPerLottery[_lotteryId]
        );

        uint32[] memory winnersPerRule = new uint32[](lottery.numberOfItems + 1);
        for (uint i; i < subsets.length; ) {
            uint subsetLength = subsets[i].length;
            if (
                roundTicketsSubsetCounter[_roundId][subsets[i].hash] > 0 &&
                rulesPerLotteryId[_lotteryId][subsetLength].rewardValue > 0
            ) {
                winnersPerRule[subsetLength] += roundTicketsSubsetCounter[_roundId][subsets[i].hash];
            }
            unchecked {
                i++;
            }
        }

        uint32 subsetRepeat = winnersPerRule[lottery.numberOfItems] * lottery.numberOfItems;
        for (uint i; i < (winnersPerRule.length - 1); ) {
            if (winnersPerRule[i] >= subsetRepeat) {
                winnersPerRule[i] -= subsetRepeat;
            }
            unchecked {
                i++;
            }
        }

        for (uint ruleIndex; ruleIndex < winnersPerRule.length; ) {
            uint winnerPerRule = winnersPerRule[ruleIndex];
            if (winnerPerRule > 0) {
                uint256 rewardAmountPerRule = _percentageOf(
                    rewardAmount,
                    rulesPerLotteryId[_lotteryId][ruleIndex].rewardValue
                );

                outRewardValue -= rewardAmountPerRule;
                roundRewardsBreakdown[_roundId][ruleIndex] = rewardAmountPerRule.div(winnerPerRule);
            }

            unchecked {
                ruleIndex++;
            }
        }
    }

    function _processOrder(
        address _buyer,
        OrderTicket calldata _order
    ) internal returns (OrderTicketResult memory orderResult) {
        // check list tickets is emptyidx
        require(_order.tickets.length != 0, "ERROR_TICKETS_EMPTY");
        // check round is open
        require(rounds[_order.roundId].status == RoundStatus.Open, "ERROR_ROUND_IS_CLOSED");
        // check limit ticket
        string storage lotteryId = rounds[_order.roundId].lotteryId;
        require(_order.tickets.length <= lotteries[lotteryId].maxNumberTicketsPerBuy, "ERROR_TICKETS_LIMIT");
        // calculate total price to pay to this contract
        uint256 amountToTransfer = _caculateTotalPriceForBulkTickets(lotteryId, _order.tickets.length);
        // increment the total amount collected for the round
        rounds[_order.roundId].totalAmount += amountToTransfer;
        rounds[_order.roundId].totalTickets += _order.tickets.length;
        uint256[] memory purchasedTicketIds = new uint256[](_order.tickets.length);
        for (uint i; i < _order.tickets.length; ) {
            purchasedTicketIds[i] = _processOrderTicket(_buyer, _order.tickets[i], _order.roundId);
            unchecked {
                i++;
            }
        }
        counterOrderId.increment();
        orderResult = OrderTicketResult({
            orderId: counterOrderId.current(),
            roundId: _order.roundId,
            ticketIds: purchasedTicketIds,
            orderAmount: amountToTransfer,
            timestamp: block.timestamp
        });
        orderResults[_buyer].push(orderResult);
    }

    function _processOrderTicket(
        address _buyer,
        uint32[] calldata _ticketNumbers,
        uint256 _roundId
    ) internal returns (uint256) {
        // Check valid ticket numbers
        require(_isValidNumbers(_ticketNumbers, rounds[_roundId].lotteryId), "ERROR_INVALID_TICKET");

        // Increment lottery ticket number
        counterTicketId.increment();
        uint256 newTicketId = counterTicketId.current();

        // Set new ticket to mapping with storage
        Ticket storage ticket = tickets[newTicketId];
        ticket.ticketId = newTicketId;
        ticket.owner = _buyer;
        ticket.roundId = _roundId;
        ticket.numbers = _ticketNumbers;

        Subsets.Result[] memory ticketSubsets = Subsets.getHashSubsets(
            ticket.numbers,
            limitSubsetPerLottery[rounds[_roundId].lotteryId]
        );
        for (uint i; i < ticketSubsets.length; ) {
            roundTicketsSubsetCounter[ticket.roundId][ticketSubsets[i].hash]++;
            unchecked {
                i++;
            }
        }
        for (uint i; i < _ticketNumbers.length; ) {
            ticket.contains[_ticketNumbers[i]] = true;
            unchecked {
                i++;
            }
        }
        ticketIds.push(newTicketId);
        ticketsPerUserId[_buyer].push(newTicketId);
        ticketsPerRoundId[_roundId].push(newTicketId);
        return newTicketId;
    }

    function _estimateReward(
        string calldata _lotteryId,
        uint256 _roundId
    ) internal view returns (uint256 treasuryAmount, uint256 injectAmount, uint256 rewardAmount) {
        treasuryAmount = _percentageOf(rounds[_roundId].totalAmount, lotteries[_lotteryId].treasuryFeePercent);
        injectAmount = _percentageOf(rounds[_roundId].totalAmount, lotteries[_lotteryId].amountInjectNextRoundPercent);
        rewardAmount = rounds[_roundId].totalAmount.sub(treasuryAmount).sub(injectAmount);
    }

    function _isValidNumbers(uint32[] memory _numbers, string memory _lotteryId) internal view returns (bool) {
        Lottery storage lottery = lotteries[_lotteryId];
        if (_numbers.length != lottery.numberOfItems) {
            return false;
        }
        uint numberLength = _numbers.length;
        for (uint i; i < numberLength; ) {
            if (_numbers[i] < lottery.minValuePerItem || _numbers[i] > lottery.maxValuePerItem) {
                return false;
            }
            unchecked {
                i++;
            }
        }
        return true;
    }

    function _caculateTotalPriceForBulkTickets(
        string memory _lotteryId,
        uint256 _numberTickets
    ) internal view returns (uint256) {
        uint256 totalPrice = lotteries[_lotteryId].pricePerTicket * _numberTickets;
        if (_numberTickets > bulkTicketsDiscountApply) {
            uint256 totalPriceDiscount = totalPrice - _percentageOf(totalPrice, lotteries[_lotteryId].discountPercent);
            return totalPriceDiscount;
        }
        return totalPrice;
    }

    function _checkWinTicket(
        uint256 _ticketId
    ) internal view returns (bool isWin, uint winRewardRule, uint256 winAmount) {
        Ticket storage ticket = tickets[_ticketId];
        Round storage round = rounds[ticket.roundId];

        // Just check ticket when round status is reward
        if (round.status == RoundStatus.Reward) {
            // Check if this ticket is eligible to win or not
            uint matchedNumbers;
            uint winingNumbersLength = round.winningNumbers.length;
            for (uint i; i < winingNumbersLength; ) {
                if (ticket.contains[round.winningNumbers[i]]) {
                    matchedNumbers++;
                }
                unchecked {
                    i++;
                }
            }

            if (matchedNumbers > 0) {
                Rule storage rule = rulesPerLotteryId[round.lotteryId][matchedNumbers];
                if (rule.rewardValue > 0) {
                    isWin = true;
                    winRewardRule = matchedNumbers;
                    winAmount = roundRewardsBreakdown[ticket.roundId][winRewardRule];
                }
            }
        }
    }

    function _calculateTreasuryFee(string memory _lotteryId, uint256 _roundId) internal view returns (uint256) {
        return _percentageOf(rounds[_roundId].totalAmount, lotteries[_lotteryId].treasuryFeePercent);
    }

    function _percentageOf(uint256 amount, uint256 percent) internal pure returns (uint256) {
        require(percent >= 0 && percent <= 100, "INVALID_PERCENT_VALUE");
        return (amount.mul(percent)).div(100);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

library Sort {
    function quickSort(uint32[] memory arr, uint left, uint right) internal pure {
        if (left >= right) return;
        uint32 p = arr[(left + right) / 2]; // p = the pivot element
        uint i = left;
        uint j = right;
        while (i < j) {
            while (arr[i] < p) ++i;
            while (arr[j] > p) --j; // arr[j] > p means p still to the left, so j > 0
            if (arr[i] > arr[j]) (arr[i], arr[j]) = (arr[j], arr[i]);
            else ++i;
        }

        // Note --j was only done when a[j] > p.  So we know: a[j] == p, a[<j] <= p, a[>j] > p
        if (j > left) quickSort(arr, left, j - 1); // j > left, so j > 0
        quickSort(arr, j + 1, right);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

library String {
    /**
     * @notice Check string is empty or not
     * @param _str String
     */
    function isEmpty(string memory _str) internal pure returns (bool) {
        return bytes(_str).length == 0;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import { Sort } from "./Sort.sol";

library Subsets {
    struct Result {
        bytes32 hash;
        uint length;
    }

    function getHashSubsets(uint32[] memory array, uint limit) internal pure returns (Result[] memory results) {
        uint arrayLength = array.length;
        uint subsetCount = 2 ** arrayLength;
        results = new Result[](subsetCount);

        for (uint i; i < subsetCount; ) {
            uint length;
            uint32[] memory subsetItem = new uint32[](arrayLength);
            for (uint32 j; j < arrayLength; ) {
                if ((i & (1 << j)) > 0) {
                    subsetItem[j] = array[j];
                    length++;
                }
                unchecked {
                    j++;
                }
            }

            if (length > limit) {
                Sort.quickSort(subsetItem, 0, subsetItem.length - 1);
                bytes32 hashSubset = hash(subsetItem);
                results[i] = Result({ hash: hashSubset, length: length });
            }

            unchecked {
                i++;
            }
        }
    }

    function hash(uint32[] memory _array) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_array));
    }
}