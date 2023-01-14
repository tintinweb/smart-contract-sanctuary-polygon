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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/cryptography/ECDSA.sol)

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
        InvalidSignatureV // Deprecated in v4.8
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
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
pragma solidity >= 0.8.1;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./ERC20ForwardRequestTypes.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 *
 * @title BiconomyForwarder
 *
 * @notice A trusted forwarder for Biconomy relayed meta transactions
 *
 * @dev - Inherits the ERC20ForwarderRequest struct
 * @dev - Verifies EIP712 signatures
 * @dev - Verifies personalSign signatures
 * @dev - Implements 2D nonces... each Tx has a BatchId and a BatchNonce
 * @dev - Keeps track of highest BatchId used by a given address, to assist in encoding of transactions client-side
 * @dev - maintains a list of verified domain seperators
 *
 */
contract BiconomyForwarder is ERC20ForwardRequestTypes,Ownable{
    using ECDSA for bytes32;

    mapping(bytes32 => bool) public domains;

    uint256 chainId;

    string public constant EIP712_DOMAIN_TYPE = "EIP712Domain(string name,string version,address verifyingContract,bytes32 salt)";

    bytes32 public constant REQUEST_TYPEHASH = keccak256(bytes("ERC20ForwardRequest(address from,address to,address token,uint256 txGas,uint256 tokenGasPrice,uint256 batchId,uint256 batchNonce,uint256 deadline,bytes data)"));

    mapping(address => mapping(uint256 => uint256)) nonces;

    constructor(
        address _owner
    ) public Ownable(){
        uint256 id;
        assembly {
            id := chainid()
        }
        chainId = id;
        require(_owner != address(0), "Owner Address cannot be 0");
    }

    /**
     * @dev registers domain seperators, maintaining that all domain seperators used for EIP712 forward requests use...
     * ... the address of this contract and the chainId of the chain this contract is deployed to
     * @param name : name of dApp/dApp fee proxy
     * @param version : version of dApp/dApp fee proxy
     */
    function registerDomainSeparator(string calldata name, string calldata version) external onlyOwner{
        uint256 id;
        /* solhint-disable-next-line no-inline-assembly */
        assembly {
            id := chainid()
        }

        bytes memory domainValue = abi.encode(
            keccak256(bytes(EIP712_DOMAIN_TYPE)),
            keccak256(bytes(name)),
            keccak256(bytes(version)),
            address(this),
            bytes32(id));

        bytes32 domainHash = keccak256(domainValue);

        domains[domainHash] = true;
        emit DomainRegistered(domainHash, domainValue);
    }

    event DomainRegistered(bytes32 indexed domainSeparator, bytes domainValue);

    /**
     * @dev returns a value from the nonces 2d mapping
     * @param from : the user address
     * @param batchId : the key of the user's batch being queried
     * @return nonce : the number of transaction made within said batch
     */
    function getNonce(address from, uint256 batchId)
    public view
    returns (uint256) {
        return nonces[from][batchId];
    }

    /**
     * @dev an external function which exposes the internal _verifySigEIP712 method
     * @param req : request being verified
     * @param domainSeparator : the domain separator presented to the user when signing
     * @param sig : the signature generated by the user's wallet
     */
    function verifyEIP712(
        ERC20ForwardRequest calldata req,
        bytes32 domainSeparator,
        bytes calldata sig)
    external view {
        _verifySigEIP712(req, domainSeparator, sig);
    }

    /**
     * @dev verifies the call is valid by calling _verifySigEIP712
     * @dev executes the forwarded call if valid
     * @dev updates the nonce after
     * @param req : request being executed
     * @param domainSeparator : the domain separator presented to the user when signing
     * @param sig : the signature generated by the user's wallet
     * @return success : false if call fails. true otherwise
     * @return ret : any return data from the call
     */
    function executeEIP712(
        ERC20ForwardRequest calldata req,
        bytes32 domainSeparator,
        bytes calldata sig
    )
    external 
    returns (bool success, bytes memory ret) {
        _verifySigEIP712(req,domainSeparator,sig);
        _updateNonce(req);
        /* solhint-disable-next-line avoid-low-level-calls */
         (success,ret) = req.to.call{gas : req.txGas}(abi.encodePacked(req.data, req.from));
         // Validate that the relayer has sent enough gas for the call.
        // See https://ronan.eth.link/blog/ethereum-gas-dangers/
        assert(gasleft() > req.txGas / 63);
        _verifyCallResult(success,ret,"Forwarded call to destination did not succeed");
    }

    /**
     * @dev an external function which exposes the internal _verifySigPersonSign method
     * @param req : request being verified
     * @param sig : the signature generated by the user's wallet
     */
    function verifyPersonalSign(
        ERC20ForwardRequest calldata req,
        bytes calldata sig)
    external view {
        _verifySigPersonalSign(req, sig);
    }

    /**
     * @dev verifies the call is valid by calling _verifySigPersonalSign
     * @dev executes the forwarded call if valid
     * @dev updates the nonce after
     * @param req : request being executed
     * @param sig : the signature generated by the user's wallet
     * @return success : false if call fails. true otherwise
     * @return ret : any return data from the call
     */
    function executePersonalSign(ERC20ForwardRequest calldata req,bytes calldata sig)
    external 
    returns(bool success, bytes memory ret){
        _verifySigPersonalSign(req, sig);
        _updateNonce(req);
        (success,ret) = req.to.call{gas : req.txGas}(abi.encodePacked(req.data, req.from));
        // Validate that the relayer has sent enough gas for the call.
        // See https://ronan.eth.link/blog/ethereum-gas-dangers/
        assert(gasleft() > req.txGas / 63);
        _verifyCallResult(success,ret,"Forwarded call to destination did not succeed");
    }

    /**
     * @dev Increments the nonce of given user/batch pair
     * @dev Updates the highestBatchId of the given user if the request's batchId > current highest
     * @dev only intended to be called post call execution
     * @param req : request that was executed
     */
    function _updateNonce(ERC20ForwardRequest calldata req) internal {
        nonces[req.from][req.batchId]++;
    }

    /**
     * @dev verifies the domain separator used has been registered via registerDomainSeparator()
     * @dev recreates the 32 byte hash signed by the user's wallet (as per EIP712 specifications)
     * @dev verifies the signature using Open Zeppelin's ECDSA library
     * @dev signature valid if call doesn't throw
     *
     * @param req : request being executed
     * @param domainSeparator : the domain separator presented to the user when signing
     * @param sig : the signature generated by the user's wallet
     *
     */
    function _verifySigEIP712(
        ERC20ForwardRequest calldata req,
        bytes32 domainSeparator,
        bytes memory sig)
    internal
    view
    {   
        uint256 id;
        /* solhint-disable-next-line no-inline-assembly */
        assembly {
            id := chainid()
        }
        require(req.deadline == 0 || block.timestamp + 20 <= req.deadline, "request expired");
        require(domains[domainSeparator], "unregistered domain separator");
        require(chainId == id, "potential replay attack on the fork");
        bytes32 digest =
            keccak256(abi.encodePacked(
                "\x19\x01",
                domainSeparator,
                keccak256(abi.encode(REQUEST_TYPEHASH,
                            req.from,
                            req.to,
                            req.token,
                            req.txGas,
                            req.tokenGasPrice,
                            req.batchId,
                            nonces[req.from][req.batchId],
                            req.deadline,
                            keccak256(req.data)
                        ))));
        require(digest.recover(sig) == req.from, "signature mismatch");
    }

    /**
     * @dev encodes a 32 byte data string (presumably a hash of encoded data) as per eth_sign
     *
     * @param hash : hash of encoded data that signed by user's wallet using eth_sign
     * @return input hash encoded to matched what is signed by the user's key when using eth_sign*/
    function prefixed(bytes32 hash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev recreates the 32 byte hash signed by the user's wallet
     * @dev verifies the signature using Open Zeppelin's ECDSA library
     * @dev signature valid if call doesn't throw
     *
     * @param req : request being executed
     * @param sig : the signature generated by the user's wallet
     *
     */
    function _verifySigPersonalSign(
        ERC20ForwardRequest calldata req,
        bytes memory sig)
    internal
    view
    {
        require(req.deadline == 0 || block.timestamp + 20 <= req.deadline, "request expired");
        bytes32 digest = prefixed(keccak256(abi.encodePacked(
            req.from,
            req.to,
            req.token,
            req.txGas,
            req.tokenGasPrice,
            req.batchId,
            nonces[req.from][req.batchId],
            req.deadline,
            keccak256(req.data)
        )));
        require(digest.recover(sig) == req.from, "signature mismatch");
    }

    /**
     * @dev verifies the call result and bubbles up revert reason for failed calls
     *
     * @param success : outcome of forwarded call
     * @param returndata : returned data from the frowarded call
     * @param errorMessage : fallback error message to show 
     */
     function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure {
        if (!success) {
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

// SPDX-License-Identifier: MIT
pragma solidity >= 0.7.6;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./ERC20ForwarderStorage.sol";
// import "../lib/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./interfaces/IFeeManager.sol";
// import "./interfaces/IERC20Permit.sol";
import "./BiconomyForwarder.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol";


/**
 * @title ERC20 Forwarder
 *
 * @notice A contract for dApps to coordinate meta transactions paid for with ERC20 transfers
 * @notice This contract is upgradeable and using using unstructured proxy pattern.
 *         https://blog.openzeppelin.com/proxy-patterns/
 *         Users always interact with Proxy contract (storage layer) - ERC20ForwarderProxy.sol
 * @dev Inherits the ERC20ForwarderRequest struct from Storage contract (using same storage contract inherited by Proxy to avoid storage collisions) - essential for compatibility with The BiconomyForwarder
 * @dev Tx Flow : calls BiconomyForwarder to handle forwarding, call _transferHandler() to charge fee after
 *
 */
 contract ERC20Forwarder is Ownable, ERC20ForwarderStorage{
     using SafeMath for uint256;
     bool internal initialized;

     constructor(address _owner) public Ownable(){
        require(_owner != address(0), "Owner Address cannot be 0");
    }
      
     /**
     * @dev sets contract variables
     *
     * @param _feeReceiver : address that will receive fees charged in ERC20 tokens
     * @param _feeManager : the address of the contract that controls the charging of fees
     * @param _forwarder : the address of the BiconomyForwarder contract
     *
     */
       function initialize(
       address _feeReceiver,
       address _feeManager,
       address payable _forwarder
       ) public {
        
        require(!initialized, "ERC20 Forwarder: contract is already initialized");
        require(
            _feeReceiver != address(0),
            "ERC20Forwarder: new fee receiver is the zero address"
        );
        require(
            _feeManager != address(0),
            "ERC20Forwarder: new fee manager is the zero address"
        );
        require(
            _forwarder != address(0),
            "ERC20Forwarder: new forwarder is the zero address"
        );
        initialized = true;
        feeReceiver = _feeReceiver;
        feeManager = _feeManager;
        forwarder = _forwarder;
       }
       
    
    function setOracleAggregator(address oa) external onlyOwner{
        require(
            oa != address(0),
            "ERC20Forwarder: new oracle aggregator can not be a zero address"
        );
        oracleAggregator = oa;
        emit OracleAggregatorChanged(oracleAggregator, msg.sender);
    }


    function setTrustedForwarder(address payable _forwarder) external onlyOwner {
        require(
            _forwarder != address(0),
            "ERC20Forwarder: new trusted forwarder can not be a zero address"
        );
        forwarder = _forwarder;
        emit TrustedForwarderChanged(forwarder, msg.sender);
    }

    /**
     * @dev enable dApps to change fee receiver addresses, e.g. for rotating keys/security purposes
     * @param _feeReceiver : address that will receive fees charged in ERC20 tokens */
    function setFeeReceiver(address _feeReceiver) external onlyOwner{
        require(
            _feeReceiver != address(0),
            "ERC20Forwarder: new fee receiver can not be a zero address"
        );
        feeReceiver = _feeReceiver;
    }

    /**
     * @dev enable dApps to change the contract that manages fee collection logic
     * @param _feeManager : the address of the contract that controls the charging of fees */
    function setFeeManager(address _feeManager) external onlyOwner{
        require(
            _feeManager != address(0),
            "ERC20Forwarder: new fee manager can not be a zero address"
        );
        feeManager = _feeManager;
    }

    function setBaseGas(uint128 gas) external onlyOwner{
        baseGas = gas;
        emit BaseGasChanged(baseGas,msg.sender);
    }
    
    function setGasRefund(uint128 refund) external onlyOwner{
        gasRefund = refund;
        emit GasRefundChanged(gasRefund,msg.sender);
    }

    function setGasTokenForwarderBaseGas(uint128 gas) external onlyOwner{
        gasTokenForwarderBaseGas = gas;
        emit GasTokenForwarderBaseGasChanged(gasTokenForwarderBaseGas,msg.sender);
    }

    /**
     * Designed to enable the community to track change in storage variable forwarder which is used
     * as a trusted forwarder contract where signature verifiction and replay attack prevention schemes are
     * deployed.
     */
    event TrustedForwarderChanged(address indexed newForwarderAddress, address indexed actor);

    /**
     * Designed to enable the community to track change in storage variable oracleAggregator which is used
     * as a oracle aggregator contract where different feeds are aggregated
     */
    event OracleAggregatorChanged(address indexed newOracleAggregatorAddress, address indexed actor);

    /* Designed to enable the community to track change in storage variable baseGas which is used for charge calcuations 
       Unlikely to change */
    event BaseGasChanged(uint128 newBaseGas, address indexed actor);

    /* Designed to enable the community to track change in storage variable transfer handler gas for particular ERC20 token which is used for charge calculations
       Only likely to change to offset the charged fee */ 
    event TransferHandlerGasChanged(address indexed tokenAddress, address indexed actor, uint256 indexed newGas);

    /* Designed to enable the community to track change in refundGas which is used to benefit users when gas tokens are burned
       Likely to change in the event of offsetting Biconomy's cost OR when new gas tokens are used */
    event GasRefundChanged(uint128 newGasRefund, address indexed actor);

    /* Designed to enable the community to track change in gas token forwarder base gas which is Biconomy's cost when gas tokens are burned for refund
       Likely to change in the event of offsetting Biconomy's cost OR when new gas token forwarder is used */
    event GasTokenForwarderBaseGasChanged(uint128 newGasTokenForwarderBaseGas, address indexed actor);
 
    /**
     * @dev change amount of excess gas charged for _transferHandler
     * NOT INTENTED TO BE CALLED : may need to be called if :
     * - new feeManager consumes more/less gas
     * - token contract is upgraded to consume less gas
     * - etc
     */
     /// @param _transferHandlerGas : max amount of gas the function _transferHandler is expected to use
    function setTransferHandlerGas(address token, uint256 _transferHandlerGas) external onlyOwner{
        require(
            token != address(0),
            "token cannot be zero"
       );
        transferHandlerGas[token] = _transferHandlerGas;
        emit TransferHandlerGasChanged(token,msg.sender,_transferHandlerGas);
    }

    function setSafeTransferRequired(address token, bool _safeTransferRequired) external onlyOwner{
        require(
            token != address(0),
            "token cannot be zero"
       );
        safeTransferRequired[token] = _safeTransferRequired;
    }
    
       
       /**
     * @dev calls the getNonce function of the BiconomyForwarder
     * @param from : the user address
     * @param batchId : the key of the user's batch being queried
     * @return nonce : the number of transaction made within said batch
     */
    function getNonce(address from, uint256 batchId)
    external view
    returns(uint256 nonce){
        nonce = BiconomyForwarder(forwarder).getNonce(from,batchId);
    }
    
    
     /**
     * @dev
     * - Keeps track of gas consumed
     * - Calls BiconomyForwarder.executeEIP712 method using arguments given
     * - Calls _transferHandler, supplying the gas usage of the executeEIP712 call
     */
    /**
     * @param req : the request being forwarded
     * @param domainSeparator : the domain separator presented to the user when signing
     * @param sig : the signature generated by the user's wallet
     * @return success : false if call fails. true otherwise
     * @return ret : any return data from the call
     */
    function executeEIP712(
        ERC20ForwardRequest calldata req,
        bytes32 domainSeparator,
        bytes calldata sig
        )
        external 
        returns (bool success, bytes memory ret){
            uint256 initialGas = gasleft();
            (success,ret) = BiconomyForwarder(forwarder).executeEIP712(req,domainSeparator,sig);
            uint256 postGas = gasleft();
            uint256 transferHandlerGas = transferHandlerGas[req.token];
            uint256 charge = _transferHandler(req,initialGas.add(baseGas).add(transferHandlerGas).sub(postGas));
            emit FeeCharged(req.from,charge,req.token);
    }

    /**
     * @dev
     * - calls permit method on the underlying ERC20 token contract (DAI permit type) with given permit options
     * - Keeps track of gas consumed
     * - Calls BiconomyForwarder.executeEIP712 method using arguments given
     * - Calls _transferHandler, supplying the gas usage of the executeEIP712 call
     */
    /**
     * @param req : the request being forwarded
     * @param domainSeparator : the domain separator presented to the user when signing
     * @param sig : the signature generated by the user's wallet
     * @param permitOptions : the permit request options for executing permit. Since it is not EIP2612 permit pass permitOptions.value = 0 for this struct. 
     * @return success : false if call fails. true otherwise
     * @return ret : any return data from the call
     */
    // function permitAndExecuteEIP712(
    //     ERC20ForwardRequest calldata req,
    //     bytes32 domainSeparator,
    //     bytes calldata sig,
    //     PermitRequest calldata permitOptions
    //     )
    //     external 
    //     returns (bool success, bytes memory ret){
    //         uint256 initialGas = gasleft();
    //         (success,ret) = BiconomyForwarder(forwarder).executeEIP712(req,domainSeparator,sig);
    //         //DAI permit
    //         IERC20Permit(req.token).permit(permitOptions.holder, permitOptions.spender, permitOptions.nonce, permitOptions.expiry, permitOptions.allowed, permitOptions.v, permitOptions.r, permitOptions.s);
    //         uint256 postGas = gasleft();
    //         uint256 transferHandlerGas = transferHandlerGas[req.token];
    //         uint256 charge = _transferHandler(req,initialGas.add(baseGas).add(transferHandlerGas).sub(postGas));
    //         emit FeeCharged(req.from,charge,req.token);
    // }

    /**
     * @dev
     * - calls permit method on the underlying ERC20 token contract (which supports EIP2612 permit) with given permit options
     * - Keeps track of gas consumed
     * - Calls BiconomyForwarder.executeEIP712 method using arguments given
     * - Calls _transferHandler, supplying the gas usage of the executeEIP712 call
     */
    /**
     * @param req : the request being forwarded
     * @param domainSeparator : the domain separator presented to the user when signing
     * @param sig : the signature generated by the user's wallet
     * @param permitOptions : the permit request options for executing permit. Since it is EIP2612 permit pass permitOptions.allowed = true/false for this struct. 
     * @return success : false if call fails. true otherwise
     * @return ret : any return data from the call
     */
    function permitEIP2612AndExecuteEIP712(
        ERC20ForwardRequest calldata req,
        bytes32 domainSeparator,
        bytes calldata sig,
        PermitRequest calldata permitOptions
        )
        external 
        returns (bool success, bytes memory ret){
            uint256 initialGas = gasleft();
            (success,ret) = BiconomyForwarder(forwarder).executeEIP712(req,domainSeparator,sig);
            //USDC or any EIP2612 permit
            IERC20Permit(req.token).permit(permitOptions.holder, permitOptions.spender, permitOptions.value, permitOptions.expiry, permitOptions.v, permitOptions.r, permitOptions.s);
            uint256 postGas = gasleft();
            uint256 transferHandlerGas = transferHandlerGas[req.token];
            uint256 charge = _transferHandler(req,initialGas.add(baseGas).add(transferHandlerGas).sub(postGas));
            emit FeeCharged(req.from,charge,req.token);
    }

     /**
     * @dev
     * - Keeps track of gas consumed
     * - Calls BiconomyForwarder.executeEIP712 method using arguments given
     * - Calls _transferHandler, supplying the gas usage of the executeEIP712 call
     *  * NOT INTENTED TO BE CALLED : may need to be called by Biconomy Relayers
     */
    /**
     * @param req : the request being forwarded
     * @param domainSeparator : the domain separator presented to the user when signing
     * @param sig : the signature generated by the user's wallet
     * @param gasTokensBurned : number of gas tokens to be burned in this transaction
     * @return success : false if call fails. true otherwise
     * @return ret : any return data from the call
     */
    function executeEIP712WithGasTokens( 
        ERC20ForwardRequest calldata req,
        bytes32 domainSeparator,
        bytes calldata sig,
        uint256 gasTokensBurned
        )
        external 
        returns (bool success, bytes memory ret){
            uint256 initialGas = gasleft();
            (success,ret) = BiconomyForwarder(forwarder).executeEIP712(req,domainSeparator,sig);
            uint256 postGas = gasleft();
            uint256 transferHandlerGas = transferHandlerGas[req.token];
            uint256 charge = _transferHandler(req,initialGas.add(baseGas).add(gasTokenForwarderBaseGas).add(transferHandlerGas).sub(postGas).sub(gasTokensBurned.mul(gasRefund)));
            emit FeeCharged(req.from,charge,req.token);
    }

    /**
     * @dev
     * - calls permit method on the underlying ERC20 token contract (DAI permit type) with given permit options
     * - Keeps track of gas consumed
     * - Calls BiconomyForwarder.executeEIP712 method using arguments given
     * - Calls _transferHandler, supplying the gas usage of the executeEIP712 call
     *  * NOT INTENTED TO BE CALLED : may need to be called by Biconomy Relayers
     */
    /**
     * @param req : the request being forwarded
     * @param domainSeparator : the domain separator presented to the user when signing
     * @param sig : the signature generated by the user's wallet
     * @param gasTokensBurned : number of gas tokens to be burned in this transaction
     * @param permitOptions : the permit request options for executing permit. Since it is not EIP2612 permit pass permitOptions.value = 0 for this struct.  
     * @return success : false if call fails. true otherwise
     * @return ret : any return data from the call
     */
    // function permitAndExecuteEIP712WithGasTokens( 
    //     ERC20ForwardRequest calldata req,
    //     bytes32 domainSeparator,
    //     bytes calldata sig,
    //     PermitRequest calldata permitOptions,
    //     uint256 gasTokensBurned
    //     )
    //     external 
    //     returns (bool success, bytes memory ret){
    //         uint256 initialGas = gasleft();
    //         (success,ret) = BiconomyForwarder(forwarder).executeEIP712(req,domainSeparator,sig);
    //         //DAI Permit
    //         IERC20Permit(req.token).permit(permitOptions.holder, permitOptions.spender, permitOptions.nonce, permitOptions.expiry, permitOptions.allowed, permitOptions.v, permitOptions.r, permitOptions.s);
    //         uint256 postGas = gasleft();
    //         uint256 transferHandlerGas = transferHandlerGas[req.token];
    //         uint256 charge = _transferHandler(req,initialGas.add(baseGas).add(gasTokenForwarderBaseGas).add(transferHandlerGas).sub(postGas).sub(gasTokensBurned.mul(gasRefund)));
    //         emit FeeCharged(req.from,charge,req.token);
    // }

    /**
     * @dev
     * - calls permit method on the underlying ERC20 token contract (which supports EIP2612 permit) with given permit options
     * - Keeps track of gas consumed
     * - Calls BiconomyForwarder.executeEIP712 method using arguments given
     * - Calls _transferHandler, supplying the gas usage of the executeEIP712 call
     *  * NOT INTENTED TO BE CALLED : may need to be called by Biconomy Relayers
     */
    /**
     * @param req : the request being forwarded
     * @param domainSeparator : the domain separator presented to the user when signing
     * @param sig : the signature generated by the user's wallet
     * @param gasTokensBurned : number of gas tokens to be burned in this transaction
     * @param permitOptions : the permit request options for executing permit. Since it is EIP2612 permit pass permitOptions.allowed = true/false for this struct. 
     * @return success : false if call fails. true otherwise
     * @return ret : any return data from the call
     */
    function permitEIP2612AndExecuteEIP712WithGasTokens( 
        ERC20ForwardRequest calldata req,
        bytes32 domainSeparator,
        bytes calldata sig,
        PermitRequest calldata permitOptions,
        uint256 gasTokensBurned
        )
        external 
        returns (bool success, bytes memory ret){
            uint256 initialGas = gasleft();
            (success,ret) = BiconomyForwarder(forwarder).executeEIP712(req,domainSeparator,sig);
            //EIP2612 Permit
            IERC20Permit(req.token).permit(permitOptions.holder, permitOptions.spender, permitOptions.value, permitOptions.expiry, permitOptions.v, permitOptions.r, permitOptions.s);
            uint256 postGas = gasleft();
            uint256 transferHandlerGas = transferHandlerGas[req.token];
            uint256 charge = _transferHandler(req,initialGas.add(baseGas).add(gasTokenForwarderBaseGas).add(transferHandlerGas).sub(postGas).sub(gasTokensBurned.mul(gasRefund)));
            emit FeeCharged(req.from,charge,req.token);
    }

     /**
     * @dev
     * - Keeps track of gas consumed
     * - Calls BiconomyForwarder.executePersonalSign method using arguments given
     * - Calls _transferHandler, supplying the gas usage of the executePersonalSign call
    **/
    /**
     * @param req : the request being forwarded
     * @param sig : the signature generated by the user's wallet
     * @return success : false if call fails. true otherwise
     * @return ret : any return data from the call
     */
    function executePersonalSign(
        ERC20ForwardRequest calldata req,
        bytes calldata sig
        )
        external 
        returns (bool success, bytes memory ret){
            uint256 initialGas = gasleft();
            (success,ret) = BiconomyForwarder(forwarder).executePersonalSign(req,sig);
            uint256 postGas = gasleft();
            uint256 transferHandlerGas = transferHandlerGas[req.token];
            uint256 charge = _transferHandler(req,initialGas.add(baseGas).add(transferHandlerGas).sub(postGas));
            emit FeeCharged(req.from,charge,req.token);
    }

    /**
     * @dev
     * - Keeps track of gas consumed
     * - Calls BiconomyForwarder.executePersonalSign method using arguments given
     * - Calls _transferHandler, supplying the gas usage of the executePersonalSign call
     *   NOT INTENTED TO BE CALLED : may need to be called by Biconomy Relayers
    **/
    /**
     * @param req : the request being forwarded
     * @param sig : the signature generated by the user's wallet
     * @param gasTokensBurned : number of gas tokens to be burned in this transaction
     * @return success : false if call fails. true otherwise
     * @return ret : any return data from the call
     */
    function executePersonalSignWithGasTokens(
        ERC20ForwardRequest calldata req,
        bytes calldata sig,
        uint256 gasTokensBurned
        )
        external 
        returns (bool success, bytes memory ret){
            uint256 initialGas = gasleft();
            (success,ret) = BiconomyForwarder(forwarder).executePersonalSign(req,sig);
            uint256 postGas = gasleft();
            uint256 transferHandlerGas = transferHandlerGas[req.token];
            uint256 charge = _transferHandler(req,initialGas.add(baseGas).add(gasTokenForwarderBaseGas).add(transferHandlerGas).sub(postGas).sub(gasTokensBurned.mul(gasRefund)));
            emit FeeCharged(req.from,charge,req.token);
    }

    // Designed to enable capturing token fees charged during the execution
    event FeeCharged(address indexed from, uint256 indexed charge, address indexed token);

    /**
     * @dev
     * - Verifies if token supplied in request is allowed
     * - Transfers tokenGasPrice*totalGas*feeMultiplier $req.token, from req.to to feeReceiver
    **/
    /**
     * @param req : the request being forwarded
     * @param executionGas : amount of gas used to execute the forwarded request call
     */
    function _transferHandler(ERC20ForwardRequest calldata req,uint256 executionGas) internal returns(uint256 charge){
        IFeeManager _feeManager = IFeeManager(feeManager);
        require(_feeManager.getTokenAllowed(req.token),"TOKEN NOT ALLOWED BY FEE MANAGER");        
        charge = req.tokenGasPrice.mul(executionGas).mul(_feeManager.getFeeMultiplier(req.from,req.token)).div(10000);
        if (!safeTransferRequired[req.token]){
            
            require(IERC20(req.token).transferFrom(
            req.from,
            feeReceiver,
            charge));
        }
        else{
            SafeERC20.safeTransferFrom(IERC20(req.token), req.from,feeReceiver,charge);
        }
    }
       
 }

// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.1;
pragma experimental ABIEncoderV2;

import "./ERC20ForwardRequestTypes.sol";

/**
 * @title ERC20 Forward Storage
 *
 * @notice A contract for dApps to coordinate meta transactions paid for with ERC20 transfers
 *
 * @dev Inherits the ERC20ForwarderRequest struct via the contract of same name - essential for compatibility with The BiconomyForwarder
 * @dev Contract owner can set the feeManager contract & the feeReceiver address
 * @dev Tx Flow : call BiconomyForwarder to handle forwarding, call _transferHandler() to charge fee after
 *
 */

contract ERC20ForwarderStorage is ERC20ForwardRequestTypes{
    mapping(address=>uint256) public transferHandlerGas;
    mapping(address=>bool) public safeTransferRequired;
    address public feeReceiver;
    address public oracleAggregator;
    address public feeManager;
    address public forwarder;
    //transaction base gas
    uint128 public baseGas=21000;
    /*gas refund given for each burned CHI token. This value is calcuated from 24000*80% (24000 is EVM gas refund for each burned CHI token) - 6150 (Biconomy's gas overhead for burning each CHI token)   */
    uint128 public gasRefund=13050; 
    //gas token forwarder base gas 
    uint128 public gasTokenForwarderBaseGas = 32330;
}

// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.1;
pragma experimental ABIEncoderV2;

/* deadline can be removed : GSN reference https://github.com/opengsn/gsn/blob/master/contracts/forwarder/IForwarder.sol (Saves 250 more gas)*/
/**
* This contract defines a struct which both ERC20FeeProxy and BiconomyForwarder inherit. ERC20ForwardRequest specifies all the fields present in the GSN V2 ForwardRequest struct, 
* but adds the following :
* address token
* uint256 tokenGasPrice
* uint256 txGas
* uint256 batchNonce (can be removed)
* uint256 deadline 
* Fields are placed in type order, to minimise storage used when executing transactions.
*/
contract ERC20ForwardRequestTypes{

/*allow the EVM to optimize for this, 
ensure that you try to order your storage variables and struct members such that they can be packed tightly*/

    struct ERC20ForwardRequest {
        address from; 
        address to; 
        address token; 
        uint256 txGas;
        uint256 tokenGasPrice;
        uint256 batchId; 
        uint256 batchNonce; 
        uint256 deadline; 
        bytes data;
    }

     struct PermitRequest {
        address holder; 
        address spender;  
        uint256 value;
        uint256 nonce;
        uint256 expiry;
        bool allowed; 
        uint8 v;
        bytes32 r; 
        bytes32 s; 
    }

    
}

// SPDX-License-Identifier: MIT
pragma solidity >= 0.7.6;

interface IFeeManager{
    function getFeeMultiplier(address user, address token) external view returns (uint16 basisPoints); //setting max multiplier at 6.5536
    function getTokenAllowed(address token) external view returns (bool allowed);
}