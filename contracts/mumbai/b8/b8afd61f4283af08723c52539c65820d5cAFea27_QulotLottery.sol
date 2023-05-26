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

import { RewardUnit } from "../lib/QulotLotteryEnums.sol";
import { Lottery, Round, Ticket } from "../lib/QulotLotteryStructs.sol";

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
     * @param _lottery lottery id
     * @dev Callable by operator
     */
    function addLottery(string calldata _lotteryId, Lottery calldata _lottery) external;

    /**
     * @notice Add more rule reward for lottery payout. Only call when deploying smart contact for the first time
     * @param _lotteryId Lottery id
     * @param _matchNumbers Number match
     * @param _rewardUnits Reward unit
     * @param _rewardValues Reward value per unit
     * @dev Callable by operator
     */
    function addRewardRules(
        string calldata _lotteryId,
        uint32[] calldata _matchNumbers,
        RewardUnit[] calldata _rewardUnits,
        uint256[] calldata _rewardValues
    ) external;

    /**
     *
     * @notice Buy tickets for the current round
     * @param _roundId Rround id
     * @param _tickets array of ticket
     * @dev Callable by users
     */
    function buyTickets(uint256 _roundId, uint32[][] calldata _tickets) external;

    /**
     *
     * @notice Buy tickets for the multi rounds
     * @param _roundIds Rround id
     * @param _tickets array of ticket
     * @dev Callable by users
     */
    function buyTicketsMultiRounds(uint256[] calldata _roundIds, uint32[][] calldata _tickets) external;

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
     * @notice Return a length of ticket ids by user address
     */
    function getTicketIdsByUserLength(address _user) external view returns (uint256);

    /**
     * @notice Return a list of ticket ids by user address
     * @param _user: user address
     * @param _cursor: cursor to start where to retrieve the tickets
     * @param _size: the number of tickets to retrieve
     * @param _asc: get list order by ascending
     */
    function getTicketIdsByUser(
        address _user,
        uint256 _cursor,
        uint256 _size,
        bool _asc
    ) external view returns (uint256[] memory ticketIds, uint256 cursor);

    /**
     * @notice Return ticket by id
     * @param _ticketId Id of round
     */
    function getTicket(uint256 _ticketId) external view returns (Ticket memory ticket);
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

enum RewardUnit {
    Percent,
    Fixed
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import { RoundStatus, RewardUnit } from "./QulotLotteryEnums.sol";

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
    uint32[] winningNumbers;
    uint256 endTime;
    uint256 openTime;
    uint256 totalAmount;
    uint256 totalTickets;
    uint256 firstRoundId;
    RoundStatus status;
}

struct Rule {
    uint32 matchNumber;
    RewardUnit rewardUnit;
    uint256 rewardValue;
}

