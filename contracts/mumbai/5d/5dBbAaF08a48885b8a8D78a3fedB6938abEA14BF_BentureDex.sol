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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

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
// OpenZeppelin Contracts (last updated v4.7.3) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 *
 * [WARNING]
 * ====
 *  Trying to delete such a structure from storage will likely result in data corruption, rendering the structure unusable.
 *  See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 *  In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an array of EnumerableSet.
 * ====
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "./interfaces/IBentureDex.sol";
import "./interfaces/IBentureAdmin.sol";

/// @title Contract that controlls creation and execution of market and limit orders
contract BentureDex is IBentureDex, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;
    using SafeERC20 for IERC20;
    using ECDSA for bytes32;
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.UintSet;

    /// @dev Precision used to calculate token amounts rations (prices)
    uint256 constant PRICE_PRECISION = 10 ** 18;

    /// @notice Percentage of each order being paid as fee (in basis points)
    uint256 public feeRate;
    /// @notice The address of the backend account
    address public backendAcc;
    /// @notice The address of the admin token
    address public adminToken;
    /// @dev Incrementing IDs of orders
    Counters.Counter private _orderId;
    /// @dev Mapping from order ID to order
    mapping(uint256 => Order) private _orders;
    /// @dev Mapping from order ID to matched order ID to boolean
    /// True if IDs matched some time before. Otherwise - false
    mapping(uint256 => mapping(uint256 => bool)) private _matchedOrders;
    /// @dev Mapping from user address to the array of orders IDs he created
    mapping(address => uint256[]) private _usersToOrders;
    /// @dev Mapping from pair tokens addresses to the list of IDs with these tokens
    mapping(address => mapping(address => uint[])) private _tokensToOrders;
    /// @dev Mapping from one token to another to boolean indicating
    ///      that the second tokens is quoated (the price of the first
    ///      is measured in the amount of second tokens)
    mapping(address => mapping(address => bool)) private _isQuoted;
    /// @dev Mapping from unquoted token of the pair to the quoted
    ///      token of the pair to the price (how many quoted tokens
    ///      to pay for a single unquoted token)
    ///      .e.g (USDT => DOGE => 420)
    ///      Each price is multiplied by `PRICE_PRECISION`
    mapping(address => mapping(address => uint256)) private _pairPrices;
    /// @dev Mapping from unquoted token of the pair to the quoted
    ///      token of the pair to the pair decimals
    mapping(address => mapping(address => uint8)) private _pairDecimals;
    /// @dev Mapping from address of token to list of IDs of orders
    ///      in which fees were paid in this order
    mapping(address => EnumerableSet.UintSet) private _tokensToFeesIds;
    /// @dev List of tokens that are currently locked as fees
    ///         for orders creations
    EnumerableSet.AddressSet private _lockedTokens;
    /// @notice Marks transaction hashes that have been executed already.
    ///         Prevents Replay Attacks
    mapping(bytes32 => bool) private _executed;
    /// @dev Mapping from token to boolean indicating
    ///      that token is verified
    mapping(address => bool) private _isTokenVerified;

    /// @dev 100% in basis points (1 bp = 1 / 100 of 1%)
    uint256 private constant HUNDRED_PERCENT = 10000;

    /// @dev Updates quoted token of the pair.
    ///      Should be applied only to sale orders functions
    ///      because pairs can be created only in sale orders.
    ///      Update of quoted tokens can be interpreted as pair creation
    modifier updateQuotes(address tokenA, address tokenB) {
        // If none of the tokens is quoted, `tokenB_` becomes a quoted token
        if (!_isQuoted[tokenA][tokenB] && !_isQuoted[tokenB][tokenA]) {
            _isQuoted[tokenA][tokenB] = true;
        }
        _;
    }

    /// @dev Checks that a pair of provided tokens has been created earlier.
    ///      Should be applied to buy/sell order functions.
    modifier onlyWhenPairExists(address tokenA, address tokenB) {
        // If none of the tokens is quoted, no pairs with these tokens
        // have been created yet
        if (!_isQuoted[tokenA][tokenB] && !_isQuoted[tokenB][tokenA]) {
            revert PairNotCreated();
        }
        _;
    }

    /// @dev Checks that user is admin of any project
    modifier onlyAdminOfAny(address user) {
        if (adminToken == address(0)) revert AdminTokenNotSet();
        if (!IBentureAdmin(adminToken).checkAdminOfAny(user)) revert NotAdmin();
        _;
    }

    /// @notice Sets the inital fee rate for orders
    constructor() {
        // Default fee rate is 0.1% (10 BP)
        feeRate = 10;
    }

    /// @notice See {IBentureDex-getUserOrders}
    function getUserOrders(
        address user
    ) external view returns (uint256[] memory) {
        if (user == address(0)) revert ZeroAddress();
        return _usersToOrders[user];
    }

    /// @notice See {IBentureDex-getOrder}
    function getOrder(
        uint256 _id
    )
        external
        view
        returns (
            address,
            address,
            address,
            uint256,
            uint256,
            OrderType,
            OrderSide,
            uint256,
            bool,
            uint256,
            uint256,
            OrderStatus
        )
    {
        if (!checkOrderExists(_id)) revert OrderDoesNotExist();

        Order memory order = _orders[_id];

        return (
            order.user,
            order.tokenA,
            order.tokenB,
            order.amount,
            order.amountFilled,
            order.type_,
            order.side,
            order.limitPrice,
            order.isCancellable,
            order.feeAmount,
            order.amountLocked,
            order.status
        );
    }

    /// @notice See {IBentureDex-getOrdersByTokens}
    function getOrdersByTokens(
        address tokenA,
        address tokenB
    ) external view returns (uint256[] memory) {
        return _tokensToOrders[tokenA][tokenB];
    }

    /// @notice See {IBentureDex-checkPairExists}
    function checkPairExists(
        address tokenA,
        address tokenB
    ) external view returns (bool) {
        // If none of the tokens is quoted, no pairs with these tokens
        // have been created yet
        if (!_isQuoted[tokenA][tokenB] && !_isQuoted[tokenB][tokenA]) {
            return false;
        }
        return true;
    }

    /// @notice See {IBentureDex-getPrice}
    function getPrice(
        address tokenA,
        address tokenB
    ) external view returns (address, uint256) {
        if (!_isQuoted[tokenA][tokenB] && !_isQuoted[tokenB][tokenA])
            revert NoQuotedTokens();
        address quotedToken = _isQuoted[tokenA][tokenB] ? tokenB : tokenA;
        return (quotedToken, _getPrice(tokenA, tokenB));
    }

    /// @notice See {IBentureDex-getDecimals}
    function getDecimals(
        address tokenA,
        address tokenB
    ) public view returns (uint8) {
        if (_isQuoted[tokenA][tokenB]) {
            return _pairDecimals[tokenA][tokenB];
        } else {
            return _pairDecimals[tokenB][tokenA];
        }
    }

    /// @notice See (IBentureDex-checkMatched)
    function checkMatched(
        uint256 firstId,
        uint256 secondId
    ) external view returns (bool) {
        if (!checkOrderExists(firstId)) revert OrderDoesNotExist();
        if (!checkOrderExists(secondId)) revert OrderDoesNotExist();
        if (
            _matchedOrders[firstId][secondId] ||
            _matchedOrders[secondId][firstId]
        ) {
            return true;
        }
        return false;
    }

    /// @notice See {IBentureDex-buyMarket}
    function buyMarket(
        address tokenA,
        address tokenB,
        uint256 amount,
        uint256 slippage,
        uint256 nonce,
        bytes memory signature
    ) external payable onlyWhenPairExists(tokenA, tokenB) nonReentrant {
        // Verify signature
        {
            bytes32 txHash = _getTxHashMarket(
                tokenA,
                tokenB,
                amount,
                slippage,
                nonce
            );
            if (_executed[txHash]) revert TxAlreadyExecuted(txHash);
            if (!_verifyBackendSignature(signature, txHash))
                revert InvalidSignature();
            // Mark that tx with a calculated hash was executed
            // Do it before function body to avoid reentrancy
            _executed[txHash] = true;
        }

        Order memory order = _prepareOrder(
            tokenA,
            tokenB,
            amount,
            0,
            OrderType.Market,
            OrderSide.Buy,
            slippage,
            false
        );

        uint256 lockAmount = _getLockAmount(
            order.tokenA,
            order.tokenB,
            order.amount,
            // This order cannot be the first one because it's market
            // So price cannot be zero here. No need to check.
            _getPrice(tokenA, tokenB)
        );

        uint256 feeAmount = _getFee(lockAmount);

        // Mark that fee for new order was paid in `tokenB`
        _tokensToFeesIds[tokenB].add(order.id);

        // Mark that `tokenB` was locked
        _lockedTokens.add(tokenB);

        // Set the real fee and lock amounts
        order.feeAmount = feeAmount;

        _createOrder(order, lockAmount);
    }

    /// @notice See {IBentureDex-sellMarket}
    function sellMarket(
        address tokenA,
        address tokenB,
        uint256 amount,
        uint256 slippage,
        uint256 nonce,
        bytes memory signature
    ) external payable onlyWhenPairExists(tokenA, tokenB) nonReentrant {
        // Verify signature
        {
            bytes32 txHash = _getTxHashMarket(
                tokenA,
                tokenB,
                amount,
                slippage,
                nonce
            );
            if (_executed[txHash]) revert TxAlreadyExecuted(txHash);
            if (!_verifyBackendSignature(signature, txHash))
                revert InvalidSignature();
            // Mark that tx with a calculated hash was executed
            // Do it before function body to avoid reentrancy
            _executed[txHash] = true;
        }

        Order memory order = _prepareOrder(
            tokenA,
            tokenB,
            amount,
            0,
            OrderType.Market,
            OrderSide.Sell,
            slippage,
            false
        );

        // User has to lock exactly the amount of `tokenB` he is selling
        uint256 lockAmount = amount;

        // Calculate the fee amount for the order
        uint256 feeAmount = _getFee(lockAmount);

        // Mark that fee for new order was paid in `tokenB`
        _tokensToFeesIds[tokenB].add(order.id);

        // Mark that `tokenB` was locked
        _lockedTokens.add(tokenB);

        // Set the real fee and lock amounts
        order.feeAmount = feeAmount;

        _createOrder(order, lockAmount);
    }

    /// @notice See {IBentureDex-buyLimit}
    function buyLimit(
        address tokenA,
        address tokenB,
        uint256 amount,
        uint256 limitPrice
    ) external payable onlyWhenPairExists(tokenA, tokenB) nonReentrant {
        Order memory order = _prepareOrder(
            tokenA,
            tokenB,
            amount,
            limitPrice,
            OrderType.Limit,
            OrderSide.Buy,
            0,
            // Orders are cancellable
            true
        );

        _updatePairPriceOnLimit(order);

        uint256 marketPrice = _getPrice(order.tokenA, order.tokenB);

        uint256 lockAmount;
        // If user wants to create a buy limit order with limit price much higher
        // than the market price, then this order will instantly be matched with
        // other limit (sell) orders that have a lower limit price
        // In this case not the whole locked amount of tokens will be used and the rest
        // should be returned to the user. We can avoid that by locking the amount of
        // tokens according to the market price instead of limit price of the order
        // We can think of this order as a market order
        if (limitPrice > marketPrice && marketPrice != 0) {
            lockAmount = _getLockAmount(tokenA, tokenB, amount, marketPrice);
        } else {
            lockAmount = _getLockAmount(tokenA, tokenB, amount, limitPrice);
        }

        uint256 feeAmount = _getFee(lockAmount);

        // Mark that fee for new order was paid in `tokenB`
        _tokensToFeesIds[tokenB].add(order.id);

        // Mark that `tokenB` was locked
        _lockedTokens.add(tokenB);

        // Set the real fee and lock amounts
        order.feeAmount = feeAmount;

        _createOrder(order, lockAmount);
    }

    /// @notice See {IBentureDex-sellLimit}
    function sellLimit(
        address tokenA,
        address tokenB,
        uint256 amount,
        uint256 limitPrice
    ) external payable onlyWhenPairExists(tokenA, tokenB) nonReentrant {
        Order memory order = _prepareOrder(
            tokenA,
            tokenB,
            amount,
            limitPrice,
            OrderType.Limit,
            OrderSide.Sell,
            0,
            // Orders are cancellable
            true
        );

        _updatePairPriceOnLimit(order);

        // User has to lock exactly the amount of `tokenB` he is selling
        uint256 lockAmount = amount;

        // Calculate the fee amount for the order
        uint256 feeAmount = _getFee(lockAmount);

        // Mark that fee for new order was paid in `tokenB`
        _tokensToFeesIds[tokenB].add(order.id);

        // Mark that `tokenB` was locked
        _lockedTokens.add(order.tokenB);

        // Set the real fee and lock amounts
        order.feeAmount = feeAmount;

        _createOrder(order, lockAmount);
    }

    /// @notice See {IBentureDex-withdrawAllFees}
    function withdrawAllFees() external onlyOwner {
        if (_lockedTokens.values().length == 0) revert NoFeesToWithdraw();
        // Get the list of all locked tokens and withdraw fees
        // for each of them
        withdrawFees(_lockedTokens.values());
    }

    /// @notice See {IBentureDex-startSaleSingle}
    function startSaleSingle(
        address tokenA,
        address tokenB,
        uint256 amount,
        uint256 price
    ) external payable nonReentrant {
        // Prevent reentrancy
        _startSaleSingle(tokenA, tokenB, amount, price);
    }

    /// @notice See {IBentureDex-startSaleMultiple}
    function startSaleMultiple(
        address tokenA,
        address tokenB,
        uint256[] memory amounts,
        uint256[] memory prices
    ) external payable nonReentrant {
        if (amounts.length != prices.length) revert DifferentLength();

        // The amount of gas spent for all operations below
        uint256 gasSpent = 0;
        // Only 2/3 of block gas limit could be spent.
        uint256 gasThreshold = (block.gaslimit * 2) / 3;
        uint256 lastGasLeft = gasleft();

        for (uint256 i = 0; i < amounts.length; i++) {
            uint256 orderId = _startSaleSingle(tokenA, tokenB, amounts[i], prices[i]);

            lastGasLeft = gasleft();
            // Increase the total amount of gas spent
            gasSpent += lastGasLeft - gasleft();
            // Check that no more than 2/3 of block gas limit was spent
            if (gasSpent >= gasThreshold) {
                emit GasLimitReached(orderId, gasSpent, block.gaslimit);
                break;
            }
        }

        // SaleStarted event is emitted for each sale from the list
        // No need to emit any other events here
    }

    /// @notice See {IBentureDex-matchOrders}
    function matchOrders(
        uint256 initId,
        uint256[] memory matchedIds,
        uint256 nonce,
        bytes calldata signature
    ) external nonReentrant {
        _matchOrders(initId, matchedIds, nonce, signature);
    }

    /// @notice See {IBentureDex-cancelOrder}
    function cancelOrder(uint256 id) external nonReentrant {
        _cancelOrder(id);
    }

    /// @notice See {IBentureDex-setBackend}
    function setBackend(address acc) external onlyOwner {
        if (acc == address(0)) revert ZeroAddress();
        emit BackendChanged(backendAcc, acc);
        backendAcc = acc;
    }

    /// @notice See {IBentureDex-setFee}
    function setFee(uint256 newFeeRate) external onlyOwner {
        emit FeeRateChanged(feeRate, newFeeRate);
        feeRate = newFeeRate;
    }

    /// @notice See {IBentureDex-setAdminToken}
    function setAdminToken(address token) external onlyOwner {
        if (token == address(0)) revert ZeroAddress();
        emit AdminTokenChanged(adminToken, token);
        adminToken = token;
    }

    /// @notice See {IBentureDex-setIsTokenVerified}
    function setIsTokenVerified(address token, bool verified) external onlyOwner {
        if (token == address(0)) revert ZeroAddress();
        emit IsTokenVerifiedChanged(token, verified);
        _isTokenVerified[token] = verified;
    }

    /// @notice See {IBentureDex-setDecimals}
    function setDecimals(address tokenA, address tokenB, uint8 decimals) external onlyOwner {
        if (tokenA == address(0)) revert InvalidFirstTokenAddress();
        _setDecimals(tokenA, tokenB, decimals);
    }

    /// @notice See {IBentureDex-getLockAmount}
    function getLockAmount(
        address tokenA,
        address tokenB,
        uint256 amount,
        uint256 limitPrice,
        OrderType type_,
        OrderSide side
    ) public view returns (uint256 lockAmount) {
        // For market orders limit price should be zero
        if (type_ == OrderType.Market && limitPrice != 0) revert InvalidPrice();
        // For limit orders limit price should be greater than zero
        if (type_ == OrderType.Limit && limitPrice == 0) revert InvalidPrice();

        // In any sell order user locks exactly the amount of tokens sold
        // sellMarket
        // sellLimit
        if (side == OrderSide.Sell) {
            lockAmount = amount;
        }

        // buyMarket
        if (type_ == OrderType.Market && side == OrderSide.Buy) {
            lockAmount = _getLockAmount(
                tokenA,
                tokenB,
                amount,
                _getPrice(tokenA, tokenB)
            );
        }

        // buyLimit
        if (type_ == OrderType.Limit && side == OrderSide.Buy) {
            // If user wants to create a buy limit order with limit price much higher
            // than the market price, then this order will instantly be matched with
            // other limit (sell) orders that have a lower limit price
            // In this case not the whole locked amount of tokens will be used and the rest
            // should be returned to the user. We can avoid that by locking the amount of
            // tokens according to the market price instead of limit price of the order
            // We can think of this order as a market order
            uint256 marketPrice = _getPrice(tokenA, tokenB);
            if (limitPrice > marketPrice && marketPrice != 0) {
                lockAmount = _getLockAmount(
                    tokenA,
                    tokenB,
                    amount,
                    marketPrice
                );
            } else {
                lockAmount = _getLockAmount(tokenA, tokenB, amount, limitPrice);
            }
        }
    }

    /// @notice See {IBentureDex-getIsTokenVerified}
    function getIsTokenVerified(address token) external view returns (bool) {
        return _isTokenVerified[token];
    }

    /// @notice See {IBentureDex-checkOrderExists}
    function checkOrderExists(uint256 id) public view returns (bool) {
        // First order has ID1
        if (id == 0) return false;
        if (id > _orderId.current()) return false;
        return true;
    }

    /// @notice See {IBentureDex-withdrawFees}
    function withdrawFees(address[] memory tokens) public onlyOwner {
        // The amount of gas spent for all operations below
        uint256 gasSpent = 0;
        // Only 2/3 of block gas limit could be spent.
        uint256 gasThreshold = (block.gaslimit * 2) / 3;
        uint256 lastGasLeft = gasleft();

        for (uint256 i = 0; i < tokens.length; i++) {
            address lockedToken = tokens[i];
            if (lockedToken == address(0)) revert ZeroAddress();
            // IDs of orders fees for which were paid in this token
            uint256[] memory ids = _tokensToFeesIds[lockedToken].values();
            for (uint256 j = 0; j < ids.length; j++) {
                Order storage order = _orders[ids[j]];
                // Only fees of closed orders can be withdrawn
                if (order.status != OrderStatus.Closed)
                    // One unmatched orders should not stop iteration
                    continue;
                uint256 transferAmount = order.feeAmount;

                // Delete order from IDs array to reduce iteration
                _tokensToFeesIds[lockedToken].remove(ids[j]);

                emit FeesWithdrawn(order.id, lockedToken, transferAmount);

                // Transfer all withdraw fees to the owner
                if (lockedToken != address(0)) {
                    IERC20(lockedToken).safeTransfer(
                        msg.sender,
                        transferAmount
                    );
                } else {
                    (bool success, ) = msg.sender.call{value: transferAmount}(
                        ""
                    );
                    if (!success) revert TransferFailed();
                }

                lastGasLeft = gasleft();
                // Increase the total amount of gas spent
                gasSpent += lastGasLeft - gasleft();
                // Check that no more than 2/3 of block gas limit was spent
                if (gasSpent >= gasThreshold) {
                    emit GasLimitReached(order.id, gasSpent, block.gaslimit);
                    break;
                }
            }
        }
    }

    /// @dev Calculates fee amount to be returned based
    ///      on the filled amount of the cancelled order
    /// @param order The cancelled order
    /// @return The fee amount to return to the user
    function _calcReturnFee(Order memory order) private pure returns (uint256) {
        return
            order.feeAmount -
            ((order.amountFilled * order.feeAmount) / order.amount);
    }

    /// @dev Calculates price slippage in basis points
    /// @param priceDif Difference between old and new price
    /// @param oldPrice Old price of pair of tokens
    /// @return slippage Price slippage in basis points
    function _calcSlippage(
        uint256 priceDif,
        uint256 oldPrice
    ) private pure returns (uint256 slippage) {
        slippage = (priceDif * HUNDRED_PERCENT) / oldPrice;
    }

    /// @dev Checks that price slippage is not too high
    /// @param oldPrice Old price of the pair
    /// @param newPrice New price of the pair
    /// @param allowedSlippage The maximum allowed slippage in basis points
    function _checkSlippage(
        uint256 oldPrice,
        uint256 newPrice,
        uint256 allowedSlippage,
        OrderSide side
    ) private pure {
        uint256 slippage = 0;

        if (side == OrderSide.Buy) {
            if (newPrice > oldPrice) {
                slippage = _calcSlippage(newPrice - oldPrice, oldPrice);
            }
        } else {
            if (newPrice < oldPrice) {
                slippage = _calcSlippage(oldPrice - newPrice, oldPrice);
            }
        }

        if (slippage > allowedSlippage) {
            revert SlippageTooBig(slippage);
        }
    }

    /// @dev Returns the price of the limit order to be used
    ///      to execute orders after matching
    /// @param initOrder The first matched order
    /// @param matchedOrder The second matched order
    /// @return The execution price for orders matching
    /// @dev One of two orders must be a limit order
    function _getNewPrice(
        Order memory initOrder,
        Order memory matchedOrder
    ) private pure returns (uint256) {
        // Price of the limit order used to calculate transferred amounts later.
        // Market orders are executed using this price
        // Expressed in pair's quoted tokens
        uint256 price;
        // In case two limit orders match, the one with a smaller amount will be fully closed first
        // so its price should be used
        if (initOrder.type_ == OrderType.Limit) {
            if (
                initOrder.amount - initOrder.amountFilled <
                matchedOrder.amount - matchedOrder.amountFilled
            ) {
                price = initOrder.limitPrice;
            } else if (
                initOrder.amount - initOrder.amountFilled >
                matchedOrder.amount - matchedOrder.amountFilled
            ) {
                price = matchedOrder.limitPrice;
            } else if (
                // If both limit orders have the same amount, the one
                // that was created later is used to set a new price
                initOrder.amount - initOrder.amountFilled ==
                matchedOrder.amount - matchedOrder.amountFilled
            ) {
                price = initOrder.limitPrice;
            }

            // In case a limit and a market orders match, market order gets executed
            // with price of a limit order
        } else {
            price = matchedOrder.limitPrice;
        }
        return price;
    }

    /// @dev Calculates fee based on the amount of locked tokens
    /// @param amount The amount of locked tokens
    /// @return retAmount The fee amount that should be paid for order creation
    function _getFee(uint256 amount) private view returns (uint256) {
        return (amount * feeRate) / HUNDRED_PERCENT;
    }

    /// @dev Returns the price of the pair in quoted tokens
    /// @param tokenA The address of the token that is received
    /// @param tokenB The address of the token that is sold
    /// @return The price of the pair in quoted tokens
    function _getPrice(
        address tokenA,
        address tokenB
    ) private view returns (uint256) {
        if (_isQuoted[tokenA][tokenB]) {
            return _pairPrices[tokenA][tokenB];
        } else {
            return _pairPrices[tokenB][tokenA];
        }
    }

    /// @dev Calculates the hash of parameters of order matching function and a nonce
    /// @param initId The ID of first matched order
    /// @param matchedIds The list of IDs of other matched orders
    /// @param nonce The unique integer
    /// @dev NOTICE: Backend must form tx hash exactly the same way
    function _getTxHashMatch(
        uint256 initId,
        uint256[] memory matchedIds,
        uint256 nonce
    ) public view returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    // Include the address of the contract to make hash even more unique
                    address(this),
                    initId,
                    matchedIds,
                    nonce
                )
            );
    }

    /// @dev Calculates the hash of parameters of market order function and a nonce
    /// @param tokenA The address of the purchased token
    /// @param tokenB The address of the sold token
    /// @param amount The amound of purchased / sold tokens
    /// @param slippage The maximum allowed price slippage
    /// @param nonce The unique integer
    /// @dev NOTICE: Backend must form tx hash exactly the same way
    function _getTxHashMarket(
        address tokenA,
        address tokenB,
        uint256 amount,
        uint256 slippage,
        uint256 nonce
    ) public view returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    address(this),
                    tokenA,
                    tokenB,
                    amount,
                    slippage,
                    nonce
                )
            );
    }

    /// @dev Verifies that message was signed by the backend
    /// @param signature A signature used to sign the tx
    /// @param txHash An unsigned hashed data
    /// @return True if tx was signed by the backend. Otherwise false.
    function _verifyBackendSignature(
        bytes memory signature,
        bytes32 txHash
    ) private view returns (bool) {
        // Remove the "\x19Ethereum Signed Message:\n" prefix from the signature
        bytes32 clearHash = txHash.toEthSignedMessageHash();
        // Recover the address of the user who signed the tx
        address recoveredUser = clearHash.recover(signature);
        return recoveredUser == backendAcc;
    }

    /// @dev Calculates the amount of tokens to be locked when creating an order
    /// @param tokenA The address of the token that is purchased
    /// @param tokenB The address of the token that is sold
    /// @param amount The amount of active tokens
    /// @param price The market/limit execution price
    /// @return The amount of tokens to be locked
    function _getLockAmount(
        address tokenA,
        address tokenB,
        uint256 amount,
        uint256 price
    ) private view returns (uint256) {
        uint256 lockAmount;

        if (_isQuoted[tokenA][tokenB]) {
            // User has to lock enough `tokenB_` to pay according to current price
            // If `tokenB_` is a quoted token, then `price` does not change
            // because it's expressed in this token
            lockAmount = (amount * price) / PRICE_PRECISION;
        } else {
            // If `tokenA_` is a quoted token, then `price` should be inversed
            lockAmount = (amount * PRICE_PRECISION) / price;
            // But if this function is called from public `getLockAmount` for the very first order,
            // we assume that this order will update quotes and make `tokenB` quoted. Thus, lock amount
            // should be calculated as it was quoted
            if (_orderId.current() == 0) {
                lockAmount = (amount * price) / PRICE_PRECISION;
            }
        }
        return lockAmount;
    }

    function _createOrder(Order memory order, uint256 lockAmount) private {
        // Mark that new ID corresponds to the pair of tokens
        _tokensToOrders[order.tokenA][order.tokenB].push(order.id);

        // NOTICE: Order with ID1 has index 0
        _usersToOrders[msg.sender].push(order.id);

        emit OrderCreated(
            order.id,
            order.user,
            order.tokenA,
            order.tokenB,
            order.amount,
            order.type_,
            order.side,
            order.limitPrice,
            order.isCancellable
        );

        // Place order in the global list
        _orders[order.id] = order;

        // Entire lock consists of lock amount and fee amount
        uint256 totalLock = lockAmount + order.feeAmount;

        _orders[order.id].amountLocked = lockAmount;

        // In any case, `tokenB` is the one that is locked.
        // It gets transferred to the contract
        // Fee is also paid in `tokenB`
        // Fee gets transferred to the contract
        if (order.tokenB != address(0)) {
            IERC20(order.tokenB).safeTransferFrom(
                msg.sender,
                address(this),
                totalLock
            );
        } else {
            // Check that caller has provided enough native tokens with tx
            if (msg.value < totalLock) revert NotEnoughNativeTokens();
        }
    }

    function _cancelOrder(uint256 id) private {
        if (!checkOrderExists(id)) revert OrderDoesNotExist();
        Order storage order = _orders[id];
        if (order.status == OrderStatus.Active) {}
        if (!order.isCancellable) revert NonCancellable();
        // Partially closed orders can be cancelled as well
        if (
            !(order.status == OrderStatus.Active) &&
            !(order.status == OrderStatus.PartiallyClosed)
        ) revert InvalidOrderStatus();
        if (msg.sender != order.user) revert NotOrderCreator();
        // The amount of tokens to be returned to the user
        uint256 returnAmount;
        if (order.status == OrderStatus.Active) {
            // If order was not executed at all, whole lock and fee should
            // be returned
            returnAmount = order.amountLocked + order.feeAmount;
            // Order fee resets
            order.feeAmount = 0;
            // Order locked amount resets
            order.amountLocked = 0;
        } else {
            // It order was partially executed, the part of the fee proportional
            // to the filled amount should be returned as well
            uint256 returnFee = _calcReturnFee(order);
            returnAmount = order.amountLocked + returnFee;
            // Order fee amount decreases by the returned amount
            order.feeAmount -= returnFee;
            // Order locked amount resets
            order.amountLocked = 0;
        }

        emit OrderCancelled(order.id);

        // Only the status of the order gets changed
        // The order itself does not get deleted
        order.status = OrderStatus.Cancelled;

        // Only `tokenB` gets locked when creating an order.
        // Thus, only `tokenB` should be returned to the user
        if (order.tokenB != address(0)) {
            IERC20(order.tokenB).safeTransfer(order.user, returnAmount);
        } else {
            // Return native tokens
            (bool success, ) = msg.sender.call{value: returnAmount}("");
            if (!success) revert TransferFailed();
        }
    }

    function _matchOrders(
        uint256 initId,
        uint256[] memory matchedIds,
        uint256 nonce,
        bytes calldata signature
    ) private {
        // Verify signature
        {
            bytes32 txHash = _getTxHashMatch(initId, matchedIds, nonce);
            if (_executed[txHash]) revert TxAlreadyExecuted(txHash);
            if (!_verifyBackendSignature(signature, txHash))
                revert InvalidSignature();
            // Mark that tx with a calculated hash was executed
            // Do it before function body to avoid reentrancy
            _executed[txHash] = true;
        }

        // NOTICE: No other checks are done here. Fully trust the backend

        // The amount of gas spent for all operations below
        uint256 gasSpent = 0;
        // Only 2/3 of block gas limit could be spent.
        uint256 lastGasLeft = gasleft();

        Order memory initOrder = _orders[initId];

        for (uint256 i = 0; i < matchedIds.length; i++) {
            Order memory matchedOrder = _orders[matchedIds[i]];

            emit OrdersMatched(initOrder.id, matchedOrder.id);

            // Mark that both orders matched
            _matchedOrders[initOrder.id][matchedOrder.id] = true;
            _matchedOrders[matchedOrder.id][initOrder.id] = true;

            // Get tokens and amounts to transfer
            (
                address tokenToInit,
                address tokenToMatched,
                uint256 amountToInit,
                uint256 amountToMatched
            ) = _getAmounts(
                    initOrder,
                    matchedOrder,
                    // Price of the executed limit order
                    _getNewPrice(initOrder, matchedOrder)
                );

            // Revert if slippage is too big for any of the orders
            // Slippage is only allowed for market orders.
            // Only initial orders can be market
            if (initOrder.type_ == OrderType.Market) {
                _checkSlippage(
                    // Old price of the pair before orders execution
                    // Expressed in pair's quoted tokens
                    _getPrice(initOrder.tokenA, initOrder.tokenB),
                    _getNewPrice(initOrder, matchedOrder),
                    matchedOrder.slippage,
                    matchedOrder.side
                );
            }

            // Pair price gets updated to the price of the last executed limit order
            _updatePairPrice(initOrder, matchedOrder);

            // Change filled and locked amounts of two matched orders
            _updateOrdersAmounts(
                initOrder,
                matchedOrder,
                amountToInit,
                amountToMatched
            );

            // Change orders' statuses according to their filled amounts
            _checkAndChangeStatus(initOrder);
            _checkAndChangeStatus(matchedOrder);

            // Actually transfer corresponding amounts

            // Transfer first token
            if (tokenToInit != address(0)) {
                IERC20(tokenToInit).safeTransfer(initOrder.user, amountToInit);
            } else {
                (bool success, ) = initOrder.user.call{value: amountToInit}("");
                if (!success) revert TransferFailed();
            }

            // Transfer second token
            if (tokenToMatched != address(0)) {
                IERC20(tokenToMatched).safeTransfer(
                    matchedOrder.user,
                    amountToMatched
                );
            } else {
                (bool success, ) = matchedOrder.user.call{
                    value: amountToMatched
                }("");
                if (!success) revert TransferFailed();
            }

            lastGasLeft = gasleft();
            // Increase the total amount of gas spent
            gasSpent += lastGasLeft - gasleft();
            // Check that no more than 2/3 of block gas limit was spent
            if (gasSpent >= (block.gaslimit * 2) / 3) {
                emit GasLimitReached(initOrder.id, gasSpent, block.gaslimit);
                // No revert here. Part of changes will take place
                break;
            }
        }
    }

    /// @dev Updates pair price for the price of limit order
    ///      This limit order is the first limit order created
    /// @param order The order updating price
    function _updatePairPriceOnLimit(Order memory order) private {
        uint256 marketPrice = _getPrice(order.tokenA, order.tokenB);
        // If market price is 0, that means this is the first limit order created.
        // Its price becomes the market price
        if (marketPrice == 0) {
            if (_isQuoted[order.tokenA][order.tokenB]) {
                _pairPrices[order.tokenA][order.tokenB] = order.limitPrice;

                emit PriceChanged(order.tokenA, order.tokenB, order.limitPrice);
            } else {
                _pairPrices[order.tokenB][order.tokenA] = order.limitPrice;

                emit PriceChanged(order.tokenB, order.tokenA, order.limitPrice);
            }
        }
    }

    /// @dev Changes order's status according to its filled amount
    /// @param order The order to change status of
    function _checkAndChangeStatus(Order memory order) private {
        Order storage order_ = _orders[order.id];
        if (
            order_.status == OrderStatus.Cancelled ||
            order_.status == OrderStatus.Closed
        ) revert InvalidOrderStatus();
        if (order_.amountFilled == order_.amount) {
            order_.status = OrderStatus.Closed;
        } else {
            order_.status = OrderStatus.PartiallyClosed;
        }
    }

    /// @dev Calculates the amount of tokens to transfer to seller and buyer after
    ///      orders match
    /// @param initOrder The first of matched orders
    /// @param matchedOrder The second of matched orders
    /// @param price The execution price of limit order
    function _getAmounts(
        Order memory initOrder,
        Order memory matchedOrder,
        uint256 price
    ) private view returns (address, address, uint256, uint256) {
        // The address of the token to transfer to the user of `initOrder`
        address tokenToInit;
        // The address of the token to transfer to the user of `matchedOrder`
        address tokenToMatched;
        // The amount to be transferred to the user of `initOrder`
        uint256 amountToInit;
        // The amount to be transferred to the user of `mathcedOrder`
        uint256 amountToMatched;

        // Indicates that pair price is expressed in `initOrder.tokenB`
        // If `price` is expressed in `tokenB` of the `initOrder` then it should be used when transferring
        // But if it's expressed in `tokenA` of the `initOrder` then is should be inversed when transferring
        bool quotedInInitB;
        if (_isQuoted[initOrder.tokenA][initOrder.tokenB]) {
            quotedInInitB = true;
        } else {
            quotedInInitB = false;
        }

        tokenToInit = initOrder.tokenA;
        tokenToMatched = initOrder.tokenB;

        if (initOrder.side == OrderSide.Buy) {
            // When trying to buy more than available in matched order, whole availabe amount of matched order
            // gets transferred (it's less)

            if (
                initOrder.amount - initOrder.amountFilled >
                matchedOrder.amount - matchedOrder.amountFilled
            ) {
                // Sell all seller's tokens to the buyer
                // Amount of buy order tokenA trasferred from sell to buy order
                amountToInit = matchedOrder.amount - matchedOrder.amountFilled;

                // Pay seller according to amount of tokens he sells
                if (quotedInInitB) {
                    // Transfer `price` times more tokenB from buy to sell order
                    amountToMatched = (amountToInit * price) / PRICE_PRECISION;
                } else {
                    amountToMatched = (amountToInit * PRICE_PRECISION) / price;
                }
            } else {
                // When trying to buy less or equal to what is available in matched order, only bought amount
                // gets transferred (it's less). Some amount stays locked in the matched order

                // Buy exactly the amount of tokens buyer wants to buy
                // Amount of buy order tokenA transferred from sell to buy order
                amountToInit = initOrder.amount - initOrder.amountFilled;

                // Pay the seller according to the amount the buyer purchases
                if (quotedInInitB) {
                    // Transfer `price` times more tokenB from buy to sell order
                    amountToMatched = (amountToInit * price) / PRICE_PRECISION;
                } else {
                    amountToMatched = (amountToInit * PRICE_PRECISION) / price;
                }
            }
        }
        if (initOrder.side == OrderSide.Sell) {
            // When trying to sell more tokens than buyer can purchase, only transfer to him the amount
            // he can purchase

            if (
                initOrder.amount - initOrder.amountFilled >
                matchedOrder.amount - matchedOrder.amountFilled
            ) {
                // Give buyer all tokens he wants to buy
                // Amount of sell order tokenB transferred from sell to buy order
                amountToMatched =
                    matchedOrder.amount -
                    matchedOrder.amountFilled;

                // Buyer pays for tokens transferred to him
                if (quotedInInitB) {
                    // Transfer `price` less times tokenA from buy to sell order
                    amountToInit = (amountToMatched * PRICE_PRECISION) / price;
                } else {
                    amountToInit = (amountToMatched * price) / PRICE_PRECISION;
                }
            } else {
                // When trying to sell less tokens than buyer can purchase, whole available amount of sold
                // tokens gets transferred to the buyer

                // Give buyer all tokens seller wants to sell
                // Amount of sell order tokenB transferred from sell to buy order
                amountToMatched = initOrder.amount - initOrder.amountFilled;

                // Buyer pays for tokens transferred to him
                if (quotedInInitB) {
                    // Transfer `price` less times tokenA from buy to sell order
                    amountToInit = (amountToMatched * PRICE_PRECISION) / price;
                } else {
                    amountToInit = (amountToMatched * price) / PRICE_PRECISION;
                }
            }
        }

        return (tokenToInit, tokenToMatched, amountToInit, amountToMatched);
    }

    /// @dev Forms args structure to be used in `_createOrder` function later.
    ///      Avoids the `Stack too deep` error
    /// @param tokenA The address of the token that is purchased
    /// @param tokenB The address of the token that is sold
    /// @param amount The amount of active tokens
    /// @param limitPrice The limit price of the order in quoted tokens
    /// @param type_ The type of the order
    /// @param side The side of the order
    /// @param slippage The slippage of market order
    /// @param isCancellable True if order is cancellable. Otherwise - false
    function _prepareOrder(
        address tokenA,
        address tokenB,
        uint256 amount,
        uint256 limitPrice,
        OrderType type_,
        OrderSide side,
        uint256 slippage,
        bool isCancellable
    ) private returns (Order memory) {
        if (amount == 0) revert ZeroAmount();

        // NOTICE: first order gets the ID of 1
        _orderId.increment();
        uint256 id = _orderId.current();

        Order memory order = Order({
            id: id,
            user: msg.sender,
            tokenA: tokenA,
            tokenB: tokenB,
            amount: amount,
            // Initial amount is always 0
            amountFilled: 0,
            type_: type_,
            side: side,
            // Limit price is 0 for market orders
            limitPrice: limitPrice,
            slippage: slippage,
            isCancellable: isCancellable,
            status: OrderStatus.Active,
            // Leave 0 for lockAmount and feeAmount for now
            feeAmount: 0,
            amountLocked: 0
        });

        return order;
    }

    /// @dev Updates price of tokens pair
    /// @param initOrder The first matched order
    /// @param matchedOrder The second matched order
    function _updatePairPrice(
        Order memory initOrder,
        Order memory matchedOrder
    ) private {
        // Indicates that pair price is expressed in `initOrder.tokenB`
        // If `price` is expressed in `tokenB` of the `initOrder` then it should be used when transferring
        // But if it's expressed in `tokenA` of the `initOrder` then is should be inversed when transferring
        bool quotedInInitB;
        if (_isQuoted[initOrder.tokenA][initOrder.tokenB]) {
            quotedInInitB = true;
        } else {
            quotedInInitB = false;
        }

        if (quotedInInitB) {
            _pairPrices[initOrder.tokenA][initOrder.tokenB] = _getNewPrice(
                initOrder,
                matchedOrder
            );

            emit PriceChanged(
                initOrder.tokenA,
                initOrder.tokenB,
                _getNewPrice(initOrder, matchedOrder)
            );
        } else {
            _pairPrices[initOrder.tokenB][initOrder.tokenA] = _getNewPrice(
                initOrder,
                matchedOrder
            );

            emit PriceChanged(
                initOrder.tokenB,
                initOrder.tokenA,
                _getNewPrice(initOrder, matchedOrder)
            );
        }
    }

    /// @dev Updates locked and filled amounts of orders
    /// @param initOrder The first matched order
    /// @param matchedOrder The second matched order
    /// @param amountToInit The amount of active tokens transferred to `initOrder`
    /// @param amountToMatched The amount of active tokens transferred to `matchedOrder`
    function _updateOrdersAmounts(
        Order memory initOrder,
        Order memory matchedOrder,
        uint256 amountToInit,
        uint256 amountToMatched
    ) private {
        if (
            initOrder.side == OrderSide.Buy &&
            matchedOrder.side == OrderSide.Sell
        ) {
            // Bought tokens increment filled amount of buy order
            _orders[initOrder.id].amountFilled += amountToInit;
            // Bought tokens increment filled amount of sell order
            _orders[matchedOrder.id].amountFilled += amountToInit;
            // Bought tokens decrement locked amount of sell order
            _orders[matchedOrder.id].amountLocked -= amountToInit;
            // Sold tokens decrement locked amount of buy order
            _orders[initOrder.id].amountLocked -= amountToMatched;
        } else {
            // Sold tokens increment filled amount of buy order
            _orders[matchedOrder.id].amountFilled += amountToMatched;
            // Sold tokens increment filled amount of sell order
            _orders[initOrder.id].amountFilled += amountToMatched;
            // Sold tokens decrement locked amount of sell order
            _orders[initOrder.id].amountLocked -= amountToMatched;
            // Bought tokens decrement locked amount of buy order
            _orders[matchedOrder.id].amountLocked -= amountToInit;
        }
    }

    function _setDecimals(address tokenA, address tokenB, uint8 decimals) private {
        if (decimals < 4) revert InvalidDecimals();
        if (!_isQuoted[tokenA][tokenB] && !_isQuoted[tokenB][tokenA])
            revert PairNotCreated();
        
        emit DecimalsChanged(tokenA, tokenB, decimals);

        if (_isQuoted[tokenA][tokenB]) {
            _pairDecimals[tokenA][tokenB] = decimals;
        } else {
            _pairDecimals[tokenB][tokenA] = decimals;
        }
    }

    function _checkAndInitPairDecimals(address tokenA, address tokenB) private {
        if (getDecimals(tokenA, tokenB) == 0)
            _setDecimals(tokenA, tokenB, 4);
    }

    function _checkAdminOfControlledTokens(address user, address tokenA, address tokenB) private view {
        if (adminToken == address(0)) revert AdminTokenNotSet();
        bool isAdminA = true;
        bool isAdminB = true;
        if (tokenA != address(0) && IBentureAdmin(adminToken).checkIsControlled(tokenA)) {
            if (!IBentureAdmin(adminToken).checkAdminOfProject(user, tokenA)) {
                isAdminA = false;
            }
        }
        if (tokenB != address(0) && IBentureAdmin(adminToken).checkIsControlled(tokenB)) {
            if (!IBentureAdmin(adminToken).checkAdminOfProject(user, tokenB)) {
                isAdminB = false;
            }
        }

        if (!isAdminA && !isAdminB) revert NotAdmin();
    }

    function _startSaleSingle(
        address tokenA,
        address tokenB,
        uint256 amount,
        uint256 price
    ) 
        private
        updateQuotes(tokenA, tokenB)
        onlyAdminOfAny(msg.sender)
        returns(uint256)
    {
        _checkAdminOfControlledTokens(msg.sender, tokenA, tokenB);
        // Native tokens cannot be sold by admins
        if (tokenA == address(0)) revert InvalidFirstTokenAddress();

        Order memory order = _prepareOrder(
            tokenA,
            tokenB,
            amount,
            price,
            OrderType.Limit,
            OrderSide.Sell,
            0,
            // Orders are NON-cancellable
            false
        );

        emit SaleStarted(order.id, tokenA, tokenB, amount, price);

        _updatePairPriceOnLimit(order);

        _checkAndInitPairDecimals(tokenA, tokenB);

        // User has to lock exactly the amount of `tokenB` he is selling
        uint256 lockAmount = amount;

        // Calculate the fee amount for the order
        uint256 feeAmount = _getFee(lockAmount);

        // Mark that fee for new order was paid in `tokenB`
        _tokensToFeesIds[tokenB].add(order.id);

        // Mark that `tokenB` was locked
        _lockedTokens.add(order.tokenB);

        // Set the real fee and lock amounts
        order.feeAmount = feeAmount;

        _createOrder(order, lockAmount);

        return order.id;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

interface IBentureAdminErrors {
    error CallerIsNotAFactory();
    error InvalidFactoryAddress();
    error InvalidUserAddress();
    error InvalidAdminAddress();
    error UserDoesNotHaveAnAdminToken();
    error InvalidTokenAddress();
    error NoControlledToken();
    error FailedToDeleteTokenID();
    error MintToZeroAddressNotAllowed();
    error OnlyOneAdminTokenForProjectToken();
    error NotAnOwner();
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

interface IBentureDexErrors {
    error TxAlreadyExecuted(bytes32 txHash);
    error SlippageTooBig(uint256 slippage);
    error InvalidSignature();
    error OrderDoesNotExist();
    error InvalidFirstTokenAddress();
    error NoQuotedTokens();
    error AdminTokenNotSet();
    error ZeroPrice();
    error NoFeesToWithdraw();
    error NotAdmin();
    error DifferentLength();
    error NonCancellable();
    error InvalidOrderStatus();
    error ZeroAmount();
    error ZeroAddress();
    error NotOrderCreator();
    error TransferFailed();
    error NotEnoughNativeTokens();
    error InvalidPrice();
    error PairNotCreated();
    error InvalidDecimals();
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./errors/IBentureAdminErrors.sol";

/// @title An interface of a factory of custom ERC20 tokens;
interface IBentureAdmin is IBentureAdminErrors {
    /// @notice Checks it the provided address owns any admin token
    function checkOwner(address user) external view;

    /// @notice Checks if the provided user owns an admin token controlling the provided ERC20 token
    /// @param user The address of the user that potentially controls ERC20 token
    /// @param ERC20Address The address of the potentially controlled ERC20 token
    /// @return True if user has admin token. Otherwise - false.
    function checkAdminOfProject(
        address user,
        address ERC20Address
    ) external view returns (bool);

    /// @notice Checks if the provided token address is controlled ERC20 token
    /// @param ERC20Address The address of the potentially controlled ERC20 token
    /// @return True if provided token is an ERC20 controlled token. Otherwise - false.
    function checkIsControlled(
        address ERC20Address
    ) external view returns (bool);

    /// @notice Checks if the provided user is an admin of any project
    /// @param user The address of the user to check
    /// @return True if user is admin of any project. Otherwise - false
    function checkAdminOfAny(address user) external view returns (bool);

    /// @notice Returns the address of the controlled ERC20 token
    /// @param tokenId The ID of ERC721 token to check
    /// @return The address of the controlled ERC20 token
    function getControlledAddressById(
        uint256 tokenId
    ) external view returns (address);

    /// @notice Returns the list of all admin tokens of the user
    /// @param admin The address of the admin
    function getAdminTokenIds(
        address admin
    ) external view returns (uint256[] memory);

    /// @notice Returns the address of the factory that mints admin tokens
    /// @return The address of the factory
    function getFactory() external view returns (address);

    /// @notice Mints a new ERC721 token with the address of the controlled ERC20 token
    /// @param to The address of the receiver of the token
    /// @param ERC20Address The address of the controlled ERC20 token
    function mintWithERC20Address(address to, address ERC20Address) external;

    /// @notice Burns the token with the provided ID
    /// @param tokenId The ID of the token to burn
    function burn(uint256 tokenId) external;

    /// @dev Indicates that a new ERC721 token got minted
    event AdminTokenCreated(uint256 tokenId, address ERC20Address);

    /// @dev Indicates that an ERC721 token got burnt
    event AdminTokenBurnt(uint256 tokenId);

    /// @dev Indicates that an ERC721 token got transferred
    event AdminTokenTransferred(address from, address to, uint256 tokenId);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./errors/IBentureDexErrors.sol";

interface IBentureDex is IBentureDexErrors {
    /// @dev The type of the order (Market of Limit)
    enum OrderType {
        Market,
        Limit
    }

    /// @dev The status of the order
    /// @dev Active: created and waiting for matching
    ///      PartiallyClosed: only part of the order was matched and executed
    ///      Closed: the whole order was matched and executed
    ///      Cancelled: the whole order was cancelled
    enum OrderStatus {
        Active,
        PartiallyClosed,
        Closed,
        Cancelled
    }

    /// @dev The side of the order
    ///      Order side defines active tokens of the order
    enum OrderSide {
        Buy,
        Sell
    }

    /// @dev The structure of the single order
    struct Order {
        // The ID (number) of the order
        uint256 id;
        // The address which created an order
        address user;
        // The address of the tokens that is purchased
        address tokenA;
        // The address of the tokens that is sold
        address tokenB;
        // The initial amount of active tokens
        // Active tokens are defined by order side
        // If it's a "sell" order, then `tokenB` is active
        // If it's a "buy" order, then `tokenA` is active
        // This amount does not change during order execution
        uint256 amount;
        // The current amount of active tokens
        // Gets increased in any type of orders
        uint256 amountFilled;
        // Order type (market or limit)
        OrderType type_;
        // Order side (buy or sell)
        OrderSide side;
        // Only for limit orders. Zero for market orders
        // Includes precision
        // Expressed in quoted tokens
        uint256 limitPrice;
        // Allowed price slippage in Basis Points
        uint256 slippage;
        // True if order can be cancelled, false - if not
        bool isCancellable;
        // Status
        OrderStatus status;
        // The amount of active tokens paid as fee
        // Decreases after cancellation of partially executed order
        uint256 feeAmount;
        // The amount of tokens locked after order creation
        // Does not include fee
        // Equals `amount` in sell orders
        // Used in order cancelling
        uint256 amountLocked;
    }

    /// @notice Indicates that a new order has been created.
    /// @param id The ID of the order
    /// @param user The creator of the order
    /// @param tokenA The address of the token that is purchased
    /// @param tokenB The address of the token that is sold
    /// @param amount The amount of active tokens
    /// @param type_ The type of the order
    /// @param side The side of the order
    /// @param limitPrice The limit price of the order in quoted tokens
    /// @param isCancellable True if order is cancellable. Otherwise - false
    event OrderCreated(
        uint256 id,
        address user,
        address tokenA,
        address tokenB,
        uint256 amount,
        OrderType type_,
        OrderSide side,
        uint256 limitPrice,
        bool isCancellable
    );

    /// @notice Indicates that order fee rate was changed
    /// @param oldFeeRate The old fee rate
    /// @param newFeeRate The new set fee rate
    event FeeRateChanged(uint256 oldFeeRate, uint256 newFeeRate);

    /// @notice Indicates that backend address was changed
    /// @param oldAcc The address of the old backend account
    /// @param newAcc The address of the new backend account
    event BackendChanged(address oldAcc, address newAcc);

    /// @notice Indicates that admin token address was changed
    /// @param oldAdminToken The address of the old admin token
    /// @param newAdminToken The address of the new admin token
    event AdminTokenChanged(address oldAdminToken, address newAdminToken);

    /// @notice Indicates that a single series sale has started
    /// @param tokenA The purchased token
    /// @param tokenB The sold token
    /// @param amount The amount of sold tokens
    /// @param price The price at which the sell is made
    event SaleStarted(
        uint256 orderId,
        address tokenA,
        address tokenB,
        uint256 amount,
        uint256 price
    );

    /// @notice Indicates that the order was cancelled
    event OrderCancelled(uint256 id);

    /// @notice Indicates that orders were matched
    /// @param initId The ID of first matched order
    /// @param matchedId The ID of the second matched order
    event OrdersMatched(uint256 initId, uint256 matchedId);

    /// @notice Indicates that price of the pair was changed
    /// @param tokenA The address of the first token of the pair
    /// @param tokenB The address of the second token of the pair
    /// @param newPrice The new price of the pair in quoted tokens
    event PriceChanged(address tokenA, address tokenB, uint256 newPrice);

    /// @notice Indicates that fees collected with one token were withdrawn
    /// @param token The address of the token in which fees were collected
    /// @param amount The amount of fees withdrawn
    event FeesWithdrawn(uint256 orderId, address token, uint256 amount);

    /// @dev Indicates that 2/3 of block gas limit was spent during the
    ///      iteration inside the contract method
    /// @param orderId ID of the order during the operation with which the 2/3 of block gas limit was spent
    /// @param gasLeft How much gas was used
    /// @param gasLimit The block gas limit
    event GasLimitReached(uint256 orderId, uint256 gasLeft, uint256 gasLimit);

    /// @notice Indicates that token verification status changed
    /// @param token The address of the token whose status has changed
    /// @param verified New token verify status
    event IsTokenVerifiedChanged(address token, bool verified);

    /// @notice Indicates that pair decimals changed
    /// @param tokenA The address of the first token of the pair
    /// @param tokenB The address of the second token of the pair
    /// @param decimals New pair decimals
    event DecimalsChanged(address tokenA, address tokenB, uint8 decimals);

    /// @notice Returns the list of IDs of orders user has created
    /// @param user The address of the user
    /// @return The list of IDs of orders user has created
    function getUserOrders(
        address user
    ) external view returns (uint256[] memory);

    /// @notice Checks that order with the given ID exists
    /// @param id The ID to search for
    /// @return True if order with the given ID exists. Otherwise - false
    function checkOrderExists(uint256 id) external view returns (bool);

    /// @notice Returns information about the given order
    /// @param _id The ID of the order to search
    /// @return The creator of the order
    /// @return The address of the token that is purchased
    /// @return The address of the token that is sold
    /// @return The initial amount of active tokens
    /// @return The current increasing amount of active tokens
    /// @return The type of the order
    /// @return The side of the order
    /// @return The limit price of the order in quoted tokens
    /// @return True if order is cancellable. Otherwise - false
    /// @return The fee paid for order creation
    /// @return The locked amount of tokens
    /// @return The current status of the order
    function getOrder(
        uint256 _id
    )
        external
        view
        returns (
            address,
            address,
            address,
            uint256,
            uint256,
            OrderType,
            OrderSide,
            uint256,
            bool,
            uint256,
            uint256,
            OrderStatus
        );

    /// @notice Returns the lisf of IDs of orders containing given tokens
    /// @param tokenA The address of the token that is purchased
    /// @param tokenB The address of the token that is sold
    /// @return The list of IDs of orders containing given tokens
    function getOrdersByTokens(
        address tokenA,
        address tokenB
    ) external view returns (uint256[] memory);

    /// @notice Checks if pair of provided tokens exists
    /// @param tokenA The address of the first token
    /// @param tokenB The address of the second token
    /// @return True if pair exists.Otherwise - false
    function checkPairExists(
        address tokenA,
        address tokenB
    ) external view returns (bool);

    /// @notice Returns the price of the pair of tokens
    /// @param tokenA The address of the first token of the pair
    /// @param tokenB The address of the second token of the pair
    /// @return The quoted token of the pair
    /// @return The price of the pair in quoted tokens
    function getPrice(
        address tokenA,
        address tokenB
    ) external view returns (address, uint256);

    /// @notice Returns the amount necessary to lock to create an order
    /// @param tokenA The address of the token that is purchased
    /// @param tokenB The address of the token that is sold
    /// @param amount The amount of bought/sold tokens
    /// @param limitPrice The limit price of the order. Zero for market orders
    /// @param type_ The type of the order
    /// @param side The side of the order
    function getLockAmount(
        address tokenA,
        address tokenB,
        uint256 amount,
        uint256 limitPrice,
        OrderType type_,
        OrderSide side
    ) external view returns (uint256);

    /// @notice Checks if token is verified
    /// @param token The address of the token
    function getIsTokenVerified(address token) external view returns (bool);

    /// @notice Checks if orders have matched any time before
    /// @param firstId The ID of the first order to check
    /// @param secondId The ID of the second order to check
    /// @return True if orders matched. Otherwise - false
    function checkMatched(
        uint256 firstId,
        uint256 secondId
    ) external view returns (bool);

    /// @notice Creates a buy market order
    /// @dev Cannot create the first order of the orderbook
    /// @param tokenA The address of the token that is purchased
    /// @param tokenB The address of the token that is sold
    /// @param amount The amount of active tokens
    /// @param slippage Allowed price slippage (in basis points)
    /// @param nonce A unique integer for each tx call
    /// @param signature The signature used to sign the hash of the message
    function buyMarket(
        address tokenA,
        address tokenB,
        uint256 amount,
        uint256 slippage,
        uint256 nonce,
        bytes memory signature
    ) external payable;

    /// @notice Creates a sell market order
    /// @dev Cannot create the first order of the orderbook
    /// @param tokenA The address of the token that is purchased
    /// @param tokenB The address of the token that is sold
    /// @param amount The amount of active tokens
    /// @param slippage Allowed price slippage (in basis points)
    /// @param nonce A unique integer for each tx call
    /// @param signature The signature used to sign the hash of the message
    function sellMarket(
        address tokenA,
        address tokenB,
        uint256 amount,
        uint256 slippage,
        uint256 nonce,
        bytes memory signature
    ) external payable;

    /// @notice Creates an buy limit order
    /// @param tokenA The address of the token that is purchased
    /// @param tokenB The address of the token that is sold
    /// @param amount The amount of active tokens
    /// @param limitPrice The limit price of the order in quoted tokens
    function buyLimit(
        address tokenA,
        address tokenB,
        uint256 amount,
        uint256 limitPrice
    ) external payable;

    /// @notice Creates an sell limit order
    /// @param tokenA The address of the token that is purchased
    /// @param tokenB The address of the token that is sold
    /// @param amount The amount of active tokens
    /// @param limitPrice The limit price of the order in quoted tokens
    function sellLimit(
        address tokenA,
        address tokenB,
        uint256 amount,
        uint256 limitPrice
    ) external payable;

    /// @notice Cancels the limit order with the given ID.
    ///         Only limit orders can be cancelled
    /// @param id The ID of the limit order to cancel
    function cancelOrder(uint256 id) external;

    /// @notice Starts a single series sale of project tokens
    /// @param tokenA The address of the token that is received
    /// @param tokenB The address of the token that is sold
    /// @param amount The amount of sold tokens
    /// @param price The limit price of the order in quoted tokens
    function startSaleSingle(
        address tokenA,
        address tokenB,
        uint256 amount,
        uint256 price
    ) external payable;

    /// @notice Starts a multiple series sale of project tokens
    /// @param tokenA The address of the token that is received
    /// @param tokenB The address of the token that is sold
    /// @param amounts The list of amounts of sold tokens. One for each series
    /// @param prices The list of prices of sold tokens. One for each series
    function startSaleMultiple(
        address tokenA,
        address tokenB,
        uint256[] memory amounts,
        uint256[] memory prices
    ) external payable;

    /// @notice Executes matched orders
    /// @param initId The ID of the market/limit order
    /// @param matchedIds The list of IDs of limit orders
    /// @param nonce A unique integer for each tx call
    /// @param signature The signature used to sign the hash of the message
    /// @dev Sum of locked amounts of `matchedIds` is always less than or
    ///      equal to the
    function matchOrders(
        uint256 initId,
        uint256[] memory matchedIds,
        uint256 nonce,
        bytes calldata signature
    ) external;

    /// @notice Sets the address of the backend account
    /// @param acc The address of the backend account
    /// @dev This function should be called right after contract deploy.
    ///      Otherwise, order creation/cancelling/matching will not work.
    function setBackend(address acc) external;

    /// @notice Sets a new fee rate
    /// @param newFeeRate A new fee rate
    function setFee(uint256 newFeeRate) external;

    /// @notice Sets address of the admin token
    /// @param token The address of the admin token
    function setAdminToken(address token) external;

    /// @notice Sets the verification status of the token
    /// @param token The address of the token
    /// @param verified New verification status of the token
    function setIsTokenVerified(address token, bool verified) external;

    /// @notice Withdraws fees accumulated by creation of specified orders
    /// @param tokens The list of addresses of active tokens of the order
    function withdrawFees(address[] memory tokens) external;

    /// @notice Withdraws all fees accumulated by creation of orders
    function withdrawAllFees() external;
}