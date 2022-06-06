// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeCast.sol)

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {
    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value <= type(uint16).max, "SafeCast: value doesn't fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= type(int128).min && value <= type(int128).max, "SafeCast: value doesn't fit in 128 bits");
        return int128(value);
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= type(int64).min && value <= type(int64).max, "SafeCast: value doesn't fit in 64 bits");
        return int64(value);
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= type(int32).min && value <= type(int32).max, "SafeCast: value doesn't fit in 32 bits");
        return int32(value);
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= type(int16).min && value <= type(int16).max, "SafeCast: value doesn't fit in 16 bits");
        return int16(value);
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= type(int8).min && value <= type(int8).max, "SafeCast: value doesn't fit in 8 bits");
        return int8(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

// SPDX-License-Identifier: BSD-4-Clause
/*
 * ABDK Math 64.64 Smart Contract Library.  Copyright © 2019 by ABDK Consulting.
 * Author: Mikhail Vladimirov <[email protected]>
 */
pragma solidity ^0.8.0;

/**
 * Smart contract library of mathematical functions operating with signed
 * 64.64-bit fixed point numbers.  Signed 64.64-bit fixed point number is
 * basically a simple fraction whose numerator is signed 128-bit integer and
 * denominator is 2^64.  As long as denominator is always the same, there is no
 * need to store it, thus in Solidity signed 64.64-bit fixed point numbers are
 * represented by int128 type holding only the numerator.
 */
library ABDKMath64x64 {
  /*
   * Minimum value signed 64.64-bit fixed point number may have. 
   */
  int128 private constant MIN_64x64 = -0x80000000000000000000000000000000;

  /*
   * Maximum value signed 64.64-bit fixed point number may have. 
   */
  int128 private constant MAX_64x64 = 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

  /**
   * Convert signed 256-bit integer number into signed 64.64-bit fixed point
   * number.  Revert on overflow.
   *
   * @param x signed 256-bit integer number
   * @return signed 64.64-bit fixed point number
   */
  function fromInt (int256 x) internal pure returns (int128) {
    unchecked {
      require (x >= -0x8000000000000000 && x <= 0x7FFFFFFFFFFFFFFF);
      return int128 (x << 64);
    }
  }

  /**
   * Convert signed 64.64 fixed point number into signed 64-bit integer number
   * rounding down.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64-bit integer number
   */
  function toInt (int128 x) internal pure returns (int64) {
    unchecked {
      return int64 (x >> 64);
    }
  }

  /**
   * Convert unsigned 256-bit integer number into signed 64.64-bit fixed point
   * number.  Revert on overflow.
   *
   * @param x unsigned 256-bit integer number
   * @return signed 64.64-bit fixed point number
   */
  function fromUInt (uint256 x) internal pure returns (int128) {
    unchecked {
      require (x <= 0x7FFFFFFFFFFFFFFF);
      return int128 (int256 (x << 64));
    }
  }

  /**
   * Convert signed 64.64 fixed point number into unsigned 64-bit integer
   * number rounding down.  Revert on underflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @return unsigned 64-bit integer number
   */
  function toUInt (int128 x) internal pure returns (uint64) {
    unchecked {
      require (x >= 0);
      return uint64 (uint128 (x >> 64));
    }
  }

  /**
   * Convert signed 128.128 fixed point number into signed 64.64-bit fixed point
   * number rounding down.  Revert on overflow.
   *
   * @param x signed 128.128-bin fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function from128x128 (int256 x) internal pure returns (int128) {
    unchecked {
      int256 result = x >> 64;
      require (result >= MIN_64x64 && result <= MAX_64x64);
      return int128 (result);
    }
  }

  /**
   * Convert signed 64.64 fixed point number into signed 128.128 fixed point
   * number.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 128.128 fixed point number
   */
  function to128x128 (int128 x) internal pure returns (int256) {
    unchecked {
      return int256 (x) << 64;
    }
  }

  /**
   * Calculate x + y.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function add (int128 x, int128 y) internal pure returns (int128) {
    unchecked {
      int256 result = int256(x) + y;
      require (result >= MIN_64x64 && result <= MAX_64x64);
      return int128 (result);
    }
  }

  /**
   * Calculate x - y.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function sub (int128 x, int128 y) internal pure returns (int128) {
    unchecked {
      int256 result = int256(x) - y;
      require (result >= MIN_64x64 && result <= MAX_64x64);
      return int128 (result);
    }
  }

  /**
   * Calculate x * y rounding down.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function mul (int128 x, int128 y) internal pure returns (int128) {
    unchecked {
      int256 result = int256(x) * y >> 64;
      require (result >= MIN_64x64 && result <= MAX_64x64);
      return int128 (result);
    }
  }

  /**
   * Calculate x * y rounding towards zero, where x is signed 64.64 fixed point
   * number and y is signed 256-bit integer number.  Revert on overflow.
   *
   * @param x signed 64.64 fixed point number
   * @param y signed 256-bit integer number
   * @return signed 256-bit integer number
   */
  function muli (int128 x, int256 y) internal pure returns (int256) {
    unchecked {
      if (x == MIN_64x64) {
        require (y >= -0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF &&
          y <= 0x1000000000000000000000000000000000000000000000000);
        return -y << 63;
      } else {
        bool negativeResult = false;
        if (x < 0) {
          x = -x;
          negativeResult = true;
        }
        if (y < 0) {
          y = -y; // We rely on overflow behavior here
          negativeResult = !negativeResult;
        }
        uint256 absoluteResult = mulu (x, uint256 (y));
        if (negativeResult) {
          require (absoluteResult <=
            0x8000000000000000000000000000000000000000000000000000000000000000);
          return -int256 (absoluteResult); // We rely on overflow behavior here
        } else {
          require (absoluteResult <=
            0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
          return int256 (absoluteResult);
        }
      }
    }
  }

  /**
   * Calculate x * y rounding down, where x is signed 64.64 fixed point number
   * and y is unsigned 256-bit integer number.  Revert on overflow.
   *
   * @param x signed 64.64 fixed point number
   * @param y unsigned 256-bit integer number
   * @return unsigned 256-bit integer number
   */
  function mulu (int128 x, uint256 y) internal pure returns (uint256) {
    unchecked {
      if (y == 0) return 0;

      require (x >= 0);

      uint256 lo = (uint256 (int256 (x)) * (y & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)) >> 64;
      uint256 hi = uint256 (int256 (x)) * (y >> 128);

      require (hi <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
      hi <<= 64;

      require (hi <=
        0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF - lo);
      return hi + lo;
    }
  }

  /**
   * Calculate x / y rounding towards zero.  Revert on overflow or when y is
   * zero.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function div (int128 x, int128 y) internal pure returns (int128) {
    unchecked {
      require (y != 0);
      int256 result = (int256 (x) << 64) / y;
      require (result >= MIN_64x64 && result <= MAX_64x64);
      return int128 (result);
    }
  }

  /**
   * Calculate x / y rounding towards zero, where x and y are signed 256-bit
   * integer numbers.  Revert on overflow or when y is zero.
   *
   * @param x signed 256-bit integer number
   * @param y signed 256-bit integer number
   * @return signed 64.64-bit fixed point number
   */
  function divi (int256 x, int256 y) internal pure returns (int128) {
    unchecked {
      require (y != 0);

      bool negativeResult = false;
      if (x < 0) {
        x = -x; // We rely on overflow behavior here
        negativeResult = true;
      }
      if (y < 0) {
        y = -y; // We rely on overflow behavior here
        negativeResult = !negativeResult;
      }
      uint128 absoluteResult = divuu (uint256 (x), uint256 (y));
      if (negativeResult) {
        require (absoluteResult <= 0x80000000000000000000000000000000);
        return -int128 (absoluteResult); // We rely on overflow behavior here
      } else {
        require (absoluteResult <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
        return int128 (absoluteResult); // We rely on overflow behavior here
      }
    }
  }

  /**
   * Calculate x / y rounding towards zero, where x and y are unsigned 256-bit
   * integer numbers.  Revert on overflow or when y is zero.
   *
   * @param x unsigned 256-bit integer number
   * @param y unsigned 256-bit integer number
   * @return signed 64.64-bit fixed point number
   */
  function divu (uint256 x, uint256 y) internal pure returns (int128) {
    unchecked {
      require (y != 0);
      uint128 result = divuu (x, y);
      require (result <= uint128 (MAX_64x64));
      return int128 (result);
    }
  }

  /**
   * Calculate -x.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function neg (int128 x) internal pure returns (int128) {
    unchecked {
      require (x != MIN_64x64);
      return -x;
    }
  }

  /**
   * Calculate |x|.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function abs (int128 x) internal pure returns (int128) {
    unchecked {
      require (x != MIN_64x64);
      return x < 0 ? -x : x;
    }
  }

  /**
   * Calculate 1 / x rounding towards zero.  Revert on overflow or when x is
   * zero.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function inv (int128 x) internal pure returns (int128) {
    unchecked {
      require (x != 0);
      int256 result = int256 (0x100000000000000000000000000000000) / x;
      require (result >= MIN_64x64 && result <= MAX_64x64);
      return int128 (result);
    }
  }

  /**
   * Calculate arithmetics average of x and y, i.e. (x + y) / 2 rounding down.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function avg (int128 x, int128 y) internal pure returns (int128) {
    unchecked {
      return int128 ((int256 (x) + int256 (y)) >> 1);
    }
  }

  /**
   * Calculate geometric average of x and y, i.e. sqrt (x * y) rounding down.
   * Revert on overflow or in case x * y is negative.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function gavg (int128 x, int128 y) internal pure returns (int128) {
    unchecked {
      int256 m = int256 (x) * int256 (y);
      require (m >= 0);
      require (m <
          0x4000000000000000000000000000000000000000000000000000000000000000);
      return int128 (sqrtu (uint256 (m)));
    }
  }

  /**
   * Calculate x^y assuming 0^0 is 1, where x is signed 64.64 fixed point number
   * and y is unsigned 256-bit integer number.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y uint256 value
   * @return signed 64.64-bit fixed point number
   */
  function pow (int128 x, uint256 y) internal pure returns (int128) {
    unchecked {
      bool negative = x < 0 && y & 1 == 1;

      uint256 absX = uint128 (x < 0 ? -x : x);
      uint256 absResult;
      absResult = 0x100000000000000000000000000000000;

      if (absX <= 0x10000000000000000) {
        absX <<= 63;
        while (y != 0) {
          if (y & 0x1 != 0) {
            absResult = absResult * absX >> 127;
          }
          absX = absX * absX >> 127;

          if (y & 0x2 != 0) {
            absResult = absResult * absX >> 127;
          }
          absX = absX * absX >> 127;

          if (y & 0x4 != 0) {
            absResult = absResult * absX >> 127;
          }
          absX = absX * absX >> 127;

          if (y & 0x8 != 0) {
            absResult = absResult * absX >> 127;
          }
          absX = absX * absX >> 127;

          y >>= 4;
        }

        absResult >>= 64;
      } else {
        uint256 absXShift = 63;
        if (absX < 0x1000000000000000000000000) { absX <<= 32; absXShift -= 32; }
        if (absX < 0x10000000000000000000000000000) { absX <<= 16; absXShift -= 16; }
        if (absX < 0x1000000000000000000000000000000) { absX <<= 8; absXShift -= 8; }
        if (absX < 0x10000000000000000000000000000000) { absX <<= 4; absXShift -= 4; }
        if (absX < 0x40000000000000000000000000000000) { absX <<= 2; absXShift -= 2; }
        if (absX < 0x80000000000000000000000000000000) { absX <<= 1; absXShift -= 1; }

        uint256 resultShift = 0;
        while (y != 0) {
          require (absXShift < 64);

          if (y & 0x1 != 0) {
            absResult = absResult * absX >> 127;
            resultShift += absXShift;
            if (absResult > 0x100000000000000000000000000000000) {
              absResult >>= 1;
              resultShift += 1;
            }
          }
          absX = absX * absX >> 127;
          absXShift <<= 1;
          if (absX >= 0x100000000000000000000000000000000) {
              absX >>= 1;
              absXShift += 1;
          }

          y >>= 1;
        }

        require (resultShift < 64);
        absResult >>= 64 - resultShift;
      }
      int256 result = negative ? -int256 (absResult) : int256 (absResult);
      require (result >= MIN_64x64 && result <= MAX_64x64);
      return int128 (result);
    }
  }

  /**
   * Calculate sqrt (x) rounding down.  Revert if x < 0.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function sqrt (int128 x) internal pure returns (int128) {
    unchecked {
      require (x >= 0);
      return int128 (sqrtu (uint256 (int256 (x)) << 64));
    }
  }

  /**
   * Calculate binary logarithm of x.  Revert if x <= 0.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function log_2 (int128 x) internal pure returns (int128) {
    unchecked {
      require (x > 0);

      int256 msb = 0;
      int256 xc = x;
      if (xc >= 0x10000000000000000) { xc >>= 64; msb += 64; }
      if (xc >= 0x100000000) { xc >>= 32; msb += 32; }
      if (xc >= 0x10000) { xc >>= 16; msb += 16; }
      if (xc >= 0x100) { xc >>= 8; msb += 8; }
      if (xc >= 0x10) { xc >>= 4; msb += 4; }
      if (xc >= 0x4) { xc >>= 2; msb += 2; }
      if (xc >= 0x2) msb += 1;  // No need to shift xc anymore

      int256 result = msb - 64 << 64;
      uint256 ux = uint256 (int256 (x)) << uint256 (127 - msb);
      for (int256 bit = 0x8000000000000000; bit > 0; bit >>= 1) {
        ux *= ux;
        uint256 b = ux >> 255;
        ux >>= 127 + b;
        result += bit * int256 (b);
      }

      return int128 (result);
    }
  }

  /**
   * Calculate natural logarithm of x.  Revert if x <= 0.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function ln (int128 x) internal pure returns (int128) {
    unchecked {
      require (x > 0);

      return int128 (int256 (
          uint256 (int256 (log_2 (x))) * 0xB17217F7D1CF79ABC9E3B39803F2F6AF >> 128));
    }
  }

  /**
   * Calculate binary exponent of x.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function exp_2 (int128 x) internal pure returns (int128) {
    unchecked {
      require (x < 0x400000000000000000); // Overflow

      if (x < -0x400000000000000000) return 0; // Underflow

      uint256 result = 0x80000000000000000000000000000000;

      if (x & 0x8000000000000000 > 0)
        result = result * 0x16A09E667F3BCC908B2FB1366EA957D3E >> 128;
      if (x & 0x4000000000000000 > 0)
        result = result * 0x1306FE0A31B7152DE8D5A46305C85EDEC >> 128;
      if (x & 0x2000000000000000 > 0)
        result = result * 0x1172B83C7D517ADCDF7C8C50EB14A791F >> 128;
      if (x & 0x1000000000000000 > 0)
        result = result * 0x10B5586CF9890F6298B92B71842A98363 >> 128;
      if (x & 0x800000000000000 > 0)
        result = result * 0x1059B0D31585743AE7C548EB68CA417FD >> 128;
      if (x & 0x400000000000000 > 0)
        result = result * 0x102C9A3E778060EE6F7CACA4F7A29BDE8 >> 128;
      if (x & 0x200000000000000 > 0)
        result = result * 0x10163DA9FB33356D84A66AE336DCDFA3F >> 128;
      if (x & 0x100000000000000 > 0)
        result = result * 0x100B1AFA5ABCBED6129AB13EC11DC9543 >> 128;
      if (x & 0x80000000000000 > 0)
        result = result * 0x10058C86DA1C09EA1FF19D294CF2F679B >> 128;
      if (x & 0x40000000000000 > 0)
        result = result * 0x1002C605E2E8CEC506D21BFC89A23A00F >> 128;
      if (x & 0x20000000000000 > 0)
        result = result * 0x100162F3904051FA128BCA9C55C31E5DF >> 128;
      if (x & 0x10000000000000 > 0)
        result = result * 0x1000B175EFFDC76BA38E31671CA939725 >> 128;
      if (x & 0x8000000000000 > 0)
        result = result * 0x100058BA01FB9F96D6CACD4B180917C3D >> 128;
      if (x & 0x4000000000000 > 0)
        result = result * 0x10002C5CC37DA9491D0985C348C68E7B3 >> 128;
      if (x & 0x2000000000000 > 0)
        result = result * 0x1000162E525EE054754457D5995292026 >> 128;
      if (x & 0x1000000000000 > 0)
        result = result * 0x10000B17255775C040618BF4A4ADE83FC >> 128;
      if (x & 0x800000000000 > 0)
        result = result * 0x1000058B91B5BC9AE2EED81E9B7D4CFAB >> 128;
      if (x & 0x400000000000 > 0)
        result = result * 0x100002C5C89D5EC6CA4D7C8ACC017B7C9 >> 128;
      if (x & 0x200000000000 > 0)
        result = result * 0x10000162E43F4F831060E02D839A9D16D >> 128;
      if (x & 0x100000000000 > 0)
        result = result * 0x100000B1721BCFC99D9F890EA06911763 >> 128;
      if (x & 0x80000000000 > 0)
        result = result * 0x10000058B90CF1E6D97F9CA14DBCC1628 >> 128;
      if (x & 0x40000000000 > 0)
        result = result * 0x1000002C5C863B73F016468F6BAC5CA2B >> 128;
      if (x & 0x20000000000 > 0)
        result = result * 0x100000162E430E5A18F6119E3C02282A5 >> 128;
      if (x & 0x10000000000 > 0)
        result = result * 0x1000000B1721835514B86E6D96EFD1BFE >> 128;
      if (x & 0x8000000000 > 0)
        result = result * 0x100000058B90C0B48C6BE5DF846C5B2EF >> 128;
      if (x & 0x4000000000 > 0)
        result = result * 0x10000002C5C8601CC6B9E94213C72737A >> 128;
      if (x & 0x2000000000 > 0)
        result = result * 0x1000000162E42FFF037DF38AA2B219F06 >> 128;
      if (x & 0x1000000000 > 0)
        result = result * 0x10000000B17217FBA9C739AA5819F44F9 >> 128;
      if (x & 0x800000000 > 0)
        result = result * 0x1000000058B90BFCDEE5ACD3C1CEDC823 >> 128;
      if (x & 0x400000000 > 0)
        result = result * 0x100000002C5C85FE31F35A6A30DA1BE50 >> 128;
      if (x & 0x200000000 > 0)
        result = result * 0x10000000162E42FF0999CE3541B9FFFCF >> 128;
      if (x & 0x100000000 > 0)
        result = result * 0x100000000B17217F80F4EF5AADDA45554 >> 128;
      if (x & 0x80000000 > 0)
        result = result * 0x10000000058B90BFBF8479BD5A81B51AD >> 128;
      if (x & 0x40000000 > 0)
        result = result * 0x1000000002C5C85FDF84BD62AE30A74CC >> 128;
      if (x & 0x20000000 > 0)
        result = result * 0x100000000162E42FEFB2FED257559BDAA >> 128;
      if (x & 0x10000000 > 0)
        result = result * 0x1000000000B17217F7D5A7716BBA4A9AE >> 128;
      if (x & 0x8000000 > 0)
        result = result * 0x100000000058B90BFBE9DDBAC5E109CCE >> 128;
      if (x & 0x4000000 > 0)
        result = result * 0x10000000002C5C85FDF4B15DE6F17EB0D >> 128;
      if (x & 0x2000000 > 0)
        result = result * 0x1000000000162E42FEFA494F1478FDE05 >> 128;
      if (x & 0x1000000 > 0)
        result = result * 0x10000000000B17217F7D20CF927C8E94C >> 128;
      if (x & 0x800000 > 0)
        result = result * 0x1000000000058B90BFBE8F71CB4E4B33D >> 128;
      if (x & 0x400000 > 0)
        result = result * 0x100000000002C5C85FDF477B662B26945 >> 128;
      if (x & 0x200000 > 0)
        result = result * 0x10000000000162E42FEFA3AE53369388C >> 128;
      if (x & 0x100000 > 0)
        result = result * 0x100000000000B17217F7D1D351A389D40 >> 128;
      if (x & 0x80000 > 0)
        result = result * 0x10000000000058B90BFBE8E8B2D3D4EDE >> 128;
      if (x & 0x40000 > 0)
        result = result * 0x1000000000002C5C85FDF4741BEA6E77E >> 128;
      if (x & 0x20000 > 0)
        result = result * 0x100000000000162E42FEFA39FE95583C2 >> 128;
      if (x & 0x10000 > 0)
        result = result * 0x1000000000000B17217F7D1CFB72B45E1 >> 128;
      if (x & 0x8000 > 0)
        result = result * 0x100000000000058B90BFBE8E7CC35C3F0 >> 128;
      if (x & 0x4000 > 0)
        result = result * 0x10000000000002C5C85FDF473E242EA38 >> 128;
      if (x & 0x2000 > 0)
        result = result * 0x1000000000000162E42FEFA39F02B772C >> 128;
      if (x & 0x1000 > 0)
        result = result * 0x10000000000000B17217F7D1CF7D83C1A >> 128;
      if (x & 0x800 > 0)
        result = result * 0x1000000000000058B90BFBE8E7BDCBE2E >> 128;
      if (x & 0x400 > 0)
        result = result * 0x100000000000002C5C85FDF473DEA871F >> 128;
      if (x & 0x200 > 0)
        result = result * 0x10000000000000162E42FEFA39EF44D91 >> 128;
      if (x & 0x100 > 0)
        result = result * 0x100000000000000B17217F7D1CF79E949 >> 128;
      if (x & 0x80 > 0)
        result = result * 0x10000000000000058B90BFBE8E7BCE544 >> 128;
      if (x & 0x40 > 0)
        result = result * 0x1000000000000002C5C85FDF473DE6ECA >> 128;
      if (x & 0x20 > 0)
        result = result * 0x100000000000000162E42FEFA39EF366F >> 128;
      if (x & 0x10 > 0)
        result = result * 0x1000000000000000B17217F7D1CF79AFA >> 128;
      if (x & 0x8 > 0)
        result = result * 0x100000000000000058B90BFBE8E7BCD6D >> 128;
      if (x & 0x4 > 0)
        result = result * 0x10000000000000002C5C85FDF473DE6B2 >> 128;
      if (x & 0x2 > 0)
        result = result * 0x1000000000000000162E42FEFA39EF358 >> 128;
      if (x & 0x1 > 0)
        result = result * 0x10000000000000000B17217F7D1CF79AB >> 128;

      result >>= uint256 (int256 (63 - (x >> 64)));
      require (result <= uint256 (int256 (MAX_64x64)));

      return int128 (int256 (result));
    }
  }

  /**
   * Calculate natural exponent of x.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function exp (int128 x) internal pure returns (int128) {
    unchecked {
      require (x < 0x400000000000000000); // Overflow

      if (x < -0x400000000000000000) return 0; // Underflow

      return exp_2 (
          int128 (int256 (x) * 0x171547652B82FE1777D0FFDA0D23A7D12 >> 128));
    }
  }

  /**
   * Calculate x / y rounding towards zero, where x and y are unsigned 256-bit
   * integer numbers.  Revert on overflow or when y is zero.
   *
   * @param x unsigned 256-bit integer number
   * @param y unsigned 256-bit integer number
   * @return unsigned 64.64-bit fixed point number
   */
  function divuu (uint256 x, uint256 y) private pure returns (uint128) {
    unchecked {
      require (y != 0);

      uint256 result;

      if (x <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
        result = (x << 64) / y;
      else {
        uint256 msb = 192;
        uint256 xc = x >> 192;
        if (xc >= 0x100000000) { xc >>= 32; msb += 32; }
        if (xc >= 0x10000) { xc >>= 16; msb += 16; }
        if (xc >= 0x100) { xc >>= 8; msb += 8; }
        if (xc >= 0x10) { xc >>= 4; msb += 4; }
        if (xc >= 0x4) { xc >>= 2; msb += 2; }
        if (xc >= 0x2) msb += 1;  // No need to shift xc anymore

        result = (x << 255 - msb) / ((y - 1 >> msb - 191) + 1);
        require (result <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);

        uint256 hi = result * (y >> 128);
        uint256 lo = result * (y & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);

        uint256 xh = x >> 192;
        uint256 xl = x << 64;

        if (xl < lo) xh -= 1;
        xl -= lo; // We rely on overflow behavior here
        lo = hi << 128;
        if (xl < lo) xh -= 1;
        xl -= lo; // We rely on overflow behavior here

        assert (xh == hi >> 128);

        result += xl / y;
      }

      require (result <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
      return uint128 (result);
    }
  }

  /**
   * Calculate sqrt (x) rounding down, where x is unsigned 256-bit integer
   * number.
   *
   * @param x unsigned 256-bit integer number
   * @return unsigned 128-bit integer number
   */
  function sqrtu (uint256 x) private pure returns (uint128) {
    unchecked {
      if (x == 0) return 0;
      else {
        uint256 xx = x;
        uint256 r = 1;
        if (xx >= 0x100000000000000000000000000000000) { xx >>= 128; r <<= 64; }
        if (xx >= 0x10000000000000000) { xx >>= 64; r <<= 32; }
        if (xx >= 0x100000000) { xx >>= 32; r <<= 16; }
        if (xx >= 0x10000) { xx >>= 16; r <<= 8; }
        if (xx >= 0x100) { xx >>= 8; r <<= 4; }
        if (xx >= 0x10) { xx >>= 4; r <<= 2; }
        if (xx >= 0x8) { r <<= 1; }
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1; // Seven iterations should be enough
        uint256 r1 = x / r;
        return uint128 (r < r1 ? r : r1);
      }
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import {SafeERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import {AssetModule} from "./modules/AssetModule.sol";
import {ExecutionModule} from "./modules/ExecutionModule.sol";
import {ManagementFeeModule} from "./modules/ManagementFeeModule.sol";
import {PerformanceFeeModule} from "./modules/PerformanceFeeModule.sol";
import {ShareModule} from "./modules/ShareModule.sol";
import {IAssetRouter} from "./assets/interfaces/IAssetRouter.sol";
import {IComptroller} from "./interfaces/IComptroller.sol";
import {IShareToken} from "./interfaces/IShareToken.sol";
import {Errors} from "./utils/Errors.sol";

/// @title The implementation contract for fund
/// @notice The functions that requires ownership, interaction between
///         different modules should be overridden and implemented here.
contract FundImplementation is AssetModule, ShareModule, ExecutionModule, ManagementFeeModule, PerformanceFeeModule {
    using SafeERC20 for IERC20;
    using SafeCast for uint256;

    constructor() {
        // set owner to address(0) in implementation contract
        renounceOwnership();
    }

    /////////////////////////////////////////////////////
    // State Changes
    /////////////////////////////////////////////////////
    /// @notice Initializer, only in `Initializing` state.
    /// @param level_ The tier of the fund.
    /// @param comptroller_ The comptroller address.
    /// @param denomination_ The denomination asset.
    /// @param shareToken_ The share token address.
    /// @param mFeeRate_ The management fee rate.
    /// @param pFeeRate_ The performance fee rate.
    /// @param crystallizationPeriod_ The crystallization period.
    /// @param newOwner_ The owner to be assigned to the fund.
    function initialize(
        uint256 level_,
        IComptroller comptroller_,
        IERC20 denomination_,
        IShareToken shareToken_,
        uint256 mFeeRate_,
        uint256 pFeeRate_,
        uint256 crystallizationPeriod_,
        address newOwner_
    ) external whenState(State.Initializing) {
        _setLevel(level_);
        _setComptroller(comptroller_);
        _setDenomination(denomination_);
        _setShareToken(shareToken_);
        _setManagementFeeRate(mFeeRate_);
        _setPerformanceFeeRate(pFeeRate_);
        _setCrystallizationPeriod(crystallizationPeriod_);
        _setVault(comptroller_.dsProxyRegistry());
        _setMortgageVault(comptroller_);
        _transferOwnership(newOwner_);
        _review();
    }

    /// @notice Finalize the initialization of the fund.
    function finalize() external nonReentrant onlyOwner {
        _finalize();

        // Add denomination to list and never remove
        Errors._require(getAssetList().length == 0, Errors.Code.IMPLEMENTATION_ASSET_LIST_NOT_EMPTY);

        Errors._require(
            comptroller.isValidDenomination(address(denomination)),
            Errors.Code.IMPLEMENTATION_INVALID_DENOMINATION
        );
        _addAsset(address(denomination));

        // Set approval for investor to redeem
        _setVaultApproval(comptroller.setupAction());

        // Initialize management fee parameters
        _initializeManagementFee();

        // Initialize performance fee parameters
        _initializePerformanceFee();

        // Transfer mortgage token to this fund then call mortgage vault
        (bool isMortgageTierSet, uint256 amount) = comptroller.mortgageTier(level);
        Errors._require(isMortgageTierSet, Errors.Code.IMPLEMENTATION_INVALID_MORTGAGE_TIER);
        if (amount > 0) {
            IERC20 mortgageToken = mortgageVault.mortgageToken();
            mortgageToken.safeTransferFrom(msg.sender, address(this), amount);
            mortgageToken.safeApprove(address(mortgageVault), amount);
            mortgageVault.mortgage(amount);
        }
    }

    /// @notice Resume the fund by anyone if can settle pending share.
    /// @dev Resume only in `Pending` state.
    function resume() external nonReentrant whenState(State.Pending) {
        uint256 grossAssetValue = getGrossAssetValue();
        Errors._require(
            _isPendingResolvable(true, grossAssetValue),
            Errors.Code.IMPLEMENTATION_PENDING_SHARE_NOT_RESOLVABLE
        );
        _settlePendingShare(true);
        _resume();
    }

    /// @notice Liquidate the fund by anyone and transfer owner to liquidator.
    function liquidate() external nonReentrant {
        Errors._require(pendingStartTime != 0, Errors.Code.IMPLEMENTATION_PENDING_NOT_START);
        Errors._require(
            block.timestamp >= pendingStartTime + comptroller.pendingExpiration(),
            Errors.Code.IMPLEMENTATION_PENDING_NOT_EXPIRE
        );
        _crystallize();
        _liquidate();

        _transferOwnership(comptroller.pendingLiquidator());
    }

    /// @notice Close fund. The pending share will be settled without penalty.
    /// @dev This function can only be used in `Executing` and `Liquidating` states.
    /// @inheritdoc AssetModule
    function close() public override onlyOwner nonReentrant whenStates(State.Executing, State.Liquidating) {
        _settlePendingShare(false);
        if (state == State.Executing) {
            _crystallize();
        }
        super.close();

        mortgageVault.claim(msg.sender);
    }

    /////////////////////////////////////////////////////
    // Setters
    /////////////////////////////////////////////////////
    /// @notice Set management fee rate only in `Reviewing` state.
    /// @param mFeeRate_ The management fee rate on a 1e4 basis.
    function setManagementFeeRate(uint256 mFeeRate_) external onlyOwner whenState(State.Reviewing) {
        _setManagementFeeRate(mFeeRate_);
    }

    /// @notice Set performance fee rate only in `Reviewing` state.
    /// @param pFeeRate_ The performance fee rate on a 1e4 basis.
    function setPerformanceFeeRate(uint256 pFeeRate_) external onlyOwner whenState(State.Reviewing) {
        _setPerformanceFeeRate(pFeeRate_);
    }

    /// @notice Set crystallization period only in `Reviewing` state.
    /// @param crystallizationPeriod_ The crystallization period to be set in second.
    function setCrystallizationPeriod(uint256 crystallizationPeriod_) external onlyOwner whenState(State.Reviewing) {
        _setCrystallizationPeriod(crystallizationPeriod_);
    }

    /////////////////////////////////////////////////////
    // Getters
    /////////////////////////////////////////////////////
    /// @notice Get gross asset value.
    /// @return Convert value to denomination amount.
    function getGrossAssetValue() public view virtual returns (uint256) {
        address[] memory assets = getAssetList();
        uint256 length = assets.length;
        uint256[] memory amounts = new uint256[](length);
        for (uint256 i = 0; i < length; i++) {
            amounts[i] = IERC20(assets[i]).balanceOf(address(vault));
        }

        return _getAssetRouter().calcAssetsTotalValue(assets, amounts, address(denomination));
    }

    /// @notice Get the value of a give asset.
    /// @param asset_ The asset to be queried.
    function getAssetValue(address asset_) public view returns (int256) {
        uint256 balance = IERC20(asset_).balanceOf(address(vault));
        if (balance == 0) return 0;

        return _getAssetRouter().calcAssetValue(asset_, balance, address(denomination));
    }

    function _getAssetRouter() internal view returns (IAssetRouter) {
        return comptroller.assetRouter();
    }

    /// inheritdoc ShareModule, PerformanceFeeModule.
    function __getGrossAssetValue() internal view override(ShareModule, PerformanceFeeModule) returns (uint256) {
        return getGrossAssetValue();
    }

    /// @notice Get the balance of the denomination asset.
    /// @return The balance of reserve.
    /// @inheritdoc ShareModule
    function getReserve() public view override returns (uint256) {
        return denomination.balanceOf(address(vault));
    }

    /////////////////////////////////////////////////////
    // Asset Module
    /////////////////////////////////////////////////////
    /// @notice Add the asset to the tracking list by owner.
    /// @param asset_ The asset to be added.
    function addAsset(address asset_) external nonReentrant onlyOwner {
        _addAsset(asset_);
        _checkAssetCapacity();
    }

    /// @notice Add the asset to the tracking list.
    /// @param asset_ The asset to be added.
    /// @inheritdoc AssetModule
    function _addAsset(address asset_) internal override {
        Errors._require(comptroller.isValidDealingAsset(level, asset_), Errors.Code.IMPLEMENTATION_INVALID_ASSET);

        address _denomination = address(denomination);
        if (asset_ == _denomination) {
            super._addAsset(asset_);
        } else {
            int256 value = getAssetValue(asset_);
            int256 dust = _getDenominationDust(_denomination);

            if (value >= dust || value < 0) {
                super._addAsset(asset_);
            }
        }
    }

    /// @notice Remove the asset from the tracking list by owner.
    /// @param asset_ The asset to be removed.
    function removeAsset(address asset_) external nonReentrant onlyOwner {
        _removeAsset(asset_);
    }

    /// @notice Remove the asset from the tracking list.
    /// @param asset_ The asset to be removed.
    /// @inheritdoc AssetModule
    function _removeAsset(address asset_) internal override {
        // Do not allow to remove denomination from list
        address _denomination = address(denomination);
        if (asset_ != _denomination) {
            int256 value = getAssetValue(asset_);
            int256 dust = _getDenominationDust(_denomination);

            if (value < dust && value >= 0) {
                super._removeAsset(asset_);
            }
        }
    }

    /// @notice Get the denomination dust.
    /// @param denomination_ The denomination address.
    /// @return The dust of denomination.
    function _getDenominationDust(address denomination_) internal view returns (int256) {
        return comptroller.getDenominationDust(denomination_).toInt256();
    }

    /////////////////////////////////////////////////////
    // Execution module
    /////////////////////////////////////////////////////
    /// @inheritdoc ExecutionModule
    function execute(bytes calldata data_) public override nonReentrant onlyOwner {
        super.execute(data_);
    }

    /// @notice Check if the gross asset value is more than gross asset value tolerance after execute.
    function _isAfterValueEnough(uint256 prevAssetValue_, uint256 grossAssetValue_) internal view returns (bool) {
        uint256 minGrossAssetValue = (prevAssetValue_ * comptroller.execAssetValueToleranceRate()) /
            _FUND_PERCENTAGE_BASE;

        return grossAssetValue_ >= minGrossAssetValue;
    }

    /// @notice Execute an action on the fund's behalf.
    /// @return The gross asset value.
    /// @inheritdoc ExecutionModule
    function _beforeExecute() internal virtual override returns (uint256) {
        return getGrossAssetValue();
    }

    /// @notice Check the reserve after the execution.
    /// @return The gross asset value.
    /// @inheritdoc ExecutionModule
    function _afterExecute(bytes memory response_, uint256 prevGrossAssetValue_) internal override returns (uint256) {
        // Remove asset from assetList
        address[] memory assetList = getAssetList();
        for (uint256 i = 0; i < assetList.length; ++i) {
            _removeAsset(assetList[i]);
        }

        // Add new asset to assetList
        address[] memory dealingAssets = abi.decode(response_, (address[]));
        for (uint256 i = 0; i < dealingAssets.length; ++i) {
            _addAsset(dealingAssets[i]);
        }

        _checkAssetCapacity();

        // Get new gross asset value
        uint256 grossAssetValue = getGrossAssetValue();
        Errors._require(
            _isAfterValueEnough(prevGrossAssetValue_, grossAssetValue),
            Errors.Code.IMPLEMENTATION_INSUFFICIENT_TOTAL_VALUE_FOR_EXECUTION
        );

        // Resume fund if the balance is sufficient to resolve pending state
        if (state == State.Pending && _isPendingResolvable(true, grossAssetValue)) {
            uint256 totalRedemption = _settlePendingShare(true);
            _resume();
            // minus redeemed denomination amount
            grossAssetValue -= totalRedemption;
        }

        return grossAssetValue;
    }

    /////////////////////////////////////////////////////
    // Management fee module
    /////////////////////////////////////////////////////
    /// @notice Manangement fee should only be accumulated in `Executing` state.
    /// @return The newly minted shares.
    /// @inheritdoc ManagementFeeModule
    function _updateManagementFee() internal override returns (uint256) {
        if (state == State.Executing) {
            return super._updateManagementFee();
        } else if (state == State.Pending) {
            lastMFeeClaimTime = block.timestamp;
        }
        return 0;
    }

    /////////////////////////////////////////////////////
    // Performance fee module
    /////////////////////////////////////////////////////
    /// @notice Crystallize for the performance fee.
    /// @dev This function can only be used in `Executing` and `Pending` states.
    /// @inheritdoc PerformanceFeeModule
    function crystallize()
        public
        override
        nonReentrant
        onlyOwner
        whenStates(State.Executing, State.Pending)
        returns (uint256)
    {
        return super.crystallize();
    }

    /// @notice Update the performace fee.
    /// @dev This function works only in `Executing` and `Pending` states.
    /// @inheritdoc PerformanceFeeModule
    function _updatePerformanceFee(uint256 grossAssetValue_) internal override {
        if (state == State.Executing || state == State.Pending) {
            super._updatePerformanceFee(grossAssetValue_);
        }
    }

    /// @notice Update the management fee before crystallization.
    /// @return The performance fee amount to be claimed.
    /// @inheritdoc PerformanceFeeModule
    function _crystallize() internal override returns (uint256) {
        _updateManagementFee();
        return super._crystallize();
    }

    /////////////////////////////////////////////////////
    // Share module
    /////////////////////////////////////////////////////
    /// @notice Update the management fee and performance fee before purchase
    ///         to get the lastest share price.
    /// @return The gross asset value.
    /// @inheritdoc ShareModule
    function _beforePurchase() internal override returns (uint256) {
        uint256 grossAssetValue = getGrossAssetValue();
        _updateManagementFee();
        _updatePerformanceFee(grossAssetValue);
        return grossAssetValue;
    }

    /// @notice Update the gross share price after purchase.
    /// @dev Attempt to settle in `Pending` state and resume to `Executing` state
    ///      if the fund is resolvable.
    /// @inheritdoc ShareModule
    function _afterPurchase(uint256 grossAssetValue_) internal override {
        _updateGrossSharePrice(grossAssetValue_);
        if (state == State.Pending && _isPendingResolvable(true, grossAssetValue_)) {
            grossAssetValue_ -= _settlePendingShare(true);
            _updateGrossSharePrice(grossAssetValue_);
            _resume();
        }
        return;
    }

    /// @notice Update the management fee and performance fee before redeem
    ///         to get the latest share price.
    /// @return The gross asset value.
    /// @inheritdoc ShareModule
    function _beforeRedeem() internal override returns (uint256) {
        uint256 grossAssetValue = getGrossAssetValue();
        _updateManagementFee();
        _updatePerformanceFee(grossAssetValue);
        return grossAssetValue;
    }

    /// @notice Update the gross share price after redeem.
    /// @inheritdoc ShareModule
    function _afterRedeem(uint256 grossAssetValue_) internal override {
        _updateGrossSharePrice(grossAssetValue_);
        return;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {LibUniqueAddressList} from "./libraries/LibUniqueAddressList.sol";
import {IComptroller} from "./interfaces/IComptroller.sol";
import {IDSProxy} from "./interfaces/IDSProxy.sol";
import {IShareToken} from "./interfaces/IShareToken.sol";
import {IMortgageVault} from "./interfaces/IMortgageVault.sol";

/// @title Furucombo fund proxy storage
/// @dev This is the first version of the storage layout which must be consistent after add new states.
abstract contract FundProxyStorageV1 is Ownable, ReentrancyGuard {
    /// Fund States
    /// Initializing - The initial state of a newly created fund, set the basic parameters of Fund.
    /// Reviewing - After initialization, only the fee parameter can be adjusted.
    /// Executing - Normal operation, when the remaining amount of denomination is positive.
    /// Pending - Unable to fulfill redemption will enter pending state. When the purchase amount is
    ///           sufficient or the strategy is executed to settle the debt, it will resume to Executing state.
    /// Liquidating - When the fund stays in pending state over pendingExpiration, it enters liquidation
    ///               process. The fund will be transferred to the liquidator, who is responsible for
    ///               exchanging assets back to denomination tokens.
    /// Closed - When only denomination tokens are left, the fund can be closed and the investors can
    ///          redeem their share token.
    enum State {
        Initializing,
        Reviewing,
        Executing,
        Pending,
        Liquidating,
        Closed
    }

    /// Pending user info stores the settled share tokens per round.
    struct PendingUserInfo {
        uint256 pendingRound;
        uint256 pendingShare;
    }

    /// Pending round info stored the total pending share and total redemption amount.
    struct PendingRoundInfo {
        uint256 totalPendingShare;
        uint256 totalRedemption;
    }

    /// @notice The level of this fund.
    uint256 public level;

    /// @notice The timestamp of entering pending state.
    uint256 public pendingStartTime;

    /// @notice The current state of the fund.
    State public state;

    /// @notice The comptroller of the fund.
    IComptroller public comptroller;

    /// @notice The denomination token for this fund.
    IERC20 public denomination;

    /// @notice The fund share token contract.
    IShareToken public shareToken;

    /// @notice The contract used to store fund assets.
    IDSProxy public vault;

    /// @notice The mortgage vault of this fund.
    IMortgageVault public mortgageVault;

    /// @notice The asset list currently managed by fund.
    LibUniqueAddressList.List internal _assetList;

    /// @notice The current total pending share amount.
    uint256 public currentTotalPendingShare;

    /// @notice The current total bunus share token amount.
    uint256 public currentTotalPendingBonus;

    /// @notice The pending round info list.
    PendingRoundInfo[] public pendingRoundList;

    /// @notice The pending info list of each pending user.
    mapping(address => PendingUserInfo) public pendingUsers;

    /// @notice The last timestamp of claiming management fee.
    uint256 public lastMFeeClaimTime;

    /// @notice The management fee rate, should be a floating point number.
    int128 public mFeeRate64x64;

    /// @notice The high water mark, should be a floating point number.
    int128 public hwm64x64;

    /// @notice The last gross share price, should be a floating point number.
    int128 public lastGrossSharePrice64x64;

    /// @notice The performance fee rate, should be a floating point number.
    int128 public pFeeRate64x64;

    /// @notice The sum of performance fee.
    uint256 public pFeeSum;

    /// @notice The last outstanding share amount.
    uint256 public lastOutstandingShare;

    /// @notice The timestamp of starting crystallization.
    uint256 public crystallizationStart;

    /// @notice The crystallization period to be set in second.
    uint256 public crystallizationPeriod;

    /// @notice The last crystallization timestamp.
    uint256 public lastCrystallization;
}

abstract contract FundProxyStorage is FundProxyStorageV1 {}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Errors} from "./utils/Errors.sol";
import {FundProxyStorage} from "./FundProxyStorage.sol";
import {IComptroller} from "./interfaces/IComptroller.sol";
import {IDSProxy, IDSProxyRegistry} from "./interfaces/IDSProxy.sol";
import {IShareToken} from "./interfaces/IShareToken.sol";
import {ISetupAction} from "./interfaces/ISetupAction.sol";

/// @title Furucombo fund proxy storage utility
abstract contract FundProxyStorageUtils is FundProxyStorage {
    uint256 internal constant _FUND_PERCENTAGE_BASE = 1e4;

    event StateTransited(State to);

    error InvalidState(State current);

    /// @dev Prevent functions from being called outside of this state.
    modifier whenState(State expect_) {
        _whenState(expect_);
        _;
    }

    /// @dev Prevent functions from being called outside of these two states.
    modifier whenStates(State expect1_, State expect2_) {
        _whenStates(expect1_, expect2_);
        _;
    }

    /// @dev Prevent functions from being called outside of these three states.
    modifier when3States(
        State expect1_,
        State expect2_,
        State expect3_
    ) {
        _when3States(expect1_, expect2_, expect3_);
        _;
    }

    /// @dev Prevent the function from being called in this state.
    modifier whenNotState(State expectNot_) {
        _whenNotState(expectNot_);
        _;
    }

    /// @dev Prevent functions from being called outside of this state.
    function _whenState(State expect_) internal view {
        if (state != expect_) revert InvalidState(state);
    }

    /// @dev Prevent functions from being called outside of this two state.
    function _whenStates(State expect1_, State expect2_) internal view {
        State s = state;
        if (s != expect1_ && s != expect2_) revert InvalidState(s);
    }

    /// @dev Prevent functions from being called outside of this three state.
    function _when3States(
        State expect1_,
        State expect2_,
        State expect3_
    ) internal view {
        State s = state;
        if (s != expect1_ && s != expect2_ && s != expect3_) revert InvalidState(s);
    }

    /// @dev Prevent the function from being called in this state.
    function _whenNotState(State expectNot_) internal view {
        if (state == expectNot_) revert InvalidState(state);
    }

    /// @dev Enter `Reviewing` state from `Initializing` state only.
    function _review() internal whenState(State.Initializing) {
        _enterState(State.Reviewing);
    }

    /// @dev Enter `Executing` state from `Reviewing` state only.
    function _finalize() internal whenState(State.Reviewing) {
        _enterState(State.Executing);
    }

    /// @dev Enter `Pending` state from `Executing` state only.
    function _pend() internal whenState(State.Executing) {
        _enterState(State.Pending);
        pendingStartTime = block.timestamp;
    }

    /// @dev Enter `Executing` state from `Pending` state only.
    function _resume() internal whenState(State.Pending) {
        pendingStartTime = 0;
        _enterState(State.Executing);
    }

    /// @dev Enter `Liquidating` state from `Pending` state only.
    function _liquidate() internal whenState(State.Pending) {
        pendingStartTime = 0;
        _enterState(State.Liquidating);
    }

    /// @dev Enter `Closed` state from `Executing` and `Liquidating` states only.
    function _close() internal whenStates(State.Executing, State.Liquidating) {
        _enterState(State.Closed);
    }

    /// @dev Change the fund state and emit state transited event.
    function _enterState(State state_) internal {
        state = state_;
        emit StateTransited(state_);
    }

    /////////////////////////////////////////////////////
    // Setters
    /////////////////////////////////////////////////////
    /// @notice Set the tier of the fund.
    function _setLevel(uint256 level_) internal {
        _checkZero(level);
        _checkNotZero(level_);
        level = level_;
    }

    /// @notice Set the comptroller of the fund.
    function _setComptroller(IComptroller comptroller_) internal {
        _checkZero(address(comptroller));
        _checkNotZero(address(comptroller_));
        comptroller = comptroller_;
    }

    /// @notice Set the denomination of the fund.
    function _setDenomination(IERC20 denomination_) internal {
        _checkZero(address(denomination));
        Errors._require(
            comptroller.isValidDenomination(address(denomination_)),
            Errors.Code.FUND_PROXY_STORAGE_UTILS_INVALID_DENOMINATION
        );
        denomination = denomination_;
    }

    /// @notice Set the share token of the fund.
    function _setShareToken(IShareToken shareToken_) internal {
        _checkZero(address(shareToken));
        _checkNotZero(address(shareToken_));
        shareToken = shareToken_;
    }

    /// @notice Set the mortgage vault of the fund.
    function _setMortgageVault(IComptroller comptroller_) internal {
        _checkZero(address(mortgageVault));
        mortgageVault = comptroller_.mortgageVault();
    }

    /// @notice Set the asset vault of the fund.
    function _setVault(IDSProxyRegistry dsProxyRegistry_) internal {
        _checkZero(address(vault));
        _checkNotZero(address(dsProxyRegistry_));

        // check if vault proxy exists
        IDSProxy vaultProxy = IDSProxy(dsProxyRegistry_.proxies(address(this)));
        if (address(vaultProxy) != address(0)) {
            Errors._require(vaultProxy.owner() == address(this), Errors.Code.FUND_PROXY_STORAGE_UTILS_UNKNOWN_OWNER);
            vault = vaultProxy;
        } else {
            // deploy vault
            vault = IDSProxy(dsProxyRegistry_.build());
            _checkNotZero(address(vault));
        }
    }

    /// @notice Set the vault approval.
    function _setVaultApproval(ISetupAction setupAction_) internal {
        _checkNotZero(address(vault));
        _checkNotZero(address(setupAction_));

        // set vault approval
        bytes memory data = abi.encodeWithSignature("maxApprove(address)", denomination);
        vault.execute(address(setupAction_), data);

        Errors._require(
            denomination.allowance(address(vault), address(this)) == type(uint256).max,
            Errors.Code.FUND_PROXY_STORAGE_UTILS_WRONG_ALLOWANCE
        );
    }

    /// @dev Check if the uint256 is zero.
    function _checkZero(uint256 param_) private pure {
        Errors._require(param_ == 0, Errors.Code.FUND_PROXY_STORAGE_UTILS_IS_NOT_ZERO);
    }

    /// @dev Check if the address is zero address.
    function _checkZero(address param_) private pure {
        Errors._require(param_ == address(0), Errors.Code.FUND_PROXY_STORAGE_UTILS_IS_NOT_ZERO);
    }

    /// @dev Check if the uint256 is not zero.
    function _checkNotZero(uint256 param_) private pure {
        Errors._require(param_ > 0, Errors.Code.FUND_PROXY_STORAGE_UTILS_IS_ZERO);
    }

    /// @dev Check if the address is not zero address.
    function _checkNotZero(address param_) private pure {
        Errors._require(param_ != address(0), Errors.Code.FUND_PROXY_STORAGE_UTILS_IS_ZERO);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IAssetOracle {
    function calcConversionAmount(
        address base_,
        uint256 baseAmount_,
        address quote_
    ) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IAssetRegistry {
    function bannedResolvers(address) external view returns (bool);

    function register(address asset_, address resolver_) external;

    function unregister(address asset_) external;

    function banResolver(address resolver_) external;

    function unbanResolver(address resolver_) external;

    function resolvers(address asset_) external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IAssetRegistry} from "./IAssetRegistry.sol";
import {IAssetOracle} from "./IAssetOracle.sol";

interface IAssetRouter {
    function oracle() external view returns (IAssetOracle);

    function registry() external view returns (IAssetRegistry);

    function setOracle(address oracle_) external;

    function setRegistry(address registry_) external;

    function calcAssetsTotalValue(
        address[] calldata bases_,
        uint256[] calldata amounts_,
        address quote_
    ) external view returns (uint256);

    function calcAssetValue(
        address asset_,
        uint256 amount_,
        address quote_
    ) external view returns (int256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IAssetRouter} from "../assets/interfaces/IAssetRouter.sol";
import {IMortgageVault} from "./IMortgageVault.sol";
import {IDSProxyRegistry} from "./IDSProxy.sol";
import {ISetupAction} from "./ISetupAction.sol";

interface IComptroller {
    function owner() external view returns (address);

    function canDelegateCall(
        uint256 level_,
        address to_,
        bytes4 sig_
    ) external view returns (bool);

    function canContractCall(
        uint256 level_,
        address to_,
        bytes4 sig_
    ) external view returns (bool);

    function canHandlerCall(
        uint256 level_,
        address to_,
        bytes4 sig_
    ) external view returns (bool);

    function execFeePercentage() external view returns (uint256);

    function execFeeCollector() external view returns (address);

    function pendingLiquidator() external view returns (address);

    function pendingExpiration() external view returns (uint256);

    function execAssetValueToleranceRate() external view returns (uint256);

    function isValidDealingAsset(uint256 level_, address asset_) external view returns (bool);

    function isValidDealingAssets(uint256 level_, address[] calldata assets_) external view returns (bool);

    function isValidInitialAssets(uint256 level_, address[] calldata assets_) external view returns (bool);

    function assetCapacity() external view returns (uint256);

    function assetRouter() external view returns (IAssetRouter);

    function mortgageVault() external view returns (IMortgageVault);

    function pendingPenalty() external view returns (uint256);

    function execAction() external view returns (address);

    function mortgageTier(uint256 tier_) external view returns (bool, uint256);

    function isValidDenomination(address denomination_) external view returns (bool);

    function getDenominationDust(address denomination_) external view returns (uint256);

    function isValidCreator(address creator_) external view returns (bool);

    function dsProxyRegistry() external view returns (IDSProxyRegistry);

    function setupAction() external view returns (ISetupAction);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IDSProxy {
    function execute(address _target, bytes calldata _data) external payable returns (bytes memory response);

    function owner() external view returns (address);

    function setAuthority(address authority_) external;
}

interface IDSProxyFactory {
    function isProxy(address proxy) external view returns (bool);

    function build() external returns (address);

    function build(address owner) external returns (address);
}

interface IDSProxyRegistry {
    function proxies(address input) external view returns (address);

    function build() external returns (address);

    function build(address owner) external returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IMortgageVault {
    function mortgageToken() external view returns (IERC20);

    function totalAmount() external view returns (uint256);

    function fundAmounts(address fund_) external view returns (uint256);

    function mortgage(uint256 amount_) external;

    function claim(address receiver_) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ISetupAction {
    function maxApprove(IERC20 token_) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol";

interface IShareToken is IERC20, IERC20Permit {
    function mint(address account_, uint256 amount_) external;

    function burn(address account_, uint256 amount_) external;

    function move(
        address sender_,
        address recipient_,
        uint256 amount_
    ) external;

    function netTotalShare() external view returns (uint256);

    function grossTotalShare() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library LibFee {
    function _max64x64(int128 a_, int128 b_) internal pure returns (int128) {
        if (a_ > b_) {
            return a_;
        } else {
            return b_;
        }
    }

    function _max(int256 a_, int256 b_) internal pure returns (int256) {
        if (a_ > b_) {
            return a_;
        } else {
            return b_;
        }
    }

    function _max(uint256 a_, uint256 b_) internal pure returns (uint256) {
        if (a_ > b_) {
            return a_;
        } else {
            return b_;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library LibUniqueAddressList {
    using LibUniqueAddressList for List;

    address private constant _HEAD = address(0);
    address private constant _TAIL = address(0);
    address private constant _NULL = address(0);

    struct List {
        uint256 sz;
        mapping(address => address) predecessor;
        mapping(address => address) successor;
    }

    // Getters
    function _get(List storage self_) internal view returns (address[] memory list) {
        if (self_._empty()) {
            return list;
        } else {
            list = new address[](self_.sz);
            uint256 index = 0;
            for (address p = self_._front(); p != _TAIL; p = self_._next(p)) {
                list[index] = p;
                index++;
            }
        }
    }

    function _empty(List storage self_) internal view returns (bool) {
        return (self_.sz == 0);
    }

    function _size(List storage self_) internal view returns (uint256) {
        return self_.sz;
    }

    function _exist(List storage self_, address node_) internal view returns (bool) {
        return (self_.successor[node_] != _NULL);
    }

    function _front(List storage self_) internal view returns (address) {
        return self_.successor[_HEAD];
    }

    function _back(List storage self_) internal view returns (address) {
        return self_.predecessor[_TAIL];
    }

    function _next(List storage self_, address node_) internal view returns (address) {
        address n = self_.successor[node_];
        return node_ == n ? _TAIL : n;
    }

    function _prev(List storage self_, address node_) internal view returns (address) {
        address p = self_.predecessor[node_];
        return node_ == p ? _HEAD : p;
    }

    function _pushFront(List storage self_, address node_) internal returns (bool) {
        if (self_._exist(node_)) {
            return false;
        } else {
            address f = self_._front();
            _connect(self_, _HEAD, node_);
            _connect(self_, node_, f);
            self_.sz++;
            return true;
        }
    }

    function _pushBack(List storage self_, address node_) internal returns (bool) {
        if (self_._exist(node_)) {
            return false;
        } else {
            address b = self_._back();
            _connect(self_, b, node_);
            _connect(self_, node_, _TAIL);
            self_.sz++;
            return true;
        }
    }

    function _popFront(List storage self_) internal returns (bool) {
        if (self_._empty()) {
            return false;
        } else {
            address f = self_._front();
            address newFront = self_._next(f);
            _connect(self_, _HEAD, newFront);
            _delete(self_, f);
            return true;
        }
    }

    function _popBack(List storage self_) internal returns (bool) {
        if (self_._empty()) {
            return false;
        } else {
            address b = self_._back();
            address newBack = self_._prev(b);
            _connect(self_, newBack, _TAIL);
            _delete(self_, b);
            return true;
        }
    }

    function _insert(
        List storage self_,
        address loc_,
        address node_
    ) internal returns (bool) {
        if (loc_ == _NULL || node_ == _NULL) {
            return false;
        } else if (!self_._exist(loc_)) {
            return false;
        } else if (self_._exist(node_)) {
            return false;
        } else {
            address p = self_._prev(loc_);
            _connect(self_, p, node_);
            _connect(self_, node_, loc_);
            self_.sz++;
            return true;
        }
    }

    function _remove(List storage self_, address node_) internal returns (bool) {
        if (node_ == _NULL) {
            return false;
        } else if (!self_._exist(node_)) {
            return false;
        } else {
            address p = self_._prev(node_);
            address n = self_._next(node_);
            _connect(self_, p, n);
            _delete(self_, node_);
            return true;
        }
    }

    function _connect(
        List storage self_,
        address node1_,
        address node2_
    ) private {
        self_.successor[node1_] = node2_ == _TAIL ? node1_ : node2_;
        self_.predecessor[node2_] = node1_ == _HEAD ? node2_ : node1_;
    }

    function _delete(List storage self_, address node_) private {
        self_.predecessor[node_] = _NULL;
        self_.successor[node_] = _NULL;
        self_.sz--;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {FundProxyStorageUtils} from "../FundProxyStorageUtils.sol";
import {Errors} from "../utils/Errors.sol";
import {LibUniqueAddressList} from "../libraries/LibUniqueAddressList.sol";

/// @title Asset module
/// @notice Define the asset relate policy of the fund.
abstract contract AssetModule is FundProxyStorageUtils {
    using LibUniqueAddressList for LibUniqueAddressList.List;

    event AssetAdded(address asset);
    event AssetRemoved(address asset);

    /// @notice Get the permitted asset list.
    /// @return Return the permitted asset list array.
    function getAssetList() public view returns (address[] memory) {
        return _assetList._get();
    }

    /// @notice Check the remaining asset should be only the denomination asset
    /// when closing the vault.
    function close() public virtual {
        Errors._require(
            _assetList._size() == 1 && _assetList._front() == address(denomination),
            Errors.Code.ASSET_MODULE_DIFFERENT_ASSET_REMAINING
        );
        _close();
    }

    /// @notice Check asset capacity.
    function _checkAssetCapacity() internal view {
        Errors._require(
            getAssetList().length <= comptroller.assetCapacity(),
            Errors.Code.ASSET_MODULE_FULL_ASSET_CAPACITY
        );
    }

    /// @notice Add asset to the asset tracking list.
    /// @param asset_ The asset to be tracked.
    /// @dev This function can only be used in `Executing`, `Pending` and `Liquidating` states.
    function _addAsset(address asset_) internal virtual when3States(State.Executing, State.Pending, State.Liquidating) {
        if (_assetList._pushBack(asset_)) {
            emit AssetAdded(asset_);
        }
    }

    /// @notice Remove the asset from the asset tracking list.
    /// @dev This function can only be used in `Executing`, `Pending` and `Liquidating` states.
    function _removeAsset(address asset_)
        internal
        virtual
        when3States(State.Executing, State.Pending, State.Liquidating)
    {
        if (_assetList._remove(asset_)) {
            emit AssetRemoved(asset_);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {FundProxyStorageUtils} from "../FundProxyStorageUtils.sol";

/// @title Execution module
abstract contract ExecutionModule is FundProxyStorageUtils {
    event Executed();

    /// @notice Execute on the fund's behalf.
    /// @param data_ The data to be applied to the execution.
    /// @dev This function can only be used in `Executing`, `Pending` and `Liquidating` states.
    function execute(bytes calldata data_)
        public
        virtual
        when3States(State.Executing, State.Pending, State.Liquidating)
    {
        uint256 lastAmount = _beforeExecute();

        address action = comptroller.execAction();
        bytes memory response = vault.execute(action, data_);

        _afterExecute(response, lastAmount);

        emit Executed();
    }

    /// @notice The virtual function being called before execution.
    function _beforeExecute() internal virtual returns (uint256) {
        return 0;
    }

    /// @notice The virtual function being called after execution.
    function _afterExecute(bytes memory, uint256) internal virtual returns (uint256) {
        return 0;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ABDKMath64x64} from "abdk-libraries-solidity/ABDKMath64x64.sol";
import {FundProxyStorageUtils} from "../FundProxyStorageUtils.sol";
import {Errors} from "../utils/Errors.sol";

/// @title Management fee module
abstract contract ManagementFeeModule is FundProxyStorageUtils {
    using ABDKMath64x64 for int128;
    using ABDKMath64x64 for uint256;

    int128 private constant _FEE_BASE64x64 = 1 << 64;
    uint256 private constant _FEE_PERIOD = 31557600; // 365.25*24*60*60

    event ManagementFeeClaimed(address indexed manager, uint256 shareAmount);

    /// @notice Claim the accumulated management fee.
    /// @return The fee amount being claimed.
    function claimManagementFee() external virtual nonReentrant returns (uint256) {
        return _updateManagementFee();
    }

    /// @notice Initial the management fee claim time.
    function _initializeManagementFee() internal virtual {
        lastMFeeClaimTime = block.timestamp;
    }

    /// @notice Set the management fee in a yearly basis.
    /// @param feeRate_ The annual fee rate in a 1e4 base.
    /// @return The management fee rate.
    function _setManagementFeeRate(uint256 feeRate_) internal virtual returns (int128) {
        Errors._require(
            feeRate_ < _FUND_PERCENTAGE_BASE,
            Errors.Code.MANAGEMENT_FEE_MODULE_FEE_RATE_SHOULD_BE_LESS_THAN_FUND_BASE
        );
        return _setManagementFeeRate(feeRate_.divu(_FUND_PERCENTAGE_BASE));
    }

    /// @notice Set the management fee rate.
    /// @param feeRate64x64_ The annual fee rate in a 1e4 base.
    /// @return The management fee rate.
    /// @dev Calculate the effective fee rate to achieve the fee rate in an exponential model.
    function _setManagementFeeRate(int128 feeRate64x64_) internal returns (int128) {
        mFeeRate64x64 = uint256(1).fromUInt().sub(feeRate64x64_).ln().neg().div(_FEE_PERIOD.fromUInt()).exp();

        return mFeeRate64x64;
    }

    /// @notice Update the current management fee and mint to the manager right away.
    ///         Update the claim time as the basis of the accumulation afterward also.
    /// @return The share being minted this time.
    function _updateManagementFee() internal virtual returns (uint256) {
        uint256 currentTime = block.timestamp;
        uint256 totalShare = shareToken.grossTotalShare();

        uint256 shareDue = (mFeeRate64x64.pow(currentTime - lastMFeeClaimTime).sub(_FEE_BASE64x64)).mulu(totalShare);

        address manager = owner();
        shareToken.mint(manager, shareDue);
        lastMFeeClaimTime = currentTime;
        emit ManagementFeeClaimed(manager, shareDue);

        return shareDue;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import {ABDKMath64x64} from "abdk-libraries-solidity/ABDKMath64x64.sol";
import {FundProxyStorageUtils} from "../FundProxyStorageUtils.sol";
import {LibFee} from "../libraries/LibFee.sol";
import {Errors} from "../utils/Errors.sol";

/// @title Performance fee module
abstract contract PerformanceFeeModule is FundProxyStorageUtils {
    using ABDKMath64x64 for int128;
    using ABDKMath64x64 for uint256;
    using SafeCast for int256;
    using SafeCast for uint256;

    int128 private constant _FEE_BASE64x64 = 1 << 64;
    uint256 private constant _FEE_PERIOD = 31557600; // 365.25*24*60*60
    address private constant _OUTSTANDING_ACCOUNT = address(1);

    event PerformanceFeeClaimed(address indexed manager, uint256 shareAmount);

    /// @notice Return the next crystallization time even if more than one period has passed.
    /// @return The available time for crystallization.
    function getNextCrystallizationTime() external view returns (uint256) {
        uint256 lastPeriod = _timeToPeriod(lastCrystallization);
        return _periodToTime(lastPeriod + 1);
    }

    /// @notice Check if the fund can be crystallized.
    /// @return The boolean of can crystallize or not.
    function isCrystallizable() public view virtual returns (bool) {
        uint256 nowPeriod = _timeToPeriod(block.timestamp);
        uint256 lastPeriod = _timeToPeriod(lastCrystallization);
        return nowPeriod > lastPeriod;
    }

    /// @notice Crystallize for the performance fee.
    /// @return Return the performance fee amount to be claimed.
    /// @dev This will check whether it can be crystallized or not.
    function crystallize() public virtual returns (uint256) {
        Errors._require(isCrystallizable(), Errors.Code.PERFORMANCE_FEE_MODULE_CAN_NOT_CRYSTALLIZED_YET);
        return _crystallize();
    }

    /// @notice Crystallize for the performance fee.
    /// @return Return the performance fee amount to be claimed.
    function _crystallize() internal virtual returns (uint256) {
        uint256 totalShare = shareToken.netTotalShare();
        if (totalShare == 0) return 0;
        uint256 grossAssetValue = __getGrossAssetValue();
        _updatePerformanceFee(grossAssetValue);
        address manager = owner();
        shareToken.move(_OUTSTANDING_ACCOUNT, manager, lastOutstandingShare);
        _updateGrossSharePrice(grossAssetValue);
        uint256 result = lastOutstandingShare;
        lastOutstandingShare = 0;
        pFeeSum = 0;
        lastCrystallization = block.timestamp;
        hwm64x64 = LibFee._max64x64(hwm64x64, lastGrossSharePrice64x64);
        emit PerformanceFeeClaimed(manager, result);

        return result;
    }

    /// @notice Convert the time to the number of crystallization periods.
    /// @param timestamp_ The timestamp to be converted.
    /// @return The period of crystallization.
    function _timeToPeriod(uint256 timestamp_) internal view returns (uint256) {
        Errors._require(timestamp_ >= crystallizationStart, Errors.Code.PERFORMANCE_FEE_MODULE_TIME_BEFORE_START);
        return (timestamp_ - crystallizationStart) / crystallizationPeriod;
    }

    /// @notice Convert the number of crystallization periods to time.
    /// @param period_ The period to be converted.
    /// @return The starting time of the period.
    function _periodToTime(uint256 period_) internal view returns (uint256) {
        return crystallizationStart + period_ * crystallizationPeriod;
    }

    /// @notice Get the gross asset value.
    /// @return The value of gross asset.
    function __getGrossAssetValue() internal view virtual returns (uint256);

    /// @notice Initialize the performance fee, crystallization time and high water mark.
    function _initializePerformanceFee() internal virtual {
        lastGrossSharePrice64x64 = _FEE_BASE64x64;
        hwm64x64 = _FEE_BASE64x64;
        crystallizationStart = block.timestamp;
        lastCrystallization = block.timestamp;
    }

    /// @notice Set the performance fee rate.
    /// @param feeRate_ The fee rate on a 1e4 basis.
    /// @return The performance fee rate.
    function _setPerformanceFeeRate(uint256 feeRate_) internal virtual returns (int128) {
        Errors._require(
            feeRate_ < _FUND_PERCENTAGE_BASE,
            Errors.Code.PERFORMANCE_FEE_MODULE_FEE_RATE_SHOULD_BE_LESS_THAN_BASE
        );
        pFeeRate64x64 = feeRate_.divu(_FUND_PERCENTAGE_BASE);
        return pFeeRate64x64;
    }

    /// @notice Set the crystallization period.
    /// @param period_ The crystallization period to be set in second.
    function _setCrystallizationPeriod(uint256 period_) internal virtual {
        Errors._require(period_ > 0, Errors.Code.PERFORMANCE_FEE_MODULE_CRYSTALLIZATION_PERIOD_TOO_SHORT);
        crystallizationPeriod = period_;
    }

    /// @notice Update the performance fee based on the performance since last
    ///         update. The fee will be minted as outstanding shares.
    /// @param grossAssetValue_ The gross asset value.
    function _updatePerformanceFee(uint256 grossAssetValue_) internal virtual {
        // Get accumulated wealth
        uint256 totalShare = shareToken.netTotalShare();
        if (totalShare == 0) {
            // net asset value should be 0 also
            return;
        }
        int128 grossSharePrice64x64 = grossAssetValue_.divu(totalShare);
        int256 wealth = LibFee
            ._max64x64(hwm64x64, grossSharePrice64x64)
            .sub(LibFee._max64x64(hwm64x64, lastGrossSharePrice64x64))
            .muli(totalShare.toInt256());
        int256 fee = pFeeRate64x64.muli(wealth);
        pFeeSum = LibFee._max(0, pFeeSum.toInt256() + fee).toUint256();
        uint256 netAssetValue = grossAssetValue_ - pFeeSum;
        uint256 outstandingShare = (totalShare * pFeeSum) / netAssetValue;
        if (outstandingShare > lastOutstandingShare) {
            shareToken.mint(_OUTSTANDING_ACCOUNT, outstandingShare - lastOutstandingShare);
        } else {
            shareToken.burn(_OUTSTANDING_ACCOUNT, lastOutstandingShare - outstandingShare);
        }
        lastOutstandingShare = outstandingShare;
        lastGrossSharePrice64x64 = grossSharePrice64x64;
    }

    /// @notice Update gross share price.
    /// @param grossAssetValue_ The gross asset value.
    function _updateGrossSharePrice(uint256 grossAssetValue_) internal virtual {
        uint256 totalShare = shareToken.netTotalShare();
        lastGrossSharePrice64x64 = grossAssetValue_.divu(totalShare);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {FundProxyStorageUtils} from "../FundProxyStorageUtils.sol";
import {Errors} from "../utils/Errors.sol";

/// @title Share module
abstract contract ShareModule is FundProxyStorageUtils {
    using SafeERC20 for IERC20;

    uint256 private constant MINIMUM_SHARE = 1e3;

    event Purchased(address indexed user, uint256 assetAmount, uint256 shareAmount, uint256 bonusAmount);
    event Redeemed(address indexed user, uint256 assetAmount, uint256 shareAmount);
    event Pended(address indexed user, uint256 shareAmount, uint256 penaltyAmount);
    event PendingShareSettled();
    event RedemptionClaimed(address indexed user, uint256 assetAmount);

    /// @notice Calculate the share amount corresponding to the given balance.
    /// @param balance_ The balance of denomination.
    /// @return share The share amount.
    function calculateShare(uint256 balance_) external view returns (uint256 share) {
        uint256 grossAssetValue = __getGrossAssetValue();
        return _calculateShare(balance_, grossAssetValue);
    }

    function _calculateShare(uint256 balance_, uint256 grossAssetValue_) internal view virtual returns (uint256 share) {
        uint256 shareAmount = shareToken.grossTotalShare();
        if (shareAmount == 0) {
            // Handle initial purchase when balance_ > MINIMUM_SHARE, otherwise return share = 0
            if (balance_ > MINIMUM_SHARE) {
                share = balance_ - MINIMUM_SHARE;
            }
        } else {
            share = (shareAmount * balance_) / grossAssetValue_;
        }
    }

    /// @notice Calculate the balance amount corresponding to the given share amount.
    /// @param share_ The queried share amount.
    /// @return balance The balance.
    function calculateBalance(uint256 share_) external view returns (uint256 balance) {
        uint256 grossAssetValue = __getGrossAssetValue();
        balance = _calculateBalance(share_, grossAssetValue);
    }

    function _calculateBalance(uint256 share_, uint256 grossAssetValue_)
        internal
        view
        virtual
        returns (uint256 balance)
    {
        uint256 shareAmount = shareToken.grossTotalShare();
        Errors._require(share_ <= shareAmount, Errors.Code.SHARE_MODULE_SHARE_AMOUNT_TOO_LARGE);
        if (shareAmount == 0) {
            balance = 0;
        } else {
            balance = (share_ * grossAssetValue_) / shareAmount;
        }
    }

    /// @notice determine pending statue could be resolvable or not
    /// @param applyPenalty_ true if enable penalty otherwise false
    /// @return true if resolvable otherwise false
    function isPendingResolvable(bool applyPenalty_) external view returns (bool) {
        uint256 grossAssetValue = __getGrossAssetValue();

        return _isPendingResolvable(applyPenalty_, grossAssetValue);
    }

    function _isPendingResolvable(bool applyPenalty_, uint256 grossAssetValue_) internal view returns (bool) {
        uint256 redeemShare = _getResolvePendingShare(applyPenalty_);
        uint256 redeemShareBalance = _calculateBalance(redeemShare, grossAssetValue_);
        uint256 reserve = getReserve();

        return reserve >= redeemShareBalance;
    }

    /// @notice Calculate the max redeemable balance of the given share amount.
    /// @param share_ The share amount to be queried.
    /// @return shareLeft The share amount left due to insufficient reserve.
    /// @return balance The max redeemable balance from reserve.
    function calculateRedeemableBalance(uint256 share_) external view returns (uint256 shareLeft, uint256 balance) {
        uint256 grossAssetValue = __getGrossAssetValue();
        return _calculateRedeemableBalance(share_, grossAssetValue);
    }

    function _calculateRedeemableBalance(uint256 share_, uint256 grossAssetValue_)
        internal
        view
        virtual
        returns (uint256 shareLeft, uint256 balance)
    {
        balance = _calculateBalance(share_, grossAssetValue_);
        uint256 reserve = getReserve();

        // insufficient reserve
        if (balance > reserve) {
            uint256 shareToBurn = _calculateShare(reserve, grossAssetValue_);
            shareLeft = share_ - shareToBurn;
            balance = reserve;
        }
    }

    /// @notice Purchase share with the given balance.
    /// @return share The purchased share amount.
    /// @dev This function can only be used in `Executing` and `Pending` states.

    function purchase(uint256 balance_)
        external
        virtual
        whenStates(State.Executing, State.Pending)
        nonReentrant
        returns (uint256 share)
    {
        // Purchase balance need to greater than zero
        Errors._require(balance_ > 0, Errors.Code.SHARE_MODULE_PURCHASE_ZERO_BALANCE);

        share = _purchase(msg.sender, balance_);
    }

    function _purchase(address user_, uint256 balance_) internal virtual returns (uint256 share) {
        uint256 grossAssetValue = _beforePurchase();
        share = _addShare(user_, balance_, grossAssetValue);

        // Purchase share need to greater than zero
        Errors._require(share > 0, Errors.Code.SHARE_MODULE_PURCHASE_ZERO_SHARE);

        // No bonus to prevent frontrun if the purchase is simultaneous with pending state transition
        uint256 bonus;
        if (state == State.Pending && pendingStartTime != block.timestamp) {
            uint256 penalty = _getPendingPenalty();
            bonus = (share * (penalty)) / (_FUND_PERCENTAGE_BASE - penalty);
            bonus = currentTotalPendingBonus > bonus ? bonus : currentTotalPendingBonus;
            currentTotalPendingBonus -= bonus;
            shareToken.move(address(this), user_, bonus);
            share += bonus;
        }
        grossAssetValue += balance_;
        denomination.safeTransferFrom(user_, address(vault), balance_);
        _afterPurchase(grossAssetValue);

        emit Purchased(user_, balance_, share, bonus);
    }

    /// @notice Redeem with the given share amount. Need to wait when fund is under liquidation
    /// @dev This function can only be used in `Executing`, `Pending` and `Closed` states.
    function redeem(uint256 share_, bool acceptPending_)
        external
        virtual
        when3States(State.Executing, State.Pending, State.Closed)
        nonReentrant
        returns (uint256 balance)
    {
        // Redeem share need to greater than zero
        Errors._require(share_ > 0, Errors.Code.SHARE_MODULE_REDEEM_ZERO_SHARE);

        // Check redeem share need to greater than user share they own
        uint256 userShare = shareToken.balanceOf(msg.sender);
        Errors._require(share_ <= userShare, Errors.Code.SHARE_MODULE_INSUFFICIENT_SHARE);

        // Claim pending redemption if need
        if (isPendingRedemptionClaimable(msg.sender)) {
            _claimPendingRedemption(msg.sender);
        }

        // Execute redeem operation
        if (state == State.Pending) {
            balance = _redeemPending(msg.sender, share_, acceptPending_);
        } else {
            balance = _redeem(msg.sender, share_, acceptPending_);
        }
    }

    function _redeem(
        address user_,
        uint256 share_,
        bool acceptPending_
    ) internal virtual returns (uint256) {
        uint256 grossAssetValue = _beforeRedeem();
        (uint256 shareLeft, uint256 balance) = _calculateRedeemableBalance(share_, grossAssetValue);

        uint256 shareRedeemed = share_ - shareLeft;
        shareToken.burn(user_, shareRedeemed);

        if (shareLeft != 0) {
            _pend();
            _redeemPending(user_, shareLeft, acceptPending_);
        }
        grossAssetValue -= balance;
        denomination.safeTransferFrom(address(vault), user_, balance);
        _afterRedeem(grossAssetValue);
        emit Redeemed(user_, balance, shareRedeemed);

        return balance;
    }

    function _redeemPending(
        address user_,
        uint256 share_,
        bool acceptPending_
    ) internal virtual returns (uint256) {
        Errors._require(acceptPending_, Errors.Code.SHARE_MODULE_REDEEM_IN_PENDING_WITHOUT_PERMISSION);

        // Add the current pending round to pending user info for the first redeem
        if (pendingUsers[user_].pendingShare == 0) {
            pendingUsers[user_].pendingRound = currentPendingRound();
        } else {
            // Confirm user pending share is in the current pending round
            Errors._require(
                pendingUsers[user_].pendingRound == currentPendingRound(),
                Errors.Code.SHARE_MODULE_PENDING_ROUND_INCONSISTENT
            );
        }

        // Calculate and update pending information
        uint256 penalty = _getPendingPenalty();
        uint256 effectiveShare = (share_ * (_FUND_PERCENTAGE_BASE - penalty)) / _FUND_PERCENTAGE_BASE;
        uint256 penaltyShare = share_ - effectiveShare;
        pendingUsers[user_].pendingShare += effectiveShare;
        currentTotalPendingShare += effectiveShare;
        currentTotalPendingBonus += penaltyShare;
        shareToken.move(user_, address(this), share_);
        emit Pended(user_, effectiveShare, penaltyShare);

        return 0;
    }

    /// @notice Claim the settled pending redemption.
    /// @param user_ address want to be claim
    /// @return balance The balance being claimed.
    function claimPendingRedemption(address user_) external nonReentrant returns (uint256 balance) {
        Errors._require(isPendingRedemptionClaimable(user_), Errors.Code.SHARE_MODULE_PENDING_REDEMPTION_NOT_CLAIMABLE);
        balance = _claimPendingRedemption(user_);
    }

    function _claimPendingRedemption(address user_) internal returns (uint256 balance) {
        balance = _calcPendingRedemption(user_);

        // reset pending user to zero value
        delete pendingUsers[user_];

        if (balance > 0) {
            denomination.safeTransfer(user_, balance);
        }
        emit RedemptionClaimed(user_, balance);
    }

    /// @notice the length of pendingRoundList, means current pending round
    /// @return current pending round
    function currentPendingRound() public view returns (uint256) {
        return pendingRoundList.length;
    }

    /// @notice Determine user could claim pending redemption or not
    /// @param user_ address could be claimable
    /// @return true if claimable otherwise false
    function isPendingRedemptionClaimable(address user_) public view returns (bool) {
        return pendingUsers[user_].pendingRound < currentPendingRound() && pendingUsers[user_].pendingShare > 0;
    }

    function _calcPendingRedemption(address user_) internal view returns (uint256) {
        PendingUserInfo storage pendingUser = pendingUsers[user_];
        PendingRoundInfo storage pendingRoundInfo = pendingRoundList[pendingUser.pendingRound];
        return (pendingRoundInfo.totalRedemption * pendingUser.pendingShare) / pendingRoundInfo.totalPendingShare;
    }

    function _getResolvePendingShare(bool applyPenalty_) internal view returns (uint256) {
        if (applyPenalty_) {
            return currentTotalPendingShare;
        } else {
            return currentTotalPendingShare + currentTotalPendingBonus;
        }
    }

    function _getPendingPenalty() internal view virtual returns (uint256) {
        return comptroller.pendingPenalty();
    }

    function getReserve() public view virtual returns (uint256);

    function __getGrossAssetValue() internal view virtual returns (uint256);

    function _beforePurchase() internal virtual returns (uint256) {
        return 0;
    }

    function _afterPurchase(uint256 grossAssetValue_) internal virtual {
        grossAssetValue_;
        return;
    }

    function _beforeRedeem() internal virtual returns (uint256) {
        return 0;
    }

    function _afterRedeem(uint256 grossAssetValue_) internal virtual {
        grossAssetValue_;
        return;
    }

    function _addShare(
        address user_,
        uint256 balance_,
        uint256 grossAssetValue_
    ) internal virtual returns (uint256 share) {
        share = _calculateShare(balance_, grossAssetValue_);

        // Lock MINIMUM_SHARE to share token contract itself for the initial puchase
        // Share token contract has blocked transfer from itself
        if (shareToken.grossTotalShare() == 0) {
            shareToken.mint(address(shareToken), MINIMUM_SHARE);
        }

        shareToken.mint(user_, share);
    }

    function _settlePendingShare(bool applyPenalty_) internal returns (uint256 totalRedemption) {
        // Get total share for the settle
        uint256 redeemShare = _getResolvePendingShare(applyPenalty_);
        if (redeemShare == 0) return 0;

        // Calculate the total redemption depending on the redeemShare
        totalRedemption = _redeem(address(this), redeemShare, false);

        // Settle this round and store settle info to round list
        pendingRoundList.push(
            PendingRoundInfo({totalPendingShare: currentTotalPendingShare, totalRedemption: totalRedemption})
        );

        currentTotalPendingShare = 0; // reset currentTotalPendingShare
        if (applyPenalty_) {
            // if applyPenalty is true that means there are some share as bonus share
            // need to burn these bonus share if they are remaining
            if (currentTotalPendingBonus != 0) {
                shareToken.burn(address(this), currentTotalPendingBonus); // burn unused bonus
                currentTotalPendingBonus = 0;
            }
        } else {
            currentTotalPendingBonus = 0;
        }

        emit PendingShareSettled();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library Errors {
    error RevertCode(Code errorCode);

    enum Code {
        COMPTROLLER_HALTED, // 0: "Halted"
        COMPTROLLER_BANNED, // 1: "Banned"
        COMPTROLLER_ZERO_ADDRESS, // 2: "Zero address"
        COMPTROLLER_TOS_AND_SIGS_LENGTH_INCONSISTENT, // 3: "tos and sigs length are inconsistent"
        COMPTROLLER_BEACON_IS_INITIALIZED, // 4: "Beacon is initialized"
        COMPTROLLER_DENOMINATIONS_AND_DUSTS_LENGTH_INCONSISTENT, // 5: "denominations and dusts length are inconsistent"
        IMPLEMENTATION_ASSET_LIST_NOT_EMPTY, // 6: "assetList is not empty"
        IMPLEMENTATION_INVALID_DENOMINATION, // 7: "Invalid denomination"
        IMPLEMENTATION_INVALID_MORTGAGE_TIER, // 8: "Mortgage tier not set in comptroller"
        IMPLEMENTATION_PENDING_SHARE_NOT_RESOLVABLE, // 9: "pending share is not resolvable"
        IMPLEMENTATION_PENDING_NOT_START, // 10: "Pending does not start"
        IMPLEMENTATION_PENDING_NOT_EXPIRE, // 11: "Pending does not expire"
        IMPLEMENTATION_INVALID_ASSET, // 12: "Invalid asset"
        IMPLEMENTATION_INSUFFICIENT_TOTAL_VALUE_FOR_EXECUTION, // 13: "Insufficient total value for execution"
        FUND_PROXY_FACTORY_INVALID_CREATOR, // 14: "Invalid creator"
        FUND_PROXY_FACTORY_INVALID_DENOMINATION, // 15: "Invalid denomination"
        FUND_PROXY_FACTORY_INVALID_MORTGAGE_TIER, // 16: "Mortgage tier not set in comptroller"
        FUND_PROXY_STORAGE_UTILS_INVALID_DENOMINATION, // 17: "Invalid denomination"
        FUND_PROXY_STORAGE_UTILS_UNKNOWN_OWNER, // 18: "Unknown owner"
        FUND_PROXY_STORAGE_UTILS_WRONG_ALLOWANCE, // 19: "Wrong allowance"
        FUND_PROXY_STORAGE_UTILS_IS_NOT_ZERO, // 20: "Is not zero value or address "
        FUND_PROXY_STORAGE_UTILS_IS_ZERO, // 21: "Is zero value or address"
        MORTGAGE_VAULT_FUND_MORTGAGED, // 22: "Fund mortgaged"
        SHARE_TOKEN_INVALID_FROM, // 23: "Invalid from"
        SHARE_TOKEN_INVALID_TO, // 24: "Invalid to"
        TASK_EXECUTOR_TOS_AND_DATAS_LENGTH_INCONSISTENT, // 25: "tos and datas length inconsistent"
        TASK_EXECUTOR_TOS_AND_CONFIGS_LENGTH_INCONSISTENT, // 26: "tos and configs length inconsistent"
        TASK_EXECUTOR_INVALID_COMPTROLLER_DELEGATE_CALL, // 27: "Invalid comptroller delegate call"
        TASK_EXECUTOR_INVALID_COMPTROLLER_CONTRACT_CALL, // 28: "Invalid comptroller contract call"
        TASK_EXECUTOR_INVALID_DEALING_ASSET, // 29: "Invalid dealing asset"
        TASK_EXECUTOR_REFERENCE_TO_OUT_OF_LOCALSTACK, // 30: "Reference to out of localStack"
        TASK_EXECUTOR_RETURN_NUM_AND_PARSED_RETURN_NUM_NOT_MATCHED, // 31: "Return num and parsed return num not matched"
        TASK_EXECUTOR_ILLEGAL_LENGTH_FOR_PARSE, // 32: "Illegal length for _parse"
        TASK_EXECUTOR_STACK_OVERFLOW, // 33: "Stack overflow"
        TASK_EXECUTOR_INVALID_INITIAL_ASSET, // 34: "Invalid initial asset"
        TASK_EXECUTOR_NON_ZERO_QUOTA, // 35: "Quota is not zero"
        AFURUCOMBO_DUPLICATED_TOKENSOUT, // 36: "Duplicated tokensOut"
        AFURUCOMBO_REMAINING_TOKENS, // 37: "Furucombo has remaining tokens"
        AFURUCOMBO_TOKENS_AND_AMOUNTS_LENGTH_INCONSISTENT, // 38: "Token length != amounts length"
        AFURUCOMBO_INVALID_COMPTROLLER_HANDLER_CALL, // 39: "Invalid comptroller handler call"
        CHAINLINK_ASSETS_AND_AGGREGATORS_INCONSISTENT, // 40: "assets.length == aggregators.length"
        CHAINLINK_ZERO_ADDRESS, // 41: "Zero address"
        CHAINLINK_EXISTING_ASSET, // 42: "Existing asset"
        CHAINLINK_NON_EXISTENT_ASSET, // 43: "Non-existent asset"
        CHAINLINK_INVALID_PRICE, // 44: "Invalid price"
        CHAINLINK_STALE_PRICE, // 45: "Stale price"
        ASSET_REGISTRY_UNREGISTERED, // 46: "Unregistered"
        ASSET_REGISTRY_BANNED_RESOLVER, // 47: "Resolver has been banned"
        ASSET_REGISTRY_ZERO_RESOLVER_ADDRESS, // 48: "Resolver zero address"
        ASSET_REGISTRY_ZERO_ASSET_ADDRESS, // 49: "Asset zero address"
        ASSET_REGISTRY_REGISTERED_RESOLVER, // 50: "Resolver is registered"
        ASSET_REGISTRY_NON_REGISTERED_RESOLVER, // 51: "Asset not registered"
        ASSET_REGISTRY_NON_BANNED_RESOLVER, // 52: "Resolver is not banned"
        ASSET_ROUTER_ASSETS_AND_AMOUNTS_LENGTH_INCONSISTENT, // 53: "assets length != amounts length"
        ASSET_ROUTER_NEGATIVE_VALUE, // 54: "Negative value"
        RESOLVER_ASSET_VALUE_NEGATIVE, // 55: "Resolver's asset value < 0"
        RESOLVER_ASSET_VALUE_POSITIVE, // 56: "Resolver's asset value > 0"
        RCURVE_STABLE_ZERO_ASSET_ADDRESS, // 57: "Zero asset address"
        RCURVE_STABLE_ZERO_POOL_ADDRESS, // 58: "Zero pool address"
        RCURVE_STABLE_ZERO_VALUED_ASSET_ADDRESS, // 59: "Zero valued asset address"
        RCURVE_STABLE_VALUED_ASSET_DECIMAL_NOT_MATCH_VALUED_ASSET, // 60: "Valued asset decimal not match valued asset"
        RCURVE_STABLE_POOL_INFO_IS_NOT_SET, // 61: "Pool info is not set"
        ASSET_MODULE_DIFFERENT_ASSET_REMAINING, // 62: "Different asset remaining"
        ASSET_MODULE_FULL_ASSET_CAPACITY, // 63: "Full Asset Capacity"
        MANAGEMENT_FEE_MODULE_FEE_RATE_SHOULD_BE_LESS_THAN_FUND_BASE, // 64: "Fee rate should be less than 100%"
        PERFORMANCE_FEE_MODULE_CAN_NOT_CRYSTALLIZED_YET, // 65: "Can not crystallized yet"
        PERFORMANCE_FEE_MODULE_TIME_BEFORE_START, // 66: "Time before start"
        PERFORMANCE_FEE_MODULE_FEE_RATE_SHOULD_BE_LESS_THAN_BASE, // 67: "Fee rate should be less than 100%"
        PERFORMANCE_FEE_MODULE_CRYSTALLIZATION_PERIOD_TOO_SHORT, // 68: "Crystallization period too short"
        SHARE_MODULE_SHARE_AMOUNT_TOO_LARGE, // 69: "The requesting share amount is greater than total share amount"
        SHARE_MODULE_PURCHASE_ZERO_BALANCE, // 70: "The purchased balance is zero"
        SHARE_MODULE_PURCHASE_ZERO_SHARE, // 71: "The share purchased need to greater than zero"
        SHARE_MODULE_REDEEM_ZERO_SHARE, // 72: "The redeem share is zero"
        SHARE_MODULE_INSUFFICIENT_SHARE, // 73: "Insufficient share amount"
        SHARE_MODULE_REDEEM_IN_PENDING_WITHOUT_PERMISSION, // 74: "Redeem in pending without permission"
        SHARE_MODULE_PENDING_ROUND_INCONSISTENT, // 75: "user pending round and current pending round are inconsistent"
        SHARE_MODULE_PENDING_REDEMPTION_NOT_CLAIMABLE // 76: "Pending redemption is not claimable"
    }

    function _require(bool condition_, Code errorCode_) internal pure {
        if (!condition_) revert RevertCode(errorCode_);
    }

    function _revertMsg(string memory functionName_, string memory reason_) internal pure {
        revert(string(abi.encodePacked(functionName_, ": ", reason_)));
    }

    function _revertMsg(string memory functionName_) internal pure {
        _revertMsg(functionName_, "Unspecified");
    }
}