struct Ticket {
    uint32[] numbers;
    address owner;
    uint256 roundId;
    bool winStatus;
    uint winRewardRule;
    uint256 winAmount;
    bool clamStatus;
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
import { RoundStatus, RewardUnit } from "./lib/QulotLotteryEnums.sol";
import { String } from "./utils/StringUtils.sol";
import { Lottery, Round, Ticket, Rule } from "./lib/QulotLotteryStructs.sol";

string constant ERROR_CONTRACT_NOT_ALLOWED = "ERROR_CONTRACT_NOT_ALLOWED";
string constant ERROR_PROXY_CONTRACT_NOT_ALLOWED = "ERROR_PROXY_CONTRACT_NOT_ALLOWED";
string constant ERROR_ONLY_OPERATOR = "ERROR_ONLY_OPERATOR";
string constant ERROR_ONLY_TRIGGER_OR_OPERATOR = "ERROR_ONLY_TRIGGER_OR_OPERATOR";
string constant ERROR_ROUND_IS_CLOSED = "ERROR_ROUND_IS_CLOSED";
string constant ERROR_ROUND_NOT_OPEN = "ERROR_ROUND_NOT_OPEN";
string constant ERROR_TICKETS_LIMIT = "ERROR_TICKETS_LIMIT";
string constant ERROR_TICKETS_EMPTY = "ERROR_TICKETS_EMPTY";
string constant ERROR_INVALID_TICKET = "ERROR_INVALID_TICKET";
string constant ERROR_INVALID_ZERO_ADDRESS = "ERROR_INVALID_ZERO_ADDRESS";
string constant ERROR_INVALID_TICKETS_LENGTH_EQUALS_ROUNDS = "ERROR_INVALID_TICKETS_LENGTH_EQUALS_ROUNDS";
string constant ERROR_NOT_TIME_DRAW_LOTTERY = "ERROR_NOT_TIME_DRAW_LOTTERY";
string constant ERROR_NOT_TIME_OPEN_LOTTERY = "ERROR_NOT_TIME_OPEN_LOTTERY";
string constant ERROR_NOT_TIME_CLOSE_LOTTERY = "ERROR_NOT_TIME_CLOSE_LOTTERY";
string constant ERROR_NOT_TIME_REWARD_LOTTERY = "ERROR_NOT_TIME_REWARD_LOTTERY";
string constant ERROR_NOT_TIME_CLAIM_TICKET = "ERROR_NOT_TIME_CLAIM_TICKET";
string constant ERROR_INVALID_WINNING_NUMBERS = "ERROR_INVALID_WINNING_NUMBERS";
string constant ERROR_INVALID_LOTTERY_ID = "ERROR_INVALID_LOTTERY_ID";
string constant ERROR_INVALID_LOTTERY_VERBOSE_NAME = "ERROR_INVALID_LOTTERY_VERBOSE_NAME";
string constant ERROR_INVALID_LOTTERY_PICTURE = "ERROR_INVALID_LOTTERY_PICTURE";
string constant ERROR_INVALID_LOTTERY_NUMBER_OF_ITEMS = "ERROR_INVALID_LOTTERY_NUMBER_OF_ITEMS";
string constant ERROR_INVALID_LOTTERY_MIN_VALUE_PER_ITEMS = "ERROR_INVALID_LOTTERY_MIN_VALUE_PER_ITEMS";
string constant ERROR_INVALID_LOTTERY_MAX_VALUE_PER_ITEMS = "ERROR_INVALID_LOTTERY_MAX_VALUE_PER_ITEMS";
string constant ERROR_INVALID_LOTTERY_PERIOD_DAYS = "ERROR_INVALID_LOTTERY_PERIOD_DAYS";
string constant ERROR_INVALID_LOTTERY_PERIOD_HOUR_OF_DAYS = "ERROR_INVALID_LOTTERY_PERIOD_HOUR_OF_DAYS";
string constant ERROR_INVALID_LOTTERY_MAX_NUMBER_TICKETS_PER_BUY = "ERROR_INVALID_LOTTERY_MAX_NUMBER_TICKETS_PER_BUY";
string constant ERROR_INVALID_LOTTERY_PRICE_PER_TICKET = "ERROR_INVALID_LOTTERY_PRICE_PER_TICKET";
string constant ERROR_INVALID_LOTTERY_TREASURY_FEE_PERCENT = "ERROR_INVALID_LOTTERY_TREASURY_FEE_PERCENT";
string constant ERROR_INVALID_LOTTERY_DISCOUNT_PERCENT = "ERROR_INVALID_LOTTERY_DISCOUNT_PERCENT";
string constant ERROR_LOTTERY_ALREADY_EXISTS = "ERROR_LOTTERY_ALREADY_EXISTS";
string constant ERROR_INVALID_RULE_REWARD_VALUE = "ERROR_INVALID_RULE_REWARD_VALUE";
string constant ERROR_INVALID_RULE_MATCH_NUMBER = "ERROR_INVALID_RULE_MATCH_NUMBER";
string constant ERROR_INVALID_RULES = "ERROR_INVALID_RULES";
string constant ERROR_INVALID_ROUND_DRAW_TIME = "ERROR_INVALID_ROUND_DRAW_TIME";
string constant ERROR_WRONG_TOKEN_ADDRESS = "ERROR_WRONG_TOKEN_ADDRESS";

contract QulotLottery is ReentrancyGuard, IQulotLottery, Ownable {
    using SafeERC20 for IERC20;
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    /* #region Events */
    event TicketsPurchase(address indexed buyer, uint256 indexed roundId, uint256[] ticketIds, uint256 amount);
    event MultiRoundsTicketsPurchase(
        address indexed buyer,
        uint256[] roundIds,
        uint256[] ticketIds,
        uint256[] ticketPrices
    );
    event TicketsClaim(address indexed claimer, uint256 amount, uint256[] ticketIds);
    event NewLottery(string lotteryId, Lottery lottery);
    event NewRewardRule(
        uint ruleIndex,
        string lotteryId,
        uint32 matchNumber,
        RewardUnit rewardUnit,
        uint256 rewardValue
    );
    event RoundOpen(uint256 roundId, string lotteryId, uint256 totalAmount, uint256 startTime, uint256 firstRoundId);
    event RoundClose(uint256 roundId, uint256 totalAmount, uint256 totalTickets);
    event RoundDraw(uint256 roundId, uint32[] numbers);
    event RoundReward(uint256 roundId, uint256 amountTreasury, uint256 amountInjectNextRound, uint256 endTime);
    event RoundInjection(uint256 roundId, uint256 injectedAmount);
    event NewRandomGenerator(address randomGeneratorAddress);
    event AdminTokenRecovery(address token, uint256 amount);
    /* #endregion */

    /* #region States */
    // Mapping lotteryId to lottery info
    string[] private lotteryIds;
    mapping(string => Lottery) private lotteries;

    // Mapping roundId to round info
    uint256[] private roundIds;
    mapping(uint256 => Round) private rounds;
    // Keep track of lottery id for a given lotteryId
    mapping(uint256 => string) private lotteriesPerRoundId;

    // Mapping ticketId to ticket info
    uint256[] private ticketIds;
    mapping(uint256 => Ticket) private tickets;
    // Keep track of user ticket ids for a given roundId
    mapping(address => uint256[]) private ticketsPerUserId;
    mapping(uint256 => uint256[]) private ticketsPerRoundId;

    mapping(string => uint256) public currentRoundIdPerLottery;
    mapping(string => uint256) public amountInjectNextRoundPerLottery;

    mapping(string => Rule[]) public rulesPerLotteryId;

    // The lottery scheduler account used to run regular operations.
    address public operatorAddress;
    address public treasuryAddress;
    address public triggerAddress;

    IERC20 public immutable token;
    IRandomNumberGenerator public randomGenerator;

    Counters.Counter private counterTicketId;
    Counters.Counter private counterRoundId;
    /* #endregion */

    /* #region Modifiers */
    /* solhint-disable avoid-tx-origin */
    modifier notContract() {
        require(!Address.isContract(msg.sender), ERROR_CONTRACT_NOT_ALLOWED);
        require(msg.sender == tx.origin, ERROR_PROXY_CONTRACT_NOT_ALLOWED);
        _;
    }
    /* solhint-enable */

    modifier onlyOperator() {
        require(msg.sender == operatorAddress, ERROR_ONLY_OPERATOR);
        _;
    }

    modifier onlyOperatorOrTrigger() {
        require(msg.sender == triggerAddress || msg.sender == operatorAddress, ERROR_ONLY_TRIGGER_OR_OPERATOR);
        _;
    }

    /* #endregion */

    /* #region Constructor */
    /**
     *
     * @notice Constructor
     * @param _tokenAddress Address of the ERC20 token
     */
    constructor(address _tokenAddress) {
        token = IERC20(_tokenAddress);
    }

    /* #endregion */

    /* #region Methods */

    /**
     *
     * @notice Add new lottery. Only call when deploying smart contact for the first time
     * @param _lotteryId lottery id
     * @param _lottery lottery id
     * @dev Callable by operator
     */
    function addLottery(string memory _lotteryId, Lottery memory _lottery) external override onlyOperator {
        require(!String.isEmpty(_lotteryId), ERROR_INVALID_LOTTERY_ID);
        require(!String.isEmpty(_lottery.picture), ERROR_INVALID_LOTTERY_PICTURE);
        require(!String.isEmpty(_lottery.verboseName), ERROR_INVALID_LOTTERY_VERBOSE_NAME);
        require(_lottery.numberOfItems > 0, ERROR_INVALID_LOTTERY_NUMBER_OF_ITEMS);
        require(_lottery.minValuePerItem > 0, ERROR_INVALID_LOTTERY_MIN_VALUE_PER_ITEMS);
        require(
            _lottery.maxValuePerItem > 0 && _lottery.maxValuePerItem < type(uint32).max,
            ERROR_INVALID_LOTTERY_MAX_VALUE_PER_ITEMS
        );
        require(_lottery.periodDays.length > 0, ERROR_INVALID_LOTTERY_PERIOD_DAYS);
        require(
            _lottery.periodHourOfDays > 0 && _lottery.periodHourOfDays <= 24,
            ERROR_INVALID_LOTTERY_PERIOD_HOUR_OF_DAYS
        );
        require(
            _lottery.maxNumberTicketsPerBuy > 0 && _lottery.maxNumberTicketsPerBuy < type(uint32).max,
            ERROR_INVALID_LOTTERY_MAX_NUMBER_TICKETS_PER_BUY
        );
        require(_lottery.pricePerTicket > 0, ERROR_INVALID_LOTTERY_PRICE_PER_TICKET);
        require(
            _lottery.treasuryFeePercent >= 0 && _lottery.treasuryFeePercent <= 100,
            ERROR_INVALID_LOTTERY_TREASURY_FEE_PERCENT
        );
        require(
            _lottery.discountPercent >= 0 && _lottery.discountPercent <= 100,
            ERROR_INVALID_LOTTERY_DISCOUNT_PERCENT
        );

        require(
            !String.compareTwoStrings(lotteries[_lotteryId].verboseName, _lottery.verboseName),
            ERROR_LOTTERY_ALREADY_EXISTS
        );

        lotteries[_lotteryId] = _lottery;
        lotteryIds.push(_lotteryId);

        emit NewLottery(_lotteryId, _lottery);
    }

    /**
     * @notice Add many rules reward for lottery payout. Only call when deploying smart contact for the first time
     * @param _lotteryId Lottery id
     * @param _matchNumbers Number match
     * @param _rewardUnits Reward unit
     * @param _rewardValues Reward value per unit
     * @dev Callable by operator
     */
    function addRewardRules(
        string calldata _lotteryId,
        uint32[] calldata _matchNumbers,
        RewardUnit[] calldata _rewardUnits,
        uint256[] calldata _rewardValues
    ) external override onlyOperator {
        require(
            _matchNumbers.length == _rewardUnits.length && _rewardUnits.length == _rewardValues.length,
            ERROR_INVALID_RULES
        );

        for (uint i = 0; i < _matchNumbers.length; i++) {
            require(!String.isEmpty(_lotteryId), ERROR_INVALID_LOTTERY_ID);
            require(_matchNumbers[i] > 0, ERROR_INVALID_RULE_MATCH_NUMBER);
            require(_rewardValues[i] > 0, ERROR_INVALID_RULE_REWARD_VALUE);

            rulesPerLotteryId[_lotteryId].push(
                Rule({ matchNumber: _matchNumbers[i], rewardUnit: _rewardUnits[i], rewardValue: _rewardValues[i] })
            );
            emit NewRewardRule(i, _lotteryId, _matchNumbers[i], _rewardUnits[i], _rewardValues[i]);
        }
    }

    /**
     *
     * @param _roundId Request id combine lotterylotteryId and lotteryroundId
     * @param _tickets Array of ticket pick numbers
     * @dev Callable by users
     */
    function buyTickets(uint256 _roundId, uint32[][] calldata _tickets) external override notContract nonReentrant {
        // check list tickets is emptyidx
        require(_tickets.length != 0, ERROR_TICKETS_EMPTY);
        // check round is open
        require(rounds[_roundId].status == RoundStatus.Open, ERROR_ROUND_IS_CLOSED);
        // check limit ticket
        require(
            _tickets.length <= lotteries[lotteriesPerRoundId[_roundId]].maxNumberTicketsPerBuy,
            ERROR_TICKETS_LIMIT
        );

        // calculate total price to pay to this contract
        uint256 amountToTransfer = _caculateTotalPriceForBulkTickets(
            lotteries[lotteriesPerRoundId[_roundId]],
            _tickets.length
        );
        // transfer tokens to this contract
        token.safeTransferFrom(address(msg.sender), address(this), amountToTransfer);

        // increment the total amount collected for the round
        rounds[_roundId].totalAmount += amountToTransfer;
        rounds[_roundId].totalTickets += _tickets.length;
        uint256[] memory purchasedTicketIds = new uint256[](_tickets.length);
        for (uint i = 0; i < _tickets.length; i++) {
            uint32[] memory ticketNumbers = _tickets[i];

            // Check valid ticket numbers
            require(_isValidNumbers(ticketNumbers, lotteries[lotteriesPerRoundId[_roundId]]), ERROR_INVALID_TICKET);

            // Increment lottery ticket number
            counterTicketId.increment();
            tickets[counterTicketId.current()] = Ticket({
                owner: msg.sender,
                roundId: _roundId,
                numbers: ticketNumbers,
                winStatus: false,
                winRewardRule: 0,
                winAmount: 0,
                clamStatus: false
            });
            ticketIds.push(counterTicketId.current());
            ticketsPerUserId[msg.sender].push(counterTicketId.current());
            ticketsPerRoundId[_roundId].push(counterTicketId.current());
            purchasedTicketIds[i] = counterTicketId.current();
        }

        emit TicketsPurchase(msg.sender, _roundId, purchasedTicketIds, amountToTransfer);
    }

    /**
     *
     * @notice Buy tickets for the rounds
     * @param _roundIds Rround id
     * @param _tickets array of ticket
     * @dev Callable by users
     */
    function buyTicketsMultiRounds(
        uint256[] calldata _roundIds,
        uint32[][] calldata _tickets
    ) external override notContract nonReentrant {
        // check list tickets is emptyidx
        require(_tickets.length != 0, ERROR_TICKETS_EMPTY);
        require(_tickets.length == _roundIds.length, ERROR_INVALID_TICKETS_LENGTH_EQUALS_ROUNDS);

        // calculate total price to pay to this contract
        uint256 amountToTransfer;

        uint256[] memory purchasedTicketIds = new uint256[](_tickets.length);
        uint256[] memory purchasedTicketPrices = new uint256[](_tickets.length);
        for (uint idx = 0; idx < _roundIds.length; idx++) {
            uint256 roundId = _roundIds[idx];
            // check round is open
            require(rounds[roundId].status == RoundStatus.Open, ERROR_ROUND_IS_CLOSED);
            // check limit ticket
            require(
                _tickets.length <= lotteries[lotteriesPerRoundId[roundId]].maxNumberTicketsPerBuy,
                ERROR_TICKETS_LIMIT
            );

            // amount to transfer need plus for price per ticket
            uint256 ticketPrice = _caculateTotalPriceForBulkTickets(lotteries[lotteriesPerRoundId[roundId]], 1);
            amountToTransfer += ticketPrice;

            uint32[] memory ticketNumbers = _tickets[idx];
            // Check valid ticket numbers
            require(_isValidNumbers(ticketNumbers, lotteries[lotteriesPerRoundId[roundId]]), ERROR_INVALID_TICKET);

            // increment the total amount collected for the round
            rounds[roundId].totalAmount += ticketPrice;
            rounds[roundId].totalTickets += 1;

            // Increment lottery ticket number
            counterTicketId.increment();

            // Set new ticket to mapping tickets
            uint256 newTicketId = counterTicketId.current();
            tickets[newTicketId] = Ticket({
                owner: msg.sender,
                roundId: roundId,
                numbers: ticketNumbers,
                winStatus: false,
                winRewardRule: 0,
                winAmount: 0,
                clamStatus: false
            });
            ticketIds.push(newTicketId);

            // Set new ticket to user
            ticketsPerUserId[msg.sender].push(newTicketId);

            // Set new ticket to round
            ticketsPerRoundId[roundId].push(newTicketId);

            purchasedTicketIds[idx] = newTicketId;
            purchasedTicketPrices[idx] = ticketPrice;
        }

        // transfer tokens to this contract
        token.safeTransferFrom(address(msg.sender), address(this), amountToTransfer);
        emit MultiRoundsTicketsPurchase(msg.sender, _roundIds, purchasedTicketIds, purchasedTicketPrices);
    }

    /**
     * @notice Claim a set of winning tickets for a lottery
     * @param _ticketIds: array of ticket ids
     * @dev Callable by users only, not contract!
     */
    function claimTickets(uint256[] calldata _ticketIds) external override notContract nonReentrant {
        require(_ticketIds.length != 0, ERROR_TICKETS_EMPTY);

        // Initializes the rewardAmountToTransfer
        uint256 rewardAmountToTransfer;
        for (uint i = 0; i < _ticketIds.length; i++) {
            uint256 ticketId = _ticketIds[i];
            require(tickets[ticketId].owner == msg.sender, "ERROR_ONLY_OWNER");
            require(tickets[ticketId].winStatus, "ERROR_TICKET_NOT_WIN");
            require(!tickets[ticketId].clamStatus, "ERROR_ONLY_CLAIM_PRIZE_ONCE");
            tickets[ticketId].clamStatus = true;
            rewardAmountToTransfer += tickets[ticketId].winAmount;
        }

        // Transfer money to msg.sender
        token.safeTransfer(msg.sender, rewardAmountToTransfer);

        emit TicketsClaim(msg.sender, rewardAmountToTransfer, _ticketIds);
    }

    /**
     *
     * @param _lotteryId lottery id
     */
    function open(string calldata _lotteryId) external override onlyOperatorOrTrigger {
        require(!String.isEmpty(_lotteryId), ERROR_INVALID_LOTTERY_ID);
        uint256 currentRoundId = currentRoundIdPerLottery[_lotteryId];
        require(
            (currentRoundId == 0) || (rounds[currentRoundId].status == RoundStatus.Reward),
            ERROR_NOT_TIME_OPEN_LOTTERY
        );

        // Increment current round id of lottery to one
        counterRoundId.increment();
        uint256 nextRoundId = counterRoundId.current();

        // Keep track lottery id and round id
        require(nextRoundId > currentRoundIdPerLottery[_lotteryId], "ERROR_ROUND_ID_LESS_THAN_CURRENT");

        currentRoundIdPerLottery[_lotteryId] = nextRoundId;
        lotteriesPerRoundId[nextRoundId] = _lotteryId;

        // Create new round
        uint256 totalAmount = amountInjectNextRoundPerLottery[_lotteryId];
        rounds[nextRoundId] = Round({
            firstRoundId: currentRoundId,
            winningNumbers: new uint32[](lotteries[_lotteryId].numberOfItems),
            openTime: block.timestamp,
            endTime: 0,
            totalAmount: totalAmount,
            totalTickets: 0,
            status: RoundStatus.Open
        });
        roundIds.push(nextRoundId);

        // Reset amount injection for next round
        amountInjectNextRoundPerLottery[_lotteryId] = 0;

        // Emit round open
        emit RoundOpen(nextRoundId, _lotteryId, totalAmount, block.timestamp, currentRoundId);
    }

    /**
     *
     * @param _lotteryId lottery id
     */
    function close(string calldata _lotteryId) external override onlyOperatorOrTrigger {
        require(!String.isEmpty(_lotteryId), ERROR_INVALID_LOTTERY_ID);
        uint256 currentRoundId = currentRoundIdPerLottery[_lotteryId];
        require(
            (currentRoundId != 0) && rounds[currentRoundId].status == RoundStatus.Open,
            ERROR_NOT_TIME_CLOSE_LOTTERY
        );

        rounds[currentRoundId].status = RoundStatus.Close;

        // Request new random number
        randomGenerator.requestRandomNumbers(
            currentRoundId,
            lotteries[_lotteryId].numberOfItems,
            lotteries[_lotteryId].minValuePerItem,
            lotteries[_lotteryId].maxValuePerItem
        );

        // Emit round close
        emit RoundClose(currentRoundId, rounds[currentRoundId].totalAmount, rounds[currentRoundId].totalTickets);
    }

    /**
     *
     * @notice Start round by id
     * @param _lotteryId round id
     * @dev Callable by operator
     */
    function draw(string calldata _lotteryId) external override onlyOperatorOrTrigger {
        require(!String.isEmpty(_lotteryId), ERROR_INVALID_LOTTERY_ID);
        uint256 currentRoundId = currentRoundIdPerLottery[_lotteryId];
        require(
            (currentRoundId != 0) && rounds[currentRoundId].status == RoundStatus.Close,
            ERROR_NOT_TIME_DRAW_LOTTERY
        );

        // get randomResult generated by ChainLink's fallback
        uint32[] memory winningNumbers = randomGenerator.getRandomResult(currentRoundId);

        // check winning numbers is valid or not
        require(_isValidNumbers(winningNumbers, lotteries[_lotteryId]), ERROR_INVALID_WINNING_NUMBERS);

        rounds[currentRoundId].status = RoundStatus.Draw;
        rounds[currentRoundId].winningNumbers = winningNumbers;

        // Emit round Draw
        emit RoundDraw(currentRoundIdPerLottery[_lotteryId], winningNumbers);
    }

    /**
     *
     * @notice Reward round by id
     * @param _lotteryId round id
     * @dev Callable by operator
     */
    function reward(string calldata _lotteryId) external override onlyOperatorOrTrigger {
        require(!String.isEmpty(_lotteryId), ERROR_INVALID_LOTTERY_ID);
        uint256 currentRoundId = currentRoundIdPerLottery[_lotteryId];
        require(
            (currentRoundId != 0) && rounds[currentRoundId].status == RoundStatus.Draw,
            ERROR_NOT_TIME_REWARD_LOTTERY
        );

        // Set round status to reward
        rounds[currentRoundId].status = RoundStatus.Reward;
        rounds[currentRoundId].endTime = block.timestamp;

        // Estimate
        (uint256 amountTreasury, uint256 amountInject, uint256 rewardAmount) = _estimateReward(
            _lotteryId,
            currentRoundId
        );

        uint256 outRewardValue = _findWinnersAndReward(_lotteryId, currentRoundId, rewardAmount);
        amountInject += outRewardValue;
        amountInjectNextRoundPerLottery[_lotteryId] = amountInject;
        // Transfer token to treasury address
        token.safeTransfer(treasuryAddress, amountTreasury);
        // Emit round Draw
        emit RoundReward(currentRoundId, amountTreasury, amountInject, block.timestamp);
    }

    /**
     * @notice Inject funds
     * @param _roundId: round id
     * @param _amount: amount to inject in token
     * @dev Callable by owner or injector address
     */
    function injectFunds(uint256 _roundId, uint256 _amount) external onlyOwner {
        require(rounds[_roundId].status == RoundStatus.Open, ERROR_ROUND_NOT_OPEN);
        token.safeTransferFrom(address(msg.sender), address(this), _amount);
        rounds[_roundId].totalAmount += _amount;
        emit RoundInjection(_roundId, _amount);
    }

    /**
     * @notice It allows the admin to recover wrong tokens sent to the contract
     * @param _tokenAddress: the address of the token to withdraw
     * @param _tokenAmount: the number of token amount to withdraw
     * @dev Only callable by owner.
     */
    function recoverWrongTokens(address _tokenAddress, uint256 _tokenAmount) external onlyOwner {
        require(_tokenAddress != address(token), ERROR_WRONG_TOKEN_ADDRESS);
        IERC20(_tokenAddress).safeTransfer(address(msg.sender), _tokenAmount);
        emit AdminTokenRecovery(_tokenAddress, _tokenAmount);
    }

    /**
     * @notice Set the random generator
     * @dev The calls to functions are used to verify the new generator implements them properly.
     * Callable only by the contract owner
     * @param _randomGeneratorAddress: address of the random generator
     */
    function setRandomGenerator(address _randomGeneratorAddress) external override onlyOwner {
        randomGenerator = IRandomNumberGenerator(_randomGeneratorAddress);
        emit NewRandomGenerator(_randomGeneratorAddress);
    }

    /**
     *
     * @param _operatorAddress The lottery scheduler account used to run regular operations.
     * @dev Callable by owner
     */
    function setOperatorAddress(address _operatorAddress) external onlyOwner {
        require(_operatorAddress != address(0), ERROR_INVALID_ZERO_ADDRESS);
        operatorAddress = _operatorAddress;
    }

    /**
     *
     * @param _treasuryAddress The address in which the burn is sent
     * @dev Callable by owner
     */
    function setTreasuryAddress(address _treasuryAddress) external onlyOwner {
        require(_treasuryAddress != address(0), ERROR_INVALID_ZERO_ADDRESS);
        treasuryAddress = _treasuryAddress;
    }

    /**
     *
     * @param _triggerAddress The lottery scheduler account used to run regular operations.
     * @dev Callable by owner
     */
    function setTriggerAddress(address _triggerAddress) external onlyOwner {
        require(_triggerAddress != address(0), ERROR_INVALID_ZERO_ADDRESS);
        triggerAddress = _triggerAddress;
    }

    /**
     * @notice Return a list of lottery ids
     */
    function getLotteryIds() external view override returns (string[] memory) {
        return lotteryIds;
    }

    /**
     * @notice Return lottery by id
     * @param _lotteryId Id of lottery
     */
    function getLottery(string calldata _lotteryId) external view override returns (Lottery memory) {
        return lotteries[_lotteryId];
    }

    /**
     * @notice Return a list of round ids
     */
    function getRoundIds() external view override returns (uint256[] memory) {
        return roundIds;
    }

    /**
     * @notice Return round by id
     * @param _roundId Id of round
     */
    function getRound(uint256 _roundId) external view override returns (Round memory) {
        return rounds[_roundId];
    }

    /**
     * @notice Return a length of ticket ids by user address
     */
    function getTicketIdsByUserLength(address _user) external view override returns (uint256) {
        return ticketsPerUserId[_user].length;
    }

    /**
     * @notice Return a list of ticket ids by user address
     * @param _user: user address
     * @param _cursor: cursor to start where to retrieve the tickets
     * @param _size: the number of tickets to retrieve
     * @param _asc: get list order by ascending
     */
    function getTicketIdsByUser(
        address _user,
        uint256 _cursor,
        uint256 _size,
        bool _asc
    ) external view override returns (uint256[] memory ids, uint256 cursor) {
        if (_asc) {
            if (_size > ticketsPerUserId[_user].length - _cursor) {
                _size = ticketsPerUserId[_user].length - _cursor;
            }
        } else {
            if (_size > _cursor) {
                _size = _cursor;
            }
        }
        ids = new uint256[](_size);
        uint256 idx;
        for (uint256 i = 0; i < _size; i++) {
            idx = _asc ? _cursor + i : _cursor - i - 1;
            ids[i] = ticketsPerUserId[_user][idx];
        }
        cursor = _asc ? _cursor + _size : _cursor - _size;
    }

    /**
     * @notice Return ticket by id
     * @param _ticketId Id of round
     */
    function getTicket(uint256 _ticketId) external view override returns (Ticket memory) {
        return tickets[_ticketId];
    }

    /**
     * @notice Find the winners and pay the prizes. the out reward will be added to inject
     * @param _lotteryId Id of lottery
     * @param _roundId Id of round
     * @param rewardAmount Reward amount share for winners
     * @dev Callable by internal
     */
    function _findWinnersAndReward(
        string calldata _lotteryId,
        uint256 _roundId,
        uint256 rewardAmount
    ) internal returns (uint256 outRewardValue) {
        outRewardValue = rewardAmount;
        uint[] memory winnersPerRule = new uint[](rulesPerLotteryId[_lotteryId].length);
        for (uint ticketIndex = 0; ticketIndex < ticketsPerRoundId[_roundId].length; ticketIndex++) {
            uint256 ticketId = ticketsPerRoundId[_roundId][ticketIndex];
            // Check if this ticket is eligible to win or not
            (bool isWin, uint matchRewardRule) = _checkIsWinTicket(ticketId, _lotteryId, _roundId);
            if (isWin) {
                tickets[ticketId].winStatus = isWin;
                tickets[ticketId].winRewardRule = matchRewardRule;
                winnersPerRule[matchRewardRule] += 1;
            }
        }

        uint256[] memory rewardsAmountPerRule = new uint256[](rulesPerLotteryId[_lotteryId].length);
        for (uint ruleIndex = 0; ruleIndex < winnersPerRule.length; ruleIndex++) {
            uint winnerPerRule = winnersPerRule[ruleIndex];
            if (winnerPerRule > 0) {
                uint256 rewardAmountPerRule = _calculateRewardAmountPerRule(_lotteryId, ruleIndex, rewardAmount);
                outRewardValue -= rewardAmountPerRule;
                uint256 rewardAmountPerTicket = rewardAmountPerRule.div(winnerPerRule);
                rewardsAmountPerRule[ruleIndex] = rewardAmountPerTicket;
            }
        }

        for (uint ticketIndex = 0; ticketIndex < ticketsPerRoundId[_roundId].length; ticketIndex++) {
            uint256 ticketId = ticketsPerRoundId[_roundId][ticketIndex];
            if (tickets[ticketId].winStatus) {
                uint256 rewardAmountPerRule = rewardsAmountPerRule[tickets[ticketId].winRewardRule];
                tickets[ticketId].winAmount = rewardAmountPerRule;
            }
        }
    }

    /**
     * @notice Return ticket by id
     * @param _lotteryId Id of lottery
     * @param _roundId Id of round
     * @return treasuryAmount Treasury fee on total prize
     * @return injectAmount Amount inject for the next round
     * @return rewardAmount Number of prizes to be divided among the winners
     */
    function _estimateReward(
        string memory _lotteryId,
        uint256 _roundId
    ) internal view returns (uint256 treasuryAmount, uint256 injectAmount, uint256 rewardAmount) {
        treasuryAmount = _percentageOf(rounds[_roundId].totalAmount, lotteries[_lotteryId].treasuryFeePercent);
        injectAmount = _percentageOf(rounds[_roundId].totalAmount, lotteries[_lotteryId].amountInjectNextRoundPercent);
        rewardAmount = rounds[_roundId].totalAmount.sub(treasuryAmount).sub(injectAmount);
    }

    /**
     *
     * @notice Check array of numbers is valid or not
     * @param _numbers Array of numbers need check in range LOTTERY require
     * @param _lottery LOTTERYs that users want to check
     */
    function _isValidNumbers(uint32[] memory _numbers, Lottery memory _lottery) internal pure returns (bool) {
        if (_numbers.length != _lottery.numberOfItems) {
            return false;
        }
        for (uint i = 0; i < _numbers.length; i++) {
            uint32 number = _numbers[i];
            if (number < _lottery.minValuePerItem || number > _lottery.maxValuePerItem) {
                return false;
            }
        }
        return true;
    }

    /**
     * @notice Calcuate final price for bulk of tickets
     * @param _lottery LOTTERYs that users want to buy tickets
     * @param _numberTickets Number of tickts want to by
     */
    function _caculateTotalPriceForBulkTickets(
        Lottery memory _lottery,
        uint256 _numberTickets
    ) internal pure returns (uint256) {
        uint256 totalPrice = _lottery.pricePerTicket * _numberTickets;
        return totalPrice - _percentageOf(totalPrice, _lottery.discountPercent);
    }

    /**
     * @notice Check if the ticket win or not. Returns the index of rule for ticket win
     * @param _ticketId Id of ticket
     * @param _lotteryId Id of lottery
     * @param _roundId Id of round
     * @return isWin Return true if ticket win
     * @return matchRewardRule Rule index rule match
     */
    function _checkIsWinTicket(
        uint256 _ticketId,
        string memory _lotteryId,
        uint256 _roundId
    ) internal view returns (bool isWin, uint matchRewardRule) {
        uint matchedNumbers = _matchNumbersCount(rounds[_roundId].winningNumbers, tickets[_ticketId].numbers);
        if (matchedNumbers != 0) {
            for (uint ruleIndex = 0; ruleIndex < rulesPerLotteryId[_lotteryId].length; ruleIndex++) {
                if (rulesPerLotteryId[_lotteryId][ruleIndex].matchNumber == matchedNumbers) {
                    isWin = true;
                    matchRewardRule = ruleIndex;
                    break;
                }
            }
        }
    }

    /**
     * @notice Calculate the amount to be paid for ticket win rule
     * @param _lotteryId Id of lottery
     * @param _ruleIndex Index of rule
     * @param _rewardAmount Total amount of reward
     */
    function _calculateRewardAmountPerRule(
        string memory _lotteryId,
        uint _ruleIndex,
        uint256 _rewardAmount
    ) internal view returns (uint256) {
        Rule memory rule = rulesPerLotteryId[_lotteryId][_ruleIndex];
        uint256 rewardAmountPerRule;
        if (rule.rewardUnit == RewardUnit.Percent) {
            rewardAmountPerRule = _percentageOf(_rewardAmount, rule.rewardValue);
        } else if (rule.rewardUnit == RewardUnit.Fixed) {
            rewardAmountPerRule = _rewardAmount - rule.rewardValue;
        }
        return rewardAmountPerRule;
    }

    /**
     * @notice Count the matching numbers between 2 arrays
     */
    function _matchNumbersCount(uint32[] memory _arr1, uint32[] memory _arr2) internal pure returns (uint) {
        uint count = 0;
        for (uint arr1Index = 0; arr1Index < _arr1.length; arr1Index++) {
            for (uint arr2Index = 0; arr2Index < _arr2.length; arr2Index++) {
                if (_arr1[arr1Index] == _arr2[arr2Index]) {
                    count++;
                }
            }
        }
        return count;
    }

    /**
     * @notice Calculate the treasury fee
     * @param _lotteryId Id of lottery
     * @param _roundId Id of round
     */
    function _calculateTreasuryFee(string memory _lotteryId, uint256 _roundId) internal view returns (uint256) {
        return _percentageOf(rounds[_roundId].totalAmount, lotteries[_lotteryId].treasuryFeePercent);
    }

    /**
     * @notice Calculate percentage value
     */
    function _percentageOf(uint256 amount, uint256 percent) internal pure returns (uint256) {
        require(percent >= 0 && percent <= 100, "INVALID_PERCENT_VALUE");
        return (amount.mul(percent)).div(100);
    }
    /* #endregion */
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

    /**
     * @notice Compare two strings. Returns true if two strings are equal
     * @param _str1 String 1
     * @param _str2 String 2
     */
    function compareTwoStrings(string memory _str1, string memory _str2) internal pure returns (bool) {
        if (bytes(_str1).length != bytes(_str2).length) {
            return false;
        }
        return keccak256(abi.encodePacked(_str1)) == keccak256(abi.encodePacked(_str2));
    }
